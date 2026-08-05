import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKTravelCheckList_usecase.dart';
import 'AKTravelCheckList_event.dart';
import 'AKTravelCheckList_state.dart';

class AkTravelCheckListBloc extends Bloc<AkTravelCheckListEvent, AkTravelCheckListState> {
  final AkTravelCheckListUseCase travelCheckListUseCase;

  AkTravelCheckListBloc(this.travelCheckListUseCase) : super(const AkTravelCheckListInitial()) {
    on<LoadAkTravelCheckListEvent>(_onLoad);
  }

  Future<void> _onLoad(
      LoadAkTravelCheckListEvent event,
      Emitter<AkTravelCheckListState> emit,
      ) async {
    emit(const AkTravelCheckListLoading());

    final result = await travelCheckListUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkTravelCheckListLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkTravelCheckListFailed(error: result.error!));
    }
  }
}
