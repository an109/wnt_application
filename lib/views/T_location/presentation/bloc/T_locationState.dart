import 'package:equatable/equatable.dart';
import '../../domain/entities/T_locationEntity.dart';

abstract class T_locationState extends Equatable {
  const T_locationState();

  @override
  List<Object?> get props => [];
}

class T_locationInitial extends T_locationState {
  const T_locationInitial();
}

class T_locationsLoading extends T_locationState {
  const T_locationsLoading();
}

class T_locationsLoaded extends T_locationState {
  final List<T_locationEntity> locations;
  final int count;
  final List<String> sources;

  const T_locationsLoaded({
    required this.locations,
    this.count = 0,
    this.sources = const [],
  });

  @override
  List<Object?> get props => [locations, count, sources];
}

class T_locationsError extends T_locationState {
  final String message;

  const T_locationsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class T_locationsSearchLoading extends T_locationState {
  const T_locationsSearchLoading();
}

class T_locationsSearchLoaded extends T_locationState {
  final List<T_locationEntity> locations;
  final int count;
  final List<String> sources;

  const T_locationsSearchLoaded({
    required this.locations,
    this.count = 0,
    this.sources = const [],
  });

  @override
  List<Object?> get props => [locations, count, sources];
}