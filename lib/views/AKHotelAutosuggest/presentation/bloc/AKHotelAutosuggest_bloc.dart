import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelAutosuggest_entity.dart';
import '../../domain/usecase/AKHotelAutosuggest_usecase.dart';
import 'AKHotelAutosuggest_event.dart';
import 'AKHotelAutosuggest_state.dart';

class AkHotelAutosuggestBloc extends Bloc<AkHotelAutosuggestEvent, AkHotelAutosuggestState> {
  final AkHotelAutosuggestUseCase autosuggestUseCase;

  AkHotelAutosuggestBloc(this.autosuggestUseCase) : super(const AkHotelAutosuggestInitial()) {
    on<SearchAkHotelLocationsEvent>(_onSearch);
  }

  Future<void> _onSearch(
    SearchAkHotelLocationsEvent event,
    Emitter<AkHotelAutosuggestState> emit,
  ) async {
    emit(const AkHotelAutosuggestLoading());

    final result = await autosuggestUseCase.call(AkHotelAutosuggestRequestEntity(term: event.term));

    if (result is DataSuccess<AkHotelAutosuggestEntity>) {
      emit(AkHotelAutosuggestLoaded(result.data!.locations));
    } else if (result is DataFailed) {
      emit(AkHotelAutosuggestFailed(result.error?.message ?? 'Unable to load suggestions'));
    }
  }
}
