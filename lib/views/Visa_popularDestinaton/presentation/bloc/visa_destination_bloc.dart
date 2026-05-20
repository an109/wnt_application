import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/visa_destination_entity.dart';
import '../../domain/usecase/get_visa_destination_usecase.dart';
import 'visa_destination_event.dart';
import 'visa_destination_state.dart';

class VisaPopularDestinationBloc extends Bloc<VisaPopularDestinationEvent, VisaPopularDestinationState> {
  final GetVisaPopularDestinationsUsecase getVisaPopularDestinationsUsecase;

  VisaPopularDestinationBloc({
    required this.getVisaPopularDestinationsUsecase,
  }) : super(VisaDestinationInitial()) {
    on<LoadVisaDestinations>(_onLoadVisaDestinations);
    on<RefreshVisaDestinations>(_onRefreshVisaDestinations);
  }

  Future<void> _onLoadVisaDestinations(
      LoadVisaDestinations event,
      Emitter<VisaPopularDestinationState> emit,
      ) async {
    print('VisaPopularDestinationBloc: Loading destinations with domain: ${event.domain}');
    emit(VisaDestinationLoading());

    final result = await getVisaPopularDestinationsUsecase.call(domain: event.domain);

    if (result is DataSuccess<List<VisaPopularDestinationEntity>>) {
      print('VisaPopularDestinationBloc: Successfully loaded ${result.data?.length ?? 0} destinations');
      emit(VisaDestinationLoaded(result.data!));
    } else if (result is DataFailed<List<VisaPopularDestinationEntity>>) {
      final errorMessage = result.error?.message ?? 'Failed to load visa destinations';
      print('VisaPopularDestinationBloc: Error - $errorMessage');
      emit(VisaDestinationError(errorMessage));
    }
  }

  Future<void> _onRefreshVisaDestinations(
      RefreshVisaDestinations event,
      Emitter<VisaPopularDestinationState> emit,
      ) async {
    print('VisaPopularDestinationBloc: Refreshing destinations with domain: ${event.domain}');
    // Keep current state while refreshing, or emit loading based on your UX preference
    final result = await getVisaPopularDestinationsUsecase.call(domain: event.domain);

    if (result is DataSuccess<List<VisaPopularDestinationEntity>>) {
      print('VisaPopularDestinationBloc: Successfully refreshed ${result.data?.length ?? 0} destinations');
      emit(VisaDestinationLoaded(result.data!));
    } else if (result is DataFailed<List<VisaPopularDestinationEntity>>) {
      final errorMessage = result.error?.message ?? 'Failed to refresh visa destinations';
      print('VisaPopularDestinationBloc: Refresh Error - $errorMessage');
      // Optionally emit error or keep old data
      emit(VisaDestinationError(errorMessage));
    }
  }
}