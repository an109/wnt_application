import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/constants/urls.dart';
import 'package:wander_nova/core/network/dio_client.dart';
import 'package:wander_nova/injection_container.dart';

import 'checkout_ui.dart';

/// Result of asking whether the current QR has been paid.
enum QrCheck { paid, notYet, failed, busy }

/// A wallet top-up by Razorpay UPI QR. There is no Razorpay order in this
/// flow (backend contract):
///  1. POST wallet/add-money/ {gateway: razorpay_qr} → the pending wallet
///     transaction's `reference`
///  2. POST razorpay/create-qr-code/ {reference_id, amount, description}
///     → qr_id, image_url, close_by. QR codes need live keys: on test keys
///     the backend answers 503.
///  3. GET razorpay/qr-status/<qr_id>/ → {paid, payment_id}, polled every 4s
///     until the QR expires
///  4. [onPaid] with the reference and payment id → the checkout calls
///     wallet/verify-payment/, which credits idempotently, so retrying is safe
///
/// Owned by the checkout screen rather than [QrPayPanel], so polling keeps
/// going while the Scan QR tab is hidden or the UPI section is collapsed.
/// Every QR gets its own wallet transaction, so an old QR can never be paid
/// against a newer QR's reference.
class QrPayController extends ChangeNotifier {
  QrPayController({required this.amount, required this.onPaid});

  final double amount;

  /// Credits the wallet; returns whether that succeeded.
  final Future<bool> Function(String reference, String paymentId) onPaid;

  static const _pollEvery = Duration(seconds: 4);

  /// How long a QR is shown and polled before it counts as expired. Razorpay
  /// keeps the QR itself open for 2 hours (`close_by`), which caps this.
  static const _window = Duration(minutes: 10);

  bool loading = false;
  bool completing = false;
  bool expired = false;

  /// Paid, but crediting the wallet failed — the panel offers a retry.
  bool paid = false;
  String? error;
  String? qrId;
  Duration left = Duration.zero;
  ui.Image? qrImage;
  Uint8List? rawImage; // fallback when the QR can't be isolated

  String? _reference;
  DateTime? _expiresAt;
  Timer? _poll;
  Timer? _ticker;
  bool _inFlight = false;
  bool _disposed = false;

  Dio get _dio => sl<DioClient>().instance;

  @override
  void dispose() {
    _disposed = true;
    _stopTimers();
    qrImage?.dispose();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _stopTimers() {
    _poll?.cancel();
    _ticker?.cancel();
    _poll = null;
    _ticker = null;
  }

  Future<void> generate() async {
    if (loading || completing) return;
    // An old QR paid after we stopped watching it must still be credited, so
    // look at it once more before replacing it.
    if (qrId != null && await check() == QrCheck.paid) return;
    if (_disposed) return;
    loading = true;
    error = null;
    _notify();
    try {
      final wallet = _body(
        await _dio.post(
          Urls.walletAddMoney,
          data: {
            'amount': amount,
            'currency': 'INR',
            'payment_method': 'razorpay',
            'gateway': 'razorpay_qr',
          },
        ),
      );
      final reference = wallet['reference']?.toString();
      if (reference == null || reference.isEmpty) {
        throw _QrFailure(wallet['error']?.toString());
      }

      final qr = _body(
        await _dio.post(
          Urls.razorpayCreateQr,
          data: {
            'reference_id': reference,
            'amount': amount,
            'description': 'Wander Nova Wallet Top-up',
          },
        ),
      );
      final id = qr['qr_id']?.toString();
      final imageUrl = qr['image_url']?.toString();
      if (id == null || id.isEmpty || imageUrl == null || imageUrl.isEmpty) {
        throw _QrFailure(qr['error']?.toString());
      }

      // image_url is a public Razorpay link: fetch it with a bare client so
      // the user's API token is never sent to Razorpay.
      final img =
          await Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
            ),
          ).get<List<int>>(
            imageUrl,
            options: Options(responseType: ResponseType.bytes),
          );
      final bytes = Uint8List.fromList(img.data ?? const []);
      final cropped = await cropQrPoster(bytes);
      if (_disposed) {
        cropped?.dispose();
        return;
      }

      var expiresAt = DateTime.now().add(_window);
      final closeBy = qr['close_by'];
      if (closeBy is num) {
        final closes = DateTime.fromMillisecondsSinceEpoch(
          (closeBy * 1000).round(),
        );
        if (closes.isBefore(expiresAt)) expiresAt = closes;
      }

      _stopTimers();
      qrImage?.dispose();
      _reference = reference;
      qrId = id;
      qrImage = cropped;
      rawImage = cropped == null ? bytes : null;
      _expiresAt = expiresAt;
      left = expiresAt.difference(DateTime.now());
      expired = false;
      paid = false;
      loading = false;
      _notify();
      _poll = Timer.periodic(_pollEvery, (_) => check());
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (e) {
      loading = false;
      error = _errorText(e);
      _notify();
    }
  }

