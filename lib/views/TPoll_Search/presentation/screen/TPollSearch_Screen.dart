import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../common_widgets/Transport_loading.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/TPollSearchEntity.dart';
import '../../../TResult/presentation/screen/TPoll_Booking.dart';
import '../../../../newUIWidgets/sheetActionButtons.dart';
import '../Widget/TPoll_EditSearchDrawer.dart';
import '../Widget/TPoll_VehicleCard.dart';
import '../bloc/TPoll_SearchBloc.dart';
import '../bloc/TPoll_SearchEvent.dart';
import '../bloc/TPoll_SearchState.dart';
import 'TPoll_FilterScreen.dart';

class TpollSearchResultsPage extends StatefulWidget {
  final String searchId;
  final String startAddress;
  final String endAddress;
  final DateTime pickupDate;
  final int numPassengers;

  // What the user searched with — used to pre-fill the edit-search drawer.
  // Optional so existing callers keep working (defaults: one-way, time taken
  // from the API's pickup_datetime).
  final TimeOfDay? pickupTime;
  final bool isOneWay;
  final DateTime? returnDate;
  final TimeOfDay? returnTime;

  /// Outstation transfers don't need flight tracking, so the booking screen
  /// keeps the Flight Information section optional for them.
  final bool isOutstation;

  const TpollSearchResultsPage({
    super.key,
    required this.searchId,
    required this.startAddress,
    required this.endAddress,
    required this.pickupDate,
    required this.numPassengers,
    this.pickupTime,
    this.isOneWay = true,
    this.returnDate,
    this.returnTime,
    this.isOutstation = false,
  });

  @override
  State<TpollSearchResultsPage> createState() => _TpollSearchResultsPageState();
}

class _TpollSearchResultsPageState extends State<TpollSearchResultsPage> {
  late TpollSearchBloc _bloc;
  TpollFilterState _filters = const TpollFilterState();

  /// Quick-filter chip under the header (a vehicle type or make from the
  /// results). null = no chip selected = show everything.
  String? _quickChip;

  static const _chipBorder = Color(0xffB8BDC3);
  static const _chipText = Color(0xff6D6D6D);
  static const _chipSelectedFill = Color(0xffE8F5FC);

