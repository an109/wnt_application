import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/fare_rule_entity.dart';
import '../../domain/repository/fare_rule_repository.dart';
import '../data_sorce/fare_rule_api_service.dart';
import '../model/fare_rule_models.dart';

class FareRuleRepositoryImpl implements FareRuleRepository {
  final FareRuleApiService apiService;

  FareRuleRepositoryImpl(this.apiService);

  @override
  Future<DataState<FareRuleResponseEntity>> getFareRules(
      FareRuleRequestEntity request) async {
    try {
      // Convert entity to model for API call
      final requestModel = FareRuleRequestModel(
        endUserIp: request.endUserIp,
        traceId: request.traceId,
        tokenId: request.tokenId,
        resultIndex: request.resultIndex,
      );

      final response = await apiService.getFareRules(requestModel);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final fareRuleResponseModel = FareRuleResponseModel.fromJson(responseData);

        // Convert model to entity
        final fareRuleResponseEntity = FareRuleResponseEntity(
          error: fareRuleResponseModel.error != null
              ? FareRuleErrorEntity(
            errorCode: fareRuleResponseModel.error!.errorCode,
            errorMessage: fareRuleResponseModel.error!.errorMessage,
          )
              : null,
          fareRules: fareRuleResponseModel.fareRules?.map((model) {
            return FareRuleEntity(
              airline: model.airline,
              departureTime: model.departureTime,
              destination: model.destination,
              fareBasisCode: model.fareBasisCode,
              fareInclusions: model.fareInclusions,
              fareRestriction: model.fareRestriction,
              fareRuleDetail: model.fareRuleDetail,
              flightId: model.flightId,
              origin: model.origin,
              returnDate: model.returnDate,
            );
          }).toList(),
          responseStatus: fareRuleResponseModel.responseStatus,
          traceId: fareRuleResponseModel.traceId,
        );

        // Check for API-level errors in response
        if (fareRuleResponseEntity.error?.errorCode != 0 &&
            fareRuleResponseEntity.error?.errorCode != null) {
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: '/api/tbo/FareRule/'),
              error: fareRuleResponseEntity.error?.errorMessage ?? 'API Error',
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: RequestOptions(path: '/api/tbo/FareRule/'),
                statusCode: fareRuleResponseEntity.error?.errorCode,
                data: responseData,
              ),
            ),
          );
        }

        return DataSuccess(fareRuleResponseEntity);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/tbo/FareRule/'),
            error: 'Unexpected response: ${response.statusCode}',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/tbo/FareRule/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}