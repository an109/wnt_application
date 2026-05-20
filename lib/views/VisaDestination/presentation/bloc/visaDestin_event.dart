import 'package:equatable/equatable.dart';

abstract class VisaDestinationEvent extends Equatable {
  const VisaDestinationEvent();

  @override
  List<Object> get props => [];
}

class LoadVisaDestinations extends VisaDestinationEvent {
  final String domain;

  const LoadVisaDestinations({this.domain = 'thewandernova.com'});

  @override
  List<Object> get props => [domain];
}

class RefreshVisaDestinations extends VisaDestinationEvent {
  final String domain;

  const RefreshVisaDestinations({this.domain = 'thewandernova.com'});

  @override
  List<Object> get props => [domain];
}