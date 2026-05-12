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
    print('=== seatOptions called ===');
    if (raw == null || raw.isEmpty) {
      print('raw is null or empty');
      return null;
    }

    final seats = <SeatOptionEntity>[];

    for (final segment in raw) {
      final segmentSeat = segment.segmentSeat;
      if (segmentSeat == null || segmentSeat.isEmpty) continue;

      for (final rowGroup in segmentSeat) {
        final rowSeats = rowGroup.rowSeats;
        if (rowSeats == null || rowSeats.isEmpty) continue;

        for (final seatRow in rowSeats) {
          final seatModels = seatRow.seats; // Now this is directly List<SeatModel>
          if (seatModels == null || seatModels.isEmpty) {
            print('No seat models found in this row');
            continue;
          }

          for (final seatModel in seatModels) {
            print('Found seat: row=${seatModel.rowNo}, seat=${seatModel.seatNo}, avail=${seatModel.availablityType}');

            // Skip invalid seats
            if (seatModel.rowNo == null || seatModel.rowNo == "0") {
              print('Skipping - invalid row');
              continue;
            }
            if (seatModel.seatNo == null || seatModel.seatNo!.isEmpty) {
              print('Skipping - invalid seatNo');
              continue;
            }
            if (seatModel.code == null || seatModel.code == "NoSeat") {
              print('Skipping - NoSeat');
              continue;
            }

            seats.add(SeatOptionEntity(
              airlineCode: seatModel.airlineCode ?? '',
              flightNumber: seatModel.flightNumber ?? '',
              craftType: seatModel.craftType ?? '',
              origin: seatModel.origin ?? '',
              destination: seatModel.destination ?? '',
              availablityType: seatModel.availablityType ?? 0,
              description: seatModel.description ?? 0,
              code: seatModel.code ?? '',
              rowNo: seatModel.rowNo ?? '',
              seatNo: seatModel.seatNo ?? '',
              seatType: seatModel.seatType ?? 0,
              seatWayType: seatModel.seatWayType ?? 0,
              compartment: seatModel.compartment ?? 0,
              deck: seatModel.deck ?? 0,
              currency: seatModel.currency ?? 'USD',
              price: seatModel.price ?? 0.0,
            ));
          }
        }
      }
    }

    print('Total seats found: ${seats.length}');
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