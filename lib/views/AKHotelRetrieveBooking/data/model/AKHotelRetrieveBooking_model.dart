import '../../domain/entity/AKHotelRetrieveBooking_entity.dart';

List<AkHotelBookingGuestEntity> _parseGuests(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((g) => AkHotelBookingGuestEntity(
            title: (g['Title'] ?? '').toString(),
            firstName: (g['FirstName'] ?? '').toString(),
            lastName: (g['LastName'] ?? '').toString(),
          ))
      .toList();
}

List<String> _parseCancellationTexts(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((p) => (p['text'] ?? '').toString()).where((t) => t.isNotEmpty).toList();
}

AkHotelBookingRoomEntity _parseRoom(Map<String, dynamic> json) {
  final rawRates = json['RoomRates'] as List<dynamic>? ?? [];
  final firstRate = rawRates.isNotEmpty && rawRates.first is Map ? rawRates.first as Map<String, dynamic> : <String, dynamic>{};
  return AkHotelBookingRoomEntity(
    name: (json['Name'] ?? '').toString(),
    guests: _parseGuests(json['Guests']),
    totalRate: (firstRate['TotalRate'] as num?)?.toDouble() ?? 0.0,
    baseRate: (firstRate['BaseRate'] as num?)?.toDouble() ?? 0.0,
    cancellationPolicyTexts: _parseCancellationTexts(json['CancellationPolicy']),
  );
}

class AkHotelRetrieveBookingModel extends AkHotelRetrieveBookingEntity {
  const AkHotelRetrieveBookingModel({
    required super.transactionId,
    required super.currentStatus,
    required super.grossFare,
    required super.netFare,
    required super.hotelName,
    required super.starRating,
    required super.city,
    required super.country,
    required super.rooms,
  });

  factory AkHotelRetrieveBookingModel.fromJson(Map<String, dynamic> json) {
    final hotelInfo = json['HotelInfo'] as Map<String, dynamic>? ?? {};
    final address = hotelInfo['HotelAddress'] as Map<String, dynamic>? ?? {};
    final rawRooms = json['Rooms'] as List<dynamic>? ?? [];
    return AkHotelRetrieveBookingModel(
      transactionId: json['TransactionId']?.toString() ?? '',
      currentStatus: json['CurrentStatus']?.toString() ?? '',
      grossFare: (json['GrossFare'] as num?)?.toDouble() ?? 0.0,
      netFare: (json['NetFare'] as num?)?.toDouble() ?? 0.0,
      hotelName: hotelInfo['Name']?.toString() ?? '',
      starRating: int.tryParse(hotelInfo['StarRating']?.toString() ?? '') ?? 0,
      city: address['City']?.toString() ?? '',
      country: address['Country']?.toString() ?? '',
      rooms: rawRooms.whereType<Map<String, dynamic>>().map(_parseRoom).toList(),
    );
  }
}
