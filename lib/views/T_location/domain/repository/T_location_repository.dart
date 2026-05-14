import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';

abstract class T_locationRepository {
  Future<DataState<Response>> getT_locations({
    String? country,
    String? searchQuery,
  });
}