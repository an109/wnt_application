import 'package:equatable/equatable.dart';

import '../../domain/entities/general_setting_entity.dart';
import '../../domain/entities/section_heros_entity.dart';

abstract class GeneralSettingsState extends Equatable {
  const GeneralSettingsState();

  @override
  List<Object?> get props => [];
}

class GeneralSettingsInitial extends GeneralSettingsState {}

class GeneralSettingsLoading extends GeneralSettingsState {}

class GeneralSettingsLoaded extends GeneralSettingsState {
  final GeneralSettingsEntity generalSettings;

  const GeneralSettingsLoaded(this.generalSettings);

  @override
  List<Object?> get props => [generalSettings];
}

class SectionHeroesLoaded extends GeneralSettingsState {
  final SectionHeroesEntity sectionHeroes;

  const SectionHeroesLoaded(this.sectionHeroes);

  @override
  List<Object?> get props => [sectionHeroes];
}

class PromoCodesLoaded extends GeneralSettingsState {
  final List<PromoCodeEntity> promoCodes;

  const PromoCodesLoaded(this.promoCodes);

  @override
  List<Object?> get props => [promoCodes];
}

class FaqListLoaded extends GeneralSettingsState {
  final List<FaqEntity> faqList;

  const FaqListLoaded(this.faqList);

  @override
  List<Object?> get props => [faqList];
}

class PopularDestinationsDataLoaded extends GeneralSettingsState {
  final GeneralSettingsEntity generalSettings;
  final SectionHeroesEntity sectionHeroes;
  final List<FaqEntity> faqList;

  const PopularDestinationsDataLoaded({
    required this.generalSettings,
    required this.sectionHeroes,
    required this.faqList,
  });

  @override
  List<Object?> get props => [generalSettings, sectionHeroes, faqList];
}

class GeneralSettingsError extends GeneralSettingsState {
  final String message;

  const GeneralSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}