import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../domain/entity/delete_account_entity.dart';

abstract class DeleteAccountState extends Equatable {
  const DeleteAccountState();

  @override
  List<Object?> get props => [];
}

class DeleteAccountInitial extends DeleteAccountState {}

class DeleteAccountLoading extends DeleteAccountState {}

class DeleteAccountSuccess extends DeleteAccountState {
  final DeleteAccountEntity deleteAccountEntity;

  const DeleteAccountSuccess(this.deleteAccountEntity);

  @override
  List<Object?> get props => [deleteAccountEntity];
}

class DeleteAccountFailed extends DeleteAccountState {
  final DioException error;

  const DeleteAccountFailed(this.error);

  @override
  List<Object?> get props => [error];
}
