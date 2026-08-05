import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKFareRule_usecase.dart';
import 'AKFareRule_event.dart';
import 'AKFareRule_state.dart';

class AkFareRuleBloc extends Bloc<AkFareRuleEvent, AkFareRuleState> {
  final AkFareRuleUseCase fareRuleUseCase;

  AkFareRuleBloc(this.fareRuleUseCase) : super(const AkFareRuleInitial()) {
    on<LoadAkFareRuleEvent>(_onLoad);
  }

  Future<void> _onLoad(
      LoadAkFareRuleEvent event,
      Emitter<AkFareRuleState> emit,
      ) async {
    emit(const AkFareRuleLoading());

    final result = await fareRuleUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkFareRuleLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkFareRuleFailed(error: result.error!));
    }
  }
}
