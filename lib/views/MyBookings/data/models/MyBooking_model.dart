// import '../../domain/entity/MyBooking_entity.dart';
//
// class BookingModel extends BookingEntity {
//   const BookingModel({
//     required super.id,
//     required super.userId,
//     required super.status,
//     required super.email,
//     required super.phoneNumber,
//     required super.firstName,
//     required super.lastName,
//     required super.currency,
//     required super.amountPaid,
//     required super.totalPrice,
//     required super.canCancel,
//     required super.cancelled,
//     super.reservationTimestamp,
//     super.cancelledTimestamp,
//     required super.providerName,
//     required super.confirmationNumber,
//     required super.created,
//     required super.updated,
//     required super.destination,
//     required super.type,
//     required super.applicantCount,
//     required super.bookedDate,
//     required super.category,
//   });
//
//   factory BookingModel.fromJson(Map<String, dynamic> json) {
//     final rawRequest = json['raw_request'] as Map<String, dynamic>? ?? {};
//
//     // 1. Extract Destination (Clean up long addresses)
//     String destination = rawRequest['trip_end_address']?.toString().split(',').first ??
//         rawRequest['trip_start_address']?.toString().split(',').first ??
//         json['provider_name']?.toString() ?? 'Unknown';
//
//     // 2. Extract Type (Vehicle or Flight)
//     String type = rawRequest['vehicle_name']?.toString() ??
//         rawRequest['flight_number']?.toString() ??
//         'Service';
//
//     // 3. Extract Applicant Count
//     int applicantCount = rawRequest['num_passengers'] ?? 1;
//
//     // 4. Format Booked Date nicely (e.g., "25 May 2026")
//     String rawDate = json['reservation_timestamp']?.toString() ?? json['created']?.toString() ?? '';
//     String bookedDate = '';
//     if (rawDate.isNotEmpty) {
//       try {
//         DateTime dateTime = DateTime.parse(rawDate);
//         List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
//         bookedDate = "${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}";
//       } catch (e) {
//         bookedDate = rawDate.split('T').first;
//       }
//     }
//
//     // 5. Determine Category for Tab Filtering
//     String category = 'Transport'; // Default
//     if (rawRequest.containsKey('vehicle_name') && rawRequest['vehicle_name'] != null) {
//       category = 'Transport';
//     } else if (rawRequest.containsKey('flight_number') && rawRequest['flight_number'] != null) {
//       category = 'Flight';
//     }
//
//     // 6. Map Status to match UI expectations
//     String rawStatus = json['status']?.toString().toLowerCase() ?? '';
//     String status = rawStatus == 'confirmed' ? 'Confirmed' : (rawStatus == 'cancelled' ? 'Cancelled' : 'Payment pending');
//
//     return BookingModel(
//       id: json['id'] ?? 0,
//       userId: json['user'] ?? 0, // Mapped from 'user' in JSON
//       status: json['status'] ?? '',
//       email: json['email'] ?? '',
//       phoneNumber: json['phone_number'] ?? '',
//       firstName: json['first_name'] ?? '',
//       lastName: json['last_name'] ?? '',
//       currency: json['currency'] ?? '',
//       amountPaid: json['amount_paid'] ?? '0.00',
//       totalPrice: json['total_price'] ?? '0.00',
//       canCancel: json['can_cancel'] ?? false,
//       cancelled: json['cancelled'] ?? false,
//       reservationTimestamp: json['reservation_timestamp'],
//       cancelledTimestamp: json['cancelled_timestamp'],
//       providerName: json['provider_name'] ?? '',
//       confirmationNumber: json['confirmation_number'] ?? '',
//       created: json['created'] ?? '',
//       updated: json['updated'] ?? '',
//       destination: destination,
//       type: type,
//       applicantCount: applicantCount,
//       bookedDate: bookedDate,
//       category: category,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'user': userId,
//       'status': status,
//       'email': email,
//       'phone_number': phoneNumber,
//       'first_name': firstName,
//       'last_name': lastName,
//       'currency': currency,
//       'amount_paid': amountPaid,
//       'total_price': totalPrice,
//       'can_cancel': canCancel,
//       'cancelled': cancelled,
//       'reservation_timestamp': reservationTimestamp,
//       'cancelled_timestamp': cancelledTimestamp,
//       'provider_name': providerName,
//       'confirmation_number': confirmationNumber,
//       'created': created,
//       'updated': updated,
//     };
//   }
// }

