import 'package:equatable/equatable.dart';
import 'package:wander_nova/views/MainApi/data/models/section_heros_model.dart';
import 'general_settings_model.dart';

class PopularDestinationsResponseModel extends Equatable {
  final bool success;
  final int count;
  final GeneralSettingsModel generalSettings;
  final SectionHeroesModel sectionHeroes;
  final List<FaqModel> faqList;

  const PopularDestinationsResponseModel({
    required this.success,
    required this.count,
    required this.generalSettings,
    required this.sectionHeroes,
    required this.faqList,
  });

  factory PopularDestinationsResponseModel.fromJson(Map<String, dynamic> json) {
    return PopularDestinationsResponseModel(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      generalSettings: GeneralSettingsModel.fromJson(json),
      sectionHeroes: SectionHeroesModel.fromJson(json),
      faqList: (json['general_settings']?['faq_list'] as List<dynamic>?)
          ?.map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    success,
    count,
    generalSettings,
    sectionHeroes,
    faqList,
  ];
}