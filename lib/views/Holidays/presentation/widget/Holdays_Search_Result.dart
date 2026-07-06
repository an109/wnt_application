import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../injection_container.dart';
import '../../../Holiday_destination/domain/entities/holiday_destination_entity.dart';
import '../../../Holiday_destination/presentation/bloc/holiday_destination_bloc.dart';
import '../../../Holiday_destination/presentation/bloc/holiday_destination_event.dart';
import '../../../Holiday_destination/presentation/bloc/holiday_destination_state.dart';
import '../screen/holiday_package_details_screen.dart';

const Color _kAccent = Color(0xffFF3B3B);
const Color _kInk = Color(0xff1A1A2E);

class HolidayResultsScreen extends StatefulWidget {
  final String? fromCity;
  final HolidayDestinationEntity? destination;
  final DateTime? departureDate;
  final int adults;
  final int children;
  final int Infants;
  final String packageType;

  const HolidayResultsScreen({
    super.key,
    this.fromCity,
    this.destination,
    this.departureDate,
    this.adults = 2,
    this.children = 0,
    this.Infants = 1,
    this.packageType = "With Flight",
  });

  @override
  State<HolidayResultsScreen> createState() => _HolidayResultsScreenState();
}

class _HolidayResultsScreenState extends State<HolidayResultsScreen> {
  static const List<String> _sortOptions = [
    "Recommended",
    "Price: Low to High",
    "Price: High to Low",
    "Duration: Short to Long",
    "Duration: Long to Short",
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  HolidayBloc? _bloc;
  StreamSubscription<HolidayState>? _subscription;

  List<Map<String, dynamic>> _allPackages = [];
  List<Map<String, dynamic>> _visiblePackages = [];

  bool _isLoading = true;
  String? _error;

  String _sortBy = _sortOptions.first;
  String _selectedCategory = "All";
  RangeValues _priceBounds = const RangeValues(0, 0);
  RangeValues? _selectedPriceRange;

  // Filter-drawer facets — all populated from the live package data, never static.
  final Set<String> _selectedFlightTypes = {};
  final Set<String> _selectedHolidayTypes = {};
  final Set<String> _selectedDurationNights = {};
  final Set<String> _selectedCountries = {};
  final Set<String> _selectedCities = {};

  String _currency = 'INR';

  int get _travellersCount => (widget.adults + widget.children).clamp(1, 999);

  @override
  void initState() {
    super.initState();
    _currency = CurrencyConverter.getPreferredCurrency();
    _resolvePreferredCurrency();

    final destination = widget.destination;
    if (destination != null) {
      // Already fetched by the search card — no extra network round-trip needed.
      debugPrint(
        'HolidayResultsScreen: using pre-fetched destination "${destination.name}" '
        'with ${destination.packages.length} package(s)',
      );
      _setPackages(List<Map<String, dynamic>>.from(destination.packages));
      _isLoading = false;
    } else {
      _bloc = sl<HolidayBloc>();
      _subscription = _bloc!.stream.listen(_onBlocState);
      _bloc!.add(const GetPopularDestinationsEvent());
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bloc?.close();
    super.dispose();
  }

  Future<void> _resolvePreferredCurrency() async {
    await ExchangeRateService.initializeUserCurrency();
    if (!mounted) return;
    final resolved = CurrencyConverter.getPreferredCurrency();
    if (resolved != _currency) {
      setState(() => _currency = resolved);
    }
  }

  void _onBlocState(HolidayState state) {
    if (!mounted) return;
    if (state is HolidayLoadingState) {
      setState(() => _isLoading = true);
    } else if (state is HolidaySuccessState) {
      final packages = <Map<String, dynamic>>[];
      for (final destination in state.destinations) {
        for (final pkg in destination.packages) {
          packages.add({...pkg, '_destinationName': destination.name});
        }
      }
      setState(() {
        _isLoading = false;
        _error = null;
        _setPackages(packages);
      });
    } else if (state is HolidayErrorState) {
      setState(() {
        _isLoading = false;
        _error = state.error;
      });
    }
  }

  // ---------------------------------------------------------------------
  // Data helpers — everything reads straight from the API package map.
  // ---------------------------------------------------------------------

  void _setPackages(List<Map<String, dynamic>> packages) {
    _allPackages = packages;
    final prices = packages.map((p) => _convert(_priceOf(p))).toList();
    if (prices.isEmpty) {
      _priceBounds = const RangeValues(0, 0);
    } else {
      final min = prices.reduce((a, b) => a < b ? a : b).floorToDouble();
      final max = prices.reduce((a, b) => a > b ? a : b).ceilToDouble();
      _priceBounds = RangeValues(min, max < min ? min : max);
    }
    _selectedPriceRange = _priceBounds;
    _applyFilters();
  }

  double _priceOf(Map<String, dynamic> pkg) =>
      double.tryParse('${pkg['package_price'] ?? 0}') ?? 0;

  double? _originalPriceOf(Map<String, dynamic> pkg) {
    final raw = pkg['original_price'];
    if (raw == null) return null;
    final parsed = double.tryParse('$raw');
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  List<String> _themesOf(Map<String, dynamic> pkg) =>
      (pkg['holiday_themes'] as List?)?.map((e) => e.toString()).toList() ?? const [];

  String _durationLabel(Map<String, dynamic> pkg) {
    final nights = pkg['nights'] ?? 0;
    final days = pkg['days'] ?? 0;
    return '${nights}N / ${days}D';
  }

  String _locationOf(Map<String, dynamic> pkg) {
    final parts = [pkg['city'], pkg['state'], pkg['country']]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.take(2).join(', ');
    return (pkg['_destinationName'] as String?) ?? '';
  }

  List<String> _highlightsOf(Map<String, dynamic> pkg) {
    final raw = pkg['highlights'] as String?;
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(3).toList();
  }

  double _convert(double amountInInr) {
    if (_currency.toUpperCase() == 'INR') return amountInInr;
    return CurrencyConverter.convert(amount: amountInInr, fromCurrency: 'INR', toCurrency: _currency);
  }

  String _formatPrice(double amountInInr) => CurrencyConverter.format(_convert(amountInInr), _currency);

  List<String> get _categories {
    final set = <String>{'All'};
    for (final pkg in _allPackages) {
      if (pkg['is_wander_nova_choice'] == true) set.add('WanderNova Choice');
      set.addAll(_themesOf(pkg));
    }
    return set.toList();
  }

  int _countWithFlight(List<Map<String, dynamic>> pkgs) => pkgs.where((p) {
        final variant = (p['package_variant'] as String?)?.toLowerCase() ?? '';
        return variant == 'both' || variant == 'with_flight';
      }).length;

  int _countWithoutFlight(List<Map<String, dynamic>> pkgs) => pkgs.where((p) {
        final variant = (p['package_variant'] as String?)?.toLowerCase() ?? '';
        return variant == 'both' || variant == 'without_flight';
      }).length;

  /// Distinct values of a string field across all packages, each with how
  /// many packages carry it — used for the Country/City facets.
  List<MapEntry<String, int>> _countedOptions(String Function(Map<String, dynamic>) keyOf) {
    final counts = <String, int>{};
    for (final pkg in _allPackages) {
      final key = keyOf(pkg).trim();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  List<MapEntry<String, int>> _holidayTypeCounts() {
    final counts = <String, int>{};
    for (final pkg in _allPackages) {
      for (final theme in _themesOf(pkg)) {
        counts[theme] = (counts[theme] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  List<MapEntry<String, int>> _durationNightCounts() {
    final counts = <String, int>{};
    for (final pkg in _allPackages) {
      final nights = pkg['nights'];
      if (nights == null) continue;
      final label = '${nights}N';
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final an = int.tryParse(a.key.replaceAll('N', '')) ?? 0;
        final bn = int.tryParse(b.key.replaceAll('N', '')) ?? 0;
        return an.compareTo(bn);
      });
    return entries;
  }

  bool get _hasActiveFilters =>
      _selectedFlightTypes.isNotEmpty ||
      _selectedHolidayTypes.isNotEmpty ||
      _selectedDurationNights.isNotEmpty ||
      _selectedCountries.isNotEmpty ||
      _selectedCities.isNotEmpty ||
      (_selectedPriceRange != null && _selectedPriceRange != _priceBounds);

  /// Flattened list of every active drawer filter, each removable individually
  /// — backs the "Applied filters" chip row at the top of the drawer.
  List<_ActiveFilter> get _activeFilters {
    final chips = <_ActiveFilter>[];
    for (final f in _selectedFlightTypes) {
      chips.add(_ActiveFilter(f, () => setState(() {
            _selectedFlightTypes.remove(f);
            _applyFilters();
          })));
    }
    for (final h in _selectedHolidayTypes) {
      chips.add(_ActiveFilter(h, () => setState(() {
            _selectedHolidayTypes.remove(h);
            _applyFilters();
          })));
    }
    for (final d in _selectedDurationNights) {
      chips.add(_ActiveFilter(d, () => setState(() {
            _selectedDurationNights.remove(d);
            _applyFilters();
          })));
    }
    for (final c in _selectedCountries) {
      chips.add(_ActiveFilter(c, () => setState(() {
            _selectedCountries.remove(c);
            _applyFilters();
          })));
    }
    for (final city in _selectedCities) {
      chips.add(_ActiveFilter(city, () => setState(() {
            _selectedCities.remove(city);
            _applyFilters();
          })));
    }
    final range = _selectedPriceRange;
    if (range != null && range != _priceBounds) {
      chips.add(_ActiveFilter(
        '${CurrencyConverter.format(range.start, _currency)} - ${CurrencyConverter.format(range.end, _currency)}',
        () => setState(() {
          _selectedPriceRange = _priceBounds;
          _applyFilters();
        }),
      ));
    }
    return chips;
  }

  void _clearAllDrawerFilters() {
    setState(() {
      _selectedFlightTypes.clear();
      _selectedHolidayTypes.clear();
      _selectedDurationNights.clear();
      _selectedCountries.clear();
      _selectedCities.clear();
      _selectedPriceRange = _priceBounds;
      _applyFilters();
    });
  }

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_allPackages);

    if (_selectedCategory == 'WanderNova Choice') {
      list = list.where((p) => p['is_wander_nova_choice'] == true).toList();
    } else if (_selectedCategory != 'All') {
      list = list.where((p) => _themesOf(p).contains(_selectedCategory)).toList();
    }

    if (_selectedFlightTypes.isNotEmpty) {
      list = list.where((p) {
        final variant = (p['package_variant'] as String?)?.toLowerCase() ?? '';
        final matchesWith = _selectedFlightTypes.contains('With Flight') &&
            (variant == 'both' || variant == 'with_flight');
        final matchesWithout = _selectedFlightTypes.contains('Without Flight') &&
            (variant == 'both' || variant == 'without_flight');
        return matchesWith || matchesWithout;
      }).toList();
    }

    if (_selectedHolidayTypes.isNotEmpty) {
      list = list.where((p) => _themesOf(p).any(_selectedHolidayTypes.contains)).toList();
    }

    if (_selectedDurationNights.isNotEmpty) {
      list = list.where((p) => _selectedDurationNights.contains('${p['nights'] ?? ''}N')).toList();
    }

    if (_selectedCountries.isNotEmpty) {
      list = list.where((p) => _selectedCountries.contains((p['country'] as String?) ?? '')).toList();
    }

    if (_selectedCities.isNotEmpty) {
      list = list.where((p) => _selectedCities.contains((p['city'] as String?) ?? '')).toList();
    }

    final range = _selectedPriceRange;
    if (range != null) {
      list = list.where((p) {
        final price = _convert(_priceOf(p));
        return price >= range.start && price <= range.end;
      }).toList();
    }

    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => _priceOf(b).compareTo(_priceOf(a)));
        break;
      case 'Duration: Short to Long':
        list.sort((a, b) => ((a['nights'] ?? 0) as num).compareTo((b['nights'] ?? 0) as num));
        break;
      case 'Duration: Long to Short':
        list.sort((a, b) => ((b['nights'] ?? 0) as num).compareTo((a['nights'] ?? 0) as num));
        break;
      default:
        list.sort((a, b) {
          final aChoice = a['is_wander_nova_choice'] == true ? 1 : 0;
          final bChoice = b['is_wander_nova_choice'] == true ? 1 : 0;
          return bChoice.compareTo(aChoice);
        });
    }

    _visiblePackages = list;
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      drawer: _buildFilterDrawer(),
      body: Column(
        children: [
          // _buildSearchSummaryCard(),
          // if (!_isLoading && _error == null && _allPackages.isNotEmpty) _buildCategoryChips(),
          // if (!_isLoading && _error == null && _allPackages.isNotEmpty) _buildSortBar(),
          if (!_isLoading && _error == null) _buildResultsCount(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final destName = widget.destination?.name ?? 'Holiday Packages';
    final subtitleParts = <String>[
      if (widget.departureDate != null) DateFormat('dd MMM yyyy').format(widget.departureDate!),
      '${widget.adults} Adult${widget.adults > 1 ? 's' : ''}',
      '${widget.Infants} Room${widget.Infants > 1 ? 's' : ''}',
    ];

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: _kAccent), // Changed to menu icon
        onPressed: _allPackages.isEmpty ? null : () => _scaffoldKey.currentState?.openDrawer(), // Changed to openDrawer
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            destName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            subtitleParts.join(' • '),
            style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Image.asset('assets/images/wander_logo.png'),
          onPressed: _allPackages.isEmpty ? null : () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    );
  }

  // Widget _buildSearchSummaryCard() {
  //   return Container(
  //     margin: EdgeInsets.all(context.w(12)),
  //     padding: EdgeInsets.all(context.w(14)),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(context.r(12)),
  //       boxShadow: [
  //         BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(child: _summaryTile('FROM', widget.fromCity ?? 'Anywhere')),
  //         _summaryDivider(),
  //         Expanded(child: _summaryTile('TO', widget.destination?.name ?? 'Any destination')),
  //         _summaryDivider(),
  //         Expanded(
  //           child: _summaryTile(
  //             'DATE',
  //             widget.departureDate != null ? DateFormat('dd MMM').format(widget.departureDate!) : 'Anytime',
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _summaryDivider() => Container(width: 1, height: context.h(40), color: Colors.grey.shade300);

  Widget _summaryTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5),
        ),
        SizedBox(height: context.h(2)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final categories = _categories;
    return SizedBox(
      height: context.h(46),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.w(12)),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final label = categories[index];
          final isSelected = label == _selectedCategory;
          return Padding(
            padding: EdgeInsets.only(right: context.w(10)),
            child: FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() {
                _selectedCategory = label;
                _applyFilters();
              }),
              backgroundColor: Colors.white,
              selectedColor: _kAccent,
              checkmarkColor: Colors.white,
              elevation: isSelected ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(20)),
                side: BorderSide(color: isSelected ? _kAccent : Colors.grey.shade300),
              ),
              padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(6)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(10)),
      padding: EdgeInsets.all(context.w(2)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(25)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _showSortSheet,
              borderRadius: BorderRadius.circular(context.r(23)),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(8)),
                decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(context.r(23))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sort, size: context.iconXSmall, color: Colors.white),
                    SizedBox(width: context.w(6)),
                    Text(_sortBy, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: context.w(4)),
          Expanded(
            child: InkWell(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              borderRadius: BorderRadius.circular(context.r(23)),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu, size: context.iconXSmall, color: Colors.grey.shade700),
                    SizedBox(width: context.w(6)),
                    Text('Filters', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isLoading ? 'Loading packages…' : 'Showing ${_visiblePackages.length} of ${_allPackages.length} packages',
            style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }

    if (_error != null) {
      return _buildStateMessage(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: _error!,
      );
    }

    if (_allPackages.isEmpty) {
      final hasSpecificDestination = widget.destination != null;
      return _buildStateMessage(
        icon: Icons.card_travel,
        title: 'No packages found',
        message: hasSpecificDestination
            ? '${widget.destination!.name} doesn\'t have any packages configured yet.'
            : 'Try selecting a destination from the search card.',
        actionLabel: hasSpecificDestination ? 'Browse other destinations' : null,
        onAction: hasSpecificDestination ? _browseAllDestinations : null,
      );
    }

    if (_visiblePackages.isEmpty) {
      return _buildStateMessage(
        icon: Icons.filter_alt_off_outlined,
        title: 'No matches for these filters',
        message: 'Try clearing a filter or changing your budget range.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.w(12)),
      itemCount: _visiblePackages.length,
      itemBuilder: (context, index) => _buildPackageCard(_visiblePackages[index]),
    );
  }

  /// Falls back to browsing packages across every destination — used when the
  /// destination the user picked has no packages configured yet, so the
  /// screen never dead-ends on a single empty result.
  void _browseAllDestinations() {
    if (_bloc != null) return;
    setState(() => _isLoading = true);
    _bloc = sl<HolidayBloc>();
    _subscription = _bloc!.stream.listen(_onBlocState);
    _bloc!.add(const GetPopularDestinationsEvent());
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.iconLarge, color: Colors.grey.shade400),
            SizedBox(height: context.h(12)),
            Text(title, style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: context.h(6)),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600)),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: context.h(16)),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
                  padding: EdgeInsets.symmetric(horizontal: context.w(20), vertical: context.h(10)),
                ),
                child: Text(actionLabel,
                    style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final price = _priceOf(pkg);
    final originalPrice = _originalPriceOf(pkg);
    final isChoice = pkg['is_wander_nova_choice'] == true;
    final imageUrl = (pkg['image_url'] as String?) ?? '';
    final title = (pkg['title'] as String?) ?? 'Holiday Package';
    final highlights = _highlightsOf(pkg);
    final discountPercent = (originalPrice != null && originalPrice > price)
        ? (((originalPrice - price) / originalPrice) * 100).round()
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: context.h(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(12))),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: context.h(180),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 900,
                        placeholder: (context, url) => Container(
                          height: context.h(180),
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: context.h(180),
                          color: Colors.grey.shade300,
                          child: Icon(Icons.image, size: context.iconLarge, color: Colors.grey.shade500),
                        ),
                      )
                    : Container(
                        height: context.h(180),
                        color: Colors.grey.shade300,
                        child: Icon(Icons.image, size: context.iconLarge, color: Colors.grey.shade500),
                      ),
              ),
              if (isChoice)
                Positioned(
                  top: context.h(10),
                  left: context.w(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(4)),
                    decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(context.r(4))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: context.iconXSmall, color: Colors.white),
                        SizedBox(width: context.w(4)),
                        Text('WanderNova Choice',
                            style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: context.h(10),
                right: context.w(10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.r(12))),
                  child: Text(_durationLabel(pkg),
                      style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w600, color: Colors.black87)),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(context.w(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.h(6)),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: context.iconXSmall, color: Colors.grey.shade500),
                    SizedBox(width: context.w(4)),
                    Expanded(
                      child: Text(
                        _locationOf(pkg),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                if (highlights.isNotEmpty) ...[
                  SizedBox(height: context.h(10)),
                  ...highlights.map(
                    (highlight) => Padding(
                      padding: EdgeInsets.only(bottom: context.h(4)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check, size: context.iconXSmall, color: Colors.green.shade600),
                          SizedBox(width: context.w(6)),
                          Expanded(
                            child: Text(
                              highlight,
                              style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: context.h(10)),
                Divider(color: Colors.grey.shade200, height: 1),
                SizedBox(height: context.h(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatPrice(price),
                                style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              if (discountPercent != null) ...[
                                SizedBox(width: context.w(6)),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(2)),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(context.r(4)),
                                  ),
                                  child: Text(
                                    '$discountPercent% OFF',
                                    style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text('/Person', style: TextStyle(fontSize: context.fs(10), color: Colors.grey.shade600)),
                          if (originalPrice != null)
                            Text(
                              _formatPrice(originalPrice),
                              style: TextStyle(
                                fontSize: context.fs(11),
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          SizedBox(height: context.h(2)),
                          Text(
                            'Total for $_travellersCount traveller${_travellersCount > 1 ? 's' : ''}: ${_formatPrice(price * _travellersCount)}',
                            style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HolidayPackageDetailsScreen(
                            package: pkg,
                            adults: widget.adults,
                            children: widget.children,
                            Infants: widget.Infants,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563EB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
                        padding: EdgeInsets.symmetric(horizontal: context.w(20), vertical: context.h(10)),
                      ),
                      child: Text('View Details',
                          style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Sheets
  // ---------------------------------------------------------------------

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20)))),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _sortOptions.map((option) {
              final selected = option == _sortBy;
              return ListTile(
                title: Text(option, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                trailing: selected ? const Icon(Icons.check, color: _kAccent) : null,
                onTap: () {
                  setState(() {
                    _sortBy = option;
                    _applyFilters();
                  });
                  Navigator.pop(sheetContext);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Filter drawer — replaces the old bottom sheet. Every section reads
  // straight off the live package data (counts included), never static.
  // ---------------------------------------------------------------------

  Widget _buildFilterDrawer() {
    final withFlightCount = _countWithFlight(_allPackages);
    final withoutFlightCount = _countWithoutFlight(_allPackages);
    final holidayTypeCounts = _holidayTypeCounts();
    final durationCounts = _durationNightCounts();
    final countryCounts = _countedOptions((p) => (p['country'] as String?) ?? '');
    final cityCounts = _countedOptions((p) => (p['city'] as String?) ?? '');

    return Drawer(
      width: context.wp(85),
      child: SafeArea(
        child: Column(
          children: [
            _filterDrawerHeader(),
            if (_hasActiveFilters) _appliedFiltersRow(),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(8)),
                children: [
                  _filterSectionHeader(
                    'Flights',
                    onReset: _selectedFlightTypes.isEmpty
                        ? null
                        : () => setState(() {
                              _selectedFlightTypes.clear();
                              _applyFilters();
                            }),
                  ),
                  _filterCheckboxTile(
                    label: 'With Flight ($withFlightCount)',
                    value: _selectedFlightTypes.contains('With Flight'),
                    onChanged: (v) => setState(() {
                      v! ? _selectedFlightTypes.add('With Flight') : _selectedFlightTypes.remove('With Flight');
                      _applyFilters();
                    }),
                  ),
                  _filterCheckboxTile(
                    label: 'Without Flight ($withoutFlightCount)',
                    value: _selectedFlightTypes.contains('Without Flight'),
                    onChanged: (v) => setState(() {
                      v! ? _selectedFlightTypes.add('Without Flight') : _selectedFlightTypes.remove('Without Flight');
                      _applyFilters();
                    }),
                  ),
                  SizedBox(height: context.h(20)),
                  _filterSectionHeader(
                    'Holiday Type',
                    onReset: _selectedHolidayTypes.isEmpty
                        ? null
                        : () => setState(() {
                              _selectedHolidayTypes.clear();
                              _applyFilters();
                            }),
                  ),
                  if (holidayTypeCounts.isEmpty)
                    Text('No holiday types available', style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade500))
                  else
                    ...holidayTypeCounts.map((entry) => _filterCheckboxTile(
                          label: '${entry.key} (${entry.value})',
                          value: _selectedHolidayTypes.contains(entry.key),
                          onChanged: (v) => setState(() {
                            v! ? _selectedHolidayTypes.add(entry.key) : _selectedHolidayTypes.remove(entry.key);
                            _applyFilters();
                          }),
                        )),
                  SizedBox(height: context.h(20)),
                  _filterSectionHeader(
                    'Budget',
                    onReset: (_selectedPriceRange == null || _selectedPriceRange == _priceBounds)
                        ? null
                        : () => setState(() {
                              _selectedPriceRange = _priceBounds;
                              _applyFilters();
                            }),
                  ),
                  _buildBudgetSlider(),
                  SizedBox(height: context.h(20)),
                  _filterSectionHeader(
                    'Duration',
                    onReset: _selectedDurationNights.isEmpty
                        ? null
                        : () => setState(() {
                              _selectedDurationNights.clear();
                              _applyFilters();
                            }),
                  ),
                  if (durationCounts.isEmpty)
                    Text('No durations available', style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade500))
                  else
                    Wrap(
                      spacing: context.w(8),
                      runSpacing: context.h(8),
                      children: durationCounts.map((entry) {
                        final selected = _selectedDurationNights.contains(entry.key);
                        return ChoiceChip(
                          label: Text('${entry.key} (${entry.value})', style: TextStyle(fontSize: context.fs(12))),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            selected ? _selectedDurationNights.remove(entry.key) : _selectedDurationNights.add(entry.key);
                            _applyFilters();
                          }),
                          selectedColor: _kAccent.withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: selected ? _kAccent : Colors.grey.shade800),
                          side: BorderSide(color: selected ? _kAccent : Colors.grey.shade300),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: context.h(20)),
                  _filterSectionHeader(
                    'Country',
                    onReset: _selectedCountries.isEmpty
                        ? null
                        : () => setState(() {
                              _selectedCountries.clear();
                              _applyFilters();
                            }),
                  ),
                  if (countryCounts.isEmpty)
                    Text('No countries available', style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade500))
                  else
                    ...countryCounts.map((entry) => _filterCheckboxTile(
                          label: '${entry.key} (${entry.value})',
                          value: _selectedCountries.contains(entry.key),
                          onChanged: (v) => setState(() {
                            v! ? _selectedCountries.add(entry.key) : _selectedCountries.remove(entry.key);
                            _applyFilters();
                          }),
                        )),
                  SizedBox(height: context.h(20)),
                  _filterSectionHeader(
                    'City',
                    onReset: _selectedCities.isEmpty
                        ? null
                        : () => setState(() {
                              _selectedCities.clear();
                              _applyFilters();
                            }),
                  ),
                  if (cityCounts.isEmpty)
                    Text('No cities available', style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade500))
                  else
                    ...cityCounts.map((entry) => _filterCheckboxTile(
                          label: '${entry.key} (${entry.value})',
                          value: _selectedCities.contains(entry.key),
                          onChanged: (v) => setState(() {
                            v! ? _selectedCities.add(entry.key) : _selectedCities.remove(entry.key);
                            _applyFilters();
                          }),
                        )),
                  SizedBox(height: context.h(20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDrawerHeader() {
    return Padding(
      padding: EdgeInsets.all(context.w(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.menu, size: context.iconMedium, color: _kInk),
              SizedBox(width: context.w(8)),
              Text('Filter', style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.bold, color: _kInk)),
            ],
          ),
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearAllDrawerFilters,
              child: Text('Clear', style: TextStyle(fontSize: context.fs(13), color: _kAccent, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _appliedFiltersRow() {
    return Padding(
      padding: EdgeInsets.only(left: context.w(16), right: context.w(16), bottom: context.h(12)),
      child: Wrap(
        spacing: context.w(6),
        runSpacing: context.h(6),
        children: [
          Text(
            'Applied filters',
            style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: Colors.grey.shade600),
          ),
          ..._activeFilters.map(
            (f) => Chip(
              label: Text(f.label, style: TextStyle(fontSize: context.fs(11))),
              onDeleted: f.onRemove,
              deleteIconColor: _kAccent,
              backgroundColor: _kAccent.withValues(alpha: 0.08),
              side: BorderSide(color: _kAccent.withValues(alpha: 0.3)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterSectionHeader(String title, {VoidCallback? onReset}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w700, color: _kInk)),
          if (onReset != null)
            TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Reset', style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600)),
            ),
        ],
      ),
    );
  }

  Widget _filterCheckboxTile({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(6)),
        child: Row(
          children: [
            SizedBox(
              width: context.w(20),
              height: context.w(20),
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: _kAccent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(child: Text(label, style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade800))),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSlider() {
    final range = _selectedPriceRange ?? _priceBounds;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(CurrencyConverter.format(range.start, _currency),
                style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w600, color: _kAccent)),
            Text(CurrencyConverter.format(range.end, _currency),
                style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w600, color: _kAccent)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _kAccent,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: _kAccent,
            trackHeight: context.h(4),
          ),
          child: RangeSlider(
            values: range,
            min: _priceBounds.start,
            max: _priceBounds.end > _priceBounds.start ? _priceBounds.end : _priceBounds.start + 1,
            onChanged: (values) => setState(() {
              _selectedPriceRange = values;
              _applyFilters();
            }),
          ),
        ),
      ],
    );
  }
}

/// A single active filter chip in the "Applied filters" row — carries its own
/// removal callback so tapping the chip's delete icon clears just that facet.
class _ActiveFilter {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilter(this.label, this.onRemove);
}
