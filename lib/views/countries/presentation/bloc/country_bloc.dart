import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/country_entity.dart';
import '../../domain/usecase/get_countries_usecase.dart';
import 'country_event.dart';
import 'country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final GetCountriesUseCase getCountriesUseCase;
  List<CountryEntity> _allCountries = [];

  CountryBloc(this.getCountriesUseCase) : super(const CountryInitial()) {
    on<LoadCountriesEvent>(_onLoadCountries);
    on<SearchCountriesEvent>(_onSearchCountries);
  }

  Future<void> _onLoadCountries(
      LoadCountriesEvent event,
      Emitter<CountryState> emit,
      ) async {
    emit(const CountryLoading());

    try {
      final result = await getCountriesUseCase();

      if (result is DataSuccess<List<CountryEntity>>) {
        _allCountries = result.data!;
        print('Countries loaded successfully: ${_allCountries.length}');
        emit(CountryLoaded(countries: _allCountries));
      } else if (result is DataFailed<List<CountryEntity>>) {
        final errorMessage = _getErrorMessage(result.error);
        print('Failed to load countries: $errorMessage');
        emit(CountryError(errorMessage));
      }
    } catch (e) {
      print('Unexpected error in CountryBloc: $e');
      emit(const CountryError('An unexpected error occurred'));
    }
  }

  void _onSearchCountries(
      SearchCountriesEvent event,
      Emitter<CountryState> emit,
      ) {
    if (state is CountryLoaded) {
      final query = event.query.toLowerCase().trim();

      if (query.isEmpty) {
        emit(CountryLoaded(countries: _allCountries));
        return;
      }

      final filteredCountries = _allCountries.where((country) {
        return country.name.toLowerCase().contains(query) ||
            country.code.toLowerCase().contains(query);
      }).toList();

      print('Search query: "$query", Found: ${filteredCountries.length} countries');

      emit((state as CountryLoaded).copyWith(
        filteredCountries: filteredCountries,
      ));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unknown error occurred';
    }

    final message = error.toString();

    if (message.contains('SocketException') || message.contains('Network')) {
      return 'No internet connection. Please check your network.';
    } else if (message.contains('401')) {
      return 'Unauthorized. Please login again.';
    } else if (message.contains('404')) {
      return 'Resource not found.';
    } else if (message.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (message.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    return 'Failed to load countries. Please try again.';
  }
}