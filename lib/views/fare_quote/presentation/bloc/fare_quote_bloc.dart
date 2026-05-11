import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/fare_quote_usecase.dart';
import 'fare_quote_event.dart';
import 'fare_quote_state.dart';

class FareQuoteBloc extends Bloc<FareQuoteEvent, FareQuoteState> {
  final FareQuoteUsecase fareQuoteUsecase;

  FareQuoteBloc({required this.fareQuoteUsecase}) : super(FareQuoteInitial()) {
    on<FetchFareQuote>(_onFetchFareQuote);
  }

  Future<void> _onFetchFareQuote(
      FetchFareQuote event,
      Emitter<FareQuoteState> emit,
      ) async {
    emit(FareQuoteLoading());

    final result = await fareQuoteUsecase(
      endUserIp: event.endUserIp,
      traceId: event.traceId,
      tokenId: event.tokenId,
      resultIndex: event.resultIndex,
    );

    if (result is DataSuccess) {
      emit(FareQuoteLoaded(result.data!));
    } else if (result is DataFailed) {
      final errorMessage = result.error?.message ?? 'An unknown error occurred';
      emit(FareQuoteError(errorMessage));
    }
  }
}