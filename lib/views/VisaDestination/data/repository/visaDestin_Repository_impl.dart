import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/visaDestin_Entity.dart';
import '../../domain/repository/visaDestin_Repository.dart';
import '../data_source/visaDestin_apiService.dart';
import '../models/VisaDestin_model.dart';

class VisaDestinationRepositoryImpl implements VisaDestinationRepository {
  final VisaDestinationApiService apiService;

  VisaDestinationRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<VisaDestinationEntity>>> getVisaDestinations({String domain = 'thewandernova.com'}) async {
    try {
      final response = await apiService.getVisaDestinations(domain: domain);

      if (response.success) {
        final entities = response.destinations
            .map((model) => _mapModelToEntity(model))
            .toList();
        return DataSuccess(entities);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/visa-destination-page-content/'),
            error: 'API returned unsuccessful response',
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/visa-destination-page-content/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  VisaDestinationEntity _mapModelToEntity(VisaDestinationModel model) {
    print(" Mapping Model to Entity for: ${model.name}");
    print("   Model.heroBannerImage: ${model.heroBannerImage}");
    print("   Model.ImageUrl: ${model.imageUrl}");
    return VisaDestinationEntity(
      id: model.id,
      name: model.name,
      region: model.region,
      price: model.price,
      priceCurrency: model.priceCurrency,
      processingTime: model.processingTime,
      heroBannerImageUrl: model.heroBannerImageUrl,
      imageUrl: model.imageUrl,
      VisaIntroParagraph: model.VisaIntroParagraph,
      heroBannerImage: model.heroBannerImage,
      visaTypes: model.visaTypes
          .map((type) => VisaTypeEntity(
        stay: type.stay,
        entry: type.entry,
        title: type.title,
        feesInr: type.feesInr,
        popular: type.popular,
        validity: type.validity,
        processing: type.processing,
      ))
          .toList(),
      priceIncludesHeading: model.priceIncludesHeading,
      priceIncludesItems: model.priceIncludesItems,
      requirementsItems: model.requirementsItems,
    );
  }
}