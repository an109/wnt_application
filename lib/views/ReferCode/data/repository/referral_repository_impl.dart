import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/referral_entity.dart';
import '../../domain/repository/referral_repository.dart';
import '../data_source/referral_api_service.dart';
import '../model/referral_model.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralApiService _referralApiService;

  ReferralRepositoryImpl(this._referralApiService);

  @override
  Future<DataState<ReferralEntity>> getUserReferral() async {
    try {
      final response = await _referralApiService.getUserReferral();

      if (response.statusCode == 200) {
        final referralModel = ReferralModel.fromJson(response.data);
        return DataSuccess(referralModel);
      } else {
        return DataFailed(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}