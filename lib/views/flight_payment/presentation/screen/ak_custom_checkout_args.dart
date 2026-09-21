/// Everything a Razorpay Custom Checkout method screen needs to submit a
/// charge against an order that [AkFlightPaymentScreen] has already created.
/// Built once per payment attempt so every method screen (card/UPI/
/// netbanking/wallet) shares the same order_id — Razorpay ties one order to
/// exactly one successful payment.
class AkCustomCheckoutArgs {
  final String keyId;
  final String orderId;
  final double amountInInr;
  final String name;
  final String email;
  final String contact;
  final String description;

  const AkCustomCheckoutArgs({
    required this.keyId,
    required this.orderId,
    required this.amountInInr,
    required this.name,
    required this.email,
    required this.contact,
    required this.description,
  });

  /// Amount in paise, as the submit payload's `amount` field expects.
  int get amountInPaise => (amountInInr * 100).round();
}
