// flights/Screen/flight_ticket_widget.dart
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logoWithoutShimmer.dart';
import '../../../../core/resources/app_colours.dart';
import '../domain/entities/FlightBookEntity.dart';

class FlightTicketWidget extends StatelessWidget {
  final FlightBookEntity booking;

  const FlightTicketWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    bool isConfirmed = booking.pnr.isNotEmpty && booking.pnr != 'null';
    Color statusColor = isConfirmed ? Colors.green : Colors.orange;
    IconData statusIcon = isConfirmed
        ? Icons.check_circle_rounded
        : Icons.hourglass_empty_rounded;
    String statusText = isConfirmed ? 'Confirmed' : 'Processing';

    return Container(
      color: AppColors.lightBg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(context.w(12)),
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: context.h(10)),
            _buildConfirmationCard(context, statusColor, statusIcon, statusText),
            SizedBox(height: context.h(12)),
            _buildFlightDetailsCard(context),
            SizedBox(height: context.h(10)),
            _buildFareSummary(context),
            SizedBox(height: context.h(10)),
            _buildPassengerInformation(context),
            SizedBox(height: context.h(10)),
            _buildBookingInformation(context),
            SizedBox(height: context.h(10)),
            _buildFooter(context),
            SizedBox(height: context.h(14)),
            Container(
              height: context.h(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0077CC)],
                ),
                borderRadius: BorderRadius.circular(context.r(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Logo(scaleFactor: 0.6),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "FLIGHT",
                style: TextStyle(
                  fontSize: context.fs(20),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: context.letterSpacingWider,
                ),
              ),
              Text(
                "TICKET",
                style: TextStyle(
                  fontSize: context.fs(20),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: context.letterSpacingWider,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationCard(
      BuildContext context, Color statusColor, IconData statusIcon, String statusText) {
    return Container(
      padding: EdgeInsets.all(context.w(4)),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.w(15),
            backgroundColor: statusColor,
            child: Icon(
              statusIcon,
              color: Colors.white,
              size: context.w(18),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                Text(
                  isConfirmed(booking)
                      ? "Your flight has been confirmed"
                      : "Your flight booking is being processed",
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "PNR",
                style: TextStyle(
                  fontSize: context.fs(8),
                  color: AppColors.textLight,
                ),
              ),
              Text(
                booking.pnr,
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlightDetailsCard(BuildContext context) {
    // Get passenger names for display
    String passengerNames = _getPassengerNames();

    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Column(
        children: [
          // Route
          Container(
            padding: EdgeInsets.symmetric(vertical: context.h(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.fromCity,
                        style: TextStyle(
                          fontSize: context.fs(22),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: context.h(2)),
                      Text(
                        _extractAirportCode(booking.fromCity),
                        style: TextStyle(
                          fontSize: context.fs(10),
                          color: AppColors.textLight,
                        ),
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        _formatDate(booking.departureDate),
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _formatTime(booking.departureDate),
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.flight_rounded,
                        color: AppColors.primary,
                        size: context.w(32),
                      ),
                      SizedBox(height: context.h(4)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(8),
                          vertical: context.h(3),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(context.r(12)),
                        ),
                        child: Text(
                          booking.flightNumber,
                          style: TextStyle(
                            fontSize: context.fs(11),
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        booking.toCity,
                        style: TextStyle(
                          fontSize: context.fs(22),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: context.h(2)),
                      Text(
                        _extractAirportCode(booking.toCity),
                        style: TextStyle(
                          fontSize: context.fs(10),
                          color: AppColors.textLight,
                        ),
                      ),
                      SizedBox(height: context.h(4)),
                      if (booking.returnDate != null && booking.returnDate!.isNotEmpty) ...[
                        Text(
                          'Return: ${_formatDate(booking.returnDate!)}',
                          style: TextStyle(
                            fontSize: context.fs(11),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatTime(booking.returnDate!),
                          style: TextStyle(
                            fontSize: context.fs(14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: context.h(16), color: AppColors.divider),
          // Flight Details
          Row(
            children: [
              Expanded(
                child: _infoBox(
                  context,
                  "Flight Type",
                  booking.flightType.replaceAll('_', ' ').toUpperCase(),
                ),
              ),
              Expanded(
                child: _infoBox(
                  context,
                  "Class",
                  booking.flightClass.toUpperCase(),
                ),
              ),
              Expanded(
                child: _infoBox(
                  context,
                  "Passengers",
                  booking.passengers.toString(),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          if (passengerNames.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textLight,
                  size: context.w(14),
                ),
                SizedBox(width: context.w(6)),
                Expanded(
                  child: Text(
                    passengerNames,
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (booking.tboBookingId.isNotEmpty) ...[
            SizedBox(height: context.h(6)),
            Row(
              children: [
                Icon(
                  Icons.confirmation_number_rounded,
                  color: AppColors.textLight,
                  size: context.w(14),
                ),
                SizedBox(width: context.w(6)),
                Text(
                  'Booking ID: ${booking.tboBookingId}',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoBox(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.fs(8),
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
            letterSpacing: context.letterSpacingWider,
          ),
        ),
        SizedBox(height: context.h(4)),
        Text(
          value,
          style: TextStyle(
            fontSize: context.fs(12),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFareSummary(BuildContext context) {
    // Calculate tax if not directly available
    double totalAmount = double.tryParse(booking.totalAmount) ?? 0.0;
    double baseFare = 0.0;
    double tax = 0.0;

    // Try to parse tax from totalAmount - baseFare if we have baseFare
    // Since baseFare might not be directly available, we'll use totalAmount
    // and show a breakdown if possible

    return _sectionCard(
      context,
      "FARE SUMMARY",
      [
        _fareRow(
          context,
          "Base Fare",
          "${booking.currency} ${(totalAmount * 0.85).toStringAsFixed(2)}",
        ),
        _fareRow(
          context,
          "Tax & Fees",
          "${booking.currency} ${(totalAmount * 0.15).toStringAsFixed(2)}",
        ),
        Divider(height: context.h(16), color: AppColors.divider),
        _fareRow(
          context,
          "Total Paid",
          "${booking.currency} ${booking.totalAmount}",
          big: true,
        ),
      ],
    );
  }

  Widget _buildPassengerInformation(BuildContext context) {
    List<Widget> passengerWidgets = [];

    if (booking.passengersData.isNotEmpty) {
      for (int i = 0; i < booking.passengersData.length; i++) {
        final p = booking.passengersData[i];
        passengerWidgets.add(
          _passengerCard(context, i + 1, p),
        );
        if (i < booking.passengersData.length - 1) {
          passengerWidgets.add(
            SizedBox(height: context.h(8)),
          );
        }
      }
    } else {
      passengerWidgets.add(
        _infoRow(context, "Total Passengers", booking.passengers.toString()),
      );
      if (booking.name != null && booking.name!.isNotEmpty) {
        passengerWidgets.add(
          _infoRow(context, "Lead Passenger", booking.name!),
        );
      }
    }

    return _sectionCard(context, "PASSENGER INFORMATION", passengerWidgets);
  }

  Widget _passengerCard(BuildContext context, int index, PassengerDataEntity passenger) {
    String paxType = _getPaxType(passenger.paxType);

    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
                child: Text(
                  "Passenger $index",
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: context.w(8)),
              if (passenger.isLeadPax)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(8),
                    vertical: context.h(2),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.r(12)),
                  ),
                  child: Text(
                    "Lead",
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                paxType,
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          Text(
            "${passenger.title} ${passenger.firstName} ${passenger.lastName}",
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.h(4)),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: context.w(12),
                      color: AppColors.textLight,
                    ),
                    SizedBox(width: context.w(4)),
                    Expanded(
                      child: Text(
                        passenger.email,
                        style: TextStyle(
                          fontSize: context.fs(10),
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(8)),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: context.w(12),
                    color: AppColors.textLight,
                  ),
                  SizedBox(width: context.w(4)),
                  Text(
                    passenger.phone,
                    style: TextStyle(
                      fontSize: context.fs(10),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.h(4)),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Text(
                    //   'Passport: ${passenger.passportNo}',
                    //   style: TextStyle(
                    //     fontSize: context.fs(10),
                    //     color: AppColors.textSecondary,
                    //   ),
                    // ),
                  ],
                ),
              ),
              // Row(
              //   children: [
              //     Icon(
              //       Icons.cake_outlined,
              //       size: context.w(12),
              //       color: AppColors.textLight,
              //     ),
              //     SizedBox(width: context.w(4)),
              //     Text(
              //       _formatDate(passenger.dateOfBirth),
              //       style: TextStyle(
              //         fontSize: context.fs(10),
              //         color: AppColors.textSecondary,
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
          if (passenger.ticketNumber.isNotEmpty) ...[
            SizedBox(height: context.h(4)),
            Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: context.w(12),
                  color: AppColors.textLight,
                ),
                SizedBox(width: context.w(4)),
                Text(
                  'Ticket: ${passenger.ticketNumber}',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingInformation(BuildContext context) {
    return _sectionCard(
      context,
      "BOOKING INFORMATION",
      [
        _infoRow(context, "PNR", booking.pnr),
        _infoRow(context, "TBO Booking ID", booking.tboBookingId),
        _infoRow(context, "Booking Token", booking.bookingToken),
        _infoRow(context, "Booking Date", _formatDate(booking.bookingDate)),
        _infoRow(context, "Status", isConfirmed(booking) ? "Confirmed" : "Processing"),
        if (booking.paidVia != null && booking.paidVia!.isNotEmpty)
          _infoRow(context, "Payment Method", booking.paidVia!),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return _sectionCard(
      context,
      "IMPORTANT INFORMATION",
      [
        _bulletPoint(context, "Please carry a valid government-issued ID proof for check-in."),
        _bulletPoint(context, "Report to the airport at least 2 hours before domestic departure."),
        _bulletPoint(context, "For international flights, report at least 3 hours before departure."),
        _bulletPoint(context, "Baggage allowance varies by airline and class."),
        _bulletPoint(context, "Web check-in is available 24 hours before departure."),
        _bulletPoint(context, "Keep your PNR and Booking ID handy for any queries."),
      ],
    );
  }

  Widget _sectionCard(BuildContext context, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: context.letterSpacingWider,
            ),
          ),
          SizedBox(height: context.h(12)),
          ...children,
        ],
      ),
    );
  }

  Widget _fareRow(BuildContext context, String title, String value,
      {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: big ? context.fs(16) : context.fs(12),
            fontWeight: big ? FontWeight.w800 : FontWeight.w600,
            color: big ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? context.fs(16) : context.fs(12),
            fontWeight: big ? FontWeight.w800 : FontWeight.w600,
            color: big ? AppColors.orange : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: context.fs(11),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty || value == 'null' ? 'N/A' : value,
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(3)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontSize: context.fs(11),
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.fs(10),
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool isConfirmed(FlightBookEntity booking) {
    return booking.pnr.isNotEmpty && booking.pnr != 'null';
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty || dateString == 'null') return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateString);
      return '${dt.day} ${_getMonth(dt.month)} ${dt.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    if (dateString.isEmpty || dateString == 'null') return '';
    try {
      DateTime dt = DateTime.parse(dateString);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _extractAirportCode(String city) {
    // This is a placeholder - you might want to map cities to airport codes
    // or extract from the city string if it contains the code
    final Map<String, String> cityToCode = {
      'Mumbai': 'BOM',
      'Delhi': 'DEL',
      'Bangalore': 'BLR',
      'Chennai': 'MAA',
      'Hyderabad': 'HYD',
      'Kolkata': 'CCU',
      'Ahmedabad': 'AMD',
      'Pune': 'PNQ',
      'Goa': 'GOI',
      'Kochi': 'COK',
      // Add more as needed
    };
    return cityToCode[city] ?? city.substring(0, 3).toUpperCase();
  }

  String _getPassengerNames() {
    if (booking.passengersData.isNotEmpty) {
      return booking.passengersData
          .map((p) => '${p.firstName} ${p.lastName}')
          .join(', ');
    }
    return '';
  }

  String _getPaxType(int type) {
    switch(type) {
      case 1: return 'Adult';
      case 2: return 'Child';
      case 3: return 'Infant';
      default: return 'Passenger';
    }
  }
}