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
  private var hostController: UIViewController?
  private var navController: UINavigationController?
  private var pendingResult: FlutterResult?

  /// Resolves the payment as a failure when the page never reaches the
  /// window. Without it a presentation UIKit quietly refuses leaves the Dart
  /// future unresolved, so the checkout screen keeps its "Complete the
  /// payment…" spinner forever *and* every later attempt is rejected as
  /// already in progress — the bridge wedges for the rest of the session.
  private var appearanceGuard: DispatchWorkItem?

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
      // The static lookup reads the key off the most recently initialised
      // instance, so one has to exist — but it must never be rebuilt
      // underneath a payment that is already in flight.
      if pendingResult == nil { prepareCheckout(keyId: keyId) }
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

    // A fresh web view, host and navigation controller for every payment: the
    // SDK binds the web view at init, and a controller that has already been
    // presented and dismissed cannot be reliably presented a second time.
    prepareCheckout(keyId: keyId, rebuild: true)

    guard let nav = navController,
          let presenter = Self.presenter(excluding: [navController, hostController]) else {
      print("[rzp] no view controller to present the payment page from")
      result(FlutterError(code: "SUBMIT_EXCEPTION", message: "Could not open payment page", details: nil))
      return
    }

    pendingResult = result
    nav.modalPresentationStyle = .fullScreen

    // `authorize` is deliberately deferred to the presentation completion.
    // The SDK drives the bank 3DS/OTP and UPI collect pages inside this web
    // view, and iOS keeps a WKWebView's content process suspended until the
    // view is in a window — so authorising first happens to work in the
    // Simulator but leaves a real device on a page that never loads and a
    // payment that never calls back.
    print("[rzp] presenting payment page for method "
          + "\(raw["method"] ?? "?"), amount \(raw["amount"] ?? "?")")
    presenter.present(nav, animated: true) { [weak self] in
      guard let self, self.pendingResult != nil else { return }
      print("[rzp] page on screen, authorizing")
      self.razorpay?.authorize(payload)
    }
    startAppearanceGuard()
  }

  /// Fails the payment if the page has not made it on screen shortly after
  /// presenting, so a refused presentation can never wedge the bridge.
  private func startAppearanceGuard() {
    appearanceGuard?.cancel()
    let item = DispatchWorkItem { [weak self] in
      guard let self,
            self.pendingResult != nil,
            self.navController?.view.window == nil else { return }
      print("[rzp] payment page never reached the window")
      self.finish(FlutterError(
        code: "SUBMIT_EXCEPTION",
        message: "The payment page could not be opened. Please try again.",
        details: nil))
    }
    appearanceGuard = item
    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: item)
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

  /// Builds the SDK instance and the page it draws into. `rebuild` forces a
  /// brand-new web view, host and navigation controller, which every payment
  /// gets; the methods lookup reuses whatever is already standing.
  private func prepareCheckout(keyId: String, rebuild: Bool = false) {
    if !rebuild, razorpay != nil, razorpayKeyId == keyId { return }
    teardown()

    let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    webView.navigationDelegate = self
    webView.backgroundColor = .white
    webView.translatesAutoresizingMaskIntoConstraints = false
    self.webView = webView

    let host = UIViewController()
    host.view.backgroundColor = .white
    host.title = "Complete Payment"
    host.navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    host.view.addSubview(webView)
    // Pinned rather than frame-set: the host's view has no useful bounds
    // until the navigation controller lays it out, and a zero-sized web view
    // never renders a bank page. Top/bottom follow the safe area so an OTP
    // field cannot end up under the navigation bar or the home indicator.
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor),
      webView.bottomAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
    ])
    hostController = host
    navController = UINavigationController(rootViewController: host)

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
    (hostController ?? navController)?.present(alert, animated: true)
  }

  /// Delivers the single result for the in-flight payment, dismisses the
  /// payment page and resets the SDK (a fresh instance per payment, as in
  /// Razorpay's own Flutter plugin).
  private func finish(_ value: Any?) {
    DispatchQueue.main.async {
      self.appearanceGuard?.cancel()
      self.appearanceGuard = nil
      guard let result = self.pendingResult else { return }
      self.pendingResult = nil
      result(value)

      // Tear the SDK down only once the page is off screen: closing it from
      // under a web view that is still presented cuts the SDK's own cleanup
      // short.
      guard let nav = self.navController, nav.presentingViewController != nil else {
        self.teardown()
        return
      }
      nav.dismiss(animated: true) { [weak self] in self?.teardown() }
    }
  }

  private func teardown() {
    razorpay?.close()
    webView?.stopLoading()
    webView?.navigationDelegate = nil
    webView?.removeFromSuperview()
    webView = nil
    hostController = nil
    navController = nil
    razorpay = nil
    razorpayKeyId = nil
  }

  /// The view controller a modal can actually be presented from: the
  /// foreground scene's key window, skipping anything mid-dismissal and
  /// never our own payment page — presenting onto that silently does nothing.
  private static func presenter(excluding ours: [UIViewController?]) -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    let windows = scene?.windows ?? []
    guard let window = windows.first(where: { $0.isKeyWindow })
            ?? windows.first(where: { !$0.isHidden }) else { return nil }

    var top = window.rootViewController
    while let presented = top?.presentedViewController, !presented.isBeingDismissed {
      top = presented
    }
    let excluded = ours.compactMap { $0 }
    if let top, excluded.contains(where: { $0 === top }) { return nil }
    return top
  }
}

extension RazorpayCustomBridge: RazorpayPaymentCompletionProtocol {
  func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable: Any]) {
    print("[rzp] success \(payment_id)")
    finish([
      "paymentId": (response["razorpay_payment_id"] as? String) ?? payment_id,
      "orderId": response["razorpay_order_id"] as? String,
      "signature": response["razorpay_signature"] as? String,
    ] as [String: Any?])
  }

  func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable: Any]) {
    print("[rzp] error \(code): \(str) | \(response)")
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
