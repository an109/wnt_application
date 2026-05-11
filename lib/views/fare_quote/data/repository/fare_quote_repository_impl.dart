import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/fare_quote_entity.dart';
import '../../domain/repository/fare_quote_repository.dart';
import '../data_source/fare_quote_api_service.dart';
import '../models/fare_quote_request_model.dart';
import '../models/fare_quote_response_model.dart';

class FareQuoteRepositoryImpl implements FareQuoteRepository {
  final FareQuoteApiService apiService;

  FareQuoteRepositoryImpl(this.apiService);

  @override
  Future<DataState<FareQuoteEntity>> getFareQuote({
    required String endUserIp,
    required String traceId,
    required String tokenId,
    required String resultIndex,
  }) async {
    try {
      final request = FareQuoteRequestModel(
        endUserIp: endUserIp,
        traceId: traceId,
        tokenId: tokenId,
        resultIndex: resultIndex,
      );

      final response = await apiService.getFareQuote(request);

      // Check for API-level errors
      if (response.response?.error?.errorCode == 0) {
        final entity = _mapResponseToEntity(response);
        return DataSuccess(entity);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.response?.error?.errorMessage ?? 'API returned error',
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  FareQuoteEntity _mapResponseToEntity(FareQuoteResponseModel model) {
    return FareQuoteEntity(
      response: model.response != null
          ? ResponseEntity(
        error: model.response!.error != null
            ? ErrorEntity(
          errorCode: model.response!.error!.errorCode,
          errorMessage: model.response!.error!.errorMessage,
        )
            : null,
        isPriceChanged: model.response!.isPriceChanged,
        responseStatus: model.response!.responseStatus,
        results: model.response!.results != null
            ? ResultsEntity(
          resultIndex: model.response!.results!.resultIndex,
          isRefundable: model.response!.results!.isRefundable,
          isHoldAllowed: model.response!.results!.isHoldAllowed,
          airlineCode: model.response!.results!.airlineCode,
          resultFareType: model.response!.results!.resultFareType,
          fare: model.response!.results!.fare != null
              ? FareEntity(
            currency: model.response!.results!.fare!.currency,
            baseFare: model.response!.results!.fare!.baseFare,
            tax: model.response!.results!.fare!.tax,
            offeredFare: model.response!.results!.fare!.offeredFare,
            publishedFare: model.response!.results!.fare!.publishedFare,
          )
              : null,
          segments: model.response!.results!.segments != null
              ? model.response!.results!.segments!.map((segmentList) {
            return segmentList.map((segment) {
              return SegmentEntity(
                baggage: segment.baggage,
                airline: segment.airline != null
                    ? AirlineEntity(
                  airlineCode: segment.airline!.airlineCode,
                  airlineName: segment.airline!.airlineName,
                  flightNumber: segment.airline!.flightNumber,
                )
                    : null,
                origin: segment.origin?.airport != null
                    ? AirportDetailEntity(
                  airportCode: segment.origin!.airport!.airportCode,
                  airportName: segment.origin!.airport!.airportName,
                  cityName: segment.origin!.airport!.cityName,
                )
                    : null,
                destination: segment.destination?.airport != null
                    ? AirportDetailEntity(
                  airportCode: segment.destination!.airport!.airportCode,
                  airportName: segment.destination!.airport!.airportName,
                  cityName: segment.destination!.airport!.cityName,
                )
                    : null,
                duration: segment.duration,
              );
            }).toList();
          }).toList()
              : null,
        )
            : null,
        traceId: model.response!.traceId,
      )
          : null,
    );
  }
}