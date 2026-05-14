import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../entities/T_locationEntity.dart';
import '../repository/T_location_repository.dart';

class T_locationsResponse {
  final bool success;
  final int count;
  final List<T_locationEntity> locations;
  final List<String> sources;

  const T_locationsResponse({
    required this.success,
    required this.count,
    required this.locations,
    required this.sources,
  });
}

class GetT_locationsUseCase {
  final T_locationRepository repository;

  GetT_locationsUseCase(this.repository);

  Future<DataState<T_locationsResponse>> execute({
    String? country,
    String? searchQuery,
  }) async {
    try {
      final result = await repository.getT_locations(
        country: country,
        searchQuery: searchQuery,
      );

      if (result is DataSuccess) {
        final response = result.data;
        if (response == null) {
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: 'getT_locations'),
              error: 'Empty response from server',
              type: DioExceptionType.unknown,
            ),
          );
        }

        // Parse the response
        final bool success = response.data['success'] ?? false;
        final int count = response.data['count'] ?? 0;
        final List<dynamic> locationsJson = response.data['locations'] ?? [];
        final List<dynamic> sourcesJson = response.data['sources'] ?? [];

        final List<T_locationEntity> locations = locationsJson
            .map((json) => T_locationEntity(
          id: json['id'] ?? '',
          source: json['source'] ?? '',
          type: json['type'] ?? '',
          label: json['label'] ?? '',
          displayName: json['display_name'] ?? '',
          name: json['name'] ?? '',
          description: json['description'] ?? '',
          formattedAddress: json['formatted_address'] ?? '',
          fullAddress: json['full_address'] ?? '',
          address: json['address'] ?? '',
          city: json['city'] ?? '',
          country: json['country'] ?? '',
          iataCode: json['iata_code'] ?? '',
          icaoCode: json['icao_code'] ?? '',
          placeId: json['place_id'] ?? '',
          lat: json['lat'] != null
              ? double.tryParse(json['lat'].toString())
              : null,
          lng: json['lng'] != null
              ? double.tryParse(json['lng'].toString())
              : null,
          timezone: json['timezone'] ?? '',
          raw: json['raw'] != null
              ? Map<String, dynamic>.from(json['raw'])
              : null,
        ))
            .toList();

        final List<String> sources = sourcesJson.map((s) => s.toString()).toList();

        return DataSuccess(T_locationsResponse(
          success: success,
          count: count,
          locations: locations,
          sources: sources,
        ));
      } else if (result is DataFailed) {
        return DataFailed(result.error!);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: 'getT_locations'),
            error: 'Unknown error occurred',
            type: DioExceptionType.unknown,
          ),
        );
      }
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'getT_locations'),
          error: 'An unexpected error occurred: ${e.toString()}',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}