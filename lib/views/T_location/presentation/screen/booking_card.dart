import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../injection_container.dart';
import '../../../TPoll_Search/presentation/screen/TPollSearch_Screen.dart';
import '../../../T_Search/presentation/bloc/T_SearchBloc.dart';
import '../../../T_Search/presentation/bloc/T_SearchEvent.dart';
import '../../../T_Search/presentation/bloc/T_SearchState.dart';
import '../../domain/entities/T_locationEntity.dart';
import '../widget/T_locationSearchDropdown.dart';

class TransportBookingCard extends StatefulWidget {
  final bool isOneWay;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  final ValueChanged<bool> onTripTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<T_locationEntity>? onPickupSelected;
  final ValueChanged<T_locationEntity>? onDropoffSelected;

  const TransportBookingCard({
    super.key,
    required this.isOneWay,
    required this.selectedDate,
    required this.selectedTime,
    required this.onTripTypeChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
    this.onPickupSelected,
    this.onDropoffSelected,
  });

  @override
  State<TransportBookingCard> createState() => _TransportBookingCardState();
}

class _TransportBookingCardState extends State<TransportBookingCard> {
  T_locationEntity? _selectedPickup;
  T_locationEntity? _selectedDropoff;
  int _passengerCount = 1;
  late DateTime _returnDate;
  late TimeOfDay _returnTime;

