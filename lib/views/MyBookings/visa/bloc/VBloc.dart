// lib/features/visa_applications/presentation/bloc/visa_application_bloc.dart
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../domain/usecase/VApp_usecase.dart';
import 'VEvent.dart';
import 'VState.dart';


class VApplicationBloc extends Bloc<VisaApplicationEvent, VisaApplicationState> {
  final GetVApplicationsUseCase getVApplicationsUseCase;

  VApplicationBloc({required this.getVApplicationsUseCase})
      : super(const VisaApplicationInitial()) {
    on<LoadVisaApplications>(_onLoadVisaApplications);
    on<RefreshVisaApplications>(_onRefreshVisaApplications);
  }

  Future<void> _onLoadVisaApplications(
      LoadVisaApplications event,
      Emitter<VisaApplicationState> emit,
      ) async {
    print('Loading visa applications...');
    emit(const VisaApplicationLoading());

    final result = await getVApplicationsUseCase.call(userEmail: event.userEmail);

    if (result is DataSuccess) {
      print('Successfully loaded ${result.data?.length ?? 0} visa applications');
      emit(VisaApplicationLoaded(result.data ?? []));
    } else if (result is DataFailed) {
      String errorMessage = 'Failed to load visa applications';
      if (result.error?.response != null) {
        errorMessage = 'Error ${result.error?.response?.statusCode}: ${result.error?.message}';
      } else if (result.error?.message != null) {
        errorMessage = result.error!.message!;
      }
      print('Failed to load visa applications: $errorMessage');
      emit(VisaApplicationError(errorMessage));
    }
  }

  Future<void> _onRefreshVisaApplications(
      RefreshVisaApplications event,
      Emitter<VisaApplicationState> emit,
      ) async {
    print('Refreshing visa applications...');

    final result = await getVApplicationsUseCase.call(userEmail: event.userEmail);

    if (result is DataSuccess) {
      print('Successfully refreshed ${result.data?.length ?? 0} visa applications');
      emit(VisaApplicationLoaded(result.data ?? []));
    } else if (result is DataFailed) {
      String errorMessage = 'Failed to refresh visa applications';
      if (result.error?.response != null) {
        errorMessage = 'Error ${result.error?.response?.statusCode}: ${result.error?.message}';
      } else if (result.error?.message != null) {
        errorMessage = result.error!.message!;
      }
      print('Failed to refresh visa applications: $errorMessage');
      emit(VisaApplicationError(errorMessage));
    }
  }
}