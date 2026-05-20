import 'package:equatable/equatable.dart';

abstract class VisaPopularDestinationEvent extends Equatable {
  const VisaPopularDestinationEvent();

  @override
  List<Object?> get props => [];
}

class LoadVisaDestinations extends VisaPopularDestinationEvent {
  final String? domain;

  const LoadVisaDestinations({this.domain});

  @override
  List<Object?> get props => [domain];
}

class RefreshVisaDestinations extends VisaPopularDestinationEvent {
  final String? domain;

  const RefreshVisaDestinations({this.domain});

  @override
  List<Object?> get props => [domain];
}