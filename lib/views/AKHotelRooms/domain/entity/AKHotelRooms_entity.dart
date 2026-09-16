import 'package:equatable/equatable.dart';

class AkHotelRoomsRequestEntity extends Equatable {
  final String searchId;
  final String hotelId;
  final String searchTracingKey;

  const AkHotelRoomsRequestEntity({required this.searchId, required this.hotelId, required this.searchTracingKey});

  @override
  List<Object?> get props => [searchId, hotelId, searchTracingKey];
}

class AkHotelOccupancyEntity extends Equatable {
  final int occupancyId;
  final int numOfAdults;
  final int numOfChildren;
  final List<int> childAges;

  const AkHotelOccupancyEntity({
    required this.occupancyId,
    required this.numOfAdults,
    required this.numOfChildren,
    required this.childAges,
  });

  @override
  List<Object?> get props => [occupancyId, numOfAdults, numOfChildren, childAges];
}

class AkHotelChargeEntity extends Equatable {
  final double amount;
  final String description;

  const AkHotelChargeEntity({required this.amount, required this.description});

  @override
  List<Object?> get props => [amount, description];
}

/// One bookable room option from one supplier. [id] (roomGroup id) and
/// [providerName] thread into Pricing as roomGroupId + priceProvider;
/// [roomId] threads in as Rooms[].RoomId at CreateItinerary time.
///
/// [roomCount] is the number of PHYSICAL rooms this option covers, which can
/// exceed `occupancies.length` — the vendor collapses rooms that share the
/// same adult/child composition into one occupancy entry (e.g. a 2-room
/// search where both rooms are "1 adult" comes back as `roomCount: 2` with a
/// single occupancy entry), so callers must expand/repeat entries up to
/// [roomCount] rather than assuming one entry per room.
class AkHotelRoomGroupEntity extends Equatable {
  final String id;
  final String providerName;
  final bool needsPriceCheck;
  final int availability;
  final String roomId;
  final String roomName;
  /// The room's own description, straight from the API's `room.description`
  /// (independent of [boardBasisDescription], which is the meal plan).
  final String description;
  /// The room's own photos, straight from `room.images` — often empty (the
  /// vendor doesn't always supply per-room photos), in which case callers
  /// fall back to the hotel's own gallery images from Content.
  final List<String> images;
  final List<AkHotelOccupancyEntity> occupancies;
  final int roomCount;
  final double baseRate;
  final double totalRate;
  final List<AkHotelChargeEntity> taxes;
  final bool refundable;
  final String boardBasisDescription;
  final List<String> cancellationPolicyTexts;

  /// `room.maxGuestAllowed` / `maxAdultAllowed` / `maxChildrenAllowed` — the
  /// vendor's own stated occupancy cap for this room, when it supplies one.
  /// Null on many hotels (the vendor just doesn't send it), in which case
  /// callers should fall back to summing [occupancies] instead of guessing.
  final int? maxGuestAllowed;
  final int? maxAdultAllowed;
  final int? maxChildrenAllowed;

  /// `room.area` — floor area, when the vendor supplies one. Unit isn't
  /// carried in the payload; every hotel in this feed prices in INR/serves
  /// the Indian market, so this is shown as sq.ft.
  final double? area;

  /// `room.beds` — bed configuration strings (e.g. "King", "2 Twin"), when
  /// the vendor supplies them.
  final List<String> bedTypes;

  /// `room.facilities` — this room's own amenities, distinct from the
  /// hotel-level facilities in Content. Same `{id, groupId, name}` shape as
  /// hotel facilities.
  final List<String> roomFacilities;

  /// `room.views` — e.g. "Garden View", when supplied.
  final String? view;

  final bool? smokingAllowed;

  const AkHotelRoomGroupEntity({
    required this.id,
    required this.providerName,
    required this.needsPriceCheck,
    required this.availability,
    required this.roomId,
    required this.roomName,
    required this.description,
    required this.images,
    required this.occupancies,
    required this.roomCount,
    required this.baseRate,
    required this.totalRate,
    required this.taxes,
    required this.refundable,
    required this.boardBasisDescription,
    required this.cancellationPolicyTexts,
    this.maxGuestAllowed,
    this.maxAdultAllowed,
    this.maxChildrenAllowed,
    this.area,
    this.bedTypes = const [],
    this.roomFacilities = const [],
    this.view,
    this.smokingAllowed,
  });

  @override
  List<Object?> get props => [
        id, providerName, needsPriceCheck, availability, roomId, roomName, description, images, occupancies,
        roomCount, baseRate, totalRate, taxes, refundable, boardBasisDescription, cancellationPolicyTexts,
        maxGuestAllowed, maxAdultAllowed, maxChildrenAllowed, area, bedTypes, roomFacilities, view, smokingAllowed,
      ];
}

/// One "recommendation" — a bundle of [roomGroups] (one per supplier) all
/// pricing the same stay. [id] threads into Pricing/CreateItinerary as
/// recommendationId.
class AkHotelRecommendationEntity extends Equatable {
  final String id;
  final double total;
  final List<AkHotelRoomGroupEntity> roomGroups;

  const AkHotelRecommendationEntity({required this.id, required this.total, required this.roomGroups});

  @override
  List<Object?> get props => [id, total, roomGroups];
}

class AkHotelRoomsResultEntity extends Equatable {
  final List<AkHotelRecommendationEntity> recommendations;

  const AkHotelRoomsResultEntity({required this.recommendations});

  @override
  List<Object?> get props => [recommendations];
}
