import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/compact_time_picker_dialog.dart';
import 'package:wander_nova/common_widgets/floating_close_dialog_card.dart';
import 'package:wander_nova/views/TResevation/presentation/screen/payment_screen.dart';
import 'package:wander_nova/views/T_location/presentation/widget/TransferCalender.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../../newUIWidgets/fare_breakup_sheet.dart';
import '../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../../TPoll_Search/domain/entities/TPollSearchEntity.dart';
import '../../../auth/domain/entity/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// "Review Your Ride" — Figma transport booking review.
///
/// Everything on this screen is read from the selected search result / search
/// data; a tile or row is simply hidden when the API didn't send that field.
/// The user must be signed in to reach it (the vehicle card gates the tap).
class TPollBookingScreen extends StatefulWidget {
  final SearchResultEntity result;
  final SearchDataEntity searchData;
  final String startAddress;
  final String endAddress;
  final DateTime pickupDate;
  final String searchId;
  final String resultId;
  final bool isOneWay;

  const TPollBookingScreen({
    super.key,
    required this.result,
    required this.searchData,
    required this.startAddress,
    required this.endAddress,
    required this.pickupDate,
    required this.searchId,
    required this.resultId,
    this.isOneWay = true,
  });

  @override
  State<TPollBookingScreen> createState() => _TPollBookingScreenState();
}

class _Dial {
  final String flag;
  final String code;
  final String name;
  const _Dial(this.flag, this.code, this.name);
}

class _TPollBookingScreenState extends State<TPollBookingScreen> {
  // ── traveller ──
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _gender; // 'Male' | 'Female' | 'Other' — collected, not sent (no API field)
  _Dial _dial = _dials.first;
  bool _editingTraveller = false;
  bool _firstNameError = false;
  bool _lastNameError = false;
  bool _phoneError = false;
  bool _emailError = false;

  // ── flight details (Mozio needs them on every reservation) ──
  final _flightNumberController = TextEditingController();
  final _airlineCodeController = TextEditingController();
  bool _flightNumberError = false;
  bool _airlineError = false;

  // ── coupon ──
  final _promoCodeController = TextEditingController();
  PromoCodeEntity? _appliedPromo;
  bool _showAllOffers = false;

  // ── add-ons ──
  final Set<String> _selectedAmenities = {};

  // ── user ──
  int? _userId;
  String _accountEmail = '';

  // ── route banner ──
  late DateTime _pickupDateTime;
  bool _routeExpanded = false;

  final _travellerKey = GlobalKey();
  final _flightKey = GlobalKey();

  static const _stroke = Color(0xffE3E5E8);
  static const _muted = AppColors.subhead;
  static const _ink = AppColors.black;
  static const _errorRed = Color(0xffDC2626);
  static const _successGreen = Color(0xff16A34A);
  static const _tileFill = Color(0xffE6F4FC);

  static const List<_Dial> _dials = [
    _Dial('🇮🇳', '+91', 'India'),
    _Dial('🇦🇪', '+971', 'UAE'),
    _Dial('🇺🇸', '+1', 'United States'),
    _Dial('🇬🇧', '+44', 'United Kingdom'),
    _Dial('🇸🇬', '+65', 'Singapore'),
    _Dial('🇦🇺', '+61', 'Australia'),
    _Dial('🇸🇦', '+966', 'Saudi Arabia'),
    _Dial('🇶🇦', '+974', 'Qatar'),
  ];

  SearchResultEntity get _r => widget.result;

