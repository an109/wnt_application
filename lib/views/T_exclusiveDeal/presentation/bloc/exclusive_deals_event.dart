import 'package:equatable/equatable.dart';

abstract class ExclusiveDealsEvent extends Equatable {
  const ExclusiveDealsEvent();

  @override
  List<Object?> get props => [];
}

class LoadExclusiveDeals extends ExclusiveDealsEvent {
  final String? domain;

  const LoadExclusiveDeals({this.domain});

  @override
  List<Object?> get props => [domain];
}

class RefreshExclusiveDeals extends ExclusiveDealsEvent {
  final String? domain;

  const RefreshExclusiveDeals({this.domain});

  @override
  List<Object?> get props => [domain];
}