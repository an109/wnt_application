import 'package:equatable/equatable.dart';

abstract class T_locationEvent extends Equatable {
  const T_locationEvent();

  @override
  List<Object?> get props => [];
}

class LoadT_locationsEvent extends T_locationEvent {
  final String? country;

  const LoadT_locationsEvent({this.country});

  @override
  List<Object?> get props => [country];
}

class SearchT_locationsEvent extends T_locationEvent {
  final String searchQuery;

  const SearchT_locationsEvent({required this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}

class ClearT_locationsEvent extends T_locationEvent {
  const ClearT_locationsEvent();
}