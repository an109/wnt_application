import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/hotel_details_entity.dart';
import '../../domain/repository/hotel_details_entity.dart';
import '../data_source/hotel_details_api_service.dart';
import '../models/hotel_details_model.dart';
import '../models/room_model.dart';

class HotelDetailsRepositoryImpl implements HotelDetailsRepository {
  final HotelDetailsApiService apiService;

  HotelDetailsRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<HotelDetailsEntity>>> getHotelDetails({
    required String hotelCode,
    required String checkIn,
    required String checkOut,
    String? language,
    String? guestNationality,
  }) async {
    try {
      final response = await apiService.getHotelDetails(
        hotelCode: hotelCode,
        checkIn: checkIn,
        checkOut: checkOut,
        language: language,
        guestNationality: guestNationality,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        final status = data['Status'];
        if (status != null && status['Code'] == 200) {
          // 👇 Parse HotelDetails array
          final hotelDetailsJson = data['HotelDetails'] as List? ?? [];
          final hotelDetailsList = hotelDetailsJson
              .map((json) => HotelDetailsModel.fromJson(json))
              .toList();

          // 👇 Parse SearchRooms from ROOT level (NOT inside HotelDetails)
          final searchRoomsJson = data['SearchRooms'] as List? ?? [];
          final searchRoomsList = searchRoomsJson
              .map((json) => RoomModel.fromJson(json))
              .toList();

          print('Successfully fetched ${hotelDetailsList.length} hotel details');
          print('Successfully fetched ${searchRoomsList.length} rooms from SearchRooms');

          // 👇 Attach rooms to the first hotel (or all hotels if needed)
          if (hotelDetailsList.isNotEmpty) {
            final hotelWithRooms = HotelDetailsModel(
              // Copy all existing fields from first hotel
              hotelCode: hotelDetailsList.first.hotelCode,
              hotelName: hotelDetailsList.first.hotelName,
              description: hotelDetailsList.first.description,
              hotelFacilities: hotelDetailsList.first.hotelFacilities,
              attractions: hotelDetailsList.first.attractions,
              image: hotelDetailsList.first.image,
              images: hotelDetailsList.first.images,
              address: hotelDetailsList.first.address,
              pinCode: hotelDetailsList.first.pinCode,
              cityId: hotelDetailsList.first.cityId,
              countryName: hotelDetailsList.first.countryName,
              phoneNumber: hotelDetailsList.first.phoneNumber,
              email: hotelDetailsList.first.email,
              hotelWebsiteUrl: hotelDetailsList.first.hotelWebsiteUrl,
              faxNumber: hotelDetailsList.first.faxNumber,
              map: hotelDetailsList.first.map,
              hotelRating: hotelDetailsList.first.hotelRating,
              cityName: hotelDetailsList.first.cityName,
              countryCode: hotelDetailsList.first.countryCode,
              checkInTime: hotelDetailsList.first.checkInTime,
              checkOutTime: hotelDetailsList.first.checkOutTime,
              hotelFees: hotelDetailsList.first.hotelFees,
              searchRooms: searchRoomsList,  // 👈 Attach rooms here
            );

            return DataSuccess([hotelWithRooms]);
          }

          return DataSuccess(hotelDetailsList);
        } else {
          final errorMessage = status?['Description'] ?? 'Failed to fetch hotel details';
          print('API returned error: $errorMessage');
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: '/hotel-details'),
              error: errorMessage,
              type: DioExceptionType.badResponse,
              response: response,
            ),
          );
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/hotel-details'),
            error: 'HTTP Error: ${response.statusCode}',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      print('Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Unknown Repository Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/hotel-details'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}