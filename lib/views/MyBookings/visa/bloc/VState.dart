import 'package:equatable/equatable.dart';
import '../../../VisaApplication/domain/entity/visaEntity.dart';

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

class VisaApplicationLoaded extends VisaApplicationState {
  final List<VisaApplicationEntity> applications;

  const VisaApplicationLoaded(this.applications);

  @override
  List<Object?> get props => [applications];
}

class VisaApplicationError extends VisaApplicationState {
  final String message;

  const VisaApplicationError(this.message);

  @override
  List<Object?> get props => [message];
}