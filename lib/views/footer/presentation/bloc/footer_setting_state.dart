import 'package:equatable/equatable.dart';
import '../../domain/entities/footer_setting_entity.dart';

abstract class FooterSettingsState extends Equatable {
  const FooterSettingsState();

  @override
  List<Object?> get props => [];
}

class FooterSettingsInitial extends FooterSettingsState {}

class FooterSettingsLoading extends FooterSettingsState {}

class FooterSettingsLoaded extends FooterSettingsState {
  final FooterSettingsEntity settings;

  const FooterSettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class FooterSettingsError extends FooterSettingsState {
  final String message;

  const FooterSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}