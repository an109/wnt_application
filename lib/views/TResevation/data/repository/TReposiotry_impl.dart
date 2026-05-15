// lib/features/transport_reservations/data/repository/transport_reservation_repository_impl.dart
import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/TReservation-entity.dart';
import '../../domain/repository/TReservation_repository.dart';
import '../data_source/TReservation_api_service.dart';
import '../model/TResevation_model.dart';

class TransportReservationRepositoryImpl implements TransportReservationRepository {
  final TransportReservationApiService apiService;

  TransportReservationRepositoryImpl(this.apiService);

  @override
  Future<DataState<TransportReservationEntity>> createReservation({
    required String searchId,
    required String resultId,
    required String firstName,
    required String email,
    required String phoneNumber,
    required CustomerInfoEntity customerInfo,
    required List<PassengerEntity> passengers,
    required int numPassengers,
    required String currency,
    required String selectedCurrency,
    required String displayCurrency,
    required double displayTotalPrice,
    required double displayBasePrice,
    required double displayRideBasePrice,
    required double displayDiscountAmount,
    required List<String> optionalAmenities,
    required String tripStartAddress,
    required String tripEndAddress,
    required String tripPickupDatetime,
    required String tripType,
    required String vehicleName,
    required String providerName,
    required String paidVia,
    required String paymentGateway,
    required String paymentReferenceId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    String? specialInstructions,
    String? notes,
    String? flightNumber,
    String? airline,
    String? couponCode,
    List<ExtraPaxInfoEntity>? extraPaxInfo,
  }) async {
    try {
      final requestData = {
        'search_id': searchId,
        'result_id': resultId,
        'first_name': firstName,
        'email': email,
        'phone_number': phoneNumber,
        'customer_info': {
          'first_name': customerInfo.firstName,
          'last_name': customerInfo.lastName,
          'email': customerInfo.email,
          'phone_number': customerInfo.phoneNumber,
        },
        'passengers': passengers.map((p) => {
          'first_name': p.firstName,
          'last_name': p.lastName,
          'email': p.email,
        }).toList(),
        'num_passengers': numPassengers,
        'currency': currency,
        'selected_currency': selectedCurrency,
        'display_currency': displayCurrency,
        'display_total_price': displayTotalPrice,
        'display_base_price': displayBasePrice,
        'display_ride_base_price': displayRideBasePrice,
        'display_discount_amount': displayDiscountAmount,
        'optional_amenities': optionalAmenities,
        'trip_start_address': tripStartAddress,
        'trip_end_address': tripEndAddress,
        'trip_pickup_datetime': tripPickupDatetime,
        'trip_type': tripType,
        'vehicle_name': vehicleName,
        'provider_name': providerName,
        'paid_via': paidVia,
        'payment_gateway': paymentGateway,
        'payment_reference_id': paymentReferenceId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        if (specialInstructions != null)
          'special_instructions': specialInstructions,
        if (notes != null) 'notes': notes,
        if (flightNumber != null) 'flight_number': flightNumber,
        if (airline != null) 'airline': airline,
        if (couponCode != null) 'coupon_code': couponCode,
        if (extraPaxInfo != null)
          'extra_pax_info': extraPaxInfo.map((e) => {
            'first_name': e.firstName,
            'last_name': e.lastName,
          }).toList(),
      };

      final response = await apiService.createReservation(requestData);

      // Convert Model to Entity before returning
      final reservationModel = TransportReservationModel.fromJson(response.data);
      final reservationEntity = reservationModel.toEntity();

      return DataSuccess(reservationEntity);
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}