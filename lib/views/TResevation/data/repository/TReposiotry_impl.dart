// lib/features/transport_reservations/data/repository/transport_reservation_repository_impl.dart
import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/TReservation-entity.dart';
import '../../domain/repository/TReservation_repository.dart';
import '../data_source/TReservation_api_service.dart';

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
        'phone_number': '91${phoneNumber}',
        'customer_info': {
          'first_name': customerInfo.firstName,
          'last_name': customerInfo.lastName,
          'email': customerInfo.email,
          'phone_number': '91${customerInfo.phoneNumber}',
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

      // The reservation response is nested: { success, reservation:{status},
      // local:{ status, confirmation_number, ... } }. The booking-shaped model
      // can't parse that, so pull status/confirmation directly and return an
      // entity built from what we sent + the live status.
      final responseData =
          (response.data as Map?)?.cast<String, dynamic>() ?? const {};
      final local =
          (responseData['local'] as Map?)?.cast<String, dynamic>() ?? const {};
      final reservationObj =
          (responseData['reservation'] as Map?)?.cast<String, dynamic>() ??
              const {};
      final status =
          (local['status'] ?? reservationObj['status'] ?? '').toString();
      // confirmation_number is blank while pending; fall back to other ids so
      // the user always has a reference to quote.
      final confirmationNumber = (local['confirmation_number'] ??
              local['mozio_reservation_id'] ??
              local['partner_tracking_id'] ??
              '')
          .toString();

      final reservationEntity = TransportReservationEntity(
        searchId: searchId,
        resultId: resultId,
        firstName: firstName,
        email: email,
        phoneNumber: phoneNumber,
        customerInfo: customerInfo,
        passengers: passengers,
        numPassengers: numPassengers,
        currency: currency,
        selectedCurrency: selectedCurrency,
        displayCurrency: displayCurrency,
        displayTotalPrice: displayTotalPrice,
        displayBasePrice: displayBasePrice,
        displayRideBasePrice: displayRideBasePrice,
        displayDiscountAmount: displayDiscountAmount,
        optionalAmenities: optionalAmenities,
        userId: 0,
        tripStartAddress: tripStartAddress,
        tripEndAddress: tripEndAddress,
        tripPickupDatetime: tripPickupDatetime,
        tripPickupDatetimePretty: '',
        tripType: tripType,
        vehicleName: vehicleName,
        providerName: providerName,
        paidVia: paidVia,
        paymentGateway: paymentGateway,
        paymentReferenceId: paymentReferenceId,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        specialInstructions: specialInstructions ?? '',
        notes: notes ?? '',
        flightNumber: flightNumber ?? '',
        airline: airline ?? '',
        couponCode: couponCode,
        extraPaxInfo: extraPaxInfo,
        status: status,
        confirmationNumber: confirmationNumber,
      );

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