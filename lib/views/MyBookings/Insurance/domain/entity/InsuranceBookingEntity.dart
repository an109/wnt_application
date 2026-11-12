import 'package:equatable/equatable.dart';

class InsuranceBookingEntity extends Equatable {
  final int id;
  final int user;
  final String policyNumber;
  final String transactionId;
  final String planName;
  final String providerName;
  final String destination;
  final String startDate;
  final String endDate;
  final int travellers;
  final String totalAmount;
  final String? basePremium;
  final String? tax;
  final String currency;
  final String status;
  final String paymentMethod;
  final String paymentId;
  final String holderName;
  final String email;
  final String phone;
  final String created;
  final String updated;

  const InsuranceBookingEntity({
    required this.id,
    required this.user,
    required this.policyNumber,
    required this.transactionId,
    required this.planName,
    required this.providerName,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travellers,
    required this.totalAmount,
    this.basePremium,
    this.tax,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.paymentId,
    required this.holderName,
    required this.email,
    required this.phone,
    required this.created,
    required this.updated,
  });

  @override
  List<Object?> get props => [
    id, user, policyNumber, transactionId, planName, providerName,
    destination, startDate, endDate, travellers, totalAmount, basePremium, tax, currency,
    status, paymentMethod, paymentId, holderName, email, phone, created, updated,
  ];
}
