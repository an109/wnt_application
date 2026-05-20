import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/footer_setting_entity.dart';
import '../../domain/repository/footer_setting_repository.dart';
import '../data_source/footer_setting_api_service.dart';
import '../domain/footer_setting_model.dart';


class FooterSettingsRepositoryImpl implements FooterSettingsRepository {
  final FooterSettingsApiService apiService;

  FooterSettingsRepositoryImpl(this.apiService);

  @override
  Future<DataState<FooterSettingsEntity>> getFooterSettings({required String domain}) async {
    try {
      final response = await apiService.getFooterSettings(domain: domain);

      if (response.statusCode == 200) {
        final model = FooterSettingsModel.fromJson(response.data);
        final entity = _mapModelToEntity(model);
        return DataSuccess(entity);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: response.requestOptions.path),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'footer_settings'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  FooterSettingsEntity _mapModelToEntity(FooterSettingsModel model) {
    return FooterSettingsEntity(
      success: model.success,
      settings: SettingsEntity(
        id: model.settings.id,
        reseller: model.settings.reseller,
        phoneNumber1: model.settings.phoneNumber1,
        phoneNumber2: model.settings.phoneNumber2,
        emailAddress: model.settings.emailAddress,
        officeAddress: model.settings.officeAddress,
        showVisa: model.settings.showVisa,
        showMastercard: model.settings.showMastercard,
        showAmex: model.settings.showAmex,
        showRupay: model.settings.showRupay,
        facebookUrl: model.settings.facebookUrl,
        instagramUrl: model.settings.instagramUrl,
        twitterUrl: model.settings.twitterUrl,
        tiktokUrl: model.settings.tiktokUrl,
        linkedinUrl: model.settings.linkedinUrl,
        youtubeUrl: model.settings.youtubeUrl,
        copyrightText: model.settings.copyrightText,
        footerBannerImage: model.settings.footerBannerImage,
        footerBannerUrl: model.settings.footerBannerUrl,
        showFooterBanner: model.settings.showFooterBanner,
        created: model.settings.created,
        updated: model.settings.updated,
      ),
    );
  }
}