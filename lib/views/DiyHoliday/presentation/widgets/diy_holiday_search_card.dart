import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/app_surface.dart';
import 'package:wander_nova/common_widgets/currency_chip.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../data/diy_dates.dart';
import '../../data/diy_origins.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../screens/diy_calendar_screen.dart';
import '../screens/diy_destination_search_screen.dart';
import '../screens/diy_origin_search_screen.dart';
import '../screens/diy_results_screen.dart';
import 'diy_rooms_sheet.dart';
import 'diy_common.dart';
import '../screens/diy_filter_screen.dart';

/// The holiday search form, styled like the flight [SearchCard]: white
/// page, dark top bar and white cards with the shared raised shadow.
class DiyHolidaySearchCard extends StatefulWidget {
  const DiyHolidaySearchCard({super.key});

  @override
  State<DiyHolidaySearchCard> createState() => DiyHolidaySearchCardState();
}

/// Public so the home screen's compact bar can read the form and run the
/// same search once the form has scrolled away.
class DiyHolidaySearchCardState extends State<DiyHolidaySearchCard> {
  /// The form as it stands.
  DiySearchQuery get query => _query;

  /// SEARCH, exactly as the form's own button runs it.
  void search() => _search();

  static const String _icCalendar = 'assets/NewIcons/departureCalendar.png';
  static const String _icAdult = 'assets/NewIcons/TravellerAdult.png';
  static const String _icChild = 'assets/NewIcons/TravellerChild.png';

  DiyOrigin _origin = DiyOrigins.defaultOrigin;
  DiyDestination? _destination;
  DateTime? _departureDate;
  int _rooms = 1;
  int _adults = 2;
  int _children = 1;
  List<int> _childAges = [DiySearchQuery.defaultChildAge];

  DiyFilters _filters = const DiyFilters();

  @override
  void initState() {
    super.initState();
    // The price API (API 5) rejects a departure that is not in the future,
    // so the form never opens on today.
    _departureDate = DiyDates.defaultDeparture();
    _restoreLastSearch();
  }

  Future<void> _restoreLastSearch() async {
    final saved = await DiySearchStore.loadLastSearch();
    if (saved == null || !mounted) return;
    setState(() {
      _origin = saved.origin;
      _destination = saved.destination;
      _departureDate =
          DiyDates.clampToFuture(saved.departureDate) ?? _departureDate;
      _rooms = saved.rooms;
      _adults = saved.adults;
      _children = saved.children;
      _childAges = saved.childAgesFilled;
    });
  }

  DiySearchQuery get _query => DiySearchQuery(
    origin: _origin,
    destination: _destination,
    departureDate: _departureDate,
    rooms: _rooms,
    adults: _adults,
    children: _children,
    childAges: _childAges,
  );

  // ------------------------------------------------------------ actions

  Future<void> _pickOrigin() async {
    final picked = await Navigator.of(context).push<DiyOrigin>(
      MaterialPageRoute(
        builder: (_) => DiyOriginSearchScreen(initial: _origin),
      ),
    );
    if (picked != null && mounted) setState(() => _origin = picked);
  }

  Future<void> _pickDestination({bool startWithImage = false}) async {
    final picked = await Navigator.of(context).push<DiyDestination>(
      MaterialPageRoute(
        builder: (_) => DiyDestinationSearchScreen(
          initial: _destination,
          openImageSearch: startWithImage,
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _destination = picked);
  }

  Future<void> _pickDate() async {
    final picked = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => DiyCalendarScreen(initialDate: _departureDate),
      ),
    );
    if (picked != null && mounted) setState(() => _departureDate = picked);
  }

  Future<void> _openFilters() async {
    final result = await openDiyFilterScreen(
      context,
      initial: _filters,
      // The sheet counts packages live; at this point the search hasn't run
      // yet, so it queries with the form as it stands.
      query: _query,
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  void _search() {
    if (_destination == null) {
      diySnack(context, 'Pick where you are travelling to', isError: true);
      return;
    }
    DiySearchStore.saveLastSearch(_query);
    DiySearchStore.addRecentDestination(_destination!);
    DiySearchStore.addRecentOrigin(_origin);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyResultsScreen(query: _query, filters: _filters),
      ),
    );
  }

  // -------------------------------------------------------------- build
  // Same look as the flight form: white page, dark top bar, white cards
  // with the shared raised shadow (412px Figma frame, hence `context.fx`).

