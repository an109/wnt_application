// import 'package:dio/dio.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../core/error/data_state.dart';
// import '../../domain/usecases/get_airport_usecase.dart';
// import 'airport_event.dart';
// import 'airport_state.dart';
//
// class AirportBloc extends Bloc<AirportEvent, AirportState> {
//   final GetAirportsUsecase getAirportsUsecase;
//
//   AirportBloc(this.getAirportsUsecase) : super(AirportInitial()) {
//     on<LoadAirports>(_onLoadAirports);
//   }
//
//   Future<void> _onLoadAirports(
//       LoadAirports event,
//       Emitter<AirportState> emit,
//       ) async {
//     emit(AirportLoading());
//
//     final result = await getAirportsUsecase(country: event.country);
//
//     if (result is DataSuccess) {
//       emit(AirportLoaded(result.data!));
//     } else if (result is DataFailed) {
//       String errorMessage = 'An error occurred';
//       if (result.error != null) {
//         // Handle different DioException types
//         switch (result.error!.type) {
//           case DioExceptionType.connectionTimeout:
//           case DioExceptionType.receiveTimeout:
//             errorMessage = 'Connection timeout. Please check your internet.';
//             break;
//           case DioExceptionType.badResponse:
//             final statusCode = result.error!.response?.statusCode;
//             if (statusCode == 401) {
//               errorMessage = 'Unauthorized. Please login again.';
//             } else if (statusCode == 404) {
//               errorMessage = 'Airports not found.';
//             } else if (statusCode != null && statusCode >= 500) {
//               errorMessage = 'Server error. Please try again later.';
//             } else {
//               errorMessage = result.error!.message ?? 'Request failed';
//             }
//             break;
//           case DioExceptionType.cancel:
//             errorMessage = 'Request cancelled';
//             break;
//           default:
//             errorMessage = result.error!.message ?? 'Unknown error';
//         }
//       }
//       emit(AirportError(errorMessage));
//     }
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecases/get_airport_usecase.dart';
import 'airport_event.dart';
import 'airport_state.dart';

class AirportBloc extends Bloc<AirportEvent, AirportState> {
  final GetAirportsUsecase getAirportsUsecase;

  AirportBloc(this.getAirportsUsecase) : super(AirportInitial()) {
    print('[AirportBloc] Initialized');
    on<LoadAirports>(_onLoadAirports);
  }

  Future<void> _onLoadAirports(
    LoadAirports event,
    Emitter<AirportState> emit,
  ) async {
    print('[AirportBloc] LoadAirports event triggered');
    print('[AirportBloc] Country: ${event.country}');

    emit(AirportLoading());
    print('[AirportBloc] State changed to AirportLoading');

    final result = await getAirportsUsecase(country: event.country);

    print('[AirportBloc] API response received');

    if (result is DataSuccess) {
      print('[AirportBloc] DataSuccess received');
      print('[AirportBloc] Total airports: ${result.data?.length}');

      emit(AirportLoaded(result.data!));

      print('[AirportBloc] State changed to AirportLoaded');
    } else if (result is DataFailed) {
      print('[AirportBloc] DataFailed received');

      String errorMessage = 'An error occurred';

      if (result.error != null) {
        print('[AirportBloc] DioException type: ${result.error!.type}');
        print('[AirportBloc] DioException message: ${result.error!.message}');

        switch (result.error!.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Connection timeout. Please check your internet.';

            print('[AirportBloc] Connection timeout error');

            break;

          case DioExceptionType.badResponse:
            final statusCode = result.error!.response?.statusCode;

            print('[AirportBloc] Bad response status code: $statusCode');

            if (statusCode == 401) {
              errorMessage = 'Unauthorized. Please login again.';

              print('[AirportBloc] Unauthorized error');
            } else if (statusCode == 404) {
              errorMessage = 'Airports not found.';

              print('[AirportBloc] Airports not found');
            } else if (statusCode != null && statusCode >= 500) {
              errorMessage = 'Server error. Please try again later.';

              print('[AirportBloc] Server error');
            } else {
              errorMessage = result.error!.message ?? 'Request failed';

              print('[AirportBloc] Request failed');
            }

            break;

          case DioExceptionType.cancel:
            errorMessage = 'Request cancelled';

            print('[AirportBloc] Request cancelled');

            break;

          default:
            errorMessage = result.error!.message ?? 'Unknown error';

            print('[AirportBloc] Unknown error occurred');
        }
      }

      print('[AirportBloc] Emitting AirportError');
      print('[AirportBloc] Error message: $errorMessage');

      emit(AirportError(errorMessage));

      print('[AirportBloc] State changed to AirportError');
    }
  }
}
