import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/TReservation_usecase.dart';
import 'TReservation_event.dart';
import 'TReservation_state.dart';

class TransportReservationBloc
    extends Bloc<TransportReservationEvent, TransportReservationState> {
  final CreateTransportReservationUseCase createTransportReservationUseCase;

  TransportReservationBloc({
    required this.createTransportReservationUseCase,
  }) : super(const TransportReservationInitial()) {
    on<CreateTransportReservationEvent>(_onCreateTransportReservation);
  }

  Future<void> _onCreateTransportReservation(
      CreateTransportReservationEvent event,
      Emitter<TransportReservationState> emit,
      ) async {
    emit(const TransportReservationLoading());

    final result = await createTransportReservationUseCase(
      searchId: event.searchId,
      resultId: event.resultId,
      firstName: event.firstName,
      email: event.email,
      phoneNumber: event.phoneNumber,
      customerInfo: event.customerInfo,
      passengers: event.passengers,
      numPassengers: event.numPassengers,
      currency: event.currency,
      selectedCurrency: event.selectedCurrency,
      displayCurrency: event.displayCurrency,
      displayTotalPrice: event.displayTotalPrice,
      displayBasePrice: event.displayBasePrice,
      displayRideBasePrice: event.displayRideBasePrice,
      displayDiscountAmount: event.displayDiscountAmount,
      optionalAmenities: event.optionalAmenities,
      tripStartAddress: event.tripStartAddress,
      tripEndAddress: event.tripEndAddress,
      tripPickupDatetime: event.tripPickupDatetime,
      tripType: event.tripType,
      vehicleName: event.vehicleName,
      providerName: event.providerName,
      paidVia: event.paidVia,
      paymentGateway: event.paymentGateway,
      paymentReferenceId: event.paymentReferenceId,
      razorpayOrderId: event.razorpayOrderId,
      razorpayPaymentId: event.razorpayPaymentId,
      specialInstructions: event.specialInstructions,
      notes: event.notes,
      flightNumber: event.flightNumber,
      airline: event.airline,
      couponCode: event.couponCode,
      extraPaxInfo: event.extraPaxInfo,
    );

    if (result is DataSuccess) {
      emit(TransportReservationSuccess(result.data!));
    } else if (result is DataFailed) {
      emit(TransportReservationFailed(result));
    }
  }
}