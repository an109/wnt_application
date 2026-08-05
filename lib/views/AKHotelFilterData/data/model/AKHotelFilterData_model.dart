import '../../domain/entity/AKHotelFilterData_entity.dart';

class AkHotelFilterOptionModel extends AkHotelFilterOptionEntity {
  const AkHotelFilterOptionModel({super.min, super.max, required super.label, required super.count, super.value});

  factory AkHotelFilterOptionModel.fromJson(Map<String, dynamic> json) {
    return AkHotelFilterOptionModel(
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      label: json['label']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      value: json['value']?.toString(),
    );
  }
}

class AkHotelFilterModel extends AkHotelFilterEntity {
  const AkHotelFilterModel({required super.name, required super.category, required super.type, required super.options});

  factory AkHotelFilterModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return AkHotelFilterModel(
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      options: rawOptions.whereType<Map<String, dynamic>>().map(AkHotelFilterOptionModel.fromJson).toList(),
    );
  }
}

class AkHotelFilterDataModel extends AkHotelFilterDataEntity {
  const AkHotelFilterDataModel({required super.filters});

  factory AkHotelFilterDataModel.fromJson(Map<String, dynamic> json) {
    final rawFilters = json['filters'] as List<dynamic>? ?? [];
    return AkHotelFilterDataModel(
      filters: rawFilters.whereType<Map<String, dynamic>>().map(AkHotelFilterModel.fromJson).toList(),
    );
  }
}
