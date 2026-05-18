import 'package:equatable/equatable.dart';

abstract class TrendingRoutesEvent extends Equatable {
  const TrendingRoutesEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrendingRoutes extends TrendingRoutesEvent {
  final String? domain;

  const LoadTrendingRoutes({this.domain});

  @override
  List<Object?> get props => [domain];

  @override
  String toString() => 'LoadTrendingRoutes{domain: $domain}';
}

class RefreshTrendingRoutes extends TrendingRoutesEvent {
  final String? domain;

  const RefreshTrendingRoutes({this.domain});

  @override
  List<Object?> get props => [domain];

  @override
  String toString() => 'RefreshTrendingRoutes{domain: $domain}';
}