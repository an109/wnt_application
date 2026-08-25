import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/logo.dart';
import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../wallet/data/data_source/wallet_api_service.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/TReservation-entity.dart';
import '../../domain/usecase/TReservation_usecase.dart';
import 'booking_confirmation_screen.dart';


class PaymentScreen extends StatefulWidget {
  final String resultId;
  final String searchId;
  final String vehicleType;
  final String vehicleName;
  final String providerName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime pickupDate;
  final int passengers;
  final double baseFare;
  final double totalAmount;
  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;
  final int? userId;

  /// Flight details captured on the booking form. Mozio requires non-blank
  /// `airline` and `flight_number` on every reservation.
  final String flightNumber;
  final String airline;

  const PaymentScreen({
    super.key,
    required this.resultId,
    required this.searchId,
    required this.vehicleType,
    required this.vehicleName,
    required this.providerName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupDate,
    required this.passengers,
    required this.baseFare,
    required this.totalAmount,
    required this.passengerName,
    required this.passengerEmail,
    required this.passengerPhone,
    required this.userId,
    required this.flightNumber,
    required this.airline,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  late final Razorpay _razorpay;
  bool _isProcessing = false;

  // Trip type chosen by the user — drives TransportReservationEntity.tripType.
  String _tripType = 'one_way'; // 'one_way' | 'round_trip'
  DateTime? _returnDate; // required when _tripType == 'round_trip'

  // Color constants
  static const _primaryBlue = Color(0xff1663F7);
  static const _primaryOrange = Color(0xffF97316);
  static const _darkNavy = Color(0xff0D1B3D);
  static const _successGreen = Color(0xff10B981);
  static const _lightGreen = Color(0xffECFDF5);

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  TransportReservationEntity _buildReservationEntity() {
    print('BUILDING RESERVATION ENTITY');

    final nameParts = widget.passengerName.split(' ');
    final firstName = nameParts[0];
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Get selected amenities from booking screen (you'll need to pass these)
    final optionalAmenities = <String>[];
    if (_selectedPaymentMethod == 'razorpay') {
      optionalAmenities.add('razorpay_payment');
    }

    final entity = TransportReservationEntity(
      searchId: widget.searchId,
      resultId: widget.resultId,
      firstName: firstName,
      email: widget.passengerEmail,
      phoneNumber: widget.passengerPhone,
      customerInfo: CustomerInfoEntity(
        firstName: firstName,
        lastName: lastName,
        email: widget.passengerEmail,
        phoneNumber: widget.passengerPhone,
      ),
      passengers: [
        PassengerEntity(
          firstName: firstName,
          lastName: lastName,
          email: widget.passengerEmail,
        ),
      ],
      numPassengers: widget.passengers,
      currency: 'USD',
      selectedCurrency: 'INR',
      displayCurrency: 'INR',
      displayTotalPrice: widget.totalAmount,
      displayBasePrice: widget.baseFare,
      displayRideBasePrice: widget.baseFare,
      displayDiscountAmount: 0.00,
      optionalAmenities: optionalAmenities,
      userId: widget.userId ?? 123,
      guestReference: null,
      tripStartAddress: widget.pickupLocation,
      tripEndAddress: widget.dropoffLocation,
      tripPickupDatetime: widget.pickupDate.toIso8601String(),
      tripPickupDatetimePretty: _formatDateTime(widget.pickupDate),
      tripReturnPickupDatetime: _tripType == 'round_trip' && _returnDate != null
          ? _returnDate!.toIso8601String()
          : '',
      tripReturnPickupDatetimePretty:
          _tripType == 'round_trip' && _returnDate != null
          ? _formatDateTime(_returnDate!)
          : '',
      tripType: _tripType,
      vehicleName: widget.vehicleName,
      providerName: widget.providerName,
      paidVia: _selectedPaymentMethod ?? '',
      paymentGateway: _selectedPaymentMethod ?? '',
      paymentReferenceId: '',
      razorpayOrderId: '',
      razorpayPaymentId: '',
      specialInstructions: '',
      notes: '',
      // Real flight details captured on the booking form. Mozio requires these
      // non-blank on every reservation.
      flightNumber: widget.flightNumber,
      airline: widget.airline,
      couponCode: null,
      extraPaxInfo: null,
    );

    print('Reservation entity built successfully');
    print('Result ID: ${entity.resultId}');
    print('Total Price: ${entity.displayTotalPrice}');
    print('Payment Method: ${entity.paidVia}');

    return entity;
  }

  /// Creates the transport reservation AFTER a successful payment. This is the
  /// step that actually calls `Urls.transportReservations` — without it the
  /// payment goes through but no booking is ever recorded.
  Future<void> _createReservation(String paymentReferenceId) async {
    final entity = _buildReservationEntity();
    print('=== CREATING TRANSPORT RESERVATION (ref=$paymentReferenceId) ===');

    try {
      final result = await di.sl<CreateTransportReservationUseCase>()(
        searchId: entity.searchId,
        resultId: entity.resultId,
        firstName: entity.firstName,
        email: entity.email,
        phoneNumber: entity.phoneNumber,
        customerInfo: entity.customerInfo,
        passengers: entity.passengers,
        numPassengers: entity.numPassengers,
        currency: entity.currency,
        selectedCurrency: entity.selectedCurrency,
        displayCurrency: entity.displayCurrency,
        displayTotalPrice: entity.displayTotalPrice,
        displayBasePrice: entity.displayBasePrice,
        displayRideBasePrice: entity.displayRideBasePrice,
        displayDiscountAmount: entity.displayDiscountAmount,
        optionalAmenities: entity.optionalAmenities,
        tripStartAddress: entity.tripStartAddress,
        tripEndAddress: entity.tripEndAddress,
        tripPickupDatetime: entity.tripPickupDatetime,
        tripType: entity.tripType,
        vehicleName: entity.vehicleName,
        providerName: entity.providerName,
        paidVia: entity.paidVia,
        paymentGateway: entity.paymentGateway,
        paymentReferenceId: paymentReferenceId,
        razorpayOrderId: entity.razorpayOrderId,
        razorpayPaymentId: entity.razorpayPaymentId,
        specialInstructions: entity.specialInstructions,
        notes: entity.notes,
        flightNumber: entity.flightNumber,
        airline: entity.airline,
        couponCode: entity.couponCode,
        extraPaxInfo: entity.extraPaxInfo,
      );

      if (!mounted) return;
      if (result is DataSuccess<TransportReservationEntity>) {
        print('Reservation created: resultId=${result.data?.resultId}');
        // Show the booking confirmation screen. Use the locally built entity
        // (it carries the full trip/passenger/flight details) and the payment
        // reference. pushReplacement so the user can't go back into payment.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              // Local entity carries the full trip/passenger details; status &
              // confirmation come from the live reservation response.
              reservation: entity,
              status: result.data?.status ?? '',
              confirmationNumber: result.data?.confirmationNumber ?? '',
            ),
          ),
        );
      } else {
        print('Reservation failed: ${result.error?.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment succeeded but the booking could not be created. '
              'Please contact support with your payment reference.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('Reservation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment succeeded but the booking could not be created. '
            'Please contact support.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('PAYMENT SCREEN BUILD CALLED');

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset("assets/images/wander_logo.png", height: 35),
          )
        ],
      ),
      // Remove BlocConsumer - just render UI directly
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTripDetailsSection(),
            const SizedBox(height: 16),
            _buildTripTypeSection(),
            const SizedBox(height: 16),
            _buildPaymentMethodSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }


