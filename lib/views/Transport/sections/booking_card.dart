import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class TransportBookingCard extends StatelessWidget {

  final bool isOneWay;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  final ValueChanged<bool> onTripTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const TransportBookingCard({
    super.key,
    required this.isOneWay,
    required this.selectedDate,
    required this.selectedTime,
    required this.onTripTypeChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.wp(5)),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(context.borderRadius + 10),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // TRIP TYPE
            Container(
              padding: const EdgeInsets.all(4),

              decoration: BoxDecoration(
                color: const Color(0xffF5F6FA),
                borderRadius: BorderRadius.circular(40),
              ),

              child: Row(
                children: [

                  Expanded(
                    child: _tripButton(
                      title: "One Way",
                      selected: isOneWay,
                      onTap: () {
                        onTripTypeChanged(true);
                      },
                    ),
                  ),

                  Expanded(
                    child: _tripButton(
                      title: "Round Trip",
                      selected: !isOneWay,
                      onTap: () {
                        onTripTypeChanged(false);
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.hp(3)),

            Row(
              children: [

                Icon(
                  Icons.directions_car_outlined,
                  size: context.iconMedium,
                  color: const Color(0xff0D1B3D),
                ),

                SizedBox(width: context.wp(2)),

                Text(
                  "Book Ground Transport",
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff0D1B3D),
                  ),
                ),
              ],
            ),

            SizedBox(height: context.hp(3)),

            _locationTile(
              context,
              title: "PICKUP FROM",
              subtitle: "Enter pickup location",
            ),

            const Divider(height: 35),

            _locationTile(
              context,
              title: "DROP-OFF AT",
              subtitle: "Enter drop-off location",
            ),

            const Divider(height: 35),

            Text(
              "PICKUP DATE & TIME",
              style: TextStyle(
                fontSize: context.labelLarge,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            SizedBox(height: context.hp(2)),

            Row(
              children: [

                Expanded(
                  child: _clickableInfoTile(
                    context,
                    icon: Icons.calendar_today_outlined,
                    text: _formatDate(selectedDate),

                    onTap: () async {
                      final picked =
                      await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );

                      if (picked != null) {
                        onDateChanged(picked);
                      }
                    },
                  ),
                ),

                SizedBox(width: context.wp(3)),

                Expanded(
                  child: _clickableInfoTile(
                    context,
                    icon: Icons.access_time,
                    text: _formatTime(selectedTime),

                    onTap: () async {
                      final picked =
                      await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );

                      if (picked != null) {
                        onTimeChanged(picked);
                      }
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: context.hp(3)),

            // SEARCH BUTTON
            SizedBox(
              width: double.infinity,
              height: context.buttonHeight + 12,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xffF97316),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.borderRadius,
                    ),
                  ),
                ),
                onPressed: () {},

                icon: Icon(
                  Icons.search,
                  size: context.iconMedium,
                ),

                label: Text(
                  "Search Rides",
                  style: TextStyle(
                    fontSize: context.titleSmall,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),


            SizedBox(height: context.hp(1)),

            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Colors.green,
                  size: context.iconMedium,
                ),

                SizedBox(width: context.wp(2)),

                Expanded(
                  child: Text(
                    "Free cancellation on most rides",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: context.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _locationTile(
      BuildContext context, {
        required String title,
        required String subtitle,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          title,
          style: TextStyle(
            fontSize: context.labelLarge,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),

        SizedBox(height: context.hp(2)),

        Row(
          children: [

            Icon(
              Icons.location_on_outlined,
              size: context.iconLarge,
              color: const Color(0xff0D1B3D),
            ),

            SizedBox(width: context.wp(3)),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    "City, airport, hotel...",
                    style: TextStyle(
                      fontSize: context.titleSmall,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff0D1B3D),
                    ),
                  ),

                  SizedBox(height: context.hp(0.5)),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _clickableInfoTile(
      BuildContext context, {
        required IconData icon,
        required String text,
        required VoidCallback onTap,
      }) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(context.borderRadius),

      onTap: onTap,

      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(3),
          vertical: context.hp(1.8),
        ),

        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
          ),

          borderRadius:
          BorderRadius.circular(context.borderRadius),
        ),

        child: Row(
          children: [

            Icon(
              icon,
              size: context.iconMedium,
              color: const Color(0xff0D1B3D),
            ),

            SizedBox(width: context.wp(3)),

            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff0D1B3D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding:
        const EdgeInsets.symmetric(vertical: 14),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff1663F7)
              : Colors.transparent,

          borderRadius: BorderRadius.circular(40),
        ),

        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(TimeOfDay time) {
    final hour =
    time.hour.toString().padLeft(2, '0');

    final minute =
    time.minute.toString().padLeft(2, '0');

    return "$hour:$minute";
  }
}