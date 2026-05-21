// lib/features/holidays/presentation/bloc/holiday_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/holiday_destination_entity.dart';

abstract class HolidayState extends Equatable {
  const HolidayState();

  @override
  List<Object?> get props => [];
}

class HolidayInitialState extends HolidayState {
  const HolidayInitialState();
}

class HolidayLoadingState extends HolidayState {
  const HolidayLoadingState();
}

class HolidaySuccessState extends HolidayState {
  final List<HolidayDestinationEntity> destinations;

  const HolidaySuccessState(this.destinations);

  @override
  List<Object?> get props => [destinations];
}

class HolidayErrorState extends HolidayState {
  final String error;

  const HolidayErrorState(this.error);

  @override
  List<Object?> get props => [error];
}