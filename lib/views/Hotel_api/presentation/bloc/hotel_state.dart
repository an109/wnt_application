import 'package:equatable/equatable.dart';
import '../../domain/entities/hotel_entity.dart';

abstract class HotelState extends Equatable {
  const HotelState();

  @override
  List<Object?> get props => [];
}

class HotelInitial extends HotelState {
  const HotelInitial();
}

class HotelLoading extends HotelState {
  const HotelLoading();
}

class HotelLoadMoreLoading extends HotelState {
  const HotelLoadMoreLoading();
}

class HotelLoaded extends HotelState {
  final List<HotelEntity> hotels;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalHotels;
  final bool hasReachedMax;

  const HotelLoaded({
    required this.hotels,
    this.currentPage = 1,
    this.pageSize = 20,
    this.totalPages = 0,
    this.totalHotels = 0,
    this.hasReachedMax = false,
  });

  HotelLoaded copyWith({
    List<HotelEntity>? hotels,
    int? currentPage,
    int? pageSize,
    int? totalPages,
    int? totalHotels,
    bool? hasReachedMax,
  }) {
    return HotelLoaded(
      hotels: hotels ?? this.hotels,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalHotels: totalHotels ?? this.totalHotels,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [
    hotels,
    currentPage,
    pageSize,
    totalPages,
    totalHotels,
    hasReachedMax,
  ];
}

class HotelError extends HotelState {
  final String message;

  const HotelError(this.message);

  @override
  List<Object?> get props => [message];
}