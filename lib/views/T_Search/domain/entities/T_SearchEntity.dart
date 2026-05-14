import 'package:equatable/equatable.dart';

class TransportSearchEntity extends Equatable {
  final bool success;
  final dynamic search;
  final dynamic local;

  const TransportSearchEntity({
    required this.success,
    required this.search,
    required this.local,
  });

  @override
  List<Object?> get props => [success, search, local];
}