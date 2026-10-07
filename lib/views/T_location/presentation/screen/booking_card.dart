import 'dart:async';
import 'dart:convert';
import 'dart:math' show pi;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/app_surface.dart';
import 'package:wander_nova/common_widgets/currency_chip.dart';
import 'package:wander_nova/common_widgets/compact_time_picker_dialog.dart';
import 'package:wander_nova/common_widgets/floating_close_dialog_card.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../TPoll_Search/presentation/screen/TPollSearch_Screen.dart';
import '../../../T_Search/presentation/bloc/T_SearchBloc.dart';
import '../../../T_Search/presentation/bloc/T_SearchEvent.dart';
import '../../../T_Search/presentation/bloc/T_SearchState.dart';
import '../../domain/entities/T_locationEntity.dart';
import '../widget/TransferCalender.dart';
import 'T_location_search_screen.dart';
import 'package:wander_nova/newUIWidgets/shine.dart';

/// Which transfer product the customer is booking (Figma "Outstation /
/// Airport" pill). [TransportSearchBloc] doesn't distinguish between the two
/// when searching, but the choice is passed on to the booking screen so it
/// knows flight details aren't needed for an outstation transfer.
enum _TransferService { outstation, airport }

class TransportBookingCard extends StatefulWidget {
  final bool isOneWay;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  final ValueChanged<bool> onTripTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<T_locationEntity>? onPickupSelected;
  final ValueChanged<T_locationEntity>? onDropoffSelected;

  /// Edit-search mode (used inside the results screen's top drawer): no hero
  /// image, dark header "Edit Your Search", full-width MODIFY SEARCH button,
  /// and a successful search replaces the results screen instead of stacking
  /// another one on top of it.
  final bool editMode;
  final DateTime? initialPickupDate;
  final DateTime? initialReturnDate;
  final TimeOfDay? initialReturnTime;
  final int? initialPassengerCount;

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
    this.editMode = false,
    this.initialPickupDate,
    this.initialReturnDate,
    this.initialReturnTime,
    this.initialPassengerCount,
  });

  @override
  State<TransportBookingCard> createState() => _TransportBookingCardState();
}

class _TransportBookingCardState extends State<TransportBookingCard> {
  static const Color _ink = AppColors.black;
  static const Color _muted = AppColors.subhead;
  static const Color _stroke = AppColors.lightsubhead;

