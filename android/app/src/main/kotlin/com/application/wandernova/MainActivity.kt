package com.application.wandernova

import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import android.widget.FrameLayout
import com.razorpay.PaymentData
import com.razorpay.PaymentMethodsCallback
import com.razorpay.PaymentResultWithDataListener
import com.razorpay.Razorpay
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Bridges the native Razorpay Android Custom Checkout SDK
 * (`com.razorpay:customui`) to Flutter for the flight payment flow. The SDK
 * needs a real WebView to render bank ACS/3DS challenge pages, so one is
 * added on top of the Flutter view here and only shown while a payment is
 * in flight.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "wander_nova/razorpay_custom"
    private var razorpay: Razorpay? = null
    private var razorpayKeyId: String? = null
    private lateinit var checkoutWebView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkoutWebView = WebView(this)
        checkoutWebView.visibility = View.GONE
        (window.decorView as ViewGroup).addView(
            checkoutWebView,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPaymentMethods" -> {
                    val keyId = call.argument<String>("keyId").orEmpty()
                    ensureRazorpay(keyId).getPaymentMethods(object : PaymentMethodsCallback {
                        // The SDK calls these off the main thread; MethodChannel.Result
                        // must only ever be invoked on the platform thread.
                        override fun onPaymentMethodsReceived(methods: String?) {
                            runOnUiThread { result.success(methods) }
                        }

                        override fun onError(error: String?) {
                            runOnUiThread { result.error("METHODS_ERROR", error, null) }
                        }
                    })
                }
                "submitPayment" -> {
                    val keyId = call.argument<String>("keyId").orEmpty()
                    val dataJson = call.argument<String>("data").orEmpty()
                    val instance = ensureRazorpay(keyId)
                    try {
                        val payload = JSONObject(dataJson)
                        checkoutWebView.visibility = View.VISIBLE
                        instance.submit(payload, object : PaymentResultWithDataListener {
                            override fun onPaymentSuccess(paymentId: String?, paymentData: PaymentData?) {
                                runOnUiThread {
                                    checkoutWebView.visibility = View.GONE
                                    result.success(
                                        hashMapOf(
                                            "paymentId" to (paymentData?.paymentId ?: paymentId),
                                            "orderId" to paymentData?.orderId,
                                            "signature" to paymentData?.signature,
                                        ),
                                    )
                                }
                            }

                            override fun onPaymentError(code: Int, description: String?, paymentData: PaymentData?) {
                                runOnUiThread {
                                    checkoutWebView.visibility = View.GONE
                                    result.error(code.toString(), description, null)
                                }
                            }
                        })
                    } catch (e: Exception) {
                        checkoutWebView.visibility = View.GONE
                        result.error("SUBMIT_EXCEPTION", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensureRazorpay(keyId: String): Razorpay {
        val current = razorpay
        if (current != null && razorpayKeyId == keyId) return current
        val instance = Razorpay(this, keyId)
        instance.setWebView(checkoutWebView)
        razorpay = instance
        razorpayKeyId = keyId
        return instance
    }
}
