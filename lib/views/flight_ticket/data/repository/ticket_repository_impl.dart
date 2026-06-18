import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repository/ticket_repository.dart';
import '../data_source/ticket_api_service.dart';
import '../models/ticket_request_model.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketApiService apiService;

  TicketRepositoryImpl(this.apiService);

  @override
  Future<DataState<TicketEntity>> issueTicket(TicketRequestModel request) async {
    try {
      final response = await apiService.issueTicket(request);
      final data = response.response;

      final entity = TicketEntity(
        responseStatus: data?.responseStatus,
        errorCode: data?.error?.errorCode,
        errorMessage: data?.error?.errorMessage,
        traceId: data?.traceId,
        pnr: data?.pnr,
        bookingId: data?.bookingId,
        passengers: data?.passengers
            ?.map((p) => TicketPassengerEntity(
                  paxId: p.paxId,
                  ticketId: p.ticketId,
                  ticketNumber: p.ticketNumber,
                  status: p.status,
                  firstName: p.firstName,
                  lastName: p.lastName,
                ))
            .toList(),
      );

      if (!entity.isSuccess && !entity.isPending) {
        final msg = entity.errorMessage ??
            'Ticket issuance failed (TBO status: ${entity.responseStatus})';
        return DataFailed(DioException(
          requestOptions: RequestOptions(path: ''),
          error: msg,
          message: msg,
        ));
      }
      return DataSuccess(entity);
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}