  @override
  void initState() {
    super.initState();
    _pickupDateTime =
        DateTime.tryParse(widget.searchData.pickupDatetime) ?? widget.pickupDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      context.read<GeneralSettingsBloc>().add(const LoadPromoCodes());
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _flightNumberController.dispose();
    _airlineCodeController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────── user data
  void _loadUserData() {
    try {
      final prefs = sl<PreferencesManager>();
      final userData = prefs.getUserData();
      if (prefs.isLoggedIn() && userData != null) {
        _applyUserData(UserEntity.fromJson(userData));
        return;
      }
    } catch (e) {
      debugPrint('Error reading user from storage: $e');
    }
    final authState = sl<AuthBloc>().state;
    if (authState is AuthAuthenticated) _applyUserData(authState.user);
  }

  void _applyUserData(UserEntity user) {
    if (!mounted) return;
    setState(() {
      _firstNameController.text = user.firstname ?? '';
      _lastNameController.text = user.lastname ?? '';
      _emailController.text = user.email;
      _accountEmail = user.email;
      _userId = int.tryParse(user.id) ?? 0;
      // No phone on the account → open the form so it can be filled in.
      _editingTraveller = _phoneController.text.trim().isEmpty ||
          _firstNameController.text.trim().isEmpty;
    });
  }

  // ─────────────────────────────────────────────────────────────── money
  /// Same rule as the results screen, so prices match what the card showed.
  String get _prefCurrency =>
      sl<PreferencesManager>().getPreferredCurrency() ?? 'USD';

  double _convert(double amount, String from, String to) {
    if (from.isEmpty || from.toUpperCase() == to.toUpperCase()) return amount;
    return CurrencyConverter.convert(
      amount: amount,
      fromCurrency: from,
      toCurrency: to,
    );
  }

  double _toPref(double amount, String from) => _convert(amount, from, _prefCurrency);

  /// "₹3,120", "₹191.02" — grouping, and decimals only when they matter.
  String _fmt(double amount, {int maxDecimals = 2}) {
    final symbol = CurrencyConverter.getSymbol(_prefCurrency);
    var s = amount.toStringAsFixed(maxDecimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '$symbol$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
  }

  // Money is computed per currency: the screen shows the user's preferred
  // currency, but the payment screen / reservation charge and record in INR.
  double _baseFareIn(String cur) => _convert(
      double.tryParse(_r.totalPriceAmount) ?? 0, _r.totalPriceCurrency, cur);

  double _amenityPriceIn(AmenityEntity a, String cur) {
    final v = double.tryParse(a.price?.value ?? '') ?? 0;
    final from = (a.price?.currency.isNotEmpty ?? false)
        ? a.price!.currency
        : _r.totalPriceCurrency;
    return _convert(v, from, cur);
  }

  List<AmenityEntity> get _selectedAmenityList =>
      _r.amenities.where((a) => _selectedAmenities.contains(a.key)).toList();

  double _addOnsIn(String cur) =>
      _selectedAmenityList.fold(0.0, (t, a) => t + _amenityPriceIn(a, cur));

  double _subtotalIn(String cur) => _baseFareIn(cur) + _addOnsIn(cur);

  double _promoDiscountIn(String cur) {
    final p = _appliedPromo;
    if (p == null) return 0;
    final v = double.tryParse(p.discountValue) ?? 0;
    // A fixed-amount promo is in the app's home currency (INR), like the
    // flight booking screen; a percentage applies to the current subtotal.
    final raw = p.discountType == 'percent'
        ? _subtotalIn(cur) * v / 100
        : _convert(v, 'INR', cur);
    return math.min(raw, _subtotalIn(cur));
  }

  double _totalIn(String cur) =>
      math.max(0, _subtotalIn(cur) - _promoDiscountIn(cur));

  // Display (preferred currency) shorthands.
  double get _baseFare => _baseFareIn(_prefCurrency);
  double _amenityPrice(AmenityEntity a) => _amenityPriceIn(a, _prefCurrency);
  double get _promoDiscount => _promoDiscountIn(_prefCurrency);
  double get _total => _totalIn(_prefCurrency);

  // ─────────────────────────────────────────────────────── derived labels
  String get _vehicleTitle {
    final makeModel = [_r.vehicleMake, _r.vehicleModel]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    if (makeModel.isNotEmpty) return makeModel;
    if (_r.vehicleName.isNotEmpty) return _r.vehicleName;
    return _r.providerName;
  }

  String _placeLabel(LocationInfoEntity loc, String fallback) {
    if (loc.fullAddress.isNotEmpty) return loc.fullAddress;
    if (loc.city.isNotEmpty) return loc.city;
    return fallback;
  }

  String get _routeLabel => [
        _placeLabel(widget.searchData.startLocation, widget.startAddress),
        _placeLabel(widget.searchData.endLocation, widget.endAddress),
      ].where((s) => s.isNotEmpty).join(' to ');

  String get _pickupLabel => DateFormat('d MMM, h:mma').format(_pickupDateTime);

  String? get _durationLabel {
    final m = _r.travelTimeMinutes;
    if (m == null || m <= 0) return null;
    if (m < 60) return '$m min';
    final h = m ~/ 60, rem = m % 60;
    return rem == 0 ? '${h}Hrs' : '${h}h ${rem}m';
  }

  bool get _hasAirConditioning => _r.amenities.any((a) {
        if (!a.included) return false;
        final s = '${a.key} ${a.name}'.toLowerCase();
        return s.contains('air_con') ||
            s.contains('air con') ||
            s.contains('aircon') ||
            s.contains('a/c');
      });

  String? get _waitingSubLabel {
    final amt = double.tryParse(_r.waitingMinuteAmount ?? '');
    if (amt == null) return null;
    final cur = (_r.waitingMinuteCurrency?.isNotEmpty ?? false)
        ? _r.waitingMinuteCurrency!
        : _r.totalPriceCurrency;
    final original = '$cur ${_trim(amt)}/min';
    if (cur.toUpperCase() == _prefCurrency.toUpperCase()) return 'then $original';
    return 'then $original (~${_fmt(_toPref(amt, cur), maxDecimals: 1)}/min)';
  }

  String _trim(double v) => v.toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');

  // ─────────────────────────────────────────────────────────────── build
  @override
  Widget build(BuildContext context) {
    final rides = <Widget>[
      _buildRouteBanner(context),
      _buildHero(context),
      _buildInfoTiles(context),
      _buildVehicleDetails(context),
      _buildTravellers(context),
      _buildFlightInfo(context),
      _buildCoupons(context),
      _buildAmenities(context),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _ink, size: context.w(22)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Review Your Ride',
          style: TextStyle(
            fontSize: context.fs(20),
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            rides[0],
            rides[1],
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  rides[2],
                  ...rides.sublist(3).expand((w) => [
                        SizedBox(height: context.h(20)),
                        w,
                      ]),
                  SizedBox(height: context.h(28)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ───────────────────────────────────────────────────────── route banner
  Widget _buildRouteBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xffE6F3FB),
      padding: EdgeInsets.symmetric(
          horizontal: context.w(16), vertical: context.h(12)),
      child: widget.isOneWay
          ? _routeBannerOneWay(context)
          : _routeBannerRoundTrip(context),
    );
  }

  Widget _editIconButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickPickupDateAndTime,
      child: Padding(
        padding: EdgeInsets.all(context.w(4)),
        child: Image.asset(
          'assets/NewIcons/edit.png',
          width: context.w(16),
          height: context.w(16),
          color: AppColors.AppBlue,
        ),
      ),
    );
  }

  Widget _dateTimeRow(BuildContext context, {bool withDuration = false}) {
    final duration = _durationLabel;
    return Row(
      children: [
        Icon(Icons.calendar_month_rounded, size: context.w(11), color: _muted),
        SizedBox(width: context.w(4)),
        Text(_pickupLabel, style: TextStyle(fontSize: context.fs(9), color: _muted)),
        if (withDuration && duration != null) ...[
          SizedBox(width: context.w(12)),
          Icon(Icons.schedule_rounded, size: context.w(11), color: _muted),
          SizedBox(width: context.w(4)),
          Text(duration, style: TextStyle(fontSize: context.fs(9), color: _muted)),
        ],
      ],
    );
  }

  /// Single-line route + date, edit icon opens the date/time picker.
  Widget _routeBannerOneWay(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _routeLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
              SizedBox(height: context.h(6)),
              _dateTimeRow(context, withDuration: true),
            ],
          ),
        ),
        _editIconButton(context),
      ],
    );
  }

  /// Collapsed: same single-line route as One Way, plus a chevron to expand.
  /// Expanded: FROM/TO rows with the full addresses (Figma). The edit icon
  /// stays pinned to the date row in both states.
  Widget _routeBannerRoundTrip(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _routeExpanded
                  ? _routeDetailRows(context)
                  : Text(
                      _routeLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w500,
                        color: _ink,
                      ),
                    ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _routeExpanded = !_routeExpanded),
              child: Padding(
                padding: EdgeInsets.all(context.w(4)),
                child: Icon(
                  _routeExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: context.w(18),
                  color: AppColors.AppBlue,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(10)),
        Row(
          children: [
            Expanded(child: _dateTimeRow(context)),
            _editIconButton(context),
          ],
        ),
      ],
    );
  }

  /// FROM (with its full sub-address) → TO, as open/filled bullet rows.
  Widget _routeDetailRows(BuildContext context) {
    final startLoc = widget.searchData.startLocation;
    final startMain = startLoc.city.isNotEmpty
        ? startLoc.city
        : (startLoc.fullAddress.isNotEmpty ? startLoc.fullAddress : widget.startAddress);
    final startSub =
        startLoc.fullAddress.isNotEmpty && startLoc.fullAddress != startMain
            ? startLoc.fullAddress
            : null;
    final endMain = _placeLabel(widget.searchData.endLocation, widget.endAddress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: context.h(2)),
              child: Icon(Icons.circle_outlined,
                  size: context.w(12), color: AppColors.AppBlue),
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(startMain,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                  if (startSub != null) ...[
                    SizedBox(height: context.h(2)),
                    Text(startSub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.fs(9), color: _muted)),
                  ],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(10)),
        Row(
          children: [
            Icon(Icons.circle, size: context.w(10), color: AppColors.AppBlue),
            SizedBox(width: context.w(9)),
            Expanded(
              child: Text(endMain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: _ink)),
            ),
          ],
        ),
      ],
    );
  }

  /// Same picker chain [TransportBookingCard._pickDateAndTime] uses: a
  /// floating calendar dialog, then a floating time dialog.
  Future<void> _pickPickupDateAndTime() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => FloatingCloseDialogCard(
        width: context.w(340),
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: context.h(560),
          child: TransferCalendarScreen(
            initialDeparture: _pickupDateTime,
            isRoundTrip: false,
            firstDate: DateTime.now(),
            lastDate: DateTime(2035),
            startLabel: 'Trip Start',
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;

    final departure = result['departure'] as DateTime?;
    if (departure == null) return;

    final pickedTime = await showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => FloatingCloseDialogCard(
        width: context.w(300),
        child: CompactTimePickerDialog(
          initialTime: TimeOfDay.fromDateTime(_pickupDateTime),
        ),
      ),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _pickupDateTime = DateTime(
        departure.year,
        departure.month,
        departure.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  // ─────────────────────────────────────────────────────────── vehicle hero
  Widget _buildHero(BuildContext context) {
    final type = _r.vehicleType;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.w(16), context.h(8), context.w(16), context.h(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: context.h(160),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // soft "platform" under the car
                Positioned(
                  bottom: context.h(4),
                  child: Container(
                    width: context.w(300),
                    height: context.h(64),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(
                          Radius.elliptical(context.w(150), context.h(32))),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xffF4F5F7), Color(0xffFFFFFF)],
                      ),
                      border: Border.all(color: const Color(0xffEDEEF0)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(90), vertical: context.h(10)),
                  child: _vehicleImage(context),
                ),
                if (type.isNotEmpty)
                  Positioned(
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.w(14), vertical: context.h(3)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.r(20)),
                        gradient: const LinearGradient(
                          colors: [Color(0xff7AD3F7), AppColors.AppBlue],
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: context.fs(9),
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.h(12)),
          Text(
            _vehicleTitle,
            style: TextStyle(
              fontSize: context.fs(18),
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleImage(BuildContext context) {
    final fallback = Icon(Icons.directions_car,
        size: context.w(64), color: Colors.grey.shade300);
    if (_r.vehicleImageUrl.isEmpty) return Center(child: fallback);
    return CachedNetworkImage(
      imageUrl: _r.vehicleImageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.AppBlue)),
      errorWidget: (_, __, ___) => Center(child: fallback),
    );
  }

  // ───────────────────────────────────────────────────── AC / seats tiles
  Widget _buildInfoTiles(BuildContext context) {
    final tiles = <Widget>[
      if (_hasAirConditioning)
        _infoTile(context,
            icon: Icons.air_rounded,
            iconColor: AppColors.AppBlue,
            iconBg: _tileFill,
            label: 'AIR-CONDITIONING',
            value: 'AC'),
      if (_r.maxPassengers > 0)
        _infoTile(context,
            icon: Icons.groups_rounded,
            iconColor: _successGreen,
            iconBg: const Color(0xffE3F6EA),
            label: 'TRAVELLERS',
            value: '${_r.maxPassengers} Seat${_r.maxPassengers == 1 ? '' : 's'}'),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(width: context.w(11)),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(12), vertical: context.h(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: _stroke),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(26),
            height: context.w(26),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
            child: Icon(icon, size: context.w(15), color: iconColor),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(8), color: _muted)),
                SizedBox(height: context.h(3)),
                Text(value,
                    style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w500,
                        color: _ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────── section shell
  Widget _section(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    Widget? trailing,
    Key? key,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.w(16), vertical: context.h(14)),
            child: Row(
              children: [
                Icon(icon, size: context.w(16), color: iconColor),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xffECEEF1)),
          Padding(padding: EdgeInsets.all(context.w(16)), child: child),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────── vehicle details
  Widget _buildVehicleDetails(BuildContext context) {
    final makeModel = [_r.vehicleMake, _r.vehicleModel]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    final wait = _r.waitMinutesIncluded;

    final tiles = <Widget>[
      if (makeModel.isNotEmpty) _detailTile(context, 'MAKE / MODEL', makeModel),
      if (_r.vehicleName.isNotEmpty)
        _detailTile(context, 'CATEGORY', _r.vehicleName),
      if (_r.maxBags > 0)
        _detailTile(context, 'MAX LUGGAGE', '${_r.maxBags} Bag${_r.maxBags == 1 ? '' : 's'}',
            leading: Icon(Icons.luggage_rounded,
                size: context.w(13), color: const Color(0xffE5383B))),
      if (wait != null)
        _detailTile(context, 'WAITING TIME', '$wait min included',
            sub: _waitingSubLabel, small: true),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();

    return _section(
      context,
      icon: Icons.directions_car_rounded,
      iconColor: const Color(0xffF97316),
      title: 'Vehicle Details',
      child: LayoutBuilder(builder: (context, c) {
        final gap = context.w(12);
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      }),
    );
  }

  Widget _detailTile(BuildContext context, String label, String value,
      {String? sub, Widget? leading, bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(12), vertical: context.h(10)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(6)),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: context.fs(8), color: _muted)),
          SizedBox(height: context.h(4)),
          Row(
            children: [
              if (leading != null) ...[leading, SizedBox(width: context.w(4))],
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: context.fs(small ? 11 : 13),
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          if (sub != null) ...[
            SizedBox(height: context.h(3)),
            Text(sub, style: TextStyle(fontSize: context.fs(9), color: _muted)),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────── travellers
  bool get _travellerComplete =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;

  Widget _buildTravellers(BuildContext context) {
    return _section(
      context,
      key: _travellerKey,
      icon: Icons.person_rounded,
      iconColor: const Color(0xff7C5CE6),
      title: 'Travellers',
      child: _editingTraveller
          ? _travellerForm(context)
          : _travellerSummary(context),
    );
  }

  Widget _travellerSummary(BuildContext context) {
    final name =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final contact = [
      if (phone.isNotEmpty) '${_dial.code} $phone',
      if (email.isNotEmpty) email,
    ].join(' | ');

    return Row(
      children: [
        Expanded(
          child: _travellerComplete
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: context.fs(13),
                            fontWeight: FontWeight.w500,
                            color: _ink)),
                    SizedBox(height: context.h(4)),
                    Text(contact,
                        style: TextStyle(fontSize: context.fs(11), color: _muted)),
                  ],
                )
              : Text('Add traveller details',
                  style: TextStyle(fontSize: context.fs(12), color: _errorRed)),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _editingTraveller = true),
          child: Padding(
            padding: EdgeInsets.all(context.w(4)),
            child: Image.asset('assets/NewIcons/edit.png',
                width: context.w(18),
                height: context.w(18),
                color: AppColors.AppBlue),
          ),
        ),
      ],
    );
  }

  Widget _travellerForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender',
            style: TextStyle(fontSize: context.fs(12), color: _muted)),
        SizedBox(height: context.h(10)),
        Row(
          children: [
            for (final g in const ['Male', 'Female', 'Other']) ...[
              _genderOption(context, g),
              SizedBox(width: context.w(22)),
            ],
          ],
        ),
        SizedBox(height: context.h(16)),
        Row(
          children: [
            Expanded(
              child: _boxField(context,
                  label: 'First Name',
                  controller: _firstNameController,
                  icon: Icons.person_outline_rounded,
                  hasError: _firstNameError,
                  capitalization: TextCapitalization.characters,
                  onChanged: () => setState(() => _firstNameError = false)),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: _boxField(context,
                  label: 'Last Name',
                  controller: _lastNameController,
                  icon: Icons.person_outline_rounded,
                  hasError: _lastNameError,
                  capitalization: TextCapitalization.characters,
                  onChanged: () => setState(() => _lastNameError = false)),
            ),
          ],
        ),
        SizedBox(height: context.h(12)),
        Row(
          children: [
            _dialPicker(context),
            SizedBox(width: context.w(10)),
            Expanded(
              child: _boxField(context,
                  label: 'Phone Number',
                  controller: _phoneController,
                  keyboard: TextInputType.phone,
                  hasError: _phoneError,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: () => setState(() => _phoneError = false)),
            ),
          ],
        ),
        SizedBox(height: context.h(12)),
        _boxField(context,
            label: 'Email ID (optional)',
            controller: _emailController,
            icon: Icons.mail_outline_rounded,
            keyboard: TextInputType.emailAddress,
            hasError: _emailError,
            onChanged: () => setState(() => _emailError = false)),
        SizedBox(height: context.h(14)),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _saveTraveller,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.w(4), vertical: context.h(4)),
              child: Text('Save',
                  style: TextStyle(
                      fontSize: context.fs(16),
                      fontWeight: FontWeight.w500,
                      color: AppColors.AppBlue)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderOption(BuildContext context, String g) {
    final selected = _gender == g;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _gender = g),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.w(20),
            height: context.w(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? AppColors.AppBlue : const Color(0xffB8BDC3),
                  width: selected ? 1.5 : 1),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: context.w(10),
                      height: context.w(10),
                      decoration: const BoxDecoration(
                          color: AppColors.AppBlue, shape: BoxShape.circle),
                    ),
                  )
                : null,
          ),
          SizedBox(width: context.w(8)),
          Text(g,
              style: TextStyle(
                  fontSize: context.fs(13),
                  color: selected ? _ink : _muted)),
        ],
      ),
    );
  }

  Widget _dialPicker(BuildContext context) {
    return PopupMenuButton<_Dial>(
      onSelected: (d) => setState(() => _dial = d),
      itemBuilder: (_) => [
        for (final d in _dials)
          PopupMenuItem(
            value: d,
            child: Text('${d.flag}  ${d.name}  ${d.code}'),
          ),
      ],
      child: Container(
        height: context.h(50),
        padding: EdgeInsets.symmetric(horizontal: context.w(10)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(color: _stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_dial.flag, style: TextStyle(fontSize: context.fs(18))),
            SizedBox(width: context.w(6)),
            Text(_dial.code,
                style: TextStyle(fontSize: context.fs(13), color: _ink)),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: context.w(18), color: _muted),
          ],
        ),
      ),
    );
  }

  /// Bordered field with a small caption inside the box (Figma traveller form).
  Widget _boxField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboard,
    bool hasError = false,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    required VoidCallback onChanged,
  }) {
    return Container(
      height: context.h(50),
      padding: EdgeInsets.symmetric(horizontal: context.w(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(
            color: hasError ? _errorRed : _stroke, width: hasError ? 1.2 : 1),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: context.w(16), color: const Color(0xffB0B6BE)),
            SizedBox(width: context.w(10)),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.fs(8),
                        color: hasError ? _errorRed : _muted)),
                TextField(
                  controller: controller,
                  keyboardType: keyboard,
                  textCapitalization: capitalization,
                  inputFormatters: formatters,
                  onChanged: (_) => onChanged(),
                  style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: _ink),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  /// Returns true when the traveller block is valid (and marks errors if not).
  bool _validateTraveller() {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    _firstNameError = _firstNameController.text.trim().isEmpty;
    _lastNameError = _lastNameController.text.trim().isEmpty;
    _phoneError = phone.length < 6 || phone.length > 15;
    _emailError = email.isNotEmpty && !_validEmail(email);
    return !(_firstNameError || _lastNameError || _phoneError || _emailError);
  }

  void _saveTraveller() {
    final ok = _validateTraveller();
    setState(() => _editingTraveller = !ok);
  }

  // ───────────────────────────────────────────────── flight information
  Widget _buildFlightInfo(BuildContext context) {
    return _section(
      context,
      key: _flightKey,
      icon: Icons.flight_takeoff_rounded,
      iconColor: AppColors.AppBlue,
      title: 'Flight Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share your flight details so the driver can track delays and arrival gates.',
            style: TextStyle(fontSize: context.fs(10), color: _muted),
          ),
          SizedBox(height: context.h(12)),
          Row(
            children: [
              Expanded(
                child: _boxField(context,
                    label: 'Flight Number',
                    controller: _flightNumberController,
                    icon: Icons.confirmation_number_outlined,
                    capitalization: TextCapitalization.characters,
                    hasError: _flightNumberError,
                    onChanged: () => setState(() => _flightNumberError = false)),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: _boxField(context,
                    label: 'Airline Code',
                    controller: _airlineCodeController,
                    icon: Icons.flight_rounded,
                    capitalization: TextCapitalization.characters,
                    hasError: _airlineError,
                    onChanged: () => setState(() => _airlineError = false)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────── coupon & offers
  bool _promoMatchesTransport(PromoCodeEntity p) {
    final cat = p.category.trim().toLowerCase();
    return cat == 'transport_booking' || cat == 'payment' || cat == 'all';
  }

  List<PromoCodeEntity> _availablePromos(GeneralSettingsState state) {
    if (state is! PromoCodesLoaded) return const [];
    final seen = <String>{};
    return state.promoCodes.where(_promoMatchesTransport).where((p) {
      final code = p.code.trim().toUpperCase();
      return code.isNotEmpty && seen.add(code);
    }).toList();
  }

  Widget _buildCoupons(BuildContext context) {
    return BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
      builder: (context, state) {
        final all = _availablePromos(state);
        final visible = _showAllOffers ? all : all.take(2).toList();

        return _section(
          context,
          icon: Icons.local_offer_rounded,
          iconColor: AppColors.AppBlue,
          title: 'Coupon & Offers',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _promoInput(context),
              for (final p in visible) ...[
                SizedBox(height: context.h(12)),
                _offerCard(context, p),
              ],
              if (all.length > 2) ...[
                SizedBox(height: context.h(8)),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showAllOffers = !_showAllOffers),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_showAllOffers ? 'View less' : 'View more',
                          style: TextStyle(
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w600,
                              color: AppColors.AppBlue)),
                      Icon(
                        _showAllOffers
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: context.w(14),
                        color: AppColors.AppBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _promoInput(BuildContext context) {
    return Container(
      height: context.h(48),
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: _stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoCodeController,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(fontSize: context.fs(12), color: _ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Have a Coupon Code?',
                hintStyle:
                    TextStyle(fontSize: context.fs(11), color: _muted),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _applyTypedPromo,
            child: Padding(
              padding: EdgeInsets.only(left: context.w(12)),
              child: Text('Apply',
                  style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.AppBlue)),
            ),
          ),
        ],
      ),
    );
  }

  /// Offer card in the flight booking screen's style. Applied → cyan border,
  /// green tick, red "Remove".
  Widget _offerCard(BuildContext context, PromoCodeEntity promo) {
    final isApplied = _appliedPromo != null &&
        _appliedPromo!.code.toUpperCase() == promo.code.toUpperCase();

    final value = double.tryParse(promo.discountValue);
    final offLabel = promo.discountType == 'percent'
        ? '${value?.toStringAsFixed(0) ?? promo.discountValue}% off'
        : '${_fmt(_toPref(value ?? 0, 'INR'))} off';

    final body = isApplied
        ? '${_fmt(_promoDiscount)} instant discount applied'
        : (promo.description.isNotEmpty
            ? promo.description
            : 'Apply this code to get $offLabel on your booking.');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
            color: isApplied ? AppColors.AppBlue : _stroke,
            width: isApplied ? 1.2 : 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isApplied)
                Icon(Icons.verified_rounded,
                    size: context.w(20), color: _successGreen)
              else
                Image.asset('assets/NewIcons/coupon_offer.png',
                    width: context.w(18), height: context.w(18)),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Text(
                  promo.code.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => isApplied ? _removePromo() : _applyPromo(promo),
                child: Text(
                  isApplied ? 'Remove' : 'Apply',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: isApplied
                        ? const Color(0xffE5383B)
                        : AppColors.AppBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Text(body,
              style: TextStyle(fontSize: context.fs(11), color: _muted)),
          if (!isApplied) ...[
            SizedBox(height: context.h(6)),
            Text(offLabel,
                style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.AppBlue)),
          ],
        ],
      ),
    );
  }

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _applyTypedPromo() {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _toast('Please enter a promo code', _errorRed);
      return;
    }
    final state = context.read<GeneralSettingsBloc>().state;
    final match = _availablePromos(state)
        .where((p) => p.code.trim().toUpperCase() == code)
        .toList();
    if (match.isEmpty) {
      _toast('Invalid promo code. Please try again.', _errorRed);
      return;
    }
    _applyPromo(match.first);
  }

  void _applyPromo(PromoCodeEntity promo) {
    setState(() {
      _appliedPromo = promo;
      _promoCodeController.clear();
    });
    _showCelebrationDialog(_promoDiscount, promo.code);
  }

  void _removePromo() => setState(() => _appliedPromo = null);

  void _showCelebrationDialog(double discountAmount, String promoCode) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(context.w(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: context.hp(25),
                  width: double.infinity,
                  child: Lottie.asset('assets/animation/celebrate.json',
                      repeat: true, fit: BoxFit.contain),
                ),
                SizedBox(height: context.h(12)),
                Text('🎉 Promo Applied!',
                    style: TextStyle(
                        fontSize: context.fs(20),
                        fontWeight: FontWeight.w700,
                        color: _ink)),
                SizedBox(height: context.h(8)),
                Text('You saved ${_fmt(discountAmount)}',
                    style: TextStyle(
                        fontSize: context.fs(16),
                        fontWeight: FontWeight.w600,
                        color: _successGreen)),
                SizedBox(height: context.h(4)),
                Text('Code: $promoCode',
                    style: TextStyle(fontSize: context.fs(13), color: _muted)),
                SizedBox(height: context.h(20)),
                SizedBox(
                  width: double.infinity,
                  height: context.h(44),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.AppBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Great!',
                        style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────── amenities
  IconData _amenityIcon(AmenityEntity a) {
    final s = '${a.key} ${a.name}'.toLowerCase();
    if (s.contains('meet')) return Icons.waving_hand_rounded;
    if (s.contains('air')) return Icons.ac_unit_rounded;
    if (s.contains('english') || s.contains('speaking')) {
      return Icons.record_voice_over_rounded;
    }
    if (s.contains('power') || s.contains('charg')) return Icons.power_rounded;
    if (s.contains('driver') || s.contains('detail')) return Icons.access_time_filled_rounded;
    if (s.contains('wifi') || s.contains('wi-fi')) return Icons.wifi_rounded;
    if (s.contains('water')) return Icons.water_drop_rounded;
    if (s.contains('child') || s.contains('baby') || s.contains('booster')) {
      return Icons.child_friendly_rounded;
    }
    if (s.contains('sms')) return Icons.sms_rounded;
    return Icons.check_circle_rounded;
  }

  Color _amenityColor(AmenityEntity a) {
    final s = '${a.key} ${a.name}'.toLowerCase();
    if (s.contains('meet')) return const Color(0xffF97316);
    if (s.contains('air') || s.contains('english')) return AppColors.AppBlue;
    if (s.contains('power')) return _successGreen;
    if (s.contains('driver') || s.contains('detail')) return const Color(0xffA855F7);
    return AppColors.AppBlue;
  }

  Widget _buildAmenities(BuildContext context) {
    final included = _r.amenities.where((a) => a.included).toList();
    final extras =
        _r.amenities.where((a) => a.chargeable && !a.included).toList();
    if (included.isEmpty && extras.isEmpty) return const SizedBox.shrink();

    return _section(
      context,
      icon: Icons.emoji_people_rounded,
      iconColor: _successGreen,
      title: 'Amenities',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in included)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(16)),
              child: Row(
                children: [
                  Icon(_amenityIcon(a),
                      size: context.w(14), color: _amenityColor(a)),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: Text(a.name,
                        style: TextStyle(fontSize: context.fs(13), color: _ink)),
                  ),
                ],
              ),
            ),
          for (final a in extras) _extraAmenityBox(context, a),
        ],
      ),
    );
  }

  Widget _extraAmenityBox(BuildContext context, AmenityEntity a) {
    final selected = _selectedAmenities.contains(a.key);
    final hasPrice = (double.tryParse(a.price?.value ?? '') ?? 0) > 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        selected ? _selectedAmenities.remove(a.key) : _selectedAmenities.add(a.key);
      }),
      child: Container(
        margin: EdgeInsets.only(bottom: context.h(10)),
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: const Color(0xffEAF3FB),
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(
              color: selected ? AppColors.AppBlue : Colors.transparent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.w(18),
              height: context.w(18),
              margin: EdgeInsets.only(top: context.h(2)),
              decoration: BoxDecoration(
                color: selected ? AppColors.AppBlue : Colors.white,
                borderRadius: BorderRadius.circular(context.r(4)),
                border: Border.all(
                    color: selected
                        ? AppColors.AppBlue
                        : const Color(0xffB8BDC3)),
              ),
              child: selected
                  ? Icon(Icons.check, size: context.w(13), color: Colors.white)
                  : null,
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPrice ? '${a.name} ${_fmt(_amenityPrice(a))}' : a.name,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.AppBlue,
                    ),
                  ),
                  if (a.description.isNotEmpty) ...[
                    SizedBox(height: context.h(3)),
                    Text(a.description,
                        style: TextStyle(fontSize: context.fs(9), color: _muted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────── bottom bar
  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: context.h(70),
        padding: EdgeInsets.symmetric(
            horizontal: context.w(19), vertical: context.h(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openFareBreakup,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _fmt(_total),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(24),
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(6)),
                    Icon(Icons.info, size: context.w(13), color: _muted),
                  ],
                ),
              ),
            ),
            SizedBox(width: context.w(12)),
            SizedBox(
              height: context.h(44),
              width: context.w(149),
              child: ElevatedButton(
                onPressed: _validateAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.OrangeColor,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(12))),
                ),
                child: Text('PAY NOW',
                    style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same shared "Fare Breakup" drawer the flight booking screen uses.
  void _openFareBreakup() {
    final lines = <FareBreakupLine>[
      FareBreakupLine(
        label: 'Base Fare',
        amount: _fmt(_baseFare),
        subLabel: _vehicleTitle,
        subAmount: _fmt(_baseFare),
      ),
      for (final a in _selectedAmenityList)
        FareBreakupLine(label: a.name, amount: _fmt(_amenityPrice(a))),
      if (_appliedPromo != null && _promoDiscount > 0)
        FareBreakupLine(
          label: 'Discounts',
          amount: '-${_fmt(_promoDiscount)}',
          subLabel: _appliedPromo!.code,
          subAmount: '-${_fmt(_promoDiscount)}',
          isDiscount: true,
        ),
    ];
    FareBreakupSheet.show(context, lines: lines, totalAmount: _fmt(_total));
  }

  // ───────────────────────────────────────────────────────────── proceed
  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 300), alignment: 0.1);
    }
  }

  void _validateAndProceed() {
    final travellerOk = _validateTraveller();
    _flightNumberError = _flightNumberController.text.trim().isEmpty;
    _airlineError = _airlineCodeController.text.trim().isEmpty;

    setState(() {
      if (!travellerOk) _editingTraveller = true;
    });

    if (!travellerOk) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollTo(_travellerKey));
      return;
    }
    if (_flightNumberError || _airlineError) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_flightKey));
      return;
    }

    _proceedToPayment();
  }

  void _proceedToPayment() {
    // Email is optional in the form; the payment/reservation still needs one,
    // so fall back to the signed-in account's address.
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : _accountEmail;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          searchId: widget.searchId,
          resultId: widget.resultId,
          vehicleType: _r.vehicleType,
          vehicleName: _r.vehicleName,
          providerName: _r.providerName,
          pickupLocation: widget.startAddress.isNotEmpty
              ? widget.startAddress
              : widget.searchData.startLocation.city,
          dropoffLocation: widget.endAddress.isNotEmpty
              ? widget.endAddress
              : widget.searchData.endLocation.city,
          pickupDate: _pickupDateTime,
          passengers: math.max(1, widget.searchData.numPassengers),
          // The payment screen charges and records in INR.
          baseFare: _baseFareIn('INR'),
          totalAmount: _totalIn('INR'),
          addOnsAmount: _addOnsIn('INR'),
          discountAmount: _promoDiscountIn('INR'),
          couponCode: _appliedPromo?.code,
          // Only real supplier amenities go to the reservation; internal
          // Wander Nova add-ons (SMS notifications) aren't Mozio amenities.
          optionalAmenityKeys: [
            for (final a in _selectedAmenityList)
              if (!a.internal) a.key,
          ],
          passengerName:
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          passengerEmail: email,
          passengerPhone: '${_dial.code}${_phoneController.text.trim()}',
          userId: _userId,
          flightNumber: _flightNumberController.text.trim().toUpperCase(),
          airline: _airlineCodeController.text.trim().toUpperCase(),
          vehicleImageUrl: _r.vehicleImageUrl,
          passengerGender: _gender,
        ),
      ),
    );
  }
}
