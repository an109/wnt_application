import 'package:equatable/equatable.dart';

abstract class AkHotelAutosuggestEvent extends Equatable {
  const AkHotelAutosuggestEvent();

  @override
  List<Object?> get props => [];
}

class SearchAkHotelLocationsEvent extends AkHotelAutosuggestEvent {
  final String term;

  const SearchAkHotelLocationsEvent(this.term);

  @override
  List<Object?> get props => [term];
}
