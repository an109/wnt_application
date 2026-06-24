import 'package:equatable/equatable.dart';

abstract class VisaApplicationEvent extends Equatable {
  const VisaApplicationEvent();

  @override
  List<Object?> get props => [];
}

class LoadVisaApplications extends VisaApplicationEvent {
  final String? userEmail;

  const LoadVisaApplications({this.userEmail});

  @override
  List<Object?> get props => [userEmail];
}

class RefreshVisaApplications extends VisaApplicationEvent {
  final String? userEmail;

  const RefreshVisaApplications({this.userEmail});

  @override
  List<Object?> get props => [userEmail];
}