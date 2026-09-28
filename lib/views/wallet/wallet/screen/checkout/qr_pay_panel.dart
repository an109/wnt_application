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

/// "Scan QR" tab: a Razorpay UPI QR the customer scans with any UPI app.
///
/// Flow (backend contract):
///  1. POST create-qr {reference_id, amount, description} → qr_id
///  2. GET  qr-image/<qr_id>/ (server proxy) → poster image; we crop it down
///     to the QR itself so no Razorpay branding shows
///  3. GET  qr-status/<qr_id>/ → {paid, payment_id} — polled automatically
///     and on "I have scanned & paid"
///  4. [onPaid] with the payment id → parent calls wallet/verify-payment/
class QrPayPanel extends StatefulWidget {
  final double amount;

  /// Returns the wallet reference (creating the wallet transaction if
  /// needed), or null if the customer backed out / it failed.
  final Future<String?> Function() prepareReference;
  final Future<void> Function(String paymentId) onPaid;

  const QrPayPanel({
    super.key,
    required this.amount,
    required this.prepareReference,
    required this.onPaid,
  });

  @override
  State<QrPayPanel> createState() => _QrPayPanelState();
}

class _QrPayPanelState extends State<QrPayPanel> {
  static const _pollEvery = Duration(seconds: 4);

  bool _loading = false;
  bool _checking = false;
  bool _completing = false;
  String? _error;
  String? _qrId;
  ui.Image? _qrImage;
  Uint8List? _rawImage; // fallback when the QR can't be isolated
  Timer? _poll;

  Dio get _dio => sl<DioClient>().instance;

  @override
  void dispose() {
    _poll?.cancel();
    _qrImage?.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reference = await widget.prepareReference();
      if (reference == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final res = await _dio.post(
        Urls.razorpayCreateQr,
        data: {
          'reference_id': reference,
          'amount': widget.amount,
          'description': 'Wallet Top-up',
        },
      );
      final body = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      final qrId = (body['qr_id'] ?? body['id'])?.toString();
      if (qrId == null || qrId.isEmpty) {
        throw Exception(body['error'] ?? 'QR could not be created');
      }

      final img = await _dio.get<List<int>>(
        Urls.razorpayQrImage(qrId),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(img.data ?? const []);
      final cropped = await cropQrPoster(bytes);

      if (!mounted) return;
      setState(() {
        _qrId = qrId;
        _qrImage = cropped;
        _rawImage = cropped == null ? bytes : null;
        _loading = false;
      });
      _poll?.cancel();
      _poll = Timer.periodic(_pollEvery, (_) => _checkStatus(silent: true));
    } catch (e) {
      if (!mounted) return;
      final data = e is DioException ? e.response?.data : null;
      setState(() {
        _loading = false;
        _error =
            (data is Map ? data['error']?.toString() : null) ??
            'Could not generate the QR code. Please try again.';
      });
    }
  }

  Future<void> _checkStatus({bool silent = false}) async {
    final qrId = _qrId;
    if (qrId == null || _checking || _completing) return;
    if (!silent) setState(() => _checking = true);
    try {
      final res = await _dio.get(Urls.razorpayQrStatus(qrId));
      final body = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      final paid = body['paid'] == true;
      final paymentId = body['payment_id']?.toString();
      if (!mounted) return;
      if (paid && paymentId != null && paymentId.isNotEmpty) {
        _poll?.cancel();
        setState(() {
          _checking = false;
          _completing = true;
        });
        await widget.onPaid(paymentId);
        if (mounted) setState(() => _completing = false);
        return;
      }
      if (!silent) {
        setState(() => _checking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "We haven't received the payment yet. It can take a few seconds.",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _checking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not check the payment status. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_qrId == null) return _intro(context);

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
          'Pay ${formatInr(widget.amount)} using GPay, PhonePe, Paytm or any UPI app',
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
            child: _qrImage != null
                ? RawImage(
                    image: _qrImage,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  )
                : Image.memory(_rawImage!, fit: BoxFit.contain),
          ),
        ),
        SizedBox(height: context.h(12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                _completing
                    ? 'Payment received — adding to wallet…'
                    : 'Waiting for payment…',
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: CheckoutColors.muted,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(14)),
        CheckoutPayButton(
          label: 'I have scanned & paid',
          loading: _checking || _completing,
          onPressed: () => _checkStatus(),
        ),
        TextButton.icon(
          onPressed: _loading || _completing ? null : _generate,
          icon: Icon(Icons.refresh_rounded, size: context.w(16)),
          label: Text(
            'Generate new QR',
            style: TextStyle(fontSize: context.fs(12.5)),
          ),
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
        if (_error != null) ...[
          SizedBox(height: context.h(10)),
          InlineNote(
            _error!,
            icon: Icons.error_outline_rounded,
            color: CheckoutColors.error,
          ),
        ],
        SizedBox(height: context.h(14)),
        CheckoutPayButton(
          label: 'Generate QR',
          loading: _loading,
          onPressed: _generate,
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
