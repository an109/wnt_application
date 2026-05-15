import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/TPollSearchEntity.dart';
import '../Widget/TPoll_VehicleCard.dart';
import '../Widget/TPoll_filterDrawer.dart';
import '../bloc/TPoll_SearchBloc.dart';
import '../bloc/TPoll_SearchEvent.dart';
import '../bloc/TPoll_SearchState.dart';

class TpollSearchResultsPage extends StatefulWidget {
  final String searchId;
  final String startAddress;
  final String endAddress;
  final DateTime pickupDate;
  final int numPassengers;

  const TpollSearchResultsPage({
    super.key,
    required this.searchId,
    required this.startAddress,
    required this.endAddress,
    required this.pickupDate,
    required this.numPassengers,
  });

  @override
  State<TpollSearchResultsPage> createState() => _TpollSearchResultsPageState();
}

class _TpollSearchResultsPageState extends State<TpollSearchResultsPage> {
  late TpollSearchBloc _bloc;
  String _sortBy = 'price_low';
  String? _selectedVehicleType;
  String? _selectedAmenity;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TpollFilterState _filters = const TpollFilterState();

  // Color constants matching website
  static const _primaryBlue = Color(0xff1663F7);
  static const _primaryOrange = Color(0xffF97316);
  static const _darkNavy = Color(0xff0D1B3D);
  static const _bgGray = Color(0xffF8F9FA);

