import 'package:equatable/equatable.dart';

abstract class FooterSettingsEvent extends Equatable {
  const FooterSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadFooterSettings extends FooterSettingsEvent {
  final String domain;

  const LoadFooterSettings({required this.domain});

  @override
  List<Object?> get props => [domain];
}