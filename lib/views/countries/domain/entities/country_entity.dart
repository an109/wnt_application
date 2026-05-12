import 'package:equatable/equatable.dart';

class CountryEntity extends Equatable {
  final String code;
  final String name;

  const CountryEntity({
    required this.code,
    required this.name,
  });

  @override
  List<Object?> get props => [code, name];
}