  @override
  void initState() {
    super.initState();
    _bloc = sl<TpollSearchBloc>();
    _bloc.add(TpollSearchFetchEvent(searchId: widget.searchId));
    CurrencyConverter.currencyListenable.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    CurrencyConverter.currencyListenable.removeListener(_onCurrencyChanged);
    _bloc.close();
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  // ── price formatting (converted to the user's preferred currency) ─────────
  String _getFormattedPrice(SearchResultEntity result) {
    final preferredCurrency = sl<PreferencesManager>().getPreferredCurrency() ?? 'USD';
    final originalAmount = double.tryParse(result.totalPriceAmount) ?? 0.0;

    if (result.totalPriceCurrency == preferredCurrency) {
      return CurrencyConverter.format(originalAmount, preferredCurrency);
    }
    final converted = CurrencyConverter.convert(
      amount: originalAmount,
      fromCurrency: result.totalPriceCurrency,
      toCurrency: preferredCurrency,
    );
    return CurrencyConverter.format(converted, preferredCurrency);
  }

  Map<String, String> _getFormattedAmenityPrices(SearchResultEntity result) {
    final preferredCurrency = sl<PreferencesManager>().getPreferredCurrency() ?? 'USD';
    final formattedPrices = <String, String>{};

    for (final amenity in result.amenities) {
      if (amenity.price == null || amenity.price!.value.isEmpty) continue;
      final amount = double.tryParse(amenity.price!.value) ?? 0.0;
      final converted = result.totalPriceCurrency == preferredCurrency
          ? amount
          : CurrencyConverter.convert(
              amount: amount,
              fromCurrency: result.totalPriceCurrency,
              toCurrency: preferredCurrency,
            );
      final text = CurrencyConverter.format(converted, preferredCurrency);
      formattedPrices[amenity.key] = text;
      formattedPrices[amenity.name] = text;
    }
    return formattedPrices;
  }

  // ─────────────────────────────────────────────────────────────────── BUILD
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<TpollSearchBloc, TpollSearchState>(
            builder: (context, state) {
              final searchData =
                  state is TpollSearchSuccess ? state.tpollSearchEntity.search : null;
              return Column(
                children: [
                  _buildHeader(context, searchData),
                  Expanded(child: _buildBody(context, state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TpollSearchState state) {
    if (state is TpollSearchLoading || state is TpollSearchInitial) {
      return const TransportLoadingIndicator();
    } else if (state is TpollSearchSuccess) {
      return _buildSuccessBody(context, state);
    } else if (state is TpollSearchFailure) {
      return _buildErrorView(context, state);
    }
    return const SizedBox.shrink();
  }

  // ── Header card: back · route + pickup time · edit ────────────────────────
  Widget _buildHeader(BuildContext context, SearchDataEntity? searchData) {
    String place(LocationInfoEntity? loc, String fallback) {
      if (loc != null && loc.city.isNotEmpty) return loc.city;
      return fallback;
    }

    final from = place(searchData?.startLocation, widget.startAddress);
    final to = place(searchData?.endLocation, widget.endAddress);
    final title = [from, to].where((s) => s.isNotEmpty).join(' to ');

    // The API's pickup_datetime is a wall-clock time; format it as given.
    final apiPickup = DateTime.tryParse(searchData?.pickupDatetime ?? '');
    final subtitle = apiPickup != null
        ? DateFormat('d MMM, h:mm a').format(apiPickup)
        : DateFormat('d MMM').format(widget.pickupDate);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.w(16), context.h(8), context.w(16), context.h(0)),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(10)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(color: const Color(0xffCCCCCC)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.arrow_back_rounded,
                  size: context.w(22), color: AppColors.subhead),
            ),
            SizedBox(width: context.w(16)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(8),
                      fontWeight: FontWeight.w500,
                      color: AppColors.subhead,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.w(8)),
            GestureDetector(
              onTap: () => _openEditSearch(searchData),
              behavior: HitTestBehavior.opaque,
              child: Image.asset(
                'assets/NewIcons/edit.png',
                width: context.w(18),
                height: context.w(18),
                color: AppColors.AppBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditSearch(SearchDataEntity? searchData) {
    final apiPickup = DateTime.tryParse(searchData?.pickupDatetime ?? '');
    final pickupTime = widget.pickupTime ??
        (apiPickup != null
            ? TimeOfDay(hour: apiPickup.hour, minute: apiPickup.minute)
            : const TimeOfDay(hour: 9, minute: 0));

    showTpollEditSearchDrawer(
      context,
      isOneWay: widget.isOneWay,
      pickupDate: widget.pickupDate,
      pickupTime: pickupTime,
      returnDate: widget.returnDate,
      returnTime: widget.returnTime,
      passengers: widget.numPassengers,
    );
  }

  // ── Results: quick-filter chips + list + floating Sort | Filter pill ──────
  Widget _buildSuccessBody(BuildContext context, TpollSearchSuccess state) {
    final searchData = state.tpollSearchEntity.search;
    final allResults = searchData.results;

    // The supplier is still searching and nothing has arrived yet — the bloc
    // keeps polling, so show the searching animation, not "No rides found".
    if (allResults.isEmpty && searchData.moreComing) {
      return const TransportLoadingIndicator();
    }

    final filteredResults = _applyFilters(allResults);
    final chips = _quickChips(allResults);

    return Stack(
      children: [
        Column(
          children: [
            if (chips.isNotEmpty) _buildChipRow(context, chips),
            Expanded(
              child: filteredResults.isEmpty
                  ? _buildEmptyView(noRidesAtAll: allResults.isEmpty)
                  : RefreshIndicator(
                      color: AppColors.OrangeColor,
                      onRefresh: () async {
                        _bloc.add(TpollSearchRefreshEvent(searchId: widget.searchId));
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          context.w(16),
                          context.h(22),
                          context.w(16),
                          // room so the last card clears the floating pill
                          context.h(100),
                        ),
                        itemCount: filteredResults.length + (searchData.moreComing ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredResults.length) {
                            return _buildMoreComingHint(context);
                          }
                          final result = filteredResults[index];
                          return TpollVehicleCard(
                            searchId: widget.searchId,
                            result: result,
                            currencySymbol: searchData.currencyInfo.prefixSymbol,
                            currencyCode: searchData.currencyInfo.code,
                            onTap: () => _handleBooking(context, result),
                            formattedPrice: _getFormattedPrice(result),
                            formattedAmenityPrices: _getFormattedAmenityPrices(result),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildActionPill(context, allResults),
        ),
      ],
    );
  }

  /// Chip labels come straight from the results: vehicle types first (most
  /// common first), then vehicle make/model names.
  List<String> _quickChips(List<SearchResultEntity> results) {
    final typeCounts = <String, int>{};
    final makes = <String>[];
    for (final r in results) {
      if (r.vehicleType.isNotEmpty) {
        typeCounts[r.vehicleType] = (typeCounts[r.vehicleType] ?? 0) + 1;
      }
      final make = _makeModel(r);
      if (make.isNotEmpty && !makes.contains(make)) makes.add(make);
    }
    final types = typeCounts.keys.toList()
      ..sort((a, b) => typeCounts[b]!.compareTo(typeCounts[a]!));
    return [...types, ...makes.where((m) => !types.contains(m))];
  }

  String _makeModel(SearchResultEntity r) => [r.vehicleMake, r.vehicleModel]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' ');

  Widget _buildChipRow(BuildContext context, List<String> chips) {
    return Padding(
      padding: EdgeInsets.only(top: context.h(22)),
      child: SizedBox(
        height: context.h(24),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          itemCount: chips.length + 1, // + the leading "All" chip
          separatorBuilder: (_, __) => SizedBox(width: context.w(11)),
          itemBuilder: (context, i) {
            final isAll = i == 0;
            final label = isAll ? 'All' : chips[i - 1];
            final selected = isAll ? _quickChip == null : _quickChip == label;
            return GestureDetector(
              onTap: () => setState(() => _quickChip = isAll ? null : label),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: context.w(9)),
                decoration: BoxDecoration(
                  color: selected ? _chipSelectedFill : AppColors.white,
                  borderRadius: BorderRadius.circular(context.r(6)),
                  border: Border.all(
                    color: selected ? AppColors.AppBlue : _chipBorder,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: selected ? AppColors.AppBlue : _chipText,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoreComingHint(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: context.w(12),
            height: context.w(12),
            child: const CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.OrangeColor),
          ),
          SizedBox(width: context.w(8)),
          Text(
            'Looking for more rides…',
            style: TextStyle(fontSize: context.fs(10), color: AppColors.subhead),
          ),
        ],
      ),
    );
  }

  // ── Floating Sort | Filter pill (same style as the flight results bar) ────
  Widget _buildActionPill(BuildContext context, List<SearchResultEntity> all) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: context.h(24)),
        child: Center(
          child: Container(
            width: context.w(190),
            height: context.h(42),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(context.r(30)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff2B3A67).withValues(alpha: 0.18),
                  blurRadius: context.w(15),
                  offset: Offset(0, context.h(4)),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _pillButton(
                    context,
                    iconPath: 'assets/NewIcons/sort.png',
                    label: 'Sort',
                    onTap: _openSortSheet,
                  ),
                ),
                Container(
                  width: 1,
                  height: context.h(24),
                  color: const Color(0xffE6E6E6),
                ),
                Expanded(
                  child: _pillButton(
                    context,
                    iconPath: 'assets/NewIcons/filter.png',
                    label: 'Filter',
                    active: _filters.hasActiveFilters,
                    onTap: () => _openFilterScreen(all),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillButton(
    BuildContext context, {
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final color = active ? AppColors.AppBlue : AppColors.black;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath,
              width: context.w(16), height: context.w(16), color: color),
          SizedBox(width: context.w(8)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterScreen(List<SearchResultEntity> all) async {
    final result = await Navigator.of(context).push<TpollFilterState>(
      MaterialPageRoute(
        builder: (_) => TpollFilterScreen(
          results: all,
          currentFilters: _filters,
        ),
      ),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  void _openSortSheet() {
    // Pending choice: the list only re-sorts on DONE; RESET goes back to the
    // default (Popularity). Same behaviour as the flight Sort sheet.
    String pending = _filters.sortBy;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close — floating just above the sheet, top right.
                Padding(
                  padding: EdgeInsets.only(
                      right: context.w(16), bottom: context.h(10)),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: Container(
                        width: context.w(34),
                        height: context.w(34),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.close_rounded,
                            size: context.w(19), color: AppColors.black),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(context.r(20))),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            margin: EdgeInsets.only(
                                top: context.h(10), bottom: context.h(4)),
                            width: context.w(100),
                            height: context.h(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1D1D6),
                              borderRadius:
                                  BorderRadius.circular(context.r(24)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(context.w(16),
                              context.h(14), context.w(20), context.h(6)),
                          child: Text(
                            'Sort by',
                            style: TextStyle(
                              fontSize: context.fs(12),
                              fontWeight: FontWeight.w500,
                              color: AppColors.subhead,
                            ),
                          ),
                        ),
                        for (final opt in TpollFilterState.sheetSortOptions)
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: context.w(16),
                                vertical: context.h(1)),
                            title: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: context.fs(16),
                                fontWeight: FontWeight.w500,
                                color: AppColors.black,
                              ),
                            ),
                            trailing: _sortRadio(pending == opt.value),
                            onTap: () =>
                                setSheetState(() => pending = opt.value),
                          ),
                        SizedBox(height: context.h(3)),
                        SheetActionButtons(
                          onSecondary: () => setSheetState(
                              () => pending = TpollFilterState.sortPopular),
                          onPrimary: () {
                            setState(() =>
                                _filters = _filters.copyWith(sortBy: pending));
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      ],
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

  Widget _sortRadio(bool selected) {
    return SizedBox(
      width: context.w(18),
      height: context.w(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.AppBlue : const Color(0xffCCCCCC),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: context.w(9),
                  height: context.w(9),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.AppBlue,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // ── Empty / error states ──────────────────────────────────────────────────
  Widget _buildEmptyView({bool noRidesAtAll = false}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.wp(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: context.iconLarge * 2,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: context.hp(2)),
            Text(
              'No rides found',
              style: TextStyle(
                fontSize: context.titleLarge,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              noRidesAtAll
                  ? 'No providers have rides for this trip. Try different locations or another date.'
                  : 'Try changing your filters or search criteria',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade500,
              ),
            ),
            if (!noRidesAtAll) SizedBox(height: context.hp(3)),
            if (!noRidesAtAll)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _filters = const TpollFilterState();
                _quickChip = null;
              }),
              icon: Icon(Icons.refresh, size: context.iconSmall),
              label: Text('Clear Filters',
                  style: TextStyle(fontSize: context.bodyMedium)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.AppBlue,
                side: const BorderSide(color: AppColors.AppBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(4),
                  vertical: context.hp(1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, TpollSearchFailure state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.wp(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: context.iconLarge * 2,
              color: Colors.red.shade300,
            ),
            SizedBox(height: context.hp(2)),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: context.titleLarge,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              state.error.message ?? 'Please try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: context.hp(3)),
            ElevatedButton.icon(
              onPressed: () {
                _bloc.add(TpollSearchRefreshEvent(searchId: widget.searchId));
              },
              icon: Icon(Icons.refresh, size: context.iconMedium),
              label: Text('Retry', style: TextStyle(fontSize: context.bodyLarge)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.OrangeColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(8),
                  vertical: context.hp(1.8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filtering & sorting ───────────────────────────────────────────────────
  double _price(SearchResultEntity r) => double.tryParse(r.totalPriceAmount) ?? 0;

  List<SearchResultEntity> _applyFilters(List<SearchResultEntity> results) {
    // Copy first: sorting below must never reorder the bloc's own list.
    var filtered = List<SearchResultEntity>.of(results);

    if (_quickChip != null) {
      filtered = filtered
          .where((r) => r.vehicleType == _quickChip || _makeModel(r) == _quickChip)
          .toList();
    }

    if (_filters.selectedVehicleTypes.isNotEmpty) {
      filtered = filtered
          .where((r) => _filters.selectedVehicleTypes.contains(r.vehicleType))
          .toList();
    }

    // Amenities: a result must offer ALL selected amenities.
    if (_filters.selectedAmenities.isNotEmpty) {
      filtered = filtered.where((r) {
        final names = r.amenities.map((a) => a.name).toSet();
        return _filters.selectedAmenities.every(names.contains);
      }).toList();
    }

    if (_filters.minPassengers != null) {
      filtered = filtered
          .where((r) => r.maxPassengers >= _filters.minPassengers!)
          .toList();
    }

    if (_filters.maxPrice != null) {
      filtered = filtered.where((r) => _price(r) <= _filters.maxPrice!).toList();
    }

    switch (_filters.sortBy) {
      case TpollFilterState.sortPriceLow:
        filtered.sort((a, b) => _price(a).compareTo(_price(b)));
        break;
      case TpollFilterState.sortPriceHigh:
        filtered.sort((a, b) => _price(b).compareTo(_price(a)));
        break;
      case TpollFilterState.sortCapacity:
        filtered.sort((a, b) => b.maxPassengers.compareTo(a.maxPassengers));
        break;
      case TpollFilterState.sortRating:
        // Highest provider rating first, then most reviews, then cheapest.
        // Results with no rating sort after rated ones.
        filtered.sort((a, b) {
          final byRating =
              (b.rating?.toDouble() ?? -1).compareTo(a.rating?.toDouble() ?? -1);
          if (byRating != 0) return byRating;
          final byCount = (b.ratingCount ?? 0).compareTo(a.ratingCount ?? 0);
          if (byCount != 0) return byCount;
          return _price(a).compareTo(_price(b));
        });
        break;
      case TpollFilterState.sortPopular:
      default:
        // Popularity = most-reviewed first (a proxy for how often the
        // supplier is booked), then rating, then cheapest.
        filtered.sort((a, b) {
          final byCount = (b.ratingCount ?? 0).compareTo(a.ratingCount ?? 0);
          if (byCount != 0) return byCount;
          final byRating =
              (b.rating?.toDouble() ?? -1).compareTo(a.rating?.toDouble() ?? -1);
          if (byRating != 0) return byRating;
          return _price(a).compareTo(_price(b));
        });
    }

    return filtered;
  }

  void _handleBooking(BuildContext context, SearchResultEntity result) {
    final currentState = _bloc.state;

    if (currentState is TpollSearchSuccess) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TPollBookingScreen(
            result: result,
            searchId: widget.searchId,
            resultId: result.resultId,
            searchData: currentState.tpollSearchEntity.search,
            startAddress: widget.startAddress,
            endAddress: widget.endAddress,
            pickupDate: widget.pickupDate,
            isOneWay: widget.isOneWay,
            returnDate: widget.returnDate,
            returnTime: widget.returnTime,
            isOutstation: widget.isOutstation,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load booking details. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
