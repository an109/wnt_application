import 'package:equatable/equatable.dart';

class SectionHeroesEntity extends Equatable {
  final String flights;
  final String hotel;
  final String visa;
  final String holidays;

  const SectionHeroesEntity({
    required this.flights,
    required this.hotel,
    required this.visa,
    required this.holidays,
  });

  @override
  List<Object?> get props => [flights, hotel, visa, holidays];
}