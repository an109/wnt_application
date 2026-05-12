
import 'package:equatable/equatable.dart';

abstract class HotelEvent extends Equatable {
  const HotelEvent();

  @override
  List<Object?> get props => [];
}

class LoadHotelsEvent extends HotelEvent {
  final String cityCode;
  final String checkIn;
  final String checkOut;
  final String guestNationality;
  final int page;
  final int pageSize;
  final Map<String, dynamic>? filters;
  final List<Map<String, dynamic>>? paxRooms;

  const LoadHotelsEvent({
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
    required this.guestNationality,
    this.page = 1,
    this.pageSize = 20,
    this.filters,
    this.paxRooms,
  });

  @override
  List<Object?> get props => [
    cityCode,
    checkIn,
    checkOut,
    guestNationality,
    page,
    pageSize,
    filters,
    paxRooms,
  ];
}

class LoadMoreHotelsEvent extends HotelEvent {
  final String cityCode;
  final String checkIn;
  final String checkOut;
  final String guestNationality;
  final int nextPage;
  final int pageSize;
  final Map<String, dynamic>? filters;
  final List<Map<String, dynamic>>? paxRooms;

  const LoadMoreHotelsEvent({
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
    required this.guestNationality,
    required this.nextPage,
    this.pageSize = 20,
    this.filters,
    this.paxRooms,
  });

  @override
  List<Object?> get props => [
    cityCode,
    checkIn,
    checkOut,
    guestNationality,
    nextPage,
    pageSize,
    filters,
    paxRooms,
  ];
}

class RefreshHotelsEvent extends HotelEvent {
  final String cityCode;
  final String checkIn;
  final String checkOut;
  final String guestNationality;
  final Map<String, dynamic>? filters;
  final List<Map<String, dynamic>>? paxRooms;

  const RefreshHotelsEvent({
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
    required this.guestNationality,
    this.filters,
    this.paxRooms,
  });

  @override
  List<Object?> get props => [
    cityCode,
    checkIn,
    checkOut,
    guestNationality,
    filters,
    paxRooms,
  ];
}