import '../utils/storage/shared_preference.dart';
import '../../injection_container.dart';

enum PaymentGateway { razorpay, nomod }

enum NomodPaymentMethod { tamara, tabby, googlePay, applePay, card }

class PaymentGatewayService {
  PaymentGatewayService._();

  static PaymentGateway get activeGateway {
    final country = sl<PreferencesManager>().getSelectedCountry() ?? 'IN';
    return country == 'AE' ? PaymentGateway.nomod : PaymentGateway.razorpay;
  }

  static bool get isRazorpay => activeGateway == PaymentGateway.razorpay;
  static bool get isNomod => activeGateway == PaymentGateway.nomod;

  static String get currency => isNomod ? 'AED' : 'INR';

  static String get gatewayName => isNomod ? 'nomod' : 'razorpay';

  static List<NomodPaymentMethod> get nomodMethods => const [
        NomodPaymentMethod.card,
        NomodPaymentMethod.applePay,
        NomodPaymentMethod.googlePay,
        NomodPaymentMethod.tamara,
        NomodPaymentMethod.tabby,
      ];

  static String nomodMethodLabel(NomodPaymentMethod method) {
    switch (method) {
      case NomodPaymentMethod.tamara:
        return 'Tamara – Buy Now, Pay Later';
      case NomodPaymentMethod.tabby:
        return 'Tabby – Buy Now, Pay Later';
      case NomodPaymentMethod.googlePay:
        return 'Google Pay';
      case NomodPaymentMethod.applePay:
        return 'Apple Pay';
      case NomodPaymentMethod.card:
        return 'Credit / Debit Cards';
    }
  }

  static String nomodMethodIcon(NomodPaymentMethod method) {
    switch (method) {
      case NomodPaymentMethod.tamara:
        return 'assets/NewIcons/wallet.png';
      case NomodPaymentMethod.tabby:
        return 'assets/NewIcons/wallet.png';
      case NomodPaymentMethod.googlePay:
        return 'assets/NewIcons/upi.png';
      case NomodPaymentMethod.applePay:
        return 'assets/NewIcons/upi.png';
      case NomodPaymentMethod.card:
        return 'assets/NewIcons/credit.png';
    }
  }

  static String nomodMethodSubtitle(NomodPaymentMethod method) {
    switch (method) {
      case NomodPaymentMethod.tamara:
        return 'Split your payment into easy instalments';
      case NomodPaymentMethod.tabby:
        return 'Pay in 4 interest-free instalments';
      case NomodPaymentMethod.googlePay:
        return 'Pay quickly with Google Pay';
      case NomodPaymentMethod.applePay:
        return 'Pay quickly with Apple Pay';
      case NomodPaymentMethod.card:
        return 'Visa, Mastercard & more';
    }
  }
}