  @override
  void initState() {
    super.initState();

    _returnDate = widget.selectedDate.add(const Duration(days: 1));
    _returnTime = widget.selectedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.wp(5)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.borderRadius + 10),
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
                      selected: widget.isOneWay,
                      onTap: () => widget.onTripTypeChanged(true),
                    ),
                  ),
                  Expanded(
                    child: _tripButton(
                      title: "Round Trip",
                      selected: !widget.isOneWay,
                      onTap: () => widget.onTripTypeChanged(false),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.hp(1.5)),

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

            SizedBox(height: context.hp(1.5)),

            // PICKUP LOCATION - UI identical to original _locationTile
            T_locationSearchTile(
              title: "PICKUP FROM",
              hint: "Enter pickup location",
              initialSubtitle: "City, airport, hotel...",
              onLocationSelected: (location) {
                setState(() => _selectedPickup = location);
                widget.onPickupSelected?.call(location);
              },
            ),

            const Divider(height: 20),

            // DROPOFF LOCATION - UI identical to original _locationTile
            T_locationSearchTile(
              title: "DROP-OFF AT",
              hint: "Enter drop-off location",
              initialSubtitle: "City, airport, hotel...",
              onLocationSelected: (location) {
                setState(() => _selectedDropoff = location);
                widget.onDropoffSelected?.call(location);
              },
            ),

            const Divider(height: 20),

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
                    text: _formatDate(widget.selectedDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: widget.selectedDate,
                        firstDate: widget.selectedDate.isBefore(DateTime.now())
                            ? widget.selectedDate
                            : DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        widget.onDateChanged(picked);
                      }
                    },
                  ),
                ),
                SizedBox(width: context.wp(3)),
                Expanded(
                  child: _clickableInfoTile(
                    context,
                    icon: Icons.access_time,
                    text: _formatTime(widget.selectedTime),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: widget.selectedTime,
                      );
                      if (picked != null) {
                        widget.onTimeChanged(picked);
                      }
                    },
                  ),
                ),
              ],
            ),

            if (!widget.isOneWay) ...[
              SizedBox(height: context.hp(2)),

              Text(
                "RETURN DATE & TIME",
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
                      text: _formatDate(_returnDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _returnDate,
                          firstDate: widget.selectedDate,
                          lastDate: DateTime(2035),
                        );

                        if (picked != null) {
                          setState(() => _returnDate = picked);
                        }
                      },
                    ),
                  ),

                  SizedBox(width: context.wp(3)),

                  Expanded(
                    child: _clickableInfoTile(
                      context,
                      icon: Icons.access_time,
                      text: _formatTime(_returnTime),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _returnTime,
                        );

                        if (picked != null) {
                          setState(() => _returnTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 20),

            Text(
              "PASSENGERS",
              style: TextStyle(
                fontSize: context.labelLarge,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            // SizedBox(height: context.hp(2)),
            SizedBox(height: context.gapSmall),

            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: context.iconMedium,
                  color: const Color(0xff0D1B3D),
                ),

                SizedBox(width: context.wp(2)),

                Text(
                  "$_passengerCount Pax",
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff0D1B3D),
                  ),
                ),

                const Spacer(),

                // Minus Button
                InkWell(
                  onTap: () {
                    if (_passengerCount > 1) {
                      setState(() => _passengerCount--);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    Icons.remove,
                    size: context.iconMedium,
                    color: const Color(0xff0D1B3D),
                  ),
                ),

                SizedBox(width: context.wp(2)),

                // Plus Button
                InkWell(
                  onTap: () {
                    setState(() => _passengerCount++);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xff1663F7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      size: context.iconMedium,
                      color: const Color(0xff1663F7),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.hp(1.5)),

            // SEARCH BUTTON
            // SizedBox(
            //   width: double.infinity,
            //   height: context.buttonHeight + 12,
            //   child: ElevatedButton.icon(
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xffF97316),
            //       foregroundColor: Colors.white,
            //       elevation: 0,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(context.borderRadius),
            //       ),
            //     ),
            //     onPressed: (_selectedPickup != null && _selectedDropoff != null)
            //         ? () {
            //       // Handle search with selected locations
            //     }
            //         : null,
            //     icon: Icon(Icons.search, size: context.iconMedium),
            //     label: Text(
            //       "Search Rides",
            //       style: TextStyle(
            //         fontSize: context.titleSmall,
            //         fontWeight: FontWeight.w700,
            //       ),
            //     ),
            //   ),
            // ),

           /// SEARCH BUTTON
            SizedBox(
              width: double.infinity,
              height: context.buttonHeight + 12,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF97316),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius),
                  ),
                ),
                onPressed: (_selectedPickup != null && _selectedDropoff != null)
                    ? () async {
                  // DEBUG PRINT 1: Button pressed
                  print('DEBUG: Search button pressed');
                  print('DEBUG: Pickup: ${_selectedPickup?.label}, Dropoff: ${_selectedDropoff?.label}');

                  // Format pickup datetime for API
                  final pickupDatetime = "${widget.selectedDate.toIso8601String().split('T')[0]}T${widget.selectedTime.hour.toString().padLeft(2, '0')}:${widget.selectedTime.minute.toString().padLeft(2, '0')}:00";
                  final returnDatetime = !widget.isOneWay
                      ? "${_returnDate.toIso8601String().split('T')[0]}T${_returnTime.hour.toString().padLeft(2, '0')}:${_returnTime.minute.toString().padLeft(2, '0')}:00"
                      : null;
                  final startAddress = _selectedPickup!.iataCode.isNotEmpty
                      ? _selectedPickup!.iataCode
                      : _selectedPickup!.formattedAddress;
                  final endAddress = _selectedDropoff!.iataCode.isNotEmpty
                      ? _selectedDropoff!.iataCode
                      : _selectedDropoff!.formattedAddress;

                  print('DEBUG: API params - start: $startAddress, end: $endAddress, datetime: $pickupDatetime');

                  // Get bloc instance
                  final transportBloc = sl<TransportSearchBloc>();
                  print('DEBUG: Got TransportSearchBloc instance: ${transportBloc.runtimeType}');

                  // Add search event
                  final event = SearchTransport(
                    startAddress: startAddress,
                    endAddress: endAddress,
                    pickupDatetime: pickupDatetime,
                    numPassengers: _passengerCount,
                    currency: 'INR',
                    mode: widget.isOneWay ? TripMode.oneWay : TripMode.roundTrip,
                    returnDatetime: returnDatetime,
                  );
                  print('DEBUG: Adding event: ${event.runtimeType}');
                  transportBloc.add(event);

                  // Listen for result
                  StreamSubscription<TransportSearchState>? subscription;
                  subscription = transportBloc.stream.listen((state) {
                    print('DEBUG: Bloc state changed: ${state.runtimeType}');

                    if (state is TransportSearchSuccess) {
                      final searchId = state.transportSearch.local.searchId;
                      print('Transport Search Success - search_id: $searchId');
                      subscription?.cancel();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TpollSearchResultsPage(
                            searchId: searchId,
                            startAddress: startAddress,
                            endAddress: endAddress,
                            pickupDate: widget.selectedDate,
                            numPassengers: _passengerCount,
                          ),
                        ),
                      );
                    } else if (state is TransportSearchFailed) {
                      print('Transport Search Failed: ${state.dataState.error?.message ?? 'Unknown error'}');
                      print('DEBUG: Full error: ${state.dataState.error}');
                      subscription?.cancel();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Search failed: ${state.dataState.error?.message ?? 'Please try again'}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (state is TransportSearchLoading) {
                      print('DEBUG: Transport search loading...');
                    }
                  });
                }
                    : null,
                icon: Icon(Icons.search, size: context.iconMedium),
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

  Widget _tripButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff1663F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _clickableInfoTile(
      BuildContext context, {
        required IconData icon,
        required String text,
        required VoidCallback onTap,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.borderRadius),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(3),
          vertical: context.hp(1.8),
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(context.borderRadius),
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}