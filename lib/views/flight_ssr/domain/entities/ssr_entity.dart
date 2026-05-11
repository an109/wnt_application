// import 'package:equatable/equatable.dart';
// import '../../data/models/baggage_model.dart';
// import '../../data/models/meal_dynamic_model.dart';
// import '../../data/models/seat_dynamic_model.dart';
// import '../../data/models/special_service_model.dart';
//
// class SsrEntity extends Equatable {
//   final int? responseStatus;
//   final int? errorCode;
//   final String? errorMessage;
//   final String? traceId;
//   final List<List<BaggageModel>>? baggage;
//   final List<List<MealDynamicModel>>? mealDynamic;
//   final List<SeatDynamicModel>? seatDynamic;
//   final List<SpecialServiceModel>? specialServices;
//
//   const SsrEntity({
//     this.responseStatus,
//     this.errorCode,
//     this.errorMessage,
//     this.traceId,
//     this.baggage,
//     this.mealDynamic,
//     this.seatDynamic,
//     this.specialServices,
//   });
//
//   @override
//   List<Object?> get props => [
//     responseStatus,
//     errorCode,
//     errorMessage,
//     traceId,
//     baggage,
//     mealDynamic,
//     seatDynamic,
//     specialServices,
//   ];
// }

import 'package:equatable/equatable.dart';
import 'package:wander_nova/views/flight_ssr/domain/entities/seat_option_entity.dart';
import 'package:wander_nova/views/flight_ssr/domain/entities/service_selection_entity.dart';
import '../../data/models/baggage_model.dart';
import '../../data/models/meal_dynamic_model.dart';
import '../../data/models/seat_dynamic_model.dart';
import '../../data/models/special_service_model.dart';
import 'baggage_option_entity.dart';
import 'meal_option_entity.dart';

class SsrEntity extends Equatable {
  final int? responseStatus;
  final int? errorCode;
  final String? errorMessage;
  final String? traceId;

  // Raw API models
  final List<List<BaggageModel>>? baggage;
  final List<List<MealDynamicModel>>? mealDynamic;
  final List<SeatDynamicModel>? seatDynamic;
  final List<SpecialServiceModel>? specialServices;

  const SsrEntity({
    this.responseStatus,
    this.errorCode,
    this.errorMessage,
    this.traceId,
    this.baggage,
    this.mealDynamic,
    this.seatDynamic,
    this.specialServices,
  });

  /// Computed getter: converts raw BaggageModel list to UI-ready BaggageOptionEntity list
  List<List<BaggageOptionEntity>>? get baggageOptions {
    if (baggage == null) return null;

    return baggage!.map((segment) {
      return segment.map((model) {
        return BaggageOptionEntity(
          airlineCode: model.airlineCode ?? '',
          flightNumber: model.flightNumber ?? '',
          wayType: model.wayType ?? 0,
          code: model.code ?? '',
          description: model.description ?? 0,
          weight: model.weight ?? 0,
          currency: model.currency ?? 'USD',
          price: model.price ?? 0.0,
          origin: model.origin ?? '',
          destination: model.destination ?? '',
        );
      }).toList();
    }).toList();
  }

  List<List<MealOptionEntity>>? get mealOptions {
    if (mealDynamic == null) return null;

    return mealDynamic!.map((segment) {
      return segment.map((model) {
        return MealOptionEntity(
          airlineCode: model.airlineCode ?? '',
          flightNumber: model.flightNumber ?? '',
          wayType: model.wayType ?? 0,
          code: model.code ?? '',
          description: model.description ?? 0,
          airlineDescription: model.airlineDescription ?? '',
          quantity: model.quantity ?? 0,
          currency: model.currency ?? 'USD',
          price: model.price ?? 0.0,
          origin: model.origin ?? '',
          destination: model.destination ?? '',
        );
      }).toList();
    }).toList();
  }

  List<SeatOptionEntity>? get seatOptions {
    final raw = seatDynamic;
    if (raw == null) return null;

    final seats = <SeatOptionEntity>[];

    for (final segment in raw) {
      final segmentSeat = segment.segmentSeat;
      if (segmentSeat == null) continue;

      for (final rowGroup in segmentSeat) {
        final rowSeats = rowGroup.rowSeats;
        if (rowSeats == null) continue;

        for (final seatGroup in rowSeats) {
          final seatList = seatGroup.seats;  // This is List<SeatGroup>
          if (seatList == null) continue;

          // 🔥 ADD THIS EXTRA LOOP - seatList contains SeatGroup, not SeatModel
          for (final innerSeatGroup in seatList) {
            final actualSeats = innerSeatGroup.seats;  // This is List<SeatModel>
            if (actualSeats == null) continue;

            for (final model in actualSeats) {
              seats.add(SeatOptionEntity(
                airlineCode: model.airlineCode ?? '',
                flightNumber: model.flightNumber ?? '',
                craftType: model.craftType ?? '',
                origin: model.origin ?? '',
                destination: model.destination ?? '',
                availablityType: model.availablityType,
                description: model.description,
                code: model.code ?? '',
                rowNo: model.rowNo ?? '',
                seatNo: model.seatNo ?? '',
                seatType: model.seatType,
                seatWayType: model.seatWayType,
                compartment: model.compartment,
                deck: model.deck,
                currency: model.currency ?? 'USD',
                price: model.price ?? 0.0,
              ));
            }
          }
        }
      }
    }

    return seats.isNotEmpty ? seats : null;
  }

  List<SpecialServiceEntity>? get specialServiceOptions {
    if (specialServices == null) return null;

    final services = <SpecialServiceEntity>[];
    for (final segment in specialServices!) {
      final segmentService = segment.segmentSpecialService;
      if (segmentService != null) {
        for (final serviceGroup in segmentService) {
          final serviceList = serviceGroup.ssrService;
          if (serviceList != null) {
            services.addAll(serviceList.map((model) {
              return SpecialServiceEntity(
                origin: model.origin ?? '',
                destination: model.destination ?? '',
                departureTime: model.departureTime,
                airlineCode: model.airlineCode ?? '',
                flightNumber: model.flightNumber ?? '',
                code: model.code ?? '',
                serviceType: model.serviceType,
                text: model.text ?? '',
                wayType: model.wayType,
                currency: model.currency ?? 'USD',
                price: model.price ?? 0.0,
              );
            }));
          }
        }
      }
    }
    return services.isNotEmpty ? services : null;
  }

  @override
  List<Object?> get props => [
    responseStatus,
    errorCode,
    errorMessage,
    traceId,
    baggage,
    mealDynamic,
    seatDynamic,
    specialServices,
  ];
}