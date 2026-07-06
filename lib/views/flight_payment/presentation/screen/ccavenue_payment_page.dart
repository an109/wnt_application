import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/constants/urls.dart';
import '../../data/ccavenue_service.dart';

enum PaymentResult { success, failure, cancelled }


class CCAvenuePaymentPage extends StatefulWidget {
  const CCAvenuePaymentPage({
    super.key,
    required this.service,
    required this.session,
    this.successScheme = Urls.ccavenueSuccessUrl,
    this.failureScheme = Urls.ccavenueFailureUrl,
  });

  final CCAvenueService service;
  final CheckoutSession session;
  final String successScheme;
  final String failureScheme;

  @override
  State<CCAvenuePaymentPage> createState() => _CCAvenuePaymentPageState();
}

class _CCAvenuePaymentPageState extends State<CCAvenuePaymentPage> {
  static const _blue = Color(0xFF1769F6);
  static const _pageBg = Color(0xFFF3F6FC);

  late final WebViewController _controller;
  bool _loading = true;
  bool _confirming = false;
  bool _finished = false;
  String? _loadError;
  // Tracks the last result URL so _confirmAndPop can fall back to URL-based
  // success/failure when getStatus fails (e.g. wallet flow uses WTX reference
  // as orderId, not a raw CCAvenue order ID).
  String? _lastResultUrl;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_pageBg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('CCAvenue WebView ▶ started: $url');
            _maybeFinishFromUrl(url);
          },
          // onUrlChange catches server-side 302 redirects to our result URLs,
          // which Android may not surface via onNavigationRequest.
          onUrlChange: (change) {
            final url = change.url;
            debugPrint('CCAvenue WebView ↪ urlChange: $url');
            if (url != null) _maybeFinishFromUrl(url);
          },
          onPageFinished: (url) {
            debugPrint('CCAvenue WebView ✓ finished: $url');
            if (mounted) setState(() => _loading = false);
          },
          // Surface load failures instead of showing a blank white screen.
          onWebResourceError: (err) {
            debugPrint(
              'CCAvenue WebView ✗ error: ${err.errorCode} ${err.description} '
              '(main frame: ${err.isForMainFrame})',
            );
            if (err.isForMainFrame == true && mounted) {
              setState(() {
                _loading = false;
                _loadError =
                    'Could not load the payment page.\n${err.description}';
              });
            }
          },
          onHttpError: (err) {
            final code = err.response?.statusCode ?? 0;
            final url = err.response?.uri?.toString() ?? '';
            debugPrint('CCAvenue WebView X httpError: $code @ $url');
            // If CCAvenue's own server returns an HTTP error (4xx/5xx) on the
            // main transaction URL, the merchant credentials or account are
            // misconfigured — show a clear error instead of the broken page.
            if (code >= 400 && url.contains('ccavenue.com') && mounted) {
              setState(() {
                _loading = false;
                _loadError =
                    'Payment gateway is currently unavailable (HTTP $code).\n'
                    'Please try a different payment method or contact support.';
              });
            }
          },
          onNavigationRequest: (req) {
            // Detect redirect back to our success/failure URLs and close
            // before the page actually loads.
            if (_isResultUrl(req.url)) {
              _confirmAndPop();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      final cookieManager = WebViewCookieManager().platform;
      if (cookieManager is AndroidWebViewCookieManager) {
        cookieManager.setAcceptThirdPartyCookies(androidController, true);
      }
    }

    _controller.loadRequest(Uri.parse(widget.session.checkoutUrl));
  }

  // Matches both the hosted-checkout scheme (/payment/success path) and the
  // wallet add-money scheme (?payment=success query param).
  bool _isSuccessUrl(String url) =>
      url.contains('/payment/success') || url.contains('payment=success');

  bool _isFailureUrl(String url) =>
      url.contains('/payment/failed') ||
      url.contains('payment=failed') ||
      url.contains('payment=failure') ||
      url.contains('payment=cancel');

  bool _isResultUrl(String url) => _isSuccessUrl(url) || _isFailureUrl(url);

  void _maybeFinishFromUrl(String url) {
    if (_isResultUrl(url)) {
      _lastResultUrl = url;
      _confirmAndPop();
    }
  }

  /// Confirm with the backend status endpoint when possible, otherwise fall
  /// back to the redirect URL (wallet flow uses a WTX reference as orderId
  /// which the CCAvenue status endpoint cannot look up).
  Future<void> _confirmAndPop() async {
    if (_finished) return;
    _finished = true;
    _controller.loadRequest(Uri.parse('about:blank'));
    if (mounted) setState(() => _confirming = true);

    PaymentResult result = PaymentResult.failure;
    try {
      final status = await widget.service.getStatus(widget.session.orderId);
      result = status == 'success'
          ? PaymentResult.success
          : PaymentResult.failure;
    } catch (_) {
      // getStatus failed (e.g. wallet flow where orderId is a WTX reference).
      // Trust the redirect URL as the fallback source of truth.
      final resultUrl = _lastResultUrl ?? '';
      result = _isSuccessUrl(resultUrl)
          ? PaymentResult.success
          : PaymentResult.failure;
    }
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_finished) {
          Navigator.of(context).pop(PaymentResult.cancelled);
        }
      },
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          title: const WanderNovaLogo(scaleFactor: 0.6),
          backgroundColor: _pageBg,
          elevation: 0,
          actions: [
            Padding(
              padding: EdgeInsets.all(context.w(8)),
              child: Image.asset(
                'assets/images/wander_nova_logo.jpg',
                height: 35,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _secureBanner(context),
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_loadError != null) _errorView(context),
                    if (_loadError == null && (_loading || _confirming))
                      _overlay(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secureBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(10),
      ),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: _blue, size: context.iconMedium),
          SizedBox(width: context.gapSmall),
          Expanded(
            child: Text(
              'Secure payment powered by CCAvenue',
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    return Container(
      color: _pageBg,
      padding: EdgeInsets.all(context.w(24)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: Colors.red.shade400, size: context.w(48)),
            SizedBox(height: context.gapLarge),
            Text(
              _loadError ?? 'Could not load the payment page.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: context.gapLarge),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loadError = null;
                  _loading = true;
                });
                _controller.loadRequest(Uri.parse(widget.session.checkoutUrl));
              },
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlay(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _blue),
            SizedBox(height: context.gapLarge),
            Text(
              _confirming ? 'Confirming your payment...' : 'Loading payment...',
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
