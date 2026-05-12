// lib/features/hotel_details/domain/usecases/get_hotel_details_usecase.dart
import '../../../../core/error/data_state.dart';
import '../entities/hotel_details_entity.dart';
import '../repository/hotel_details_entity.dart';


class GetHotelDetailsUsecase {
  final HotelDetailsRepository repository;

  GetHotelDetailsUsecase(this.repository);

  Future<DataState<List<HotelDetailsEntity>>> call({
    required String hotelCode,
    required String checkIn,
    required String checkOut,
    String? language,
    String? guestNationality,
  }) {
    return repository.getHotelDetails(
      hotelCode: hotelCode,
      checkIn: checkIn,
      checkOut: checkOut,
      language: language,
      guestNationality: guestNationality,
    );
  }
}