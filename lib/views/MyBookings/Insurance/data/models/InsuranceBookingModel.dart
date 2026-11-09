import '../../domain/entity/InsuranceBookingEntity.dart';

class InsuranceBookingModel extends InsuranceBookingEntity {
  const InsuranceBookingModel({
    required super.id,
    required super.user,
    required super.policyNumber,
    required super.transactionId,
    required super.planName,
    required super.providerName,
    required super.destination,
    required super.startDate,
    required super.endDate,
    required super.travellers,
    required super.totalAmount,
    required super.currency,
    required super.status,
    required super.paymentMethod,
    required super.paymentId,
    required super.holderName,
    required super.email,
    required super.phone,
    required super.created,
    required super.updated,
  });

  factory InsuranceBookingModel.fromJson(Map<String, dynamic> json) {
    return InsuranceBookingModel(
      id: json['id'] ?? 0,
      user: json['user'] ?? 0,
      policyNumber: json['policy_number']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? json['product_name']?.toString() ?? '',
      providerName: json['provider_name']?.toString() ?? json['insurer']?.toString() ?? '',
      destination: json['destination']?.toString() ?? json['country']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? json['travel_start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? json['travel_end_date']?.toString() ?? '',
      travellers: json['travellers'] ?? json['num_travellers'] ?? json['pax_count'] ?? 1,
      totalAmount: json['total_amount']?.toString() ?? json['premium']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? json['razorpay_payment_id']?.toString() ?? '',
      holderName: _buildName(json),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['phone_number']?.toString() ?? '',
      created: json['created']?.toString() ?? json['created_at']?.toString() ?? '',
      updated: json['updated']?.toString() ?? json['updated_at']?.toString() ?? '',
    );
  }

  static String _buildName(Map<String, dynamic> json) {
    final first = json['first_name']?.toString() ?? '';
    final last = json['last_name']?.toString() ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return json['holder_name']?.toString() ?? json['customer_name']?.toString() ?? '';
  }
}
