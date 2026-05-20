import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/footer_setting_entity.dart';
import '../../domain/usecase/get_footer_settings_usecase.dart';
import 'footer_setting_event.dart';
import 'footer_setting_state.dart';


class FooterSettingsBloc extends Bloc<FooterSettingsEvent, FooterSettingsState> {
  final GetFooterSettingsUseCase getFooterSettingsUseCase;

  FooterSettingsBloc(this.getFooterSettingsUseCase) : super(FooterSettingsInitial()) {
    on<LoadFooterSettings>(_onLoadFooterSettings);
  }

  Future<void> _onLoadFooterSettings(
      LoadFooterSettings event,
      Emitter<FooterSettingsState> emit,
      ) async {
    emit(FooterSettingsLoading());

    final result = await getFooterSettingsUseCase(domain: event.domain);

    if (result is DataSuccess<FooterSettingsEntity>) {
      emit(FooterSettingsLoaded(result.data!));
    } else if (result is DataFailed<FooterSettingsEntity>) {
      final errorMessage = result.error?.message ?? 'An unknown error occurred';
      emit(FooterSettingsError(errorMessage));
    }
  }
}