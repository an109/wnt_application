import 'package:equatable/equatable.dart';

class ReservationPollEntity extends Equatable {
  final bool? success;
  final String? status;
  final String? localStatus;
  final String? confirmationNumber;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? totalPrice;

  const ReservationPollEntity({
    this.success,
    this.status,
    this.localStatus,
    this.confirmationNumber,
    this.email,
    this.firstName,
    this.lastName,
    this.totalPrice,
  });

  @override
  List<Object?> get props => [
    success,
    status,
    localStatus,
    confirmationNumber,
    email,
    firstName,
    lastName,
    totalPrice,
  ];
}