  Widget _buildTripDetailsSection() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(2),
      ),
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.wp(2)),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: _primaryBlue,
                  size: context.iconMedium,
                ),
              ),
              SizedBox(width: context.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transport Booking',
                      style: TextStyle(
                        fontSize: context.titleMedium,
                        fontWeight: FontWeight.w700,
                        color: _darkNavy,
                      ),
                    ),
                    Text(
                      '${widget.vehicleType} • ${widget.providerName}',
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: context.hp(2)),

          // Pickup and Drop-off
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'PICKUP',
                  value: widget.pickupLocation,
                  icon: Icons.location_on,
                ),
              ),
              SizedBox(width: context.wp(3)),
              Expanded(
                child: _buildInfoCard(
                  title: 'DROP-OFF',
                  value: widget.dropoffLocation,
                  icon: Icons.location_on,
                ),
              ),
            ],
          ),

          SizedBox(height: context.hp(2)),

          // Date and Passengers
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'DATE & TIME',
                  value: _formatDateTime(widget.pickupDate),
                  icon: Icons.calendar_today,
                ),
              ),
              SizedBox(width: context.wp(3)),
              Expanded(
                child: _buildInfoCard(
                  title: 'PASSENGERS',
                  value: '${widget.passengers}',
                  icon: Icons.person,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(context.wp(3)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Colors.grey.shade500,
              ),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.labelSmall,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: _darkNavy,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _pickReturnDateTime() async {
    final base = _returnDate ??
        widget.pickupDate.add(const Duration(hours: 2));
    final initial = base.isBefore(widget.pickupDate) ? widget.pickupDate : base;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: widget.pickupDate,
      lastDate: widget.pickupDate.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _returnDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Widget _buildTripTypeSection() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(2),
      ),
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Type',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w700,
              color: _darkNavy,
            ),
          ),
          SizedBox(height: context.hp(1.5)),
          Row(
            children: [
              Expanded(
                child: _buildTripTypeOption(
                  label: 'One Way',
                  icon: Icons.arrow_forward,
                  value: 'one_way',
                ),
              ),
              SizedBox(width: context.wp(3)),
              Expanded(
                child: _buildTripTypeOption(
                  label: 'Round Trip',
                  icon: Icons.compare_arrows,
                  value: 'round_trip',
                ),
              ),
            ],
          ),
          if (_tripType == 'round_trip') ...[
            SizedBox(height: context.hp(2)),
            Text(
              'RETURN PICKUP',
              style: TextStyle(
                fontSize: context.labelSmall,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: context.hp(1)),
            InkWell(
              onTap: _pickReturnDateTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(context.wp(3)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _returnDate == null
                        ? Colors.grey.shade300
                        : _primaryBlue,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: context.iconSmall,
                      color: _primaryBlue,
                    ),
                    SizedBox(width: context.wp(3)),
                    Expanded(
                      child: Text(
                        _returnDate == null
                            ? 'Select return date & time'
                            : _formatDateTime(_returnDate!),
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          color: _returnDate == null
                              ? Colors.grey.shade500
                              : _darkNavy,
                          fontWeight: _returnDate == null
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: context.iconSmall,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripTypeOption({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _tripType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tripType = value;
          if (value == 'one_way') _returnDate = null;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.hp(1.5)),
        decoration: BoxDecoration(
          color: isSelected ? _primaryBlue.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: context.iconSmall,
              color: isSelected ? _primaryBlue : Colors.grey.shade600,
            ),
            SizedBox(width: context.wp(2)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.bodyMedium,
                fontWeight: FontWeight.w600,
                color: isSelected ? _primaryBlue : _darkNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(2),
      ),
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Choose Payment Method',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.w700,
                  color: _darkNavy,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: _successGreen,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'SSL Secured',
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      color: _successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '100% secure & encrypted payments',
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade600,
            ),
          ),

          SizedBox(height: context.hp(2)),

          // Payment Methods List
          _buildPaymentMethodsList(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    final paymentMethods = [
      {
        'id': 'wallet',
        'name': 'My Wallet',
        'subtitle': 'Bal: 0 INR',
        'icon': Icons.account_balance_wallet,
      },
      {
        'id': 'razorpay',
        'name': 'Razorpay',
        'subtitle': 'Cards, UPI, Net Banking, Wallets',
        'icon': Icons.payment,
      },
    ];

    return Column(
      children: paymentMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              // Toggle selection - deselect if already selected
              if (isSelected) {
                _selectedPaymentMethod = null;
              } else {
                _selectedPaymentMethod = method['id'] as String;
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(context.wp(3)),
            decoration: BoxDecoration(
              color: isSelected
                  ? (method['id'] == 'wallet' ? _lightGreen : _primaryBlue.withOpacity(0.05))
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? (method['id'] == 'wallet' ? _successGreen : _primaryBlue)
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  method['icon'] as IconData,
                  size: context.iconMedium,
                  color: isSelected
                      ? (method['id'] == 'wallet' ? _successGreen : _primaryBlue)
                      : Colors.grey.shade600,
                ),
                SizedBox(width: context.wp(3)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method['name'] as String,
                            style: TextStyle(
                              fontSize: context.bodyMedium,
                              fontWeight: FontWeight.w600,
                              color: _darkNavy,
                            ),
                          ),
                          if (isSelected) ...[
                            const Spacer(),
                            Icon(
                              Icons.check_circle,
                              color: method['id'] == 'wallet'
                                  ? _successGreen
                                  : _primaryBlue,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        method['subtitle'] as String,
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fare Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Base fare',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'INR ${widget.baseFare.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: _darkNavy,
                  ),
                ),
                Text(
                  'INR ${widget.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w800,
                    color: _darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Passenger Info
            Container(
              padding: EdgeInsets.all(context.wp(3)),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Passenger',
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          fontWeight: FontWeight.w600,
                          color: _darkNavy,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.passengerName,
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: _darkNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.passengerEmail,
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    widget.passengerPhone,
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scan & Pay Button
            SizedBox(
              width: double.infinity,
              height: context.buttonHeight,
              child: ElevatedButton(
                onPressed: (_selectedPaymentMethod != null && !_isProcessing)
                    ? _processPayment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (_selectedPaymentMethod != null && !_isProcessing)
                      ? _primaryOrange
                      : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getPaymentIcon(),
                            size: context.iconMedium,
                          ),
                          SizedBox(width: context.wp(2)),
                          Text(
                            _getButtonText(),
                            style: TextStyle(
                              fontSize: context.bodyLarge,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total payable amount: INR ${widget.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentIcon() {
    switch (_selectedPaymentMethod) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'razorpay':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  String _getButtonText() {
    switch (_selectedPaymentMethod) {
      case 'wallet':
        return 'Pay with Wallet';
      case 'razorpay':
        return 'Pay with Razorpay';
      default:
        return 'Select a payment method';
    }
  }


  // void _processPayment() {
  //   print('=== PROCESS PAYMENT CLICKED ===');
  //
  //   if (_selectedPaymentMethod == null) {
  //     print('ERROR: No payment method selected');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Please select a payment method'),
  //         backgroundColor: Colors.red,
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //       ),
  //     );
  //     return;
  //   }
  //
  //   print('Payment method selected: $_selectedPaymentMethod');
  //
  //   try {
  //     final bloc = context.read<TransportReservationBloc>();
  //     print('BLoC instance retrieved: ${bloc.runtimeType}');
  //
  //     final reservationEntity = _buildReservationEntity();
  //
  //     print('=== DISPATCHING CREATE RESERVATION EVENT ===');
  //     print('Search ID: ${reservationEntity.searchId}');
  //     print('Result ID: ${reservationEntity.resultId}');
  //     print('User ID: ${reservationEntity.userId}');
  //     print('Customer: ${reservationEntity.firstName} ${reservationEntity.customerInfo.lastName}');
  //     print('Email: ${reservationEntity.email}');
  //     print('Phone: ${reservationEntity.phoneNumber}');
  //     print('Trip: ${reservationEntity.tripStartAddress} → ${reservationEntity.tripEndAddress}');
  //     print('Pickup: ${reservationEntity.tripPickupDatetime}');
  //     print('Vehicle: ${reservationEntity.vehicleName} (${reservationEntity.providerName})');
  //     print('Total: ${reservationEntity.displayTotalPrice} ${reservationEntity.displayCurrency}');
  //     print('Payment: ${reservationEntity.paidVia} via ${reservationEntity.paymentGateway}');
  //
  //     bloc.add(
  //       CreateTransportReservationEvent(
  //         searchId: reservationEntity.searchId,
  //         resultId: reservationEntity.resultId,
  //         firstName: reservationEntity.firstName,
  //         email: reservationEntity.email,
  //         phoneNumber: reservationEntity.phoneNumber,
  //         customerInfo: reservationEntity.customerInfo,
  //         passengers: reservationEntity.passengers,
  //         numPassengers: reservationEntity.numPassengers,
  //         currency: reservationEntity.currency,
  //         selectedCurrency: reservationEntity.selectedCurrency,
  //         displayCurrency: reservationEntity.displayCurrency,
  //         displayTotalPrice: reservationEntity.displayTotalPrice,
  //         displayBasePrice: reservationEntity.displayBasePrice,
  //         displayRideBasePrice: reservationEntity.displayRideBasePrice,
  //         displayDiscountAmount: reservationEntity.displayDiscountAmount,
  //         optionalAmenities: reservationEntity.optionalAmenities,
  //         tripStartAddress: reservationEntity.tripStartAddress,
  //         tripEndAddress: reservationEntity.tripEndAddress,
  //         tripPickupDatetime: reservationEntity.tripPickupDatetime,
  //         tripType: reservationEntity.tripType,
  //         vehicleName: reservationEntity.vehicleName,
  //         providerName: reservationEntity.providerName,
  //         paidVia: reservationEntity.paidVia,
  //         paymentGateway: reservationEntity.paymentGateway,
  //         paymentReferenceId: reservationEntity.paymentReferenceId,
  //         razorpayOrderId: reservationEntity.razorpayOrderId,
  //         razorpayPaymentId: reservationEntity.razorpayPaymentId,
  //         specialInstructions: reservationEntity.specialInstructions,
  //         notes: reservationEntity.notes,
  //         flightNumber: reservationEntity.flightNumber,
  //         airline: reservationEntity.airline,
  //         couponCode: reservationEntity.couponCode,
  //         extraPaxInfo: reservationEntity.extraPaxInfo,
  //       ),
  //     );
  //
  //     print('✓ Event dispatched successfully');
  //
  //   } catch (e, stack) {
  //     print('✗ ERROR in _processPayment: $e');
  //     print('Stack trace: $stack');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error: $e'),
  //         backgroundColor: Colors.red,
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //   }
  // }
  /// Pays from the wallet if its balance covers the total (uses
  /// [Urls.walletBalance]). There is no debit endpoint, so a sufficient
  /// balance is treated as a successful payment.
  Future<void> _payWithWallet() async {
    // Wallet payment requires a logged-in user.
    if (!di.sl<PreferencesManager>().isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to pay with your wallet'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response = await di.sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (balance >= widget.totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment successful from wallet!'),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Wallet paid → record the booking via the reservation API.
        await _createReservation('WALLET${DateTime.now().millisecondsSinceEpoch}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient wallet balance '
              '(INR ${balance.toStringAsFixed(2)} available)',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch wallet balance. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // ----- Razorpay flow -----
  // ============================================================
  Future<void> _processPayment() async {
    print('=== PAYMENT SCREEN: Processing payment method ===');

    if (_selectedPaymentMethod == null) {
      print('ERROR: No payment method selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_tripType == 'round_trip' && _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a return date & time for your round trip'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Wallet uses the wallet-balance flow; all other methods go via Razorpay.
    if (_selectedPaymentMethod == 'wallet') {
      await _payWithWallet();
      return;
    }

    await _initiateRazorpayPayment();
  }

  Future<void> _initiateRazorpayPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Total is shown in INR on this screen; send a 2-decimal amount.
      final amount = double.parse(widget.totalAmount.toStringAsFixed(2));

      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': amount,
          'currency': 'INR',
          'reference_id': 'transport_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final orderId = response.data['order_id'];
      final keyId = response.data['key_id'];
      print("Razorpay Key: $keyId");

      final options = {
        'key': keyId,
        'amount': (amount * 100).toInt(),
        'currency': 'INR',
        'name': 'WanderNova',
        'description': 'Transport: ${widget.vehicleName}',
        'order_id': orderId,
        'prefill': {
          'name': widget.passengerName,
          'email': widget.passengerEmail,
          'contact': widget.passengerPhone,
        },
        'theme': {'color': '#1663F7'},
      };

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _razorpay.open(options);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      print('Razorpay order error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create payment order. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      print('Razorpay checkout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start payment. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) {
    print('Transport payment success: ${response.paymentId}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment successful!'),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Payment done → now record the booking via the reservation API.
    _createReservation(response.paymentId ?? '');
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? 'Please try again.'}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    print('Razorpay external wallet: ${response.walletName}');
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$dayName, $monthName $day, $year, $hour:$minute';
  }
}