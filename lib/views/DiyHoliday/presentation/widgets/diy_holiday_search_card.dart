import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
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

/// The holiday hero + search form.
///
/// Built like the flight [SearchCard]: a full-bleed hero photo behind the
/// form, faded to white along the bottom edge so the page content below
/// appears to grow out of the image.
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

  String? _heroImage;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GeneralSettingsBloc>().add(
        const LoadSectionHeroes(domain: 'thewandernova.com'),
      );
    });
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeneralSettingsBloc, GeneralSettingsState>(
      listener: (context, state) {
        if (state is SectionHeroesLoaded && mounted) {
          setState(() => _heroImage = state.sectionHeroes.holidays);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Full-bleed hero, edge to edge, behind the whole form.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizedBox(
              height: context.screenHeight * 0.46,
              child: _heroBackdrop(),
            ),
          ),

          // Bottom edge: white "cloud" fade so the page below melts into the
          // photo instead of ending on a hard line.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: context.h(34),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.92),
                    Colors.white.withOpacity(0.72),
                    Colors.white.withOpacity(0.38),
                    Colors.white.withOpacity(0.10),
                    Colors.white.withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.20, 0.40, 0.60, 0.80, 1.0],
                ),
              ),
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: context.statusBarHeight + context.h(10)),
              _topBar(),
              SizedBox(height: context.h(16)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                child: _originField(),
              ),
              SizedBox(height: context.h(10)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                child: _destinationField(),
              ),
              SizedBox(height: context.h(10)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _dateField()),
                      SizedBox(width: context.w(10)),
                      Expanded(child: _roomField()),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.h(34)),
              _searchButton(),
              SizedBox(height: context.h(20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroBackdrop() {
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E9BE0), Color(0xFF8FD3F4)],
        ),
      ),
    );

    final hero = _heroImage;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hero != null && hero.isNotEmpty)
          Image.network(
            hero,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : fallback,
          )
        else
          fallback,

        // Same two-layer white fade the flight hero uses, so both heroes
        // blur out into the page identically.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.92),
                  Colors.white.withOpacity(0.72),
                  Colors.white.withOpacity(0.38),
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.05),
                ],
                stops: const [0.0, 0.20, 0.40, 0.60, 0.80, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(80),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white.withOpacity(0.30),
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
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
              color: Colors.white,
            ),
          ),
          SizedBox(width: context.w(14)),
          Text(
            'Holiday',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openFilters,
            child: Icon(
              Icons.tune_rounded,
              size: context.w(22),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- fields

  BoxDecoration get _fieldDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(context.r(12)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: context.w(14),
        offset: Offset(0, context.h(4)),
      ),
    ],
  );

  Widget _fieldLabel(String text, {bool chevron = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: context.fs(9),
            fontWeight: FontWeight.w700,
            color: DiyTokens.labelGrey,
            letterSpacing: 0.6,
          ),
        ),
        if (chevron) ...[
          SizedBox(width: context.w(3)),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.w(12),
            color: DiyTokens.labelGrey,
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
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(11),
        ),
        decoration: _fieldDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _fieldLabel('STARTING FROM'),
            SizedBox(height: context.h(6)),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/NewIcons/location.svg',
                  width: context.w(16),
                  height: context.w(19),
                  colorFilter: const ColorFilter.mode(
                    AppColors.AppBlue,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Text(
                    _origin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w600,
                      color: DiyTokens.navy,
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
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(11),
        ),
        decoration: _fieldDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _fieldLabel('TRAVELLING TO'),
            SizedBox(height: context.h(6)),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/NewIcons/location_outline.svg',
                  width: context.w(16),
                  height: context.w(19),
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Text(
                    destination?.name ?? 'Select destination',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w600,
                      color: destination == null
                          ? DiyTokens.labelGrey
                          : DiyTokens.navy,
                    ),
                  ),
                ),
                // Figma: orange camera chip — "search with an image".
                GestureDetector(
                  onTap: () => _pickDestination(startWithImage: true),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.all(context.w(5)),
                    decoration: BoxDecoration(
                      color: DiyTokens.orange,
                      borderRadius: BorderRadius.circular(context.r(7)),
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: context.w(15),
                      color: Colors.white,
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
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(11),
        ),
        decoration: _fieldDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _fieldLabel('STARTING DATE', chevron: true),
            SizedBox(height: context.h(6)),
            Row(
              children: [
                Image.asset(
                  _icCalendar,
                  width: context.w(22),
                  height: context.w(22),
                  fit: BoxFit.contain,
                  color: AppColors.AppBlue,
                ),
                SizedBox(width: context.w(8)),
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
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700,
                          color: DiyTokens.navy,
                        ),
                      ),
                      SizedBox(height: context.h(1)),
                      Text(
                        date == null ? '-' : diyWeekday(date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(11),
                          color: DiyTokens.subGrey,
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
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(11),
        ),
        decoration: _fieldDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _fieldLabel('ROOM', chevron: true),
            SizedBox(height: context.h(8)),
            Row(
              children: [
                _countChip(icon: Icons.bed_rounded, count: _rooms),
                _countDivider(),
                _countChip(asset: _icAdult, count: _adults),
                _countDivider(),
                _countChip(asset: _icChild, count: _children),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countDivider() => Container(
    width: 0.5,
    height: context.w(18),
    margin: EdgeInsets.symmetric(horizontal: context.w(8)),
    color: Colors.grey.shade300,
  );

  Widget _countChip({IconData? icon, String? asset, required int count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (asset != null)
          Image.asset(
            asset,
            width: context.w(14),
            height: context.w(14),
            fit: BoxFit.contain,
          )
        else
          Icon(icon, size: context.w(15), color: DiyTokens.blue),
        SizedBox(width: context.w(4)),
        Text(
          '$count',
          style: TextStyle(
            fontSize: context.fs(12),
            fontWeight: FontWeight.w600,
            color: DiyTokens.navy,
          ),
        ),
      ],
    );
  }

  Widget _searchButton() {
    return Center(
      child: SizedBox(
        width: context.w(170),
        height: context.h(43),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DiyTokens.orange,
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: DiyTokens.orange.withOpacity(0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(30)),
            ),
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
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
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w600,
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
