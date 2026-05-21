import 'package:equatable/equatable.dart';

abstract class HolidayEvent extends Equatable {
  const HolidayEvent();

  @override
  List<Object?> get props => [];
}

class GetPopularDestinationsEvent extends HolidayEvent {
  final String? domain;

  const GetPopularDestinationsEvent({this.domain});

  @override
  List<Object?> get props => [domain];
}