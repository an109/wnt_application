import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../../flight_search/presentation/screen/booking_screen.dart';

class TicketVoucherScreen extends StatelessWidget {
  final TicketEntity ticket;
  final FlightRouteSegment route;
  final Map<String, dynamic> passengerData;

  const TicketVoucherScreen({
    super.key,
    required this.ticket,
    required this.route,
    required this.passengerData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset('assets/images/wander_nova_logo.jpg', height: 35),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          children: [
            SizedBox(height: context.gapLarge),
            _buildSuccessBanner(context),
            SizedBox(height: context.gapLarge),
            _buildPNRCard(context),
            SizedBox(height: context.gapLarge),
            _buildFlightCard(context),
            SizedBox(height: context.gapLarge),
            _buildPassengerCard(context),
            SizedBox(height: context.gapLarge),
            _buildFareCard(context),
            SizedBox(height: context.gapLarge),
            _buildActionButtons(context),
            SizedBox(height: context.gapLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.gapLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
        ),
        borderRadius: BorderRadius.circular(context.borderRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 48),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.titleLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your ticket has been issued successfully.',
                  style: TextStyle(
                    color: Colors.white.
                    withOpacity(0.9),
                    fontSize: context.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPNRCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PNR Number',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: Colors.grey.shade600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: ticket.pnr ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PNR copied to clipboard')),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 16, color: Colors.indigo),
                    SizedBox(width: 4),
                    Text('Copy', style: TextStyle(color: Colors.indigo, fontSize: context.labelSmall)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),
          Text(
            ticket.pnr ?? 'N/A',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: const Color(0xFFE71D36),
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'Booking ID: ${ticket.bookingId ?? 'N/A'}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: context.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_takeoff, color: Colors.indigo, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Text(
                'Flight Details',
                style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: context.gapLarge),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.from, style: TextStyle(fontSize: context.headlineSmall, fontWeight: FontWeight.bold)),
                    Text(route.departureTime, style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(route.duration, style: TextStyle(color: Colors.grey.shade500, fontSize: context.labelSmall)),
                  Icon(Icons.flight, color: Colors.red, size: context.iconMedium),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(route.to, style: TextStyle(fontSize: context.headlineSmall, fontWeight: FontWeight.bold)),
                    Text(route.arrivalTime, style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),
          Divider(color: Colors.grey.shade200),
          SizedBox(height: context.gapSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${route.airline} · ${route.flightNo}', style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
              if (route.isRefundable == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text('Refundable', style: TextStyle(color: Colors.green.shade700, fontSize: context.labelSmall)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(BuildContext context) {
    final passengers = ticket.passengers ?? [];

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.indigo, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Text('Passengers', style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: context.gapLarge),
          if (passengers.isEmpty)
            _passengerRow(context,
              name: '${passengerData['firstName'] ?? ''} ${passengerData['lastName'] ?? ''}',
              ticketNo: 'Processing...',
              status: 'Confirmed',
            )
          else
            ...passengers.map((p) {
              final lastName = (p.lastName?.isNotEmpty == true) ? p.lastName! : (passengerData['lastName'] ?? '');
              return _passengerRow(
                context,
                name: '${p.firstName ?? ''} $lastName'.trim(),
                ticketNo: p.ticketNumber ?? 'N/A',
                status: p.status ?? 'Confirmed',
              );
            }),
        ],
      ),
    );
  }

  Widget _passengerRow(BuildContext context, {
    required String name,
    required String ticketNo,
    required String status,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.gapMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.indigo.shade50,
            child: Icon(Icons.person_outline, color: Colors.indigo, size: 18),
          ),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isNotEmpty ? name : 'Passenger', style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.bodyMedium)),
                SizedBox(height: 2),
                Text('Ticket: $ticketNo', style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: TextStyle(color: Colors.green.shade700, fontSize: context.labelSmall)),
          ),
        ],
      ),
    );
  }

  Widget _buildFareCard(BuildContext context) {
    final fare = route.fareQuoteData;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.indigo, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Text('Fare Summary', style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: context.gapLarge),
          if (fare != null) ...[
            _fareRow(context, 'Base Fare', '${fare.currency} ${fare.baseFare.toStringAsFixed(2)}'),
            SizedBox(height: context.gapSmall),
            _fareRow(context, 'Taxes & Fees', '${fare.currency} ${fare.tax.toStringAsFixed(2)}'),
            Divider(height: context.gapLarge, color: Colors.grey.shade200),
            _fareRow(context, 'Total Paid', '${fare.currency} ${fare.total.toStringAsFixed(2)}', isTotal: true),
          ] else
            _fareRow(context, 'Total Paid', route.price, isTotal: true),
        ],
      ),
    );
  }

  Widget _fareRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.black : Colors.grey.shade700,
        )),
        Text(value, style: TextStyle(
          fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          color: isTotal ? const Color(0xFFE71D36) : Colors.black,
        )),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: context.buttonHeight + 10,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF download coming soon')),
              );
            },
            icon: const Icon(Icons.download, color: Colors.white),
            label: Text('Download Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: context.bodyLarge)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE71D36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius)),
            ),
          ),
        ),
        SizedBox(height: context.gapMedium),
        SizedBox(
          width: double.infinity,
          height: context.buttonHeight + 10,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE71D36)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius)),
            ),
            child: Text('Back to Home', style: TextStyle(color: const Color(0xFFE71D36), fontWeight: FontWeight.bold, fontSize: context.bodyLarge)),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
