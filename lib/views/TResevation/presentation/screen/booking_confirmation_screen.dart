// import 'package:flutter/material.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
//
// import '../../../../common_widgets/logo.dart';
// import '../../../home/presentation/screens/home_screen.dart';
// import '../../domain/entities/TReservation-entity.dart';
//
// class BookingConfirmationScreen extends StatelessWidget {
//   final TransportReservationEntity reservation;
//
//   /// Reservation status from the response (e.g. "pending", "confirmed").
//   final String status;
//
//   /// Mozio confirmation number. Blank while the booking is still pending.
//   final String confirmationNumber;
//
//   const BookingConfirmationScreen({
//     super.key,
//     required this.reservation,
//     required this.status,
//     required this.confirmationNumber,
//   });
//
//   static const _primaryBlue = Color(0xff1663F7);
//   static const _darkNavy = Color(0xff0D1B3D);
//   static const _successGreen = Color(0xff10B981);
//   static const _amber = Color(0xffF59E0B);
//
//   bool get _isPending => status.toLowerCase() == 'pending';
//   bool get _isConfirmed =>
//       status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'completed';
//
//   Color get _statusColor =>
//       _isConfirmed ? _successGreen : (_isPending ? _amber : _primaryBlue);
//
//   String get _statusLabel =>
//       status.isEmpty ? 'Pending' : status[0].toUpperCase() + status.substring(1);
//
//   void _goHome(BuildContext context) {
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (_) => const HomeScreen()),
//       (route) => false,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final r = reservation;
//     final currency = r.displayCurrency.isNotEmpty ? r.displayCurrency : 'INR';
//
//     return PopScope(
//       // Hardware back also returns home, never to the payment screen.
//       canPop: false,
//       onPopInvokedWithResult: (didPop, _) {
//         if (!didPop) _goHome(context);
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xffF8F9FA),
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           title: const WanderNovaLogo(scaleFactor: 0.6),
//           backgroundColor: Colors.white,
//           elevation: 0,
//           actions: [
//             Padding(
//               padding: EdgeInsets.all(context.w(8)),
//               child: Image.asset('assets/images/wander_logo.png', height: 35),
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           padding: EdgeInsets.all(context.wp(4)),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               SizedBox(height: context.hp(2)),
//               _buildSuccessHeader(context),
//               SizedBox(height: context.hp(3)),
//               _buildReferenceCard(context),
//               SizedBox(height: context.hp(2)),
//               _buildTripCard(context),
//               SizedBox(height: context.hp(2)),
//               _buildPassengerCard(context),
//               SizedBox(height: context.hp(2)),
//               _buildPaymentCard(context, currency),
//               SizedBox(height: context.hp(4)),
//             ],
//           ),
//         ),
//         bottomNavigationBar: _buildBottomBar(context),
//       ),
//     );
//   }
//
//   Widget _buildSuccessHeader(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           width: context.wp(22),
//           height: context.wp(22),
//           decoration: BoxDecoration(
//             color: _statusColor.withValues(alpha: 0.12),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             _isPending ? Icons.hourglass_top_rounded : Icons.check_circle,
//             color: _statusColor,
//             size: context.wp(14),
//           ),
//         ),
//         SizedBox(height: context.hp(2)),
//         Text(
//           _isPending ? 'Booking Received!' : 'Booking Confirmed!',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: context.titleLarge,
//             fontWeight: FontWeight.w800,
//             color: _darkNavy,
//           ),
//         ),
//         SizedBox(height: context.hp(0.8)),
//         Text(
//           _isPending
//               ? 'Your payment is done and the booking is being confirmed. '
//                   'We\'ll email ${reservation.email} once it\'s confirmed.'
//               : 'Your transport has been booked successfully. A confirmation '
//                   'has been sent to ${reservation.email}.',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: context.bodyMedium,
//             color: Colors.grey.shade600,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildReferenceCard(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(context.wp(4)),
//       decoration: BoxDecoration(
//         color: _primaryBlue.withValues(alpha: 0.06),
//         borderRadius: BorderRadius.circular(context.borderRadius),
//         border: Border.all(color: _primaryBlue.withValues(alpha: 0.2)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.confirmation_number_outlined,
//               color: _primaryBlue, size: context.iconMedium),
//           SizedBox(width: context.wp(3)),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'CONFIRMATION NUMBER',
//                   style: TextStyle(
//                     fontSize: context.labelSmall,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.grey.shade600,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 SizedBox(height: context.hp(0.4)),
//                 Text(
//                   confirmationNumber.isNotEmpty
//                       ? confirmationNumber
//                       : 'Pending confirmation',
//                   style: TextStyle(
//                     fontSize: confirmationNumber.isNotEmpty
//                         ? context.titleMedium
//                         : context.bodyMedium,
//                     fontWeight: FontWeight.w800,
//                     color: confirmationNumber.isNotEmpty
//                         ? _darkNavy
//                         : Colors.grey.shade500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _statusBadge(context),
//         ],
//       ),
//     );
//   }
//
//   Widget _statusBadge(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: context.wp(3),
//         vertical: context.hp(0.6),
//       ),
//       decoration: BoxDecoration(
//         color: _statusColor.withValues(alpha: 0.12),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(
//               color: _statusColor,
//               shape: BoxShape.circle,
//             ),
//           ),
//           SizedBox(width: context.wp(1.5)),
//           Text(
//             _statusLabel,
//             style: TextStyle(
//               fontSize: context.labelSmall,
//               fontWeight: FontWeight.w700,
//               color: _statusColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTripCard(BuildContext context) {
//     return _card(
//       context,
//       title: 'Trip Details',
//       icon: Icons.directions_car,
//       children: [
//         _row(context, 'Vehicle', reservation.vehicleName),
//         _row(context, 'Provider', reservation.providerName),
//         _row(context, 'Trip Type',
//             reservation.tripType == 'round_trip' ? 'Round Trip' : 'One Way'),
//         _row(context, 'Pickup', reservation.tripStartAddress),
//         _row(context, 'Drop-off', reservation.tripEndAddress),
//         _row(context, 'Pickup Time', reservation.tripPickupDatetimePretty),
//         if (reservation.tripReturnPickupDatetimePretty.isNotEmpty)
//           _row(context, 'Return Time',
//               reservation.tripReturnPickupDatetimePretty),
//         if (reservation.flightNumber.isNotEmpty)
//           _row(context, 'Flight',
//               '${reservation.airline}'.trim()),
//         _row(context, 'Flight Number',
//               '${reservation.flightNumber}'.trim()),
//         _row(context, 'Passengers', '${reservation.numPassengers}'),
//       ],
//     );
//   }
//
//   Widget _buildPassengerCard(BuildContext context) {
//     return _card(
//       context,
//       title: 'Passenger',
//       icon: Icons.person_outline,
//       children: [
//         _row(context, 'Name',
//             '${reservation.customerInfo.firstName} ${reservation.customerInfo.lastName}'
//                 .trim()),
//         _row(context, 'Email', reservation.email),
//         _row(context, 'Phone', reservation.phoneNumber),
//       ],
//     );
//   }
//
//   Widget _buildPaymentCard(BuildContext context, String currency) {
//     return _card(
//       context,
//       title: 'Payment',
//       icon: Icons.receipt_long,
//       children: [
//         _row(context, 'Method',
//             reservation.paidVia.isEmpty ? '—' : reservation.paidVia),
//         _row(
//           context,
//           'Amount Paid',
//           '$currency ${reservation.displayTotalPrice.toStringAsFixed(2)}',
//           highlight: true,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBottomBar(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(context.wp(4)),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.08),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: SizedBox(
//           width: double.infinity,
//           height: context.buttonHeight,
//           child: ElevatedButton.icon(
//             onPressed: () => _goHome(context),
//             icon: const Icon(Icons.home_outlined),
//             label: const Text('Back to Home'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _primaryBlue,
//               foregroundColor: Colors.white,
//               elevation: 0,
//               textStyle: TextStyle(
//                 fontSize: context.bodyLarge,
//                 fontWeight: FontWeight.w700,
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _card(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Container(
//       padding: EdgeInsets.all(context.wp(4)),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(context.borderRadius),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: _primaryBlue, size: context.iconMedium),
//               SizedBox(width: context.wp(2)),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: context.titleMedium,
//                   fontWeight: FontWeight.w700,
//                   color: _darkNavy,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: context.hp(1.5)),
//           ...children,
//         ],
//       ),
//     );
//   }
//
//   Widget _row(
//     BuildContext context,
//     String label,
//     String value, {
//     bool highlight = false,
//   }) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: context.hp(0.6)),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: context.wp(28),
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: context.bodySmall,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value.isEmpty ? '—' : value,
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                 fontSize: highlight ? context.bodyLarge : context.bodyMedium,
//                 fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
//                 color: highlight ? _successGreen : _darkNavy,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../TReservation_poll/presentation/bloc/poll_bloc.dart';
import '../../../TReservation_poll/presentation/bloc/poll_event.dart';
import '../../../TReservation_poll/presentation/bloc/poll_state.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../domain/entities/TReservation-entity.dart';
// Import your generated GetIt instance and Bloc files
import '../../../../injection_container.dart' as di;

class BookingConfirmationScreen extends StatefulWidget {
  final TransportReservationEntity reservation;
  final String status;
  final String confirmationNumber;

  const BookingConfirmationScreen({
    super.key,
    required this.reservation,
    required this.status,
    required this.confirmationNumber,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  static const _primaryBlue = Color(0xff1663F7);
  static const _darkNavy = Color(0xff0D1B3D);
  static const _successGreen = Color(0xff10B981);
  static const _amber = Color(0xffF59E0B);

  late ReservationPollBloc _pollBloc;

  // Local state to hold updated data from polling
  String? _updatedStatus;
  String? _updatedConfirmationNumber;

  bool get _isPending => (_updatedStatus ?? widget.status).toLowerCase() == 'pending';
  bool get _isConfirmed =>
      (_updatedStatus ?? widget.status).toLowerCase() == 'confirmed' ||
          (_updatedStatus ?? widget.status).toLowerCase() == 'completed';

  Color get _statusColor =>
      _isConfirmed ? _successGreen : (_isPending ? _amber : _primaryBlue);

  String get _statusLabel {
    final s = _updatedStatus ?? widget.status;
    return s.isEmpty ? 'Pending' : s[0].toUpperCase() + s.substring(1);
  }

  String get _displayConfirmationNumber {
    // Prioritize updated number from poll, fallback to initial prop
    if (_updatedConfirmationNumber != null && _updatedConfirmationNumber!.isNotEmpty) {
      return _updatedConfirmationNumber!;
    }
    return widget.confirmationNumber;
  }

  @override
  void initState() {
    super.initState();
    // Initialize the bloc using GetIt
    _pollBloc = di.sl<ReservationPollBloc>();

    // If initially pending, start polling
    if (widget.status.toLowerCase() == 'pending') {
      // Assuming searchId is available in reservation entity.
      // Adjust 'searchId' property name based on your TReservation-entity.dart
      final searchId = widget.reservation.searchId;

      if (searchId != null && searchId.isNotEmpty) {
        print('Starting reservation poll for ID: $searchId');
        _pollBloc.add(FetchReservationPoll(searchId: searchId));
      }
    }
  }

  @override
  void dispose() {
    _pollBloc.close();
    super.dispose();
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReservationPollBloc, ReservationPollState>(
      bloc: _pollBloc,
      listener: (context, state) {
        if (state is ReservationPollSuccess) {
          final entity = state.reservationPoll;

          // Update local state if we get new info
          setState(() {
            if (entity.status != null) _updatedStatus = entity.status;
            if (entity.confirmationNumber != null) _updatedConfirmationNumber = entity.confirmationNumber;
          });

          // Optional: Stop polling if confirmed
          if (_isConfirmed) {
            print('Booking confirmed via poll. Stopping further actions.');
            // You could add a snackbar here if you want
          }
        } else if (state is ReservationPollFailed) {
          print('Polling failed: ${state.error}');
          // You might want to show a subtle error or just let it stay pending
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goHome(context);
        },
        child: Scaffold(
          backgroundColor: const Color(0xffF8F9FA),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const WanderNovaLogo(scaleFactor: 0.6),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              Padding(
                padding: EdgeInsets.all(context.w(8)),
                child: Image.asset('assets/images/wander_logo.png', height: 35),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(context.wp(4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: context.hp(2)),
                _buildSuccessHeader(context),
                SizedBox(height: context.hp(3)),
                _buildReferenceCard(context),
                SizedBox(height: context.hp(2)),
                _buildTripCard(context),
                SizedBox(height: context.hp(2)),
                _buildPassengerCard(context),
                SizedBox(height: context.hp(2)),
                _buildPaymentCard(context),
                SizedBox(height: context.hp(4)),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.wp(22),
          height: context.wp(22),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isPending ? Icons.hourglass_top_rounded : Icons.check_circle,
            color: _statusColor,
            size: context.wp(14),
          ),
        ),
        SizedBox(height: context.hp(2)),
        Text(
          _isPending ? 'Booking Received!' : 'Booking Confirmed!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.titleLarge,
            fontWeight: FontWeight.w800,
            color: _darkNavy,
          ),
        ),
        SizedBox(height: context.hp(0.8)),
        Text(
          _isPending
              ? 'Your payment is done and the booking is being confirmed. '
              'We\'ll email ${widget.reservation.email} once it\'s confirmed.'
              : 'Your transport has been booked successfully. A confirmation '
              'has been sent to ${widget.reservation.email}.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.bodyMedium,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.confirmation_number_outlined,
              color: _primaryBlue, size: context.iconMedium),
          SizedBox(width: context.wp(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIRMATION NUMBER',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: context.hp(0.4)),
                Text(
                  _displayConfirmationNumber.isNotEmpty
                      ? _displayConfirmationNumber
                      : 'Pending confirmation',
                  style: TextStyle(
                    fontSize: _displayConfirmationNumber.isNotEmpty
                        ? context.titleMedium
                        : context.bodyMedium,
                    fontWeight: FontWeight.w800,
                    color: _displayConfirmationNumber.isNotEmpty
                        ? _darkNavy
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(context),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(3),
        vertical: context.hp(0.6),
      ),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: context.wp(1.5)),
          Text(
            _statusLabel,
            style: TextStyle(
              fontSize: context.labelSmall,
              fontWeight: FontWeight.w700,
              color: _statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context) {
    return _card(
      context,
      title: 'Trip Details',
      icon: Icons.directions_car,
      children: [
        _row(context, 'Vehicle', widget.reservation.vehicleName),
        _row(context, 'Provider', widget.reservation.providerName),
        _row(context, 'Trip Type',
            widget.reservation.tripType == 'round_trip' ? 'Round Trip' : 'One Way'),
        _row(context, 'Pickup', widget.reservation.tripStartAddress),
        _row(context, 'Drop-off', widget.reservation.tripEndAddress),
        _row(context, 'Pickup Time', widget.reservation.tripPickupDatetimePretty),
        if (widget.reservation.tripReturnPickupDatetimePretty.isNotEmpty)
          _row(context, 'Return Time',
              widget.reservation.tripReturnPickupDatetimePretty),
        if (widget.reservation.flightNumber.isNotEmpty)
          _row(context, 'Flight',
              '${widget.reservation.airline}'.trim()),
        _row(context, 'Flight Number',
            '${widget.reservation.flightNumber}'.trim()),
        _row(context, 'Passengers', '${widget.reservation.numPassengers}'),
      ],
    );
  }

  Widget _buildPassengerCard(BuildContext context) {
    return _card(
      context,
      title: 'Passenger',
      icon: Icons.person_outline,
      children: [
        _row(context, 'Name',
            '${widget.reservation.customerInfo.firstName} ${widget.reservation.customerInfo.lastName}'
                .trim()),
        _row(context, 'Email', widget.reservation.email),
        _row(context, 'Phone', widget.reservation.phoneNumber),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
    final currency = widget.reservation.displayCurrency.isNotEmpty ? widget.reservation.displayCurrency : 'INR';
    return _card(
      context,
      title: 'Payment',
      icon: Icons.receipt_long,
      children: [
        _row(context, 'Method',
            widget.reservation.paidVia.isEmpty ? '—' : widget.reservation.paidVia),
        _row(
          context,
          'Amount Paid',
          '$currency ${widget.reservation.displayTotalPrice.toStringAsFixed(2)}',
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: context.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: () => _goHome(context),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              textStyle: TextStyle(
                fontSize: context.bodyLarge,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(
      BuildContext context, {
        required String title,
        required IconData icon,
        required List<Widget> children,
      }) {
    return Container(
      padding: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryBlue, size: context.iconMedium),
              SizedBox(width: context.wp(2)),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.w700,
                  color: _darkNavy,
                ),
              ),
            ],
          ),
          SizedBox(height: context.hp(1.5)),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context,
      String label,
      String value, {
        bool highlight = false,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.hp(0.6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.wp(28),
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: highlight ? context.bodyLarge : context.bodyMedium,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? _successGreen : _darkNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
