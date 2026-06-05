import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/logo.dart';
import '../../domain/entities/TReservation-entity.dart';


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
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;

  // Color constants
  static const _primaryBlue = Color(0xff1663F7);
  static const _primaryOrange = Color(0xffF97316);
  static const _darkNavy = Color(0xff0D1B3D);
  static const _successGreen = Color(0xff10B981);
  static const _lightGreen = Color(0xffECFDF5);

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
      tripReturnPickupDatetime: '',
      tripReturnPickupDatetimePretty: '',
      tripType: 'one_way',
      vehicleName: widget.vehicleName,
      providerName: widget.providerName,
      paidVia: _selectedPaymentMethod ?? 'razorpay',
      paymentGateway: _selectedPaymentMethod ?? 'razorpay',
      paymentReferenceId: '',
      razorpayOrderId: '',
      razorpayPaymentId: '',
      specialInstructions: '',
      notes: '',
      flightNumber: '',
      airline: '',
      couponCode: null,
      extraPaxInfo: null,
    );

    print('Reservation entity built successfully');
    print('Result ID: ${entity.resultId}');
    print('Total Price: ${entity.displayTotalPrice}');
    print('Payment Method: ${entity.paidVia}');

    return entity;
  }

  @override
  Widget build(BuildContext context) {
    print('PAYMENT SCREEN BUILD CALLED');

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset("assets/images/wander_nova_logo.png", height: 35),
          )
        ],
      ),
      // Remove BlocConsumer - just render UI directly
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTripDetailsSection(),
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
        color: const Color(0xffF8F9FA),
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
        'id': 'card',
        'name': 'Credit / Debit Card',
        'subtitle': 'Visa, Mastercard, Rupay',
        'icon': Icons.credit_card,
      },
      {
        'id': 'netbanking',
        'name': 'Net Banking',
        'subtitle': '40+ Banks Available',
        'icon': Icons.account_balance,
      },
      {
        'id': 'wallets',
        'name': 'Digital Wallets',
        'subtitle': 'Paytm, PhonePe, Amazon Pay',
        'icon': Icons.wallet,
      },
      {
        'id': 'upi',
        'name': 'UPI',
        'subtitle': 'GPay, PhonePe, BHIM & more',
        'icon': Icons.payment,
      },
      {
        'id': 'qr',
        'name': 'QR Code',
        'subtitle': 'Instant Refund · High Success',
        'icon': Icons.qr_code,
      },
      {
        'id': 'razorpay',
        'name': 'Razorpay',
        'subtitle': 'Cards, UPI, Net Banking (INR)',
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
                onPressed: _selectedPaymentMethod != null
                    ? _processPayment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPaymentMethod != null
                      ? _primaryOrange
                      : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
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
    if (_selectedPaymentMethod == null) {
      return Icons.qr_code_scanner;
    }

    switch (_selectedPaymentMethod) {
      case 'qr':
        return Icons.qr_code_scanner;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.payment;
      case 'netbanking':
        return Icons.account_balance;
      case 'wallets':
        return Icons.wallet;
      case 'razorpay':
        return Icons.payment;
      default:
        return Icons.qr_code_scanner;
    }
  }

  String _getButtonText() {
    if (_selectedPaymentMethod == null) {
      return 'Scan & Pay';
    }

    switch (_selectedPaymentMethod) {
      case 'qr':
        return 'Scan & Pay';
      case 'wallet':
        return 'Pay with Wallet';
      case 'card':
        return 'Pay with Card';
      case 'upi':
        return 'Pay with UPI';
      case 'netbanking':
        return 'Pay with Net Banking';
      case 'wallets':
        return 'Pay with Digital Wallet';
      case 'razorpay':
        return 'Pay with Razorpay';
      default:
        return 'Scan & Pay';
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
  void _processPayment() {
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

    print('Payment method selected: $_selectedPaymentMethod');

    // Since reservation is already created, just proceed with payment gateway
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing $_selectedPaymentMethod payment...'),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // TODO: Integrate actual payment gateway (Razorpay, etc.) here
    // After payment success, navigate to confirmation screen
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