import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/hotel_entity.dart';
import '../../domain/usecase/get_hotels_by_city_usecase.dart';
import 'hotel_event.dart';
import 'hotel_state.dart';

class HotelBloc extends Bloc<HotelEvent, HotelState> {
  final GetHotelsByCityUseCase getHotelsByCityUseCase;

  // Store the search parameters for pagination
  String? _currentCityCode;
  String? _currentCheckIn;
  String? _currentCheckOut;
  String? _currentGuestNationality;
  Map<String, dynamic>? _currentFilters;
  List<Map<String, dynamic>>? _currentPaxRooms;

  HotelBloc({required this.getHotelsByCityUseCase}) : super(const HotelInitial()) {
    on<LoadHotelsEvent>(_onLoadHotels);
    on<LoadMoreHotelsEvent>(_onLoadMoreHotels);
    on<RefreshHotelsEvent>(_onRefreshHotels);
  }

  Future<void> _onLoadHotels(
      LoadHotelsEvent event,
      Emitter<HotelState> emit,
      ) async {
    emit(const HotelLoading());

    // Store current parameters for pagination
    _currentCityCode = event.cityCode;
    _currentCheckIn = event.checkIn;
    _currentCheckOut = event.checkOut;
    _currentGuestNationality = event.guestNationality;
    _currentFilters = event.filters;
    _currentPaxRooms = event.paxRooms;

    final result = await getHotelsByCityUseCase(
      cityCode: event.cityCode,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      guestNationality: event.guestNationality,
      page: event.page,
      pageSize: event.pageSize,
      filters: event.filters,
      paxRooms: event.paxRooms,
    );

    if (result is DataSuccess<List<HotelEntity>>) {
      print('Hotels loaded successfully: ${result.data!.length}');
      emit(HotelLoaded(
        hotels: result.data!,
        currentPage: event.page,
        pageSize: event.pageSize,
        hasReachedMax: result.data!.isEmpty,
      ));
    } else if (result is DataFailed) {
      print('Failed to load hotels: ${result.error?.message}');
      emit(HotelError(result.error?.message ?? 'Failed to load hotels'));
    }
  }

  Future<void> _onLoadMoreHotels(
      LoadMoreHotelsEvent event,
      Emitter<HotelState> emit,
      ) async {
    // Only proceed if we're not already loading and haven't reached max
    if (state is HotelLoaded) {
      final currentState = state as HotelLoaded;
      if (currentState.hasReachedMax || currentState.hotels.isEmpty) {
        return;
      }

      emit(const HotelLoadMoreLoading());

      // Use stored parameters or event parameters
      final cityCode = _currentCityCode ?? event.cityCode;
      final checkIn = _currentCheckIn ?? event.checkIn;
      final checkOut = _currentCheckOut ?? event.checkOut;
      final guestNationality = _currentGuestNationality ?? event.guestNationality;
      final filters = _currentFilters ?? event.filters;
      final paxRooms = _currentPaxRooms ?? event.paxRooms;

      final result = await getHotelsByCityUseCase(
        cityCode: cityCode,
        checkIn: checkIn,
        checkOut: checkOut,
        guestNationality: guestNationality,
        page: event.nextPage,
        pageSize: event.pageSize,
        filters: filters,
        paxRooms: paxRooms,
      );

      if (result is DataSuccess<List<HotelEntity>>) {
        print('More hotels loaded: ${result.data!.length}');

        final currentHotels = currentState.hotels;
        final newHotels = result.data!;

        // Check if we've reached the end
        final hasReachedMax = newHotels.isEmpty || newHotels.length < event.pageSize;

        emit(currentState.copyWith(
          hotels: [...currentHotels, ...newHotels],
          currentPage: event.nextPage,
          hasReachedMax: hasReachedMax,
        ));
      } else if (result is DataFailed) {
        print('Failed to load more hotels: ${result.error?.message}');
        // Revert to previous state on error
        emit(currentState);
      }
    }
  }

  Future<void> _onRefreshHotels(
      RefreshHotelsEvent event,
      Emitter<HotelState> emit,
      ) async {
    emit(const HotelLoading());

    // Update stored parameters
    _currentCityCode = event.cityCode;
    _currentCheckIn = event.checkIn;
    _currentCheckOut = event.checkOut;
    _currentGuestNationality = event.guestNationality;
    _currentFilters = event.filters;
    _currentPaxRooms = event.paxRooms;

    final result = await getHotelsByCityUseCase(
      cityCode: event.cityCode,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      guestNationality: event.guestNationality,
      page: 1,
      pageSize: 20,
      filters: event.filters,
      paxRooms: event.paxRooms,
    );

    if (result is DataSuccess<List<HotelEntity>>) {
      print('Hotels refreshed successfully: ${result.data!.length}');
      emit(HotelLoaded(
        hotels: result.data!,
        currentPage: 1,
        pageSize: 20,
        hasReachedMax: result.data!.isEmpty,
      ));
    } else if (result is DataFailed) {
      print('Failed to refresh hotels: ${result.error?.message}');
      emit(HotelError(result.error?.message ?? 'Failed to refresh hotels'));
    }
  }
}