  @override
  void initState() {
    super.initState();
    _bloc = sl<TpollSearchBloc>();
    _bloc.add(TpollSearchFetchEvent(searchId: widget.searchId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _bgGray,
        drawer: BlocBuilder<TpollSearchBloc, TpollSearchState>(
          // ← ADD
          builder: (context, state) {
            if (state is TpollSearchSuccess) {
              return TpollFilterDrawer(
                results: state.tpollSearchEntity.search.results,
                currentFilters: _filters,
                onApply: (newFilters) {
                  setState(() => _filters = newFilters);
                },
              );
            }
            return const SizedBox.shrink(); // drawer not ready until data loads
          },
        ),
        appBar: _buildAppBar(context),
        body: BlocBuilder<TpollSearchBloc, TpollSearchState>(
          builder: (context, state) {
            if (state is TpollSearchLoading || state is TpollSearchInitial) {
              return _buildLoadingView();
            } else if (state is TpollSearchSuccess) {
              return _buildSuccessBody(context, state);
            } else if (state is TpollSearchFailure) {
              return _buildErrorView(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,

      title: const WanderNovaLogo(scaleFactor: 0.6),
      actions: [
        // ── ADD THIS FILTER BUTTON ──
        BlocBuilder<TpollSearchBloc, TpollSearchState>(
          builder: (context, state) {
            if (state is! TpollSearchSuccess) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [

                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/images/wander_nova_logo.jpg", height: 35),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  Widget _buildSuccessBody(BuildContext context, TpollSearchSuccess state) {
    final searchData = state.tpollSearchEntity.search;
    final allResults = searchData.results;
    final filteredResults = _applyFilters(allResults);

    // Get unique vehicle types for filter
    final vehicleTypes = allResults.map((r) => r.vehicleType).toSet().toList();

    // Get unique amenity names for filter
    final allAmenities = allResults
        .expand((r) => r.amenities)
        .map((a) => a.name)
        .toSet()
        .toList();

    return Column(
      children: [
        // Route summary header
        _buildRouteHeader(context, searchData),
        // Filters + sort bar
        _buildFilterSortBar(context, vehicleTypes, allAmenities),
        // Results count bar
        _buildResultsCountBar(
          context,
          filteredResults.length,
          searchData.moreComing,
        ),
        // Results list
        Expanded(
          child: filteredResults.isEmpty
              ? _buildEmptyView()
              : RefreshIndicator(
                  color: _primaryOrange,
                  onRefresh: () async {
                    _bloc.add(
                      TpollSearchRefreshEvent(searchId: widget.searchId),
                    );
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.wp(4),
                      vertical: context.hp(2),
                    ),
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final result = filteredResults[index];
                      return TpollVehicleCard(
                        result: result,
                        currencySymbol: searchData.currencyInfo.prefixSymbol,
                        currencyCode: searchData.currencyInfo.code,
                        onTap: () => _handleBooking(context, result),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Route header: shows from → to, date, passengers
  Widget _buildRouteHeader(BuildContext context, SearchDataEntity searchData) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // From → To row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FROM',
                      style: TextStyle(
                        fontSize: context.labelSmall ?? 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.startAddress.isNotEmpty
                          ? widget.startAddress
                          : searchData.startLocation.city.isNotEmpty
                          ? searchData.startLocation.city
                          : searchData.startLocation.iataCode,
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w700,
                        color: _darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primaryOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: _primaryOrange,
                    size: 16,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TO',
                      style: TextStyle(
                        fontSize: context.labelSmall ?? 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.endAddress.isNotEmpty
                          ? widget.endAddress
                          : searchData.endLocation.city.isNotEmpty
                          ? searchData.endLocation.city
                          : searchData.endLocation.iataCode,
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w700,
                        color: _darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date + Passengers row
          Row(
            children: [
              _infoChip(
                icon: Icons.calendar_today_outlined,
                label: _formatDate(widget.pickupDate),
              ),
              SizedBox(width: context.wp(3)),
              _infoChip(
                icon: Icons.person_outline,
                label:
                    '${widget.numPassengers} Passenger${widget.numPassengers > 1 ? 's' : ''}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Horizontal scrollable vehicle type filters + sort dropdown
  Widget _buildFilterSortBar(
    BuildContext context,
    List<String> vehicleTypes,
    List<String> amenities,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.wp(4),
              vertical: context.hp(0.8),
            ),
            child: Row(
              children: [
                Text(
                  'SORT BY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(width: context.wp(3)),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _sortChip('price_low', 'Price: Low to High'),
                        _sortChip('price_high', 'Price: High to Low'),
                        _sortChip('popular', 'Top Rated'),
                        _sortChip('capacity', 'Most Capacity'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String value, String label) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check_circle, size: 13, color: _primaryBlue),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? _primaryBlue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCountBar(
    BuildContext context,
    int count,
    bool moreComing,
  ) {
    return Container(
      color: _bgGray,
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(1),
      ),
      child: Row(
        children: [
          Text(
            '$count result${count != 1 ? 's' : ''} found',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          if (moreComing) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: _primaryOrange,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'More coming...',
              style: TextStyle(
                fontSize: 12,
                color: _primaryOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _primaryOrange),
          const SizedBox(height: 16),
          Text(
            'Finding the best rides for you...',
            style: TextStyle(
              color: _darkNavy,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Searching across multiple providers',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No rides found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your filters or search criteria',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedVehicleType = null;
                  _selectedAmenity = null;
                  _sortBy = 'price_low';
                });
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                side: const BorderSide(color: _primaryBlue),
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

  Widget _buildErrorView(BuildContext context, TpollSearchFailure state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error.message ?? 'Please try again',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _bloc.add(TpollSearchRefreshEvent(searchId: widget.searchId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
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

  List<SearchResultEntity> _applyFilters(List<SearchResultEntity> results) {
    var filtered = results;

    // Vehicle type
    if (_filters.selectedVehicleType != null) {
      filtered = filtered
          .where((r) => r.vehicleType == _filters.selectedVehicleType)
          .toList();
    }

    // Amenities (must have ALL selected amenities)
    if (_filters.selectedAmenities.isNotEmpty) {
      filtered = filtered.where((r) {
        final names = r.amenities.map((a) => a.name).toSet();
        return _filters.selectedAmenities.every((a) => names.contains(a));
      }).toList();
    }

    // Min passengers
    if (_filters.minPassengers != null) {
      filtered = filtered
          .where((r) => r.maxPassengers >= _filters.minPassengers!)
          .toList();
    }

    // Price range
    if (_filters.priceRange != null) {
      filtered = filtered.where((r) {
        final price = double.tryParse(r.totalPriceAmount) ?? 0;
        return price >= _filters.priceRange!.start &&
            price <= _filters.priceRange!.end;
      }).toList();
    }

    // Sort (use drawer's sort, ignore old _sortBy)
    switch (_filters.sortBy) {
      case 'price_low':
        filtered.sort(
          (a, b) => (double.tryParse(a.totalPriceAmount) ?? 0).compareTo(
            double.tryParse(b.totalPriceAmount) ?? 0,
          ),
        );
        break;
      case 'price_high':
        filtered.sort(
          (a, b) => (double.tryParse(b.totalPriceAmount) ?? 0).compareTo(
            double.tryParse(a.totalPriceAmount) ?? 0,
          ),
        );
        break;
      case 'capacity':
        filtered.sort((a, b) => b.maxPassengers.compareTo(a.maxPassengers));
        break;
      case 'top_rated':
        filtered.sort(
          (a, b) => (b.bookable ? 1 : 0).compareTo(a.bookable ? 1 : 0),
        );
        break;
    }

    return filtered;
  }

  void _handleBooking(BuildContext context, SearchResultEntity result) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Booking ${result.vehicleType} - ${result.providerName}'),
    //     backgroundColor: _primaryOrange,
    //     behavior: SnackBarBehavior.floating,
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    //   ),
    // );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'private car':
      case 'sedan':
        return Icons.directions_car_outlined;
      case 'shared shuttle':
        return Icons.airport_shuttle_outlined;
      case 'minivan':
      case 'suv':
      case 'minivan / suv':
        return Icons.airline_seat_recline_extra_outlined;
      case 'bus':
      case 'bus / coach':
        return Icons.directions_bus_outlined;
      case 'premium':
        return Icons.star_outline;
      default:
        return Icons.directions_car_outlined;
    }
  }
}
