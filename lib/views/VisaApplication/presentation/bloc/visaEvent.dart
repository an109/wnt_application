import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

import '../../domain/entity/visaEntity.dart';

abstract class VisaApplicationEvent extends Equatable {
  const VisaApplicationEvent();

  @override
  List<Object?> get props => [];
}

class GetVisaApplicationsEvent extends VisaApplicationEvent {
  const GetVisaApplicationsEvent();
}

class GetVisaApplicationByIdEvent extends VisaApplicationEvent {
  final int id;

  const GetVisaApplicationByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateVisaApplicationEvent extends VisaApplicationEvent {
  final VisaApplicationEntity application;

  const CreateVisaApplicationEvent(this.application);

  @override
  List<Object?> get props => [application];
}

// class UploadVisaDocumentsEvent extends VisaApplicationEvent {
//   final VisaApplicationEntity application;
//   final Map<String, PlatformFile> files;
//
//   const UploadVisaDocumentsEvent(this.application, this.files);
//
//   @override
//   List<Object?> get props => [application, files];
// }