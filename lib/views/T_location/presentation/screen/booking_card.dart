import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
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
  // MakeMyTrip brand colors
  static const Color _mmtBlue = Color(0xFF0066E5);
  static const Color _mmtOrange = Color(0xFFF97316);
  static const Color _mmtNavy = Color(0xFF07163B);
  static const Color _mmtMuted = Color(0xFF6B7280);
  static const Color _mmtFieldFill = Color(0xFFF6F7FB);
  static const Color _mmtFieldBorder = Color(0xFFECEEF4);
  static const Color _mmtGreen = Color(0xFF22A652);

  T_locationEntity? _selectedPickup;
  T_locationEntity? _selectedDropoff;
  int _passengerCount = 1;
  late DateTime _returnDate;
  late TimeOfDay _returnTime;
  late DateTime _pickupDate;

  static const String _lastTransportSearchKey = 'last_transport_search_data';

  @override
  void initState() {
    super.initState();
    _pickupDate = widget.selectedDate.add(const Duration(days: 1));
    _returnDate = widget.selectedDate.add(const Duration(days: 1));
    _returnTime = widget.selectedTime;
    // Prefill pickup/drop-off/travellers from the user's last transport search.
    _loadLastSearch();
  }

  Future<void> _saveLastSearch() async {
    try {
      final prefsManager =
          await PreferencesManager.create(await SharedPreferences.getInstance());

      final searchData = {
        'pickup': _locationToJson(_selectedPickup),
        'dropoff': _locationToJson(_selectedDropoff),
        'passengerCount': _passengerCount,
      };

      await prefsManager.setString(
          _lastTransportSearchKey, jsonEncode(searchData));
    } catch (e) {
      debugPrint('Error saving last transport search: $e');
    }
  }

  Future<void> _loadLastSearch() async {
    try {
      final prefsManager =
          await PreferencesManager.create(await SharedPreferences.getInstance());
      final raw = prefsManager.getString(_lastTransportSearchKey);
      if (raw == null || !mounted) return;

      final lastSearch = jsonDecode(raw) as Map<String, dynamic>;

      setState(() {
        final pickup = _locationFromJson(lastSearch['pickup']);
        final dropoff = _locationFromJson(lastSearch['dropoff']);
        if (pickup != null) _selectedPickup = pickup;
        if (dropoff != null) _selectedDropoff = dropoff;
        _passengerCount = lastSearch['passengerCount'] ?? _passengerCount;
      });
    } catch (e) {
      debugPrint('Error loading last transport search: $e');
    }
  }

  Map<String, dynamic>? _locationToJson(T_locationEntity? l) {
    if (l == null) return null;
    return {
      'id': l.id,
      'source': l.source,
      'type': l.type,
      'label': l.label,
      'displayName': l.displayName,
      'name': l.name,
      'description': l.description,
      'formattedAddress': l.formattedAddress,
      'fullAddress': l.fullAddress,
      'address': l.address,
      'city': l.city,
      'country': l.country,
      'iataCode': l.iataCode,
      'icaoCode': l.icaoCode,
      'placeId': l.placeId,
      'lat': l.lat,
      'lng': l.lng,
      'timezone': l.timezone,
    };
  }

  T_locationEntity? _locationFromJson(dynamic json) {
    if (json == null || json['id'] == null) return null;
    return T_locationEntity(
      id: json['id'] ?? '',
      source: json['source'] ?? '',
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      displayName: json['displayName'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      iataCode: json['iataCode'] ?? '',
      icaoCode: json['icaoCode'] ?? '',
      placeId: json['placeId'] ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      timezone: json['timezone'] ?? '',
      raw: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: _mmtNavy.withValues(alpha: 0.06),
            blurRadius: context.w(16),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Trip Type Toggle - MMT Style
          Container(
            padding: EdgeInsets.all(context.w(2)),
            decoration: BoxDecoration(
              color: _mmtFieldFill,
              borderRadius: BorderRadius.circular(context.r(40)),
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

          SizedBox(height: context.h(12)),

          /// PICKUP & DROPOFF - Connected Box Style (MMT Signature)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _mmtFieldFill,
                  borderRadius: BorderRadius.circular(context.r(8)),
                  border: Border.all(color: _mmtFieldBorder, width: 1),
                ),
                child: Column(
                  children: [
                    T_locationSearchTile(
                      // title: "PICKUP FROM",
                      hint: "Enter pickup location",
                      initialSubtitle: "Select pickup point",
                      initialLocation: _selectedPickup,
                      onLocationSelected: (location) {
                        setState(() => _selectedPickup = location);
                        widget.onPickupSelected?.call(location);
                      },
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: _mmtFieldBorder,
                      indent: context.w(41),
                    ),
                    T_locationSearchTile(
                      // title: "DROP-OFF AT",
                      hint: "Enter drop-off location",
                      initialSubtitle: "Select drop-off point",
                      initialLocation: _selectedDropoff,
                      onLocationSelected: (location) {
                        setState(() => _selectedDropoff = location);
                        widget.onDropoffSelected?.call(location);
                      },
                    ),
                  ],
                ),
              ),
              /// Swap Button - MMT Style
              Positioned.fill(
                child: Align(
                  alignment: Alignment(0.93, 0),
                  child: GestureDetector(
                    onTap: _swapLocations,
                    child: Container(
                      width: context.w(32),
                      height: context.w(32),
                      decoration: BoxDecoration(
                        color: _mmtBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _mmtBlue.withValues(alpha: 0.3),
                            blurRadius: context.w(8),
                            offset: Offset(0, context.h(2)),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.swap_vert,
                        color: Colors.white,
                        size: context.w(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(4)),

          /// DATE & TIME - Connected Box (MMT Style)
          Container(
            decoration: BoxDecoration(
              color: _mmtFieldFill,
              border: Border.all(color: _mmtFieldBorder, width: 1),
              borderRadius: BorderRadius.circular(context.r(8)),
            ),
            child: Column(
              children: [
                /// Pickup Date & Time Row
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _mmtDateTile(
                          icon: Icons.flight_takeoff,
                          label: "PICKUP",
                          date: _pickupDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _pickupDate,
                              firstDate: widget.selectedDate.isBefore(DateTime.now())
                                  ? widget.selectedDate
                                  : DateTime.now(),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() {
                                _pickupDate = picked;
                                _returnDate = picked.add(const Duration(days: 1));
                              });
                              widget.onDateChanged(picked);
                            }
                          },
                        ),
                      ),
                      Container(
                        width: 1,
                        height: context.h(32),
                        color: _mmtFieldBorder,
                        margin: EdgeInsets.symmetric(horizontal: context.w(8)),
                      ),
                      Expanded(
                        child: _mmtTimeTile(
                          icon: Icons.access_time_outlined,
                          label: "TIME",
                          time: widget.selectedTime,
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
                ),

                if (!widget.isOneWay) ...[
                  Divider(height: 1, thickness: 1, color: _mmtFieldBorder),

                  /// Return Date & Time Row
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(12),
                      vertical: context.h(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _mmtDateTile(
                            icon: Icons.flight_land,
                            label: "RETURN",
                            date: _returnDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _returnDate,
                                firstDate: widget.selectedDate,
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() {
                                  _returnDate = picked;
                                  if (_returnDate.isBefore(_pickupDate)) {
                                    _returnDate = _pickupDate.add(const Duration(days: 2));
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        Container(
                          width: 1,
                          height: context.h(32),
                          color: _mmtFieldBorder,
                          margin: EdgeInsets.symmetric(horizontal: context.w(8)),
                        ),
                        Expanded(
                          child: _mmtTimeTile(
                            icon: Icons.access_time_outlined,
                            label: "TIME",
                            time: _returnTime,
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
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: context.h(4)),

          /// Passengers & Travellers - MMT Style
          _mmtInfoTile(
            context,
            icon: Icons.person_outline,
            title: "TRAVELLERS",
            value: "$_passengerCount Traveller${_passengerCount > 1 ? 's' : ''}",
            onTap: _openPassengerSheet,
          ),

          SizedBox(height: context.h(12)),

          /// SEARCH BUTTON - MMT Orange Style
          SizedBox(
            width: double.infinity,
            height: context.h(44),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _mmtOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
              ),
              onPressed: (_selectedPickup != null && _selectedDropoff != null)
                  ? _performSearch
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: context.w(16)),
                  SizedBox(width: context.w(8)),
                  Text(
                    "Search Rides",
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: context.h(8)),

          /// Free Cancellation Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(8),
              vertical: context.h(5),
            ),
            decoration: BoxDecoration(
              color: _mmtGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.r(20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: _mmtGreen,
                  size: context.w(12),
                ),
                SizedBox(width: context.w(5)),
                Text(
                  "Free cancellation on most rides",
                  style: TextStyle(
                    color: _mmtGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: context.fs(11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _swapLocations() {
    setState(() {
      final temp = _selectedPickup;
      _selectedPickup = _selectedDropoff;
      _selectedDropoff = temp;
    });
  }

  void _performSearch() async {
    print('DEBUG: Search button pressed');
    print('DEBUG: Pickup: ${_selectedPickup?.label}, Dropoff: ${_selectedDropoff?.label}');

    // Persist this search so the form is prefilled next time.
    _saveLastSearch();

    final pickupDatetime =
        "${_pickupDate.toIso8601String().split('T')[0]}T${widget.selectedTime.hour.toString().padLeft(2, '0')}:${widget.selectedTime.minute.toString().padLeft(2, '0')}:00";

    final returnDatetime = !widget.isOneWay
        ? "${_returnDate.toIso8601String().split('T')[0]}T${_returnTime.hour.toString().padLeft(2, '0')}:${_returnTime.minute.toString().padLeft(2, '0')}:00"
        : null;

    final startAddress = _selectedPickup!.iataCode.isNotEmpty
        ? _selectedPickup!.iataCode
        : _selectedPickup!.formattedAddress;
    final endAddress = _selectedDropoff!.iataCode.isNotEmpty
        ? _selectedDropoff!.iataCode
        : _selectedDropoff!.formattedAddress;

    print('DEBUG: Displayed pickup date: ${_formatDate(_pickupDate)}');
    print('DEBUG: API pickup datetime: $pickupDatetime');
    print('DEBUG: API params - start: $startAddress, end: $endAddress, datetime: $pickupDatetime');

    final transportBloc = sl<TransportSearchBloc>();
    print('DEBUG: Got TransportSearchBloc instance: ${transportBloc.runtimeType}');

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
              pickupDate: _pickupDate,
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

  Widget _tripButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: context.h(9)),
        decoration: BoxDecoration(
          color: selected ? _mmtBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(context.r(40)),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _mmtNavy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _mmtDateTile({
    required IconData icon,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.w(13), color: _mmtMuted),
              SizedBox(width: context.w(5)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(9),
                  fontWeight: FontWeight.w700,
                  color: _mmtMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(4)),
          Text(
            _formatDate(date),
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w700,
              color: _mmtNavy,
            ),
          ),
          Text(
            _getDayOfWeek(date),
            style: TextStyle(
              fontSize: context.fs(9),
              fontWeight: FontWeight.w500,
              color: _mmtMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mmtTimeTile({
    required IconData icon,
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.w(13), color: _mmtMuted),
              SizedBox(width: context.w(5)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(9),
                  fontWeight: FontWeight.w700,
                  color: _mmtMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(4)),
          Text(
            _formatTime(time),
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w700,
              color: _mmtNavy,
            ),
          ),
          SizedBox(height: context.fs(9)),
        ],
      ),
    );
  }

  Widget _mmtInfoTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(8)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(10),
        ),
        decoration: BoxDecoration(
          color: _mmtFieldFill,
          border: Border.all(color: _mmtFieldBorder, width: 1),
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.w(16), color: _mmtNavy),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.fs(9),
                      fontWeight: FontWeight.w700,
                      color: _mmtMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w700,
                      color: _mmtNavy,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: context.w(16),
              color: _mmtMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _openPassengerSheet() {
    // Create a local copy of passenger count for dialog state
    int tempPassengerCount = _passengerCount;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(16)),
              ),
              title: Text(
                "Select Travellers",
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w700,
                  color: _mmtNavy,
                ),
              ),
              content: Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _passengerRow(
                      title: "Adults (12+ Years)",
                      value: tempPassengerCount,
                      onIncrement: () {
                        setDialogState(() {
                          tempPassengerCount++;
                        });
                      },
                      onDecrement: () {
                        if (tempPassengerCount > 1) {
                          setDialogState(() {
                            tempPassengerCount--;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    "CANCEL",
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: _mmtMuted,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply the changes to the main state
                    setState(() {
                      _passengerCount = tempPassengerCount;
                    });
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mmtOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                  ),
                  child: Text(
                    "APPLY",
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _passengerRow({
    required String title,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w500,
              color: _mmtNavy,
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: onDecrement,
                child: Container(
                  padding: EdgeInsets.all(context.w(6)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _mmtFieldFill,
                  ),
                  child: Icon(Icons.remove, size: context.w(14), color: _mmtMuted),
                ),
              ),
              SizedBox(width: context.w(12)),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700,
                  color: _mmtNavy,
                ),
              ),
              SizedBox(width: context.w(12)),
              InkWell(
                onTap: onIncrement,
                child: Container(
                  padding: EdgeInsets.all(context.w(6)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _mmtOrange.withValues(alpha: 0.1),
                  ),
                  child: Icon(Icons.add, size: context.w(14), color: _mmtOrange),
                ),
              ),
            ],
          ),
        ],
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

  String _getDayOfWeek(DateTime date) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[date.weekday - 1];
  }
}