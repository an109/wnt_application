import 'package:equatable/equatable.dart';

import '../../domain/entities/section_heros_entity.dart';

class SectionHeroesModel extends Equatable {
  final String flights;
  final String hotel;
  final String visa;
  final String holidays;

  const SectionHeroesModel({
    required this.flights,
    required this.hotel,
    required this.visa,
    required this.holidays,
  });

  factory SectionHeroesModel.fromJson(Map<String, dynamic> json) {
    final heroes = json['section_heroes'] as Map<String, dynamic>? ?? {};
    return SectionHeroesModel(
      flights: heroes['flights'] ?? '',
      hotel: heroes['hotel'] ?? '',
      visa: heroes['visa'] ?? '',
      holidays: heroes['holidays'] ?? '',
    );
  }

  SectionHeroesEntity toEntity() {
    return SectionHeroesEntity(
      flights: flights,
      hotel: hotel,
      visa: visa,
      holidays: holidays,
    );
  }

  @override
  List<Object?> get props => [flights, hotel, visa, holidays];
}