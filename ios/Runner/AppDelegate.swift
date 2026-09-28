import Flutter
import UIKit
import GoogleMaps
import Razorpay
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var razorpayCustomBridge: RazorpayCustomBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     GMSServices.provideAPIKey("AIzaSyDaxxK1mhgIzh5jhn-YRVRz84aO9h-Gxoc")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// With the UIScene lifecycle (required from iOS 27) the Flutter engine is
  /// only created once the scene loads Main.storyboard, after launch — so
  /// plugins and app-level channels are registered here, not in
  /// didFinishLaunching. See https://flutter.dev/to/uiscene-migration
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    razorpayCustomBridge = RazorpayCustomBridge(
      messenger: engineBridge.applicationRegistrar.messenger())
  }
}

/// iOS twin of the Android bridge in `MainActivity.kt`: exposes the native
/// Razorpay iOS Custom Checkout SDK (`razorpay-customui-pod`) on the same
/// `wander_nova/razorpay_custom` channel with the same two methods, so the
/// Flutter Custom Checkout screens work unchanged on both platforms.
///
/// The SDK needs a real WKWebView for bank 3DS/OTP and UPI collect pages, so
/// one is shown full-screen (with a Cancel button) only while a payment is in
/// flight.
final class RazorpayCustomBridge: NSObject {
  private let channel: FlutterMethodChannel
  private var razorpay: RazorpayCheckout?
  private var razorpayKeyId: String?
  private var webView: WKWebView?
  private let hostController = UIViewController()
  private var navController: UINavigationController?
  private var pendingResult: FlutterResult?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "wander_nova/razorpay_custom", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let keyId = args["keyId"] as? String ?? ""

    switch call.method {
    case "getPaymentMethods":
      ensureRazorpay(keyId)
      RazorpayCheckout.getPaymentMethods(withOptions: nil, withSuccessCallback: { methods in
        // Same contract as Android: the methods object as a JSON string.
        let json = (try? JSONSerialization.data(withJSONObject: methods))
          .flatMap { String(data: $0, encoding: .utf8) }
        DispatchQueue.main.async { result(json) }
      }, andFailureCallback: { error in
        DispatchQueue.main.async {
          result(FlutterError(code: "METHODS_ERROR", message: error, details: nil))
        }
      })

    case "getUpiApps":
      // UPI apps installed on this device that can take an intent payment,
      // normalised to the same [{name, package}] shape Android returns.
      RazorpayCheckout.getAppsWhichSupportUpi { apps in
        let normalised: [[String: String]] = apps.compactMap { app in
          func str(_ keys: [String]) -> String? {
            for key in keys {
              if let v = app[key] as? String, !v.isEmpty { return v }
            }
            return nil
          }
          guard let package = str(["appPackageName", "packageName", "package_name",
                                   "app_package_name", "shortcode", "appShortcode", "package"])
          else { return nil }
          let name = str(["appName", "app_name", "name", "displayName"]) ?? package
          return ["name": name, "package": package]
        }
        DispatchQueue.main.async { result(normalised) }
      }

    case "submitPayment":
      submitPayment(keyId: keyId, dataJson: args["data"] as? String ?? "", result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func submitPayment(keyId: String, dataJson: String, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "IN_PROGRESS", message: "A payment is already in progress", details: nil))
      return
    }
    guard let data = dataJson.data(using: .utf8),
          let raw = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
      result(FlutterError(code: "SUBMIT_EXCEPTION", message: "Invalid payment data", details: nil))
      return
    }

    let payload = Self.iosPayload(raw)
    ensureRazorpay(keyId)
    pendingResult = result

    guard let nav = navController, let presenter = Self.topViewController() else {
      finish(FlutterError(code: "SUBMIT_EXCEPTION", message: "Could not open payment page", details: nil))
      return
    }
    nav.modalPresentationStyle = .fullScreen
    presenter.present(nav, animated: true)
    razorpay?.authorize(payload)
  }

  /// The Dart screens build Android-style payloads. The iOS SDK takes nested
  /// objects as flat form keys (`card[number]`, per Razorpay's iOS docs) and
  /// the UPI flow as `flow`, so translate here to keep Dart identical.
  private static func iosPayload(_ raw: [String: Any]) -> [AnyHashable: Any] {
    var out: [AnyHashable: Any] = [:]
    for (key, value) in raw {
      if let nested = value as? [String: Any] {
        for (k, v) in nested { out["\(key)[\(k)]"] = v }
      } else if key == "_[flow]" {
        out["flow"] = value
      } else {
        out[key] = value
      }
    }
    return out
  }

  private func ensureRazorpay(_ keyId: String) {
    if razorpay != nil && razorpayKeyId == keyId { return }
    teardown()

    let webView = WKWebView(frame: UIScreen.main.bounds, configuration: WKWebViewConfiguration())
    webView.navigationDelegate = self
    webView.backgroundColor = .white
    webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.webView = webView

    hostController.view.backgroundColor = .white
    hostController.view.subviews.forEach { $0.removeFromSuperview() }
    webView.frame = hostController.view.bounds
    hostController.view.addSubview(webView)
    hostController.title = "Complete Payment"
    hostController.navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    if navController == nil {
      navController = UINavigationController(rootViewController: hostController)
    }

    razorpay = RazorpayCheckout.initWithKey(keyId, andDelegate: self, withPaymentWebView: webView)
    razorpayKeyId = keyId
  }

  @objc private func cancelTapped() {
    let alert = UIAlertController(
      title: "Cancel payment?",
      message: "Are you sure you want to cancel this payment?",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "No", style: .cancel))
    alert.addAction(UIAlertAction(title: "Yes, Cancel", style: .destructive) { [weak self] _ in
      self?.razorpay?.userCancelledPayment()
      self?.finish(FlutterError(code: "CANCELLED", message: "Payment cancelled", details: nil))
    })
    hostController.present(alert, animated: true)
  }

  /// Delivers the single result for the in-flight payment, dismisses the
  /// payment page and resets the SDK (a fresh instance per payment, as in
  /// Razorpay's own Flutter plugin).
  private func finish(_ value: Any?) {
    DispatchQueue.main.async {
      guard let result = self.pendingResult else { return }
      self.pendingResult = nil
      result(value)
      self.navController?.dismiss(animated: true)
      self.teardown()
    }
  }

  private func teardown() {
    razorpay?.close()
    webView?.stopLoading()
    webView?.removeFromSuperview()
    webView = nil
    razorpay = nil
    razorpayKeyId = nil
  }

  private static func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}

extension RazorpayCustomBridge: RazorpayPaymentCompletionProtocol {
  func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable: Any]) {
    finish([
      "paymentId": (response["razorpay_payment_id"] as? String) ?? payment_id,
      "orderId": response["razorpay_order_id"] as? String,
      "signature": response["razorpay_signature"] as? String,
    ] as [String: Any?])
  }

  func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable: Any]) {
    finish(FlutterError(code: String(code), message: str, details: nil))
  }
}

extension RazorpayCustomBridge: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    razorpay?.webView(webView, didCommit: navigation)
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    razorpay?.webView(webView, didFinish: navigation)
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    razorpay?.webView(webView, didFail: navigation, withError: error)
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    razorpay?.webView(webView, didFailProvisionalNavigation: navigation, withError: error)
  }
}
