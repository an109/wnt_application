import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../models/ticket_request_model.dart';
import '../models/ticket_response_model.dart';

abstract class TicketApiService {
  Future<TicketResponseModel> issueTicket(TicketRequestModel request);
}

class TicketApiServiceImpl implements TicketApiService {
  final Dio dio;

  TicketApiServiceImpl(this.dio);

  @override
  Future<TicketResponseModel> issueTicket(TicketRequestModel request) async {
    try {
      print('CALLING TICKET API: ${Urls.ticket}');
      print('Request body: ${request.toJson()}');

      final response = await dio.post(
        Urls.ticket,
        data: request.toJson(),
      );

      print('TICKET API Response Status: ${response.statusCode}');
      return TicketResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Ticket API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Ticket API Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.ticket),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
