import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';

class FlightDetailsPopup extends StatelessWidget {
  final String airlineName;
  final String airlineCode;
  final String flightNumber;
  final String fromCode;
  final String toCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String price;
  final String? traceId;
  final String? resultIndex;

  const FlightDetailsPopup({
    super.key,
    required this.airlineName,
    required this.airlineCode,
    required this.flightNumber,
    required this.fromCode,
    required this.toCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    this.traceId,
    this.resultIndex
  });

   static void show(
      BuildContext context, {
        required String airlineName,
        required String airlineCode,
        required String flightNumber,
        required String fromCode,
        required String toCode,
        required String departureTime,
        required String arrivalTime,
        required String duration,
        required String price,
         String? traceId,
         String? resultIndex,
      }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: context.wp(4),
          vertical: context.hp(3),
        ),
        child: FlightDetailsPopup(
          airlineName: airlineName,
          airlineCode: airlineCode,
          flightNumber: flightNumber,
          fromCode: fromCode,
          toCode: toCode,
          departureTime: departureTime,
          arrivalTime: arrivalTime,
          duration: duration,
          price: price,
          traceId: traceId,
          resultIndex: resultIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.isDesktop
          ? 700
          : context.isTablet
          ? 600
          : double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// TOP SECTION
          Padding(
            padding: EdgeInsets.all(context.gapMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// PRICE BOX
                Container(
                  width: context.isMobile ? 110 : 140,
                  padding: EdgeInsets.all(context.gapMedium),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FAEC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Price",
                        style: TextStyle(
                          fontSize: context.bodySmall,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: context.gapSmall),

                      Text(
                        "₹$price",
                        style: TextStyle(
                          fontSize: context.titleLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "per adult",
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: context.gapMedium),

                /// FLIGHT INFO
                Expanded(
                  child: Column(
                    children: [

                      /// TIMES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          /// DEPARTURE
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                departureTime,
                                style: TextStyle(
                                  fontSize: context.headlineSmall,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "$fromCode",
                                style: TextStyle(
                                  fontSize: context.bodyMedium,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),

                          /// DURATION
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.gapMedium,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    duration,
                                    style: TextStyle(
                                      fontSize: context.bodySmall,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: context.gapSmall),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey.shade300,
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Icon(
                                          Icons.flight,
                                          size: context.iconSmall,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey.shade300,
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: context.gapSmall),

                                  Text(
                                    "Non Stop",
                                    style: TextStyle(
                                      fontSize: context.labelSmall,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          /// ARRIVAL
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                arrivalTime,
                                style: TextStyle(
                                  fontSize: context.headlineSmall,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "$toCode",
                                style: TextStyle(
                                  fontSize: context.bodyMedium,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: context.gapSmall),

                /// AIRLINE + CLOSE
                Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey.shade100,
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: context.gapSmall),

                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.flight,
                        color: Colors.indigo,
                        size: context.iconMedium,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      airlineCode,
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey.shade200, height: 1),

          /// MIDDLE SECTION
          Padding(
            padding: EdgeInsets.all(context.gapMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// LEFT
                Expanded(
                  child: _infoTile(
                    context,
                    icon: Icons.airline_seat_recline_normal,
                    title: "Seats, Meals & More",
                    subtitle: "Meals information not available",
                    iconColor: Colors.purple,
                  ),
                ),

                Container(
                  width: 1,
                  height: 70,
                  color: Colors.grey.shade200,
                ),

                SizedBox(width: context.gapMedium),

                /// RIGHT
                Expanded(
                  child: _infoTile(
                    context,
                    icon: Icons.shield_outlined,
                    title: "Flexibility",
                    subtitle: "Per airline rules",
                    iconColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          /// FEATURES BAR
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapMedium,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF4),
              border: Border(
                top: BorderSide(color: Colors.amber.shade100),
                bottom: BorderSide(color: Colors.amber.shade100),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 12,
              children: [
                _featureItem(
                  context,
                  Icons.lock_outline,
                  "Trusted Booking",
                  "100% Secure",
                ),

                _featureItem(
                  context,
                  Icons.headphones,
                  "24/7 Support",
                  "We're here to help",
                ),

                _featureItem(
                  context,
                  Icons.sync_alt,
                  "Easy Changes",
                  "Hassle-free process",
                ),

                _featureItem(
                  context,
                  Icons.verified_outlined,
                  "Best Price Guarantee",
                  "Get the best deals",
                ),
              ],
            ),
          ),

          /// BOTTOM
          Padding(
            padding: EdgeInsets.all(context.gapMedium),
            child: Row(
              children: [

                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Colors.green,
                        size: context.iconSmall,
                      ),

                      SizedBox(width: context.gapSmall),

                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Free cancellation ",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.bodySmall,
                                ),
                              ),
                              TextSpan(
                                text: "available as per airline policy",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: context.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: context.gapMedium),

                SizedBox(
                  height: context.buttonHeight + 6,
                  child: ElevatedButton(
                    onPressed: () {
                      print('>>>>>>> Passing to BookingScreen - traceId: $traceId');
                      print('>>>>>>> Passing to BookingScreen - resultIndex: $resultIndex');

                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlightBookingScreen(
                            routes: [

                              FlightRouteSegment(

                                from: fromCode,
                                price: price,
                                to: toCode,
                                traceId: traceId,
                                resultIndex: resultIndex,

                                departureTime: departureTime,
                                arrivalTime: arrivalTime,

                                duration: duration,

                                airline: airlineName,

                                flightNo: "$airlineCode • $flightNumber",
                              ),

                            ],

                            totalPrice: price,
                            traceId: traceId,
                            resultIndex: resultIndex,
                            price: price,

                            isLoggedIn: false,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71D36),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Book Now",
                      style: TextStyle(
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color iconColor,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(
            icon,
            color: iconColor,
            size: context.iconSmall,
          ),
        ),

        SizedBox(width: context.gapMedium),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureItem(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: context.iconSmall,
          color: Colors.orange.shade700,
        ),

        SizedBox(width: context.gapSmall),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: context.bodySmall,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: context.labelSmall,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}