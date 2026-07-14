import 'package:dio/dio.dart';
import 'package:wander_nova/core/constants/urls.dart';

abstract class TravellerApiService {
  Future<Response> addTraveller(Map<String, dynamic> payload);
  Future<Response> getTravellers(String email);
}

class TravellerApiServiceImpl implements TravellerApiService {
  final Dio dio;

  TravellerApiServiceImpl(this.dio);

  @override
  Future<Response> addTraveller(Map<String, dynamic> payload) async {
    return dio.post(Urls.travellers, data: payload);
  }

  @override
  Future<Response> getTravellers(String email) async {
    return dio.get(Urls.travellersByEmail(email));
  }
}
