import 'package:equatable/equatable.dart';

abstract class GeneralSettingsEvent extends Equatable {
  const GeneralSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPromoCodes extends GeneralSettingsEvent {
  final String? domain;

  const LoadPromoCodes({this.domain});

  @override
  List<Object?> get props => [domain];
}

class LoadGeneralSettings extends GeneralSettingsEvent {
  final String? domain;

  const LoadGeneralSettings({this.domain});

  @override
  List<Object?> get props => [domain];
}

class LoadSectionHeroes extends GeneralSettingsEvent {
  final String? domain;

  const LoadSectionHeroes({this.domain});

  @override
  List<Object?> get props => [domain];
}

class LoadFaqList extends GeneralSettingsEvent {
  final String? domain;

  const LoadFaqList({this.domain});

  @override
  List<Object?> get props => [domain];
}

class LoadAllPopularDestinationsData extends GeneralSettingsEvent {
  final String? domain;

  const LoadAllPopularDestinationsData({this.domain});

  @override
  List<Object?> get props => [domain];
}