
import '../../domain/entity/poll_entity.dart';

class ReservationPollResponseModel {
  final bool? success;
  final ReservationWrapper? reservation;
  final LocalReservation? local;

  ReservationPollResponseModel({this.success, this.reservation, this.local});

  factory ReservationPollResponseModel.fromJson(Map<String, dynamic> json) {
    return ReservationPollResponseModel(
      success: json['success'] as bool?,
      reservation: json['reservation'] != null
          ? ReservationWrapper.fromJson(json['reservation'] as Map<String, dynamic>)
          : null,
      local: json['local'] != null
          ? LocalReservation.fromJson(json['local'] as Map<String, dynamic>)
          : null,
    );
  }

  ReservationPollEntity toEntity() {
    String? confNum = local?.confirmationNumber;
    if (confNum == null && reservation?.reservations != null && reservation!.reservations!.isNotEmpty) {
      confNum = reservation!.reservations!.first.confirmationNumber;
    }

    return ReservationPollEntity(
      success: success,
      status: reservation?.status,
      localStatus: local?.status,
      confirmationNumber: confNum,
      email: local?.email,
      firstName: local?.firstName,
      lastName: local?.lastName,
      totalPrice: local?.totalPrice,
    );
  }
}

class ReservationWrapper {
  final String? status;
  final List<ReservationDetail>? reservations;

  ReservationWrapper({this.status, this.reservations});

  factory ReservationWrapper.fromJson(Map<String, dynamic> json) {
    return ReservationWrapper(
      status: json['status'] as String?,
      reservations: (json['reservations'] as List?)
          ?.map((e) => ReservationDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReservationDetail {
  final String? id;
  final String? status;
  final String? confirmationNumber;

  ReservationDetail({this.id, this.status, this.confirmationNumber});

  factory ReservationDetail.fromJson(Map<String, dynamic> json) {
    return ReservationDetail(
      id: json['id'] as String?,
      status: json['status'] as String?,
      confirmationNumber: json['confirmation_number'] as String?,
    );
  }
}

class LocalReservation {
  final int? id;
  final String? status;
  final String? confirmationNumber;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? totalPrice;

  LocalReservation({
    this.id,
    this.status,
    this.confirmationNumber,
    this.email,
    this.firstName,
    this.lastName,
    this.totalPrice,
  });

  factory LocalReservation.fromJson(Map<String, dynamic> json) {
    return LocalReservation(
      id: json['id'] as int?,
      status: json['status'] as String?,
      confirmationNumber: json['confirmation_number'] as String?,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      totalPrice: json['total_price'] as String?,
    );
  }
}