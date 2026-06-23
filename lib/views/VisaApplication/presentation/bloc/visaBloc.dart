import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/create_visa_application_usecase.dart';
import '../../domain/usecase/get_visaBy_id.dart';
import '../../domain/usecase/visaUsecase.dart';
import 'visaEntity.dart';
import 'visaState.dart';


class VisaApplicationBloc extends Bloc<VisaApplicationEvent, VisaApplicationState> {
  final GetVisaApplicationsUseCase getVisaApplicationsUseCase;
  final GetVisaApplicationByIdUseCase getVisaApplicationByIdUseCase;
  final CreateVisaApplicationUseCase createVisaApplicationUseCase;

  VisaApplicationBloc({
    required this.getVisaApplicationsUseCase,
    required this.getVisaApplicationByIdUseCase,
    required this.createVisaApplicationUseCase,
  }) : super(const VisaApplicationInitial()) {
    on<GetVisaApplicationsEvent>(_onGetVisaApplications);
    on<GetVisaApplicationByIdEvent>(_onGetVisaApplicationById);
    on<CreateVisaApplicationEvent>(_onCreateVisaApplication);
  }

  Future<void> _onGetVisaApplications(
      GetVisaApplicationsEvent event,
      Emitter<VisaApplicationState> emit,
      ) async {
    emit(const VisaApplicationLoading());

    final result = await getVisaApplicationsUseCase.call();

    result.data != null
        ? emit(VisaApplicationsLoaded(result.data!))
        : emit(VisaApplicationError(
        result.error?.message ?? 'Failed to load visa applications'));
  }

  Future<void> _onGetVisaApplicationById(
      GetVisaApplicationByIdEvent event,
      Emitter<VisaApplicationState> emit,
      ) async {
    emit(const VisaApplicationLoading());

    final result = await getVisaApplicationByIdUseCase.call(event.id);

    result.data != null
        ? emit(VisaApplicationDetailLoaded(result.data!))
        : emit(VisaApplicationError(
        result.error?.message ?? 'Failed to load visa application'));
  }

  Future<void> _onCreateVisaApplication(
      CreateVisaApplicationEvent event,
      Emitter<VisaApplicationState> emit,
      ) async {
    emit(const VisaApplicationLoading());

    final result = await createVisaApplicationUseCase.call(event.application);

    result.data != null
        ? emit(VisaApplicationCreated(result.data!))
        : emit(VisaApplicationError(
        result.error?.message ?? 'Failed to create visa application'));
  }
}