  @override
  Widget build(BuildContext context) {
    final gutter = EdgeInsets.symmetric(horizontal: context.fx(16));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: context.statusBarHeight + context.fx(16)),
        Padding(padding: gutter, child: _topBar()),
        SizedBox(height: context.fx(24)),
        Padding(padding: gutter, child: _originField()),
        SizedBox(height: context.fx(12)),
        Padding(padding: gutter, child: _destinationField()),
        SizedBox(height: context.fx(12)),
        Padding(
          padding: gutter,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _dateField()),
                SizedBox(width: context.fx(12)),
                Expanded(child: _roomField()),
              ],
            ),
          ),
        ),
        SizedBox(height: context.fx(24)),
        _searchButton(),
        SizedBox(height: context.fx(16)),
      ],
    );
  }

  Widget _topBar() {
    return SizedBox(
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
            'Holiday',
            style: TextStyle(
              fontSize: context.ffs(20),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Filters',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openFilters,
              child: Icon(Icons.tune_rounded, size: context.fx(24), color: Colors.black),
            ),
          ),
          SizedBox(width: context.fx(16)),
          const CurrencyChip(),
          SizedBox(width: context.fx(16)),
          SvgPicture.asset(
            'assets/home/notification.svg',
            width: context.fx(24),
            height: context.fx(24),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- fields

  BoxDecoration get _fieldDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(context.fx(12)),
    boxShadow: kRaisedCardShadow,
  );

  static const Color _muted = Color(0xFF757575);

  Widget _fieldLabel(String text, {bool chevron = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: context.ffs(9),
            fontWeight: FontWeight.w600,
            color: _muted,
            letterSpacing: 0.6,
          ),
        ),
        if (chevron) ...[
          SizedBox(width: context.fx(4)),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.fx(14),
            color: _muted,
          ),
        ],
      ],
    );
  }

  Widget _originField() {
    return GestureDetector(
      onTap: _pickOrigin,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.fx(12)),
        decoration: _fieldDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _fieldLabel('STARTING FROM'),
            SizedBox(height: context.fx(8)),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/NewIcons/location.svg',
                  width: context.fx(16),
                  height: context.fx(19),
                  colorFilter: const ColorFilter.mode(
                    AppColors.AppBlue,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: context.fx(10)),
                Expanded(
                  child: Text(
                    _origin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.ffs(14),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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

  Widget _destinationField() {
    final destination = _destination;
    return GestureDetector(
      onTap: _pickDestination,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.fx(12)),
        decoration: _fieldDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _fieldLabel('TRAVELLING TO'),
            SizedBox(height: context.fx(8)),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/NewIcons/location_outline.svg',
                  width: context.fx(16),
                  height: context.fx(19),
                ),
                SizedBox(width: context.fx(10)),
                Expanded(
                  child: Text(
                    destination?.name ?? 'Select destination',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.ffs(14),
                      fontWeight: FontWeight.w600,
                      color: destination == null
                          ? Colors.grey.shade400
                          : Colors.black,
                    ),
                  ),
                ),
                // Orange camera chip — "search with an image".
                Semantics(
                  button: true,
                  label: 'Search destination with an image',
                  child: GestureDetector(
                    onTap: () => _pickDestination(startWithImage: true),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsets.all(context.fx(6)),
                      decoration: BoxDecoration(
                        color: DiyTokens.orange,
                        borderRadius: BorderRadius.circular(context.fx(8)),
                      ),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: context.fx(16),
                        color: Colors.white,
                      ),
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

  Widget _dateField() {
    final date = _departureDate;
    return GestureDetector(
      onTap: _pickDate,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.fx(12)),
        decoration: _fieldDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _fieldLabel('STARTING DATE', chevron: true),
            SizedBox(height: context.fx(6)),
            Row(
              children: [
                Image.asset(
                  _icCalendar,
                  width: context.fx(26),
                  height: context.fx(26),
                  fit: BoxFit.contain,
                  color: AppColors.AppBlue,
                ),
                SizedBox(width: context.fx(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        date == null ? 'Select date' : diyFullDate(date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.ffs(12),
                          fontWeight: FontWeight.w600,
                          color: date == null ? Colors.grey.shade400 : Colors.black,
                        ),
                      ),
                      SizedBox(height: context.fx(2)),
                      Text(
                        date == null ? '-' : diyWeekday(date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.ffs(10),
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomField() {
    return GestureDetector(
      onTap: _openRoomSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.fx(12)),
        decoration: _fieldDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _fieldLabel('ROOM', chevron: true),
            SizedBox(height: context.fx(12)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _countChip(icon: Icons.bed_rounded, count: _rooms),
                  _countDivider(),
                  _countChip(asset: _icAdult, count: _adults),
                  _countDivider(),
                  _countChip(asset: _icChild, count: _children),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countDivider() => Container(
    width: 0.5,
    height: context.fx(20),
    margin: EdgeInsets.symmetric(horizontal: context.fx(9)),
    color: const Color(0xFFCCCCCC),
  );

  Widget _countChip({IconData? icon, String? asset, required int count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (asset != null)
          Image.asset(
            asset,
            width: context.fx(16),
            height: context.fx(16),
            fit: BoxFit.contain,
            color: AppColors.AppBlue,
          )
        else
          Icon(icon, size: context.fx(16), color: AppColors.AppBlue),
        SizedBox(width: context.fx(8)),
        Text(
          '$count',
          style: TextStyle(
            fontSize: context.ffs(12),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _searchButton() {
    return Center(
      child: SizedBox(
        width: context.fx(210),
        height: context.fx(42),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: AppColors.orange.withValues(alpha: 0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.fx(21)),
            ),
            padding: EdgeInsets.symmetric(horizontal: context.fx(8)),
          ),
          onPressed: _search,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
    );
  }

  // --------------------------------------------------------- room sheet

  Future<void> _openRoomSheet() async {
    final edited = await showDiyRoomsSheet(context, query: _query);
    if (edited == null || !mounted) return;
    setState(() {
      _rooms = edited.rooms;
      _adults = edited.adults;
      _children = edited.children;
      _childAges = edited.childAgesFilled;
    });
  }
}
