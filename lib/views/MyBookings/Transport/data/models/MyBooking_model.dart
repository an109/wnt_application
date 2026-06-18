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
    super.rawTotalPrice,
    super.rawCurrency,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final rawRequest = json['raw_request'] as Map<String, dynamic>? ?? {};

    String rawTotalPrice = '0.00';
    String rawCurrency = 'USD';

    if (rawRequest.containsKey('display_total_price') && rawRequest['display_total_price'] != null) {
      // Use display_total_price from raw_request
      rawTotalPrice = rawRequest['display_total_price'].toString();
      rawCurrency = rawRequest['display_currency']?.toString() ?? 'USD';
    } else if (rawRequest.containsKey('display_base_price') && rawRequest['display_base_price'] != null) {
      // Fallback to display_base_price
      rawTotalPrice = rawRequest['display_base_price'].toString();
      rawCurrency = rawRequest['display_currency']?.toString() ?? 'USD';
    } else {
      // Last resort: use the top-level total_price
      rawTotalPrice = json['total_price']?.toString() ?? '0.00';
      rawCurrency = json['currency']?.toString() ?? 'USD';
    }

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
      currency: rawCurrency,
      amountPaid: json['amount_paid'] ?? '0.00',
      totalPrice: rawTotalPrice,
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
      rawTotalPrice: rawTotalPrice,
      rawCurrency: rawCurrency,
    );
  }
}