  _TransferService _service = _TransferService.airport;
  bool _isSearching = false;

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
    _pickupDate = widget.initialPickupDate ??
        widget.selectedDate.add(const Duration(days: 1));
    _returnDate = widget.initialReturnDate ??
        widget.selectedDate.add(const Duration(days: 1));
    _returnTime = widget.initialReturnTime ?? widget.selectedTime;
    if (widget.initialPassengerCount != null) {
      _passengerCount = widget.initialPassengerCount!;
    }
    // Prefill pickup/drop-off/travellers from the user's last transport search.
    _loadLastSearch();
  }

  Future<void> _saveLastSearch() async {
    try {
      final prefsManager = await PreferencesManager.create(
        await SharedPreferences.getInstance(),
      );

      final searchData = {
        'pickup': _locationToJson(_selectedPickup),
        'dropoff': _locationToJson(_selectedDropoff),
        'passengerCount': _passengerCount,
      };

      await prefsManager.setString(
        _lastTransportSearchKey,
        jsonEncode(searchData),
      );
    } catch (e) {
      debugPrint('Error saving last transport search: $e');
    }
  }

  Future<void> _addToSearchHistory() async {
    try {
      final prefsManager = await PreferencesManager.create(
        await SharedPreferences.getInstance(),
      );
      final searchData = {
        'type': 'transport',
        'pickup': _locationToJson(_selectedPickup),
        'dropoff': _locationToJson(_selectedDropoff),
        'passengerCount': _passengerCount,
        'isOneWay': widget.isOneWay,
        'pickupDate': _pickupDate.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefsManager.addToSearchHistory(searchData);
    } catch (e) {
      debugPrint('Error adding transport search to history: $e');
    }
  }

  Future<void> _loadLastSearch() async {
    try {
      final prefsManager = await PreferencesManager.create(
        await SharedPreferences.getInstance(),
      );
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

  // ==================================================================
  // BUILD
  // ==================================================================

  // Main screen: same look as the flight form — white page, dark top bar,
  // light toggle track and white cards with the shared raised shadow
  // (412px Figma frame, hence `context.fx`).
  static const Color _kTrackBg = Color(0xFFEEF3FA);

  @override
  Widget build(BuildContext context) {
    if (widget.editMode) return _buildEditLayout(context);
    final gutter = EdgeInsets.symmetric(horizontal: context.fx(16));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: context.statusBarHeight + context.fx(16)),
        _buildTopBar(context),
        SizedBox(height: context.fx(24)),
        Padding(padding: gutter, child: _buildServiceToggle(context)),
        SizedBox(height: context.fx(16)),
        Padding(padding: gutter, child: _buildTripTypeRow(context)),
        SizedBox(height: context.fx(12)),
        Padding(padding: gutter, child: _buildLocationsCard(context)),
        SizedBox(height: context.fx(12)),
        Padding(padding: gutter, child: _buildDateTravellersCard(context)),
        SizedBox(height: context.fx(24)),
        _buildSearchButton(context),
        SizedBox(height: context.fx(16)),
      ],
    );
  }

  /// Same form as below, without the hero backdrop (results-screen edit
  /// drawer).
  Widget _buildEditLayout(BuildContext context) {
    EdgeInsets side() => EdgeInsets.symmetric(horizontal: context.w(14));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: context.statusBarHeight + context.h(10)),
        _buildTopBar(context),
        SizedBox(height: context.h(18)),
        Padding(padding: side(), child: _buildServiceToggle(context)),
        SizedBox(height: context.h(14)),
        Padding(padding: side(), child: _buildTripTypeRow(context)),
        SizedBox(height: context.h(14)),
        Padding(padding: side(), child: _buildLocationsCard(context)),
        SizedBox(height: context.h(14)),
        Padding(padding: side(), child: _buildDateTravellersCard(context)),
        SizedBox(height: context.h(20)),
        _buildSearchButton(context),
        SizedBox(height: context.h(24)),
      ],
    );
  }

  // --------------------------------------------------------------- TOP BAR

  Widget _buildTopBar(BuildContext context) {
    if (!widget.editMode) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.fx(16)),
        child: SizedBox(
          height: context.fx(36),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Back',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: context.fx(6)),
                    child: Icon(Icons.arrow_back, size: context.fx(24), color: Colors.black),
                  ),
                ),
              ),
              SizedBox(width: context.fx(16)),
              Text(
                'Transfer',
                style: TextStyle(
                  fontSize: context.ffs(20),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              const CurrencyChip(),
              SizedBox(width: context.fx(16)),
              SvgPicture.asset(
                'assets/home/notification.svg',
                width: context.fx(24),
                height: context.fx(24),
              ),
            ],
          ),
        ),
      );
    }

    // Edit drawer header.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            child: Image.asset(
              'assets/NewIcons/arrowBack.png',
              width: context.w(17),
              height: context.w(17),
              color: AppColors.black,
            ),
          ),
          SizedBox(width: context.w(14)),
          Text(
            'Edit Your Search',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------- SERVICE TOGGLE (new)

  /// "Outstation / Airport" pill — new section added to match the Figma; UI
  /// state only, see [_TransferService].
  Widget _buildServiceToggle(BuildContext context) {
    final radius = BorderRadius.circular(context.r(30));
    final row = Row(
      children: [
        Expanded(
          child: _serviceButton(
            context,
            iconAsset: 'assets/NewIcons/flip.png',
            label: 'Outstation',
            selected: _service == _TransferService.outstation,
            onTap: () => setState(() => _service = _TransferService.outstation),
          ),
        ),
        Expanded(
          child: _serviceButton(
            context,
            icon: Icons.flight_rounded,
            label: 'Airport',
            selected: _service == _TransferService.airport,
            onTap: () => setState(() => _service = _TransferService.airport),
          ),
        ),
      ],
    );

    // Edit drawer sits on plain white, so no blur — a flat light-grey pill.
    if (widget.editMode) {
      return Container(
        padding: EdgeInsets.all(context.w(4)),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F4),
          borderRadius: radius,
        ),
        child: row,
      );
    }

    return Container(
      padding: EdgeInsets.all(context.fx(8)),
      decoration: BoxDecoration(
        color: _kTrackBg,
        borderRadius: BorderRadius.circular(context.fx(26)),
      ),
      child: row,
    );
  }

  Widget _serviceButton(
    BuildContext context, {
    IconData? icon,
    String? iconAsset,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final idle = widget.editMode ? AppColors.subhead : const Color(0xFF757575);
    final tint = selected ? AppColors.AppBlue : idle;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: context.h(10)),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(context.r(24)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: context.w(10),
                    offset: Offset(0, context.h(2)),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconAsset != null)
              Image.asset(
                iconAsset,
                width: context.w(11),
                height: context.w(11),
                color: tint,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Icon(icon, size: context.w(14), color: tint),
            SizedBox(width: context.w(6)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.AppBlue : idle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------- TRIP TYPE ROW

  Widget _buildTripTypeRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _tripTypeCard(
            context,
            title: 'One Way',
            subtitle: 'Get dropped off',
            selected: widget.isOneWay,
            badge: null,
            onTap: () => widget.onTripTypeChanged(true),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: _tripTypeCard(
            context,
            title: 'Round Trip',
            subtitle: 'Keep cap till return',
            selected: !widget.isOneWay,
            badge: 'Save more',
            onTap: () => widget.onTripTypeChanged(false),
          ),
        ),
      ],
    );
  }

  Widget _tripTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool selected,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(12),
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(context.fx(12)),
              border: selected
                  ? Border.all(color: AppColors.AppBlue.withValues(alpha: 0.5))
                  : null,
              boxShadow: kRaisedCardShadow,
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withValues(alpha: 0.06),
              //     blurRadius: context.w(10),
              //     offset: Offset(0, context.h(3)),
              //   ),
              // ],
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: context.w(16),
                  color: selected ? AppColors.AppBlue : const Color(0xFFB0B6C0),
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.fs(12),
                                fontWeight: FontWeight.w600,
                                color: selected ? AppColors.AppBlue : _ink,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            SizedBox(width: context.w(6)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(6),
                                vertical: context.h(2),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(
                                  context.r(8),
                                ),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: context.fs(7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: context.h(2)),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(8),
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------- FROM/TO CARD

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(context.fx(12)),
    boxShadow: kRaisedCardShadow,
  );

  Widget _buildLocationsCard(BuildContext context) {
    final locationRows = Column(
      children: [
        _locationRow(
          context,
          icon: null,
          iconColor: AppColors.AppBlue,
          label: 'FROM',
          value: _selectedPickup?.label,
          placeholder: 'Enter your current location',
          onTap: () => _openLocationSearch(startWithPickup: true),
        ),
        SizedBox(height: context.h(7)),
        Divider(
          height: 0.2,
          color: _stroke.withValues(alpha: 0.3),
          indent: context.w(1),
        ),
        SizedBox(height: context.h(7)),
        _locationRow(
          context,
          icon: null,
          iconColor: AppColors.orange,
          label: 'TO',
          value: _selectedDropoff?.label,
          placeholder: 'Enter drop address',
          onTap: () => _openLocationSearch(startWithPickup: false),
          trailing: _addStopButton(context),
        ),
        if (!widget.isOneWay) ...[
          Divider(height: 0.7, color: _stroke.withValues(alpha: 0.3), indent: context.w(1)),
          SizedBox(height: context.h(4)),
          _returnToPickupRow(context),
        ],
      ],
    );

    // Different connector asset per trip type — both are shown, the source
    // just changes. One Way: person → drop. Round Trip: pickup → drop → return.
    final connectorAsset =
    widget.isOneWay ? 'assets/Newimage/locate.png' : 'assets/Newimage/Rlocate.png';

    return Container(
      decoration: _cardDecoration,
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.h(12)),
                  child: Image.asset(
                    connectorAsset,
                    width: context.w(26),
                    // No fixed height → stretches to match the full column
                    // height so it fits both the 2-row (One Way) and 3-row
                    // (Round Trip) layouts cleanly.
                    fit: BoxFit.fill,
                  ),
                ),
                SizedBox(width: context.w(12)),
                Expanded(child: locationRows),
              ],
            ),
          ),
          // Swap button, floating on the right edge between FROM and TO.
          Positioned(
            right: 0,
            top: context.h(45),
            child: GestureDetector(
              onTap: _swapLocations,
              child: Container(
                width: context.w(28),
                height: context.w(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightsubhead,
                      blurRadius: context.w(6),
                      offset: Offset(0, context.h(1)),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: 90 * pi / 180,
                  child: Image.asset(
                    'assets/NewIcons/flip.png',
                    width: context.w(11),
                    height: context.w(11),
                    color: AppColors.AppBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _locationRow(
    BuildContext context, {
    IconData? icon,
    String? iconAsset,
    required Color iconColor,
    required String label,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    // Neither is passed when a shared connector graphic is already drawn
    // alongside the whole FROM/TO block (see One Way in _buildLocationsCard).
    final leading = iconAsset != null
        ? Image.asset(
            iconAsset,
            width: context.w(18),
            height: context.w(18),
            color: iconColor,
          )
        : icon != null
        ? Icon(icon, size: context.w(18), color: iconColor)
        : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(12)),
        child: Row(
          children: [
            if (leading != null) ...[leading, SizedBox(width: context.w(12))],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: context.fs(9),
                      fontWeight: FontWeight.w800,
                      color: _muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    value ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: value != null ? _ink : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  /// "+ Add a Stop" — new affordance on One Way, UI only for now (no
  /// multi-stop search wired up yet).
  Widget _addStopButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: context.w(24)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Multiple stops coming soon')),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.w(14),
              height: context.w(14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.AppBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: context.w(10), color: Colors.white),
            ),
            SizedBox(width: context.w(5)),
            Text(
              'Add a Stop',
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w400,
                color: AppColors.AppBlue,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.AppBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _returnToPickupRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(12)),
      child: Row(
        children: [
          // Icon(
          //   Icons.replay_circle_filled_outlined,
          //   size: context.w(18),
          //   color: AppColors.AppBlue,
          // ),
          // SizedBox(width: context.w(12)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,

              children: [
                Row(
                  children: [
                    Text(
                      'RETURN TO PICKUP LOCATION',
                      style: TextStyle(
                        fontSize: context.fs(9),
                        fontWeight: FontWeight.w800,
                        color: _muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(6),
                        vertical: context.h(2),
                      ),
                      // decoration: BoxDecoration(
                      //   color: AppColors.AppBlue,
                      //   borderRadius: BorderRadius.circular(context.r(6)),
                      // ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF80DAFF),
                            Color(0xFF00A1E4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(context.r(8)),
                      ),
                      child: Text(
                        'Round Trip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.fs(8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(2)),
                Text(
                  _selectedPickup?.label ?? 'Same as pickup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// FROM and TO each open their own dedicated single-field screen (rather
  /// than one screen juggling both), matching the Figma.
  Future<void> _openLocationSearch({required bool startWithPickup}) async {
    final result = await Navigator.of(context).push<T_locationEntity>(
      MaterialPageRoute(
        builder: (_) => TLocationSearchScreen(
          fieldLabel: startWithPickup ? 'FROM' : 'TO',
          hint: startWithPickup ? 'Enter pick up address' : 'Enter drop address',
          showUseCurrentLocation: startWithPickup,
          initialLocation: startWithPickup ? _selectedPickup : _selectedDropoff,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (startWithPickup) {
        _selectedPickup = result;
      } else {
        _selectedDropoff = result;
      }
    });
    if (startWithPickup) {
      widget.onPickupSelected?.call(result);
    } else {
      widget.onDropoffSelected?.call(result);
    }
  }

  void _swapLocations() {
    setState(() {
      final temp = _selectedPickup;
      _selectedPickup = _selectedDropoff;
      _selectedDropoff = temp;
    });
  }

  // ------------------------------------------------- DATE / TRAVELLERS CARD

  /// One Way shows just Trip Start + Travellers; Round Trip inserts a Return
  /// Date column between them — built as a list rather than a fixed 3-slot
  /// row so One Way doesn't leave a blank gap where Return Date would be.
  Widget _buildDateTravellersCard(BuildContext context) {
    final columns = <Widget>[
      Expanded(
        child: _dateColumn(
          context,
          label: 'TRIP START',
          date: _pickupDate,
          time: widget.selectedTime,
          onTap: () => _pickDateAndTime(isReturn: false),
        ),
      ),
    ];

    if (!widget.isOneWay) {
      columns.add(_columnDivider(context));
      columns.add(
        Expanded(
          child: _dateColumn(
            context,
            label: 'RETURN DATE',
            date: _returnDate,
            time: _returnTime,
            onTap: () => _pickDateAndTime(isReturn: true),
          ),
        ),
      );
    }

    columns.add(_columnDivider(context));
    columns.add(Expanded(child: _travellersColumn(context)));

    return Container(
      decoration: _cardDecoration,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: columns,
        ),
      ),
    );
  }

  Widget _travellersColumn(BuildContext context) {
    return GestureDetector(
      onTap: _openPassengerSheet,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TRAVELLERS',
            style: TextStyle(
              fontSize: context.fs(9),
              fontWeight: FontWeight.w800,
              color: _muted,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: context.h(6)),
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: context.w(24),
                color: AppColors.AppBlue,
              ),
              SizedBox(width: context.w(8)),
              Text(
                '$_passengerCount ${_passengerCount == 1 ? 'Traveller' : 'Travellers'}',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _columnDivider(BuildContext context) => Container(
    width: 1,
    color: _stroke,
    margin: EdgeInsets.symmetric(horizontal: context.w(8)),
  );

  Widget _dateColumn(
    BuildContext context, {
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(9),
                    fontWeight: FontWeight.w800,
                    color: _muted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          Row(
            children: [
              Image.asset(
                  'assets/NewIcons/departureCalendar.png',
                width: context.w(24),
                height: context.h(24),
              color: AppColors.AppBlue,
              ),
              SizedBox(width: context.w(10),),
              Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('dd MMM, yy').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  SizedBox(height: context.h(2),),
                  Text(
                    _formatTime(time),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(11), color: _muted),
                  ),
                ],
              ),
              ),
            ],
          ),
          // Text(
          //   _formatTime(time),
          //   maxLines: 1,
          //   overflow: TextOverflow.ellipsis,
          //   style: TextStyle(fontSize: context.fs(11), color: _muted),
          // ),
        ],
      ),
    );
  }

  /// Date selection reuses [transferCalendarScreen]'s content — same design
  /// the flight search card uses — just presented as a floating dialog
  /// (Figma) instead of a full-screen route. Time uses [CompactTimePickerDialog]
  /// the same way, chained so one tap still resolves both.
  Future<void> _pickDateAndTime({required bool isReturn}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => FloatingCloseDialogCard(
        width: context.w(340),
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: context.h(560),
          child: TransferCalendarScreen(
            initialDeparture: _pickupDate,
            initialReturn: !widget.isOneWay ? _returnDate : null,
            isRoundTrip: !widget.isOneWay,
            startWithReturn: isReturn,
            firstDate: widget.selectedDate.isBefore(DateTime.now())
                ? widget.selectedDate
                : DateTime.now(),
            lastDate: DateTime(2035),
            startLabel: 'Trip Start',
            endLabel: 'Return',
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;

    final departure = result['departure'] as DateTime?;
    final returnD = result['return'] as DateTime?;

    setState(() {
      if (departure != null) _pickupDate = departure;
      if (returnD != null) _returnDate = returnD;
    });
    if (departure != null) widget.onDateChanged(departure);

    if (!mounted) return;
    final pickedTime = await showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => FloatingCloseDialogCard(
        width: context.w(300),
        child: CompactTimePickerDialog(initialTime: isReturn ? _returnTime : widget.selectedTime),
      ),
    );
    if (pickedTime == null) return;
    if (isReturn) {
      setState(() => _returnTime = pickedTime);
    } else {
      widget.onTimeChanged(pickedTime);
    }
  }

  // ------------------------------------------------------- SEARCH BUTTON

  /// Same shine-border pill used by the flight SearchCard's "Search Flight"
  /// button — kept visually solid/enabled at all times (validation happens
  /// on tap, in [_performSearch]) rather than greying out, matching that
  /// widget's own behaviour.
  Widget _buildSearchButton(BuildContext context) {
    if (widget.editMode) return _buildModifyButton(context);
    const double shineWidth = 1.7;

    return Center(
      child: ShineBorderButton(
        enabled: !_isSearching,
        borderRadius: context.fx(21),
        borderWidth: shineWidth,
        shineColor: const Color(0xFFFFE0B2),
        duration: const Duration(seconds: 2, milliseconds: 500),
        child: SizedBox(
          width: context.fx(210) - (shineWidth * 2),
          height: context.fx(42) - (shineWidth * 2),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: AppColors.orange.withValues(alpha: 0.45),
              disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.fx(21)),
              ),
              padding: EdgeInsets.symmetric(horizontal: context.fx(8)),
            ),
            onPressed: _isSearching ? null : _performSearch,
            child: _isSearching
                ? SizedBox(
                    width: context.w(22),
                    height: context.w(22),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Search',
                          style: TextStyle(
                            fontSize: context.ffs(14),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: context.fx(10)),
                        Icon(Icons.arrow_forward, size: context.fx(18), color: Colors.white),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Edit drawer: flat full-width orange "MODIFY SEARCH →" (Figma).
  Widget _buildModifyButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      child: SizedBox(
        width: double.infinity,
        height: context.h(48),
        child: ElevatedButton(
          onPressed: _isSearching ? null : _performSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.OrangeColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(8)),
            ),
          ),
          child: _isSearching
              ? SizedBox(
                  width: context.w(22),
                  height: context.w(22),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MODIFY SEARCH',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: context.w(10)),
                    Image.asset(
                      'assets/NewIcons/arrowForward.png',
                      width: context.w(9.54),
                      height: context.w(13),
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _performSearch() async {
    if (_selectedPickup == null || _selectedDropoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and drop-off locations'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    // Persist this search so the form is prefilled next time.
    _saveLastSearch();
    _addToSearchHistory();

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

    final transportBloc = sl<TransportSearchBloc>();

    final event = SearchTransport(
      startAddress: startAddress,
      endAddress: endAddress,
      pickupDatetime: pickupDatetime,
      numPassengers: _passengerCount,
      currency: 'INR',
      mode: widget.isOneWay ? TripMode.oneWay : TripMode.roundTrip,
      returnDatetime: returnDatetime,
    );
    transportBloc.add(event);

    StreamSubscription<TransportSearchState>? subscription;
    subscription = transportBloc.stream.listen((state) {
      if (state is TransportSearchSuccess) {
        final searchId = state.transportSearch.local.searchId;
        subscription?.cancel();
        if (mounted) setState(() => _isSearching = false);
        final resultsRoute = MaterialPageRoute(
          builder: (context) => TpollSearchResultsPage(
            searchId: searchId,
            startAddress: startAddress,
            endAddress: endAddress,
            pickupDate: _pickupDate,
            numPassengers: _passengerCount,
            pickupTime: widget.selectedTime,
            isOneWay: widget.isOneWay,
            returnDate: _returnDate,
            returnTime: _returnTime,
            isOutstation: _service == _TransferService.outstation,
          ),
        );
        if (widget.editMode) {
          // Close the edit drawer, then swap the old results page for the new
          // search (so Back returns to the search form, not the old results).
          final nav = Navigator.of(context);
          nav.pop();
          nav.pushReplacement(resultsRoute);
        } else {
          Navigator.push(context, resultsRoute);
        }
      } else if (state is TransportSearchFailed) {
        subscription?.cancel();
        if (mounted) setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlySearchError(state.dataState.error)),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  /// The server sends a friendly message inside the response body (e.g.
  /// `{"error":"...","details":{"field":[{"message":"...","user_message":"..."}]}}`)
  /// — surface that instead of the DioException's own status-code dump.
  String _friendlySearchError(DioException? error) {
    final data = error?.response?.data;
    if (data is Map) {
      final details = data['details'];
      if (details is Map) {
        for (final v in details.values) {
          if (v is List && v.isNotEmpty && v.first is Map) {
            final first = v.first as Map;
            final msg = first['user_message'] ?? first['message'];
            if (msg is String && msg.isNotEmpty) return msg;
          }
        }
      }
      final err = data['error'];
      if (err is String && err.isNotEmpty) return err;
    }
    return error?.message ?? 'Please try again';
  }

  // ------------------------------------------------------- TRAVELLERS SHEET

  /// Matches the Figma's floating "Travellers" card: drag handle, "Select" /
  /// "Travellers" labels, a segmented counter, and a single full-width DONE
  /// button (no separate Cancel — the floating × handles dismissal).
  void _openPassengerSheet() {
    int tempPassengerCount = _passengerCount;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return FloatingCloseDialogCard(
              width: context.w(310),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: context.w(83),
                      height: context.h(6),
                      decoration: BoxDecoration(
                        color: _stroke.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(context.r(24)),
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(12)),
                  Text(
                    "Select",
                    style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: _ink),
                  ),
                  SizedBox(height: context.h(12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Travellers",
                      style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w800, color: _ink),
                    ),
                  ),
                  SizedBox(height: context.h(16)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: context.w(8)),
                            height: context.h(44),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(context.r(10)),
                            ),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: _counterBox(
                                    context,
                                    icon: Icons.remove,
                                    onTap: () {
                                      if (tempPassengerCount > 1) setDialogState(() => tempPassengerCount--);
                                    },
                                  ),
                                ),
                                Text(
                                  '$tempPassengerCount',
                                  style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w700, color: _ink),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: _counterBox(
                                    context,
                                    icon: Icons.add,
                                    onTap: () => setDialogState(() => tempPassengerCount++),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(20)),
                  SizedBox(
                    width: double.infinity,
                    height: context.h(44),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                      ),
                      onPressed: () {
                        setState(() => _passengerCount = tempPassengerCount);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "DONE",
                        style: TextStyle(color: Colors.white, fontSize: context.fs(14), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _counterBox(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.w(80),
        height: context.h(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05), // 5% black
              blurRadius: 4,                    // 2% of width
              offset: Offset(0, context.h(2)),
            ),
          ],
        ),
        child: Icon(icon, size: context.w(15), color: AppColors.AppBlue),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
