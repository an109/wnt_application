import 'package:equatable/equatable.dart';

class AkHotelFilterDataRequestEntity extends Equatable {
  final String searchId;
  final String searchTracingKey;

  const AkHotelFilterDataRequestEntity({required this.searchId, required this.searchTracingKey});

  @override
  List<Object?> get props => [searchId, searchTracingKey];
}

class AkHotelFilterOptionEntity extends Equatable {
  final double? min;
  final double? max;
  final String label;
  final int count;
  final String? value;

  const AkHotelFilterOptionEntity({this.min, this.max, required this.label, required this.count, this.value});

  @override
  List<Object?> get props => [min, max, label, count, value];
}

/// One filter facet (category), e.g. PriceGroup or StarRating. `type` is
/// "text" | "range" | "list" — `options` is null for "text".
class AkHotelFilterEntity extends Equatable {
  final String name;
  final String category;
  final String type;
  final List<AkHotelFilterOptionEntity> options;

  const AkHotelFilterEntity({required this.name, required this.category, required this.type, required this.options});

  @override
  List<Object?> get props => [name, category, type, options];
}

class AkHotelFilterDataEntity extends Equatable {
  final List<AkHotelFilterEntity> filters;

  const AkHotelFilterDataEntity({required this.filters});

  @override
  List<Object?> get props => [filters];
}
