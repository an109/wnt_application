import 'package:equatable/equatable.dart';

import '../../domain/entity/visaEntity.dart';

abstract class VisaApplicationState extends Equatable {
  const VisaApplicationState();

  @override
  List<Object?> get props => [];
}

class VisaApplicationInitial extends VisaApplicationState {
  const VisaApplicationInitial();
}

class VisaApplicationLoading extends VisaApplicationState {
  const VisaApplicationLoading();
}

class VisaApplicationsLoaded extends VisaApplicationState {
  final List<VisaApplicationEntity> applications;

  const VisaApplicationsLoaded(this.applications);

  @override
  List<Object?> get props => [applications];
}

class VisaApplicationDetailLoaded extends VisaApplicationState {
  final VisaApplicationEntity application;

  const VisaApplicationDetailLoaded(this.application);

  @override
  List<Object?> get props => [application];
}

class VisaApplicationCreated extends VisaApplicationState {
  final VisaApplicationEntity application;

  const VisaApplicationCreated(this.application);

  @override
  List<Object?> get props => [application];
}

class VisaApplicationError extends VisaApplicationState {
  final String message;

  const VisaApplicationError(this.message);

  @override
  List<Object?> get props => [message];
}