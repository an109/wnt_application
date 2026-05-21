import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/general_setting_entity.dart';
import '../../domain/entities/section_heros_entity.dart';
import '../../domain/usecase/get_faq_list_usecase.dart';
import '../../domain/usecase/get_general_setting_usecase.dart';
import '../../domain/usecase/get_section_heros_usecase.dart';
import 'general_settings_event.dart';
import 'general_settings_state.dart';

class GeneralSettingsBloc extends Bloc<GeneralSettingsEvent, GeneralSettingsState> {
  final GetGeneralSettingsUsecase getGeneralSettingsUsecase;
  final GetSectionHeroesUsecase getSectionHeroesUsecase;
  final GetFaqListUsecase getFaqListUsecase;

  GeneralSettingsBloc({
    required this.getGeneralSettingsUsecase,
    required this.getSectionHeroesUsecase,
    required this.getFaqListUsecase,
  }) : super(GeneralSettingsInitial()) {
    on<LoadGeneralSettings>(_onLoadGeneralSettings);
    on<LoadSectionHeroes>(_onLoadSectionHeroes);
    on<LoadFaqList>(_onLoadFaqList);
    on<LoadAllPopularDestinationsData>(_onLoadAllPopularDestinationsData);
  }

  Future<void> _onLoadGeneralSettings(
      LoadGeneralSettings event,
      Emitter<GeneralSettingsState> emit,
      ) async {
    emit(GeneralSettingsLoading());

    final result = await getGeneralSettingsUsecase(domain: event.domain);

    if (result is DataSuccess<GeneralSettingsEntity>) {
      emit(GeneralSettingsLoaded(result.data!));
    } else if (result is DataFailed<GeneralSettingsEntity>) {
      final errorMessage = result.error?.message ?? 'Failed to load general settings';
      emit(GeneralSettingsError(errorMessage));
    }
  }

  Future<void> _onLoadSectionHeroes(
      LoadSectionHeroes event,
      Emitter<GeneralSettingsState> emit,
      ) async {
    emit(GeneralSettingsLoading());

    final result = await getSectionHeroesUsecase(domain: event.domain);

    if (result is DataSuccess<SectionHeroesEntity>) {
      emit(SectionHeroesLoaded(result.data!));
    } else if (result is DataFailed<SectionHeroesEntity>) {
      final errorMessage = result.error?.message ?? 'Failed to load section heroes';
      emit(GeneralSettingsError(errorMessage));
    }
  }

  Future<void> _onLoadFaqList(
      LoadFaqList event,
      Emitter<GeneralSettingsState> emit,
      ) async {
    emit(GeneralSettingsLoading());

    final result = await getFaqListUsecase(domain: event.domain);

    if (result is DataSuccess<List<FaqEntity>>) {
      emit(FaqListLoaded(result.data!));
    } else if (result is DataFailed<List<FaqEntity>>) {
      final errorMessage = result.error?.message ?? 'Failed to load FAQ list';
      emit(GeneralSettingsError(errorMessage));
    }
  }

  Future<void> _onLoadAllPopularDestinationsData(
      LoadAllPopularDestinationsData event,
      Emitter<GeneralSettingsState> emit,
      ) async {
    emit(GeneralSettingsLoading());

    try {
      // Fetch all data in parallel
      final generalSettingsResult = await getGeneralSettingsUsecase(domain: event.domain);
      final sectionHeroesResult = await getSectionHeroesUsecase(domain: event.domain);
      final faqListResult = await getFaqListUsecase(domain: event.domain);

      // Check if all requests were successful
      if (generalSettingsResult is DataSuccess<GeneralSettingsEntity> &&
          sectionHeroesResult is DataSuccess<SectionHeroesEntity> &&
          faqListResult is DataSuccess<List<FaqEntity>>) {

        emit(PopularDestinationsDataLoaded(
          generalSettings: generalSettingsResult.data!,
          sectionHeroes: sectionHeroesResult.data!,
          faqList: faqListResult.data!,
        ));
      } else {
        // Handle partial failures
        String errorMessage = 'Failed to load some data';
        if (generalSettingsResult is DataFailed) {
          errorMessage = generalSettingsResult.error?.message ?? errorMessage;
        } else if (sectionHeroesResult is DataFailed) {
          errorMessage = sectionHeroesResult.error?.message ?? errorMessage;
        } else if (faqListResult is DataFailed) {
          errorMessage = faqListResult.error?.message ?? errorMessage;
        }
        emit(GeneralSettingsError(errorMessage));
      }
    } catch (e) {
      emit(GeneralSettingsError('Unexpected error: $e'));
    }
  }
}