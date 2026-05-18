import 'package:equatable/equatable.dart';
import '../../domain/entities/trending_routes_entity.dart';

abstract class TrendingRoutesState extends Equatable {
  const TrendingRoutesState();

  @override
  List<Object?> get props => [];
}

class TrendingRoutesInitial extends TrendingRoutesState {
  const TrendingRoutesInitial();

  @override
  String toString() => 'TrendingRoutesInitial';
}

class TrendingRoutesLoading extends TrendingRoutesState {
  const TrendingRoutesLoading();

  @override
  String toString() => 'TrendingRoutesLoading';
}

class TrendingRoutesLoaded extends TrendingRoutesState {
  final List<TrendingRouteEntity> routes;

  const TrendingRoutesLoaded(this.routes);

  @override
  List<Object?> get props => [routes];

  @override
  String toString() => 'TrendingRoutesLoaded{routes: ${routes.length}}';
}

class TrendingRoutesError extends TrendingRoutesState {
  final String message;

  const TrendingRoutesError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'TrendingRoutesError{message: $message}';
}