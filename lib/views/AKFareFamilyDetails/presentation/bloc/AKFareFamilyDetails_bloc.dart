import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKFareFamilyDetails_usecase.dart';
import 'AKFareFamilyDetails_event.dart';
import 'AKFareFamilyDetails_state.dart';

class AkFareFamilyDetailsBloc
    extends Bloc<AkFareFamilyDetailsEvent, AkFareFamilyDetailsState> {
  final AkFareFamilyDetailsUseCase useCase;

  AkFareFamilyDetailsBloc(this.useCase)
      : super(const AkFareFamilyDetailsInitial()) {
    on<LoadAkFareFamilyDetailsEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadAkFareFamilyDetailsEvent event,
    Emitter<AkFareFamilyDetailsState> emit,
  ) async {
    emit(const AkFareFamilyDetailsLoading());

    final result = await useCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkFareFamilyDetailsLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkFareFamilyDetailsFailed(error: result.error!));
    }
  }
}
