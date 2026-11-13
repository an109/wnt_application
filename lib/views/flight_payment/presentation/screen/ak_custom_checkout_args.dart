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

  /// The paise the Razorpay order was actually minted for, as the
  /// backend reported it. Always pass this when the create-order
  /// response carries an `amount`.
  final int? orderAmountPaise;

  const AkCustomCheckoutArgs({
    required this.keyId,
    required this.orderId,
    required this.amountInInr,
    required this.name,
    required this.email,
    required this.contact,
    required this.description,
    this.orderAmountPaise,
  });

  /// Amount in paise, as the submit payload's `amount` field expects.
  ///
  /// Prefers the order's own figure: re-deriving paise from a double can
  /// disagree with the order by a paisa (8.29 * 100 is 828.9999999999999),
  /// and Razorpay then refuses payment initiation.
  int get amountInPaise => orderAmountPaise ?? (amountInInr * 100).round();
}
