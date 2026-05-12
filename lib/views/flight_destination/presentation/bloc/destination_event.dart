import 'package:equatable/equatable.dart';

abstract class DestinationEvent extends Equatable {
  const DestinationEvent();

  @override
  List<Object?> get props => [];
}

class LoadDestinationsEvent extends DestinationEvent {
  final String? searchQuery;
  final String? countryCode;

  const LoadDestinationsEvent({
    this.searchQuery,
    this.countryCode,
  });

  @override
  List<Object?> get props => [searchQuery, countryCode];
}

class SearchDestinationsEvent extends DestinationEvent {
  final String query;
  final String? countryCode;
  final int limit;

  const SearchDestinationsEvent({
    required this.query,
    this.countryCode,
    this.limit = 100,
  });

  @override
  List<Object?> get props => [query, countryCode, limit];
}