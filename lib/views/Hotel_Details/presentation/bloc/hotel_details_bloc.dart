import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/get_hotel_details_usecase.dart';
import 'hotel_details_event.dart';
import 'hotel_details_state.dart';

class HotelDetailsBloc extends Bloc<HotelDetailsEvent, HotelDetailsState> {
  final GetHotelDetailsUsecase getHotelDetailsUsecase;

  HotelDetailsBloc({required this.getHotelDetailsUsecase})
      : super(const HotelDetailsInitial()) {
    on<FetchHotelDetailsEvent>(_onFetchHotelDetails);
  }

  Future<void> _onFetchHotelDetails(
      FetchHotelDetailsEvent event,
      Emitter<HotelDetailsState> emit,
      ) async {
    print('HotelDetailsBloc: Fetching hotel details for code: ${event.hotelCode}');

    emit(const HotelDetailsLoading());

    try {
      final result = await getHotelDetailsUsecase(
        hotelCode: event.hotelCode,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        language: event.language,
        guestNationality: event.guestNationality,
      );

      if (result is DataSuccess) {
        print('HotelDetailsBloc: Successfully loaded ${result.data!.length} hotels');
        emit(HotelDetailsLoaded(result.data!));
      } else if (result is DataFailed) {
        final errorMessage = _getErrorMessage(result.error);
        print('HotelDetailsBloc: Error - $errorMessage');
        emit(HotelDetailsError(errorMessage));
      }
    } catch (e) {
      print('HotelDetailsBloc: Unexpected error - $e');
      emit(HotelDetailsError('An unexpected error occurred'));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unknown error occurred';
    }

    // Handle DioException
    final errorString = error.toString();

    if (errorString.contains('SocketException') ||
        errorString.contains('Network')) {
      return 'Network error. Please check your connection';
    }

    if (errorString.contains('401')) {
      return 'Unauthorized. Please login again';
    }

    if (errorString.contains('404')) {
      return 'Hotel not found';
    }

    if (errorString.contains('500')) {
      return 'Server error. Please try again later';
    }

    // Try to extract error message from response
    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map && data['Status'] != null) {
        return data['Status']['Description'] ?? 'Failed to fetch hotel details';
      }
    }

    return error.message ?? 'Failed to fetch hotel details';
  }
}