  void _tick() {
    final expiresAt = _expiresAt;
    if (expiresAt == null || _disposed) return;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining > Duration.zero) {
      left = remaining;
      _notify();
      return;
    }
    _stopTimers();
    left = Duration.zero;
    expired = true;
    _notify();
    // The customer may have paid in the last few seconds.
    check();
  }

  /// Asks the backend whether the current QR has been paid and, if so, hands
  /// the payment to [onPaid].
  Future<QrCheck> check() async {
    final id = qrId;
    final reference = _reference;
    if (id == null || reference == null || _inFlight || completing) {
      return QrCheck.busy;
    }
    _inFlight = true;
    try {
      final body = _body(await _dio.get(Urls.razorpayQrStatus(id)));
      final paymentId = body['payment_id']?.toString();
      if (body['paid'] != true || paymentId == null || paymentId.isEmpty) {
        return QrCheck.notYet;
      }
      if (_disposed) return QrCheck.busy;
      _stopTimers();
      completing = true;
      _notify();
      final credited = await onPaid(reference, paymentId);
      if (!credited) {
        completing = false;
        paid = true;
        _notify();
      }
      return QrCheck.paid;
    } catch (_) {
      return QrCheck.failed;
    } finally {
      _inFlight = false;
    }
  }

  static Map<String, dynamic> _body(Response<dynamic> res) {
    final data = res.data;
    return data is Map ? data.cast<String, dynamic>() : const {};
  }

  static String _errorText(Object e) {
    if (e is DioException) {
      // QR codes need live Razorpay keys; on test keys the backend says 503.
      if (e.response?.statusCode == 503) {
        return 'QR payments are not available right now. '
            'Please pay with a UPI ID or another method.';
      }
      final data = e.response?.data;
      final message = data is Map
          ? (data['error'] ?? data['message'])?.toString()
          : null;
      if (message != null && message.isNotEmpty) return message;
    } else if (e is _QrFailure) {
      final message = e.message;
      if (message != null && message.isNotEmpty) return message;
    }
    return 'Could not generate the QR code. Please try again.';
  }
}

/// A successful reply missing what the QR flow needs, carrying the backend's
/// `error` text when it sent one.
class _QrFailure implements Exception {
  final String? message;

  const _QrFailure(this.message);
}

/// "Scan QR" tab: shows the [QrPayController]'s QR with a countdown, and
/// lets the customer confirm payment or get a fresh QR.
class QrPayPanel extends StatefulWidget {
  final QrPayController controller;

  const QrPayPanel({super.key, required this.controller});

  @override
  State<QrPayPanel> createState() => _QrPayPanelState();
}

class _QrPayPanelState extends State<QrPayPanel> {
  bool _checking = false;

  QrPayController get _qr => widget.controller;