import '../../domain/entity/MyBooking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.status,
    required super.email,
    required super.phoneNumber,
    required super.firstName,
    required super.lastName,
    required super.currency,
    required super.amountPaid,
    required super.totalPrice,
    required super.canCancel,
    required super.cancelled,
    super.reservationTimestamp,
    super.cancelledTimestamp,
    required super.providerName,
    required super.confirmationNumber,
    required super.created,
    required super.updated,
    required super.destination,
    required super.type,
    required super.applicantCount,
    required super.bookedDate,
    required super.category,
    super.startAddress,
    super.endAddress,
    super.pickupDatetime,
    super.flightNumber,
    super.vehicleName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final rawRequest = json['raw_request'] as Map<String, dynamic>? ?? {};

    // Extract destination
    String destination = rawRequest['trip_end_address']?.toString().split(',').first ??
        rawRequest['trip_start_address']?.toString().split(',').first ??
        json['provider_name']?.toString() ?? 'Unknown';

    // Extract type
    String type = rawRequest['vehicle_name']?.toString() ??
        rawRequest['flight_number']?.toString() ??
        'Service';

    // Extract applicant count
    int applicantCount = rawRequest['num_passengers'] ?? 1;

    // Format booked date
    String rawDate = json['reservation_timestamp']?.toString() ?? json['created']?.toString() ?? '';
    String bookedDate = '';
    if (rawDate.isNotEmpty) {
      try {
        DateTime dateTime = DateTime.parse(rawDate);
        List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        bookedDate = "${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}";
      } catch (e) {
        bookedDate = rawDate.split('T').first;
      }
    }

    // Determine category
    String category = 'Transport';
    if (rawRequest.containsKey('vehicle_name') && rawRequest['vehicle_name'] != null) {
      category = 'Transport';
    } else if (rawRequest.containsKey('flight_number') && rawRequest['flight_number'] != null) {
      category = 'Flight';
    }

    // Map status
    String rawStatus = json['status']?.toString().toLowerCase() ?? '';
    String status = rawStatus == 'confirmed' ? 'Confirmed' : (rawStatus == 'cancelled' ? 'Cancelled' : 'Payment pending');

    return BookingModel(
      id: json['id'] ?? 0,
      userId: json['user'] ?? 0,
      status: status,
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      currency: json['currency'] ?? 'USD',
      amountPaid: json['amount_paid'] ?? '0.00',
      totalPrice: json['total_price'] ?? '0.00',
      canCancel: json['can_cancel'] ?? false,
      cancelled: json['cancelled'] ?? false,
      reservationTimestamp: json['reservation_timestamp'],
      cancelledTimestamp: json['cancelled_timestamp'],
      providerName: json['provider_name'] ?? '',
      confirmationNumber: json['confirmation_number'] ?? '',
      created: json['created'] ?? '',
      updated: json['updated'] ?? '',
      destination: destination,
      type: type,
      applicantCount: applicantCount,
      bookedDate: bookedDate,
      category: category,
      // NEW FIELDS
      startAddress: rawRequest['trip_start_address']?.toString() ?? '',
      endAddress: rawRequest['trip_end_address']?.toString() ?? '',
      pickupDatetime: rawRequest['trip_pickup_datetime']?.toString() ?? '',
      flightNumber: rawRequest['flight_number']?.toString() ?? '',
      vehicleName: rawRequest['vehicle_name']?.toString() ?? '',
    );
  }
}