import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/fare_rule_entity.dart';
import '../../domain/usecase/fare_rule_usecase.dart';
import 'fare_rule_event.dart';
import 'fare_rule_state.dart';

// lib/features/fare_rule/presentation/bloc/fare_rule_bloc.dart

class FareRuleBloc extends Bloc<FareRuleEvent, FareRuleState> {
  final GetFareRulesUsecase getFareRulesUsecase;

  FareRuleBloc({required this.getFareRulesUsecase}) : super(FareRuleInitial()) {
    on<FetchFareRules>(_onFetchFareRules);
    on<ClearFareRules>(_onClearFareRules);
  }

  Future<void> _onFetchFareRules(
      FetchFareRules event,
      Emitter<FareRuleState> emit,
      ) async {
    print('FareRuleBloc: === EVENT RECEIVED ===');
    print('FareRuleBloc: event.request.traceId=${event.request.traceId}');
    print('FareRuleBloc: event.request.resultIndex=${event.request.resultIndex}');

    emit(FareRuleLoading());
    print('FareRuleBloc: State emitted: FareRuleLoading');

    try {
      print('FareRuleBloc: Calling usecase...');
      final result = await getFareRulesUsecase(event.request);
      print('FareRuleBloc: Usecase returned: ${result.runtimeType}');

      if (result is DataSuccess<FareRuleResponseEntity>) {
        print('FareRuleBloc: Success - emitting FareRuleLoaded');
        emit(FareRuleLoaded(fareRuleResponse: result.data!));
      } else if (result is DataFailed<FareRuleResponseEntity>) {
        print('FareRuleBloc: Failed - error: ${result.error?.message}');
        emit(FareRuleError(
          message: result.error?.message ?? 'An unknown error occurred',
          error: result.error,
        ));
      }
    } catch (e, stack) {
      print('FareRuleBloc: Exception: $e');
      print('FareRuleBloc: Stack: $stack');
      emit(FareRuleError(message: e.toString()));
    }
  }

  Future<void> _onClearFareRules(
      ClearFareRules event,
      Emitter<FareRuleState> emit,
      ) async {
    print('FareRuleBloc: Clear event received');
    emit(FareRuleCleared());
  }
}