  String get _countdown {
    final s = _qr.left.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    final result = await _qr.check();
    if (!mounted) return;
    setState(() => _checking = false);
    final message = switch (result) {
      QrCheck.notYet =>
        "We haven't received the payment yet. It can take a few seconds.",
      QrCheck.failed => 'Could not check the payment status. Please try again.',
      QrCheck.paid || QrCheck.busy => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _qr,
      builder: (context, _) {
        if (_qr.qrId == null) return _intro(context);
        if (_qr.expired && !_qr.paid) return _expiredView(context);
        return _qrView(context);
      },
    );
  }

  Widget _qrView(BuildContext context) {
    final size = context.w(210).clamp(160.0, 280.0);
    return Column(
      children: [
        Text(
          'Scan with any UPI app',
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w700,
            color: CheckoutColors.ink,
          ),
        ),
        SizedBox(height: context.h(4)),
        Text(
          'Pay ${formatInr(_qr.amount)} using GPay, PhonePe, Paytm or any UPI app',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.fs(12),
            color: CheckoutColors.muted,
          ),
        ),
        SizedBox(height: context.h(14)),
        Container(
          padding: EdgeInsets.all(context.w(10)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: CheckoutColors.stroke),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
              ),
            ],
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: _qr.qrImage != null
                ? RawImage(
                    image: _qr.qrImage,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  )
                : Image.memory(
                    _qr.rawImage!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: InlineNote(
                        'Could not load the QR image. Tap "Generate new QR".',
                        icon: Icons.error_outline_rounded,
                        color: CheckoutColors.error,
                      ),
                    ),
                  ),
          ),
        ),
        SizedBox(height: context.h(12)),
        _statusRow(context),
        if (_qr.error != null) ...[
          SizedBox(height: context.h(10)),
          InlineNote(
            _qr.error!,
            icon: Icons.error_outline_rounded,
            color: CheckoutColors.error,
          ),
        ],
        SizedBox(height: context.h(14)),
        CheckoutPayButton(
          label: _qr.paid ? 'Retry adding to wallet' : 'I have scanned & paid',
          loading: _checking || _qr.completing,
          onPressed: _checkNow,
        ),
        if (!_qr.paid)
          TextButton.icon(
            onPressed: _qr.loading || _qr.completing ? null : _qr.generate,
            icon: _qr.loading
                ? SizedBox(
                    width: context.w(14),
                    height: context.w(14),
                    child: const CircularProgressIndicator(strokeWidth: 1.6),
                  )
                : Icon(Icons.refresh_rounded, size: context.w(16)),
            label: Text(
              'Generate new QR',
              style: TextStyle(fontSize: context.fs(12.5)),
            ),
          ),
      ],
    );
  }

  Widget _statusRow(BuildContext context) {
    final text = _qr.completing
        ? 'Payment received — adding to wallet…'
        : _qr.paid
        ? 'Payment received'
        : 'Waiting for payment · expires in $_countdown';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_qr.paid && !_qr.completing)
          Icon(
            Icons.check_circle_rounded,
            size: context.w(14),
            color: CheckoutColors.offer,
          )
        else
          SizedBox(
            width: context.w(12),
            height: context.w(12),
            child: const CircularProgressIndicator(
              strokeWidth: 1.6,
              color: CheckoutColors.primary,
            ),
          ),
        SizedBox(width: context.w(8)),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: context.fs(12),
              color: CheckoutColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _expiredView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: context.w(44),
              height: context.w(44),
              decoration: BoxDecoration(
                color: CheckoutColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
              child: Icon(
                Icons.timer_off_rounded,
                color: CheckoutColors.error,
                size: context.w(24),
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Text(
                'This QR has expired. Generate a new one to pay.',
                style: TextStyle(
                  fontSize: context.fs(12.5),
                  color: CheckoutColors.ink,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        if (_qr.error != null) ...[
          SizedBox(height: context.h(10)),
          InlineNote(
            _qr.error!,
            icon: Icons.error_outline_rounded,
            color: CheckoutColors.error,
          ),
        ],
        SizedBox(height: context.h(14)),
        CheckoutPayButton(
          label: 'Generate new QR',
          loading: _qr.loading || _qr.completing,
          onPressed: _qr.generate,
        ),
      ],
    );
  }

  Widget _intro(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: context.w(44),
              height: context.w(44),
              decoration: BoxDecoration(
                color: CheckoutColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                color: CheckoutColors.primary,
                size: context.w(28),
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Text(
                'Generate a QR and scan it with any UPI app on another phone — or screenshot it and scan from your gallery.',
                style: TextStyle(
                  fontSize: context.fs(12.5),
                  color: CheckoutColors.ink,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        if (_qr.error != null) ...[
          SizedBox(height: context.h(10)),
          InlineNote(
            _qr.error!,
            icon: Icons.error_outline_rounded,
            color: CheckoutColors.error,
          ),
        ],
        SizedBox(height: context.h(14)),
        CheckoutPayButton(
          label: 'Generate QR',
          loading: _qr.loading,
          onPressed: _qr.generate,
        ),
      ],
    );
  }
}

/// Razorpay's QR image is a branded poster. Find the QR inside it — the
/// longest unbroken run of rows (then columns) containing dark modules,
/// which text lines can't match — and crop to it with a quiet zone.
/// Returns null (show the full image) if nothing square-ish is found.
@visibleForTesting
Future<ui.Image?> cropQrPoster(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final src = (await codec.getNextFrame()).image;
    final data = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final w = src.width, h = src.height;

    bool dark(int x, int y) {
      final i = (y * w + x) * 4;
      final r = data.getUint8(i),
          g = data.getUint8(i + 1),
          b = data.getUint8(i + 2);
      final a = data.getUint8(i + 3);
      return a > 128 && r < 90 && g < 90 && b < 90;
    }

    (int, int)? longestRun(int length, bool Function(int) hit) {
      int bestStart = -1, bestLen = 0, curStart = -1;
      for (var i = 0; i <= length; i++) {
        final on = i < length && hit(i);
        if (on && curStart < 0) curStart = i;
        if (!on && curStart >= 0) {
          if (i - curStart > bestLen) {
            bestLen = i - curStart;
            bestStart = curStart;
          }
          curStart = -1;
        }
      }
      return bestLen == 0 ? null : (bestStart, bestStart + bestLen);
    }

    final rows = longestRun(h, (y) {
      var c = 0;
      for (var x = 0; x < w; x += 2) {
        if (dark(x, y)) c++;
      }
      return c * 2 >= w * 0.04;
    });
    if (rows == null) return null;
    final cols = longestRun(w, (x) {
      var c = 0;
      for (var y = rows.$1; y < rows.$2; y += 2) {
        if (dark(x, y)) c++;
      }
      return c * 2 >= (rows.$2 - rows.$1) * 0.04;
    });
    if (cols == null) return null;

    final qw = cols.$2 - cols.$1, qh = rows.$2 - rows.$1;
    final ratio = qw / qh;
    if (ratio < 0.8 || ratio > 1.25 || qw < w * 0.2) return null;

    final pad = (qw * 0.06).round();
    final rect = Rect.fromLTRB(
      (cols.$1 - pad).clamp(0, w).toDouble(),
      (rows.$1 - pad).clamp(0, h).toDouble(),
      (cols.$2 + pad).clamp(0, w).toDouble(),
      (rows.$2 + pad).clamp(0, h).toDouble(),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & rect.size, Paint()..color = Colors.white);
    canvas.drawImageRect(
      src,
      rect,
      Offset.zero & rect.size,
      Paint()..filterQuality = FilterQuality.none,
    );
    return await recorder.endRecording().toImage(
      rect.width.round(),
      rect.height.round(),
    );
  } catch (_) {
    return null;
  }
}
