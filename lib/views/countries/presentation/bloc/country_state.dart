import 'package:equatable/equatable.dart';
import '../../domain/entities/country_entity.dart';

abstract class CountryState extends Equatable {
  const CountryState();

  @override
  List<Object?> get props => [];
}

class CountryInitial extends CountryState {
  const CountryInitial();
}

class CountryLoading extends CountryState {
  const CountryLoading();
}

class CountryLoaded extends CountryState {
  final List<CountryEntity> countries;
  final List<CountryEntity> filteredCountries;

  const CountryLoaded({
    required this.countries,
    List<CountryEntity>? filteredCountries,
  }) : filteredCountries = filteredCountries ?? countries;

  @override
  List<Object?> get props => [countries, filteredCountries];

  CountryLoaded copyWith({
    List<CountryEntity>? countries,
    List<CountryEntity>? filteredCountries,
  }) {
    return CountryLoaded(
      countries: countries ?? this.countries,
      filteredCountries: filteredCountries ?? this.filteredCountries,
    );
  }
}

class CountryError extends CountryState {
  final String message;

  const CountryError(this.message);

  @override
  List<Object?> get props => [message];
}