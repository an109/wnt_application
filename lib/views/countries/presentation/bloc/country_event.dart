import 'package:equatable/equatable.dart';

abstract class CountryEvent extends Equatable {
  const CountryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCountriesEvent extends CountryEvent {
  const LoadCountriesEvent();
}

class SearchCountriesEvent extends CountryEvent {
  final String query;

  const SearchCountriesEvent(this.query);

  @override
  List<Object?> get props => [query];
}