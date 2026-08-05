import '../../domain/entity/AKHotelAutosuggest_entity.dart';

class AkHotelLocationModel extends AkHotelLocationEntity {
  const AkHotelLocationModel({
    required super.id,
    required super.name,
    required super.fullName,
    required super.type,
    super.state,
    super.country,
    super.referenceId,
    super.lat,
    super.long,
  });

  factory AkHotelLocationModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as Map<String, dynamic>?;
    return AkHotelLocationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'city',
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      referenceId: json['referenceId']?.toString(),
      lat: coordinates == null ? null : double.tryParse(coordinates['lat'].toString()),
      long: coordinates == null ? null : double.tryParse(coordinates['long'].toString()),
    );
  }
}

class AkHotelAutosuggestModel extends AkHotelAutosuggestEntity {
  const AkHotelAutosuggestModel({required super.success, required super.locations});

  factory AkHotelAutosuggestModel.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'] as List<dynamic>? ?? [];
    return AkHotelAutosuggestModel(
      success: json['success'] == true,
      locations: rawLocations
          .whereType<Map<String, dynamic>>()
          .map(AkHotelLocationModel.fromJson)
          .toList(),
    );
  }
}
