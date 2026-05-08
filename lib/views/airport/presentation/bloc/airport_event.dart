import 'package:equatable/equatable.dart';

abstract class AirportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// class LoadAirports extends AirportEvent {
//   final String? country;
//
//   LoadAirports({this.country});
//
//   @override
//   List<Object?> get props => [country];
// }

class LoadAirports extends AirportEvent {
  final String? country;
  final String? searchQuery;

  LoadAirports({this.country, this.searchQuery});

  @override
  List<Object?> get props => [country, searchQuery];
}