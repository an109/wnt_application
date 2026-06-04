import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../../injection_container.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../home/flight/flight_screen.dart';
import '../../data/models/tripModel.dart';
import '../bloc/upcomingTrip_bloc.dart';
import '../bloc/upcomingTrip_event.dart';
import '../bloc/upcomingTrip_state.dart';


class UpcomingTripsScreen extends StatefulWidget {
  const UpcomingTripsScreen({super.key});

  @override
  State<UpcomingTripsScreen> createState() => _UpcomingTripsScreenState();
}

class _UpcomingTripsScreenState extends State<UpcomingTripsScreen> {
  late final UpcomingTripBloc _bloc;
  final TextEditingController _searchController = TextEditingController();

  int _selectedFilterIndex = 0;
  String _searchQuery = '';
  List<TripItem> _allTrips = [];
  String _currentCurrency = 'USD';

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.handshake_outlined},
    {'label': 'Flight', 'icon': Icons.flight_takeoff},
    {'label': 'Hotel', 'icon': Icons.hotel},
    {'label': 'Transport', 'icon': Icons.directions_car},
    {'label': 'Visa', 'icon': Icons.card_membership},
    {'label': 'Holidays', 'icon': Icons.beach_access},
  ];

  @override
  void initState() {
    super.initState();
    _bloc = sl<UpcomingTripBloc>();

    // Get preferred currency
    _currentCurrency = CurrencyConverter.getPreferredCurrency();

    final prefs = sl<PreferencesManager>();
    final userData = prefs.getUserData();
    final userEmail = userData?['email'] as String? ?? '';

    if (userEmail.isNotEmpty) {
      _bloc.add(FetchUpcomingTrips(userEmail: userEmail));
    }

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _onFilterTap(int index) {
    setState(() {
      _selectedFilterIndex = index;
    });
  }

  List<TripItem> _getFilteredTrips() {
    List<TripItem> filtered = List.from(_allTrips);

    final selectedCategory = _categories[_selectedFilterIndex]['label'] as String;
    if (selectedCategory != 'All') {
      filtered = filtered
          .where((trip) =>
      trip.category.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((trip) {
        return trip.destination.toLowerCase().contains(query) ||
            trip.type.toLowerCase().contains(query) ||
            trip.refId.toLowerCase().contains(query) ||
            trip.status.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildHeaderSection(),
            Expanded(
              child: BlocBuilder<UpcomingTripBloc, UpcomingTripState>(
                bloc: _bloc,
                builder: (context, state) {
                  if (state is UpcomingTripInitial ||
                      state is UpcomingTripLoading) {
                    return _buildLoadingState();
                  }

                  if (state is UpcomingTripError) {
                    return _buildErrorState(state.error.message ?? 'Something went wrong');
                  }

                  if (state is UpcomingTripLoaded) {
                    _allTrips = state.trips
                        .map((entity) => TripItem.fromEntity(entity))
                        .toList();

                    final filteredTrips = _getFilteredTrips();
                    final selectedCategory =
                    _categories[_selectedFilterIndex]['label'] as String;

                    if (selectedCategory != 'All' &&
                        selectedCategory != 'Visa') {
                      return _buildEmptyState(
                        title: 'No $selectedCategory bookings',
                        subtitle:
                        'Your $selectedCategory bookings will appear here.',
                      );
                    }

                    if (filteredTrips.isEmpty) {
                      if (_searchQuery.isNotEmpty) {
                        return _buildEmptyState(
                          title: 'No results found',
                          subtitle:
                          'Try a different search term for "$_searchQuery".',
                        );
                      }
                      return _buildEmptyState(
                        title: "Looks like empty, you've no bookings.",
                        subtitle:
                        'Try using search to find the perfect place for you.',
                      );
                    }

                    return _buildTripList(filteredTrips);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, size: context.w(18), color: Colors.grey[700]),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Icon(Icons.account_circle_outlined,
              color: Colors.grey[600], size: context.w(22)),
          SizedBox(width: context.w(8)),
          Text(
            'My Account',
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: context.fs(13),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(6)),
            child: Text('>',
                style: TextStyle(color: Colors.grey[500], fontSize: context.fs(13))),
          ),
          Text(
            'Upcoming Trips',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: context.fs(15),
            ),
          ),
        ],
      ),
      actions: [
        // Currency indicator
        Container(
          margin: EdgeInsets.only(right: context.w(12)),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(10),
            vertical: context.h(5),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F),
            borderRadius: BorderRadius.circular(context.r(6)),
          ),
          child: Text(
            _currentCurrency,
            style: TextStyle(
              color: Colors.white,
              fontSize: context.fs(11),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEBF4FF), Color(0xFFFCE4EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: context.h(12)),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            child: Container(
              height: context.h(42),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(width: context.w(12)),
                  Icon(Icons.search, color: Colors.grey[500], size: context.w(20)),
                  SizedBox(width: context.w(8)),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: context.fs(14)),
                      decoration: InputDecoration(
                        hintText: 'Search by destination, type, or ref...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: context.fs(13),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: context.h(12),
                        ),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, size: context.w(18), color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: context.h(14)),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'SORT BY',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: context.fs(11),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: context.w(8)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(6),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.r(8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Travel Date',
                        style: TextStyle(fontSize: context.fs(12)),
                      ),
                      SizedBox(width: context.w(4)),
                      Icon(Icons.arrow_drop_down,
                          size: context.w(16), color: Colors.grey[700]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.h(12)),

          SizedBox(
            height: context.h(82),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: context.w(10)),
              itemBuilder: (context, index) {
                final bool isSelected = _selectedFilterIndex == index;
                final category = _categories[index];

                return GestureDetector(
                  onTap: () => _onFilterTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: context.w(70),
                    margin: EdgeInsets.symmetric(horizontal: context.w(3)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: context.w(52),
                          height: context.w(52),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                                : [],
                          ),
                          child: Icon(
                            category['icon'] as IconData,
                            color: isSelected
                                ? const Color(0xFFD32F2F)
                                : Colors.grey[600],
                            size: context.w(24),
                          ),
                        ),
                        SizedBox(height: context.h(6)),
                        Text(
                          category['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFD32F2F)
                                : Colors.grey[700],
                            fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: context.fs(11),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: context.h(10)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: context.w(48),
            height: context.w(48),
            child: const CircularProgressIndicator(
              color: Color(0xFFD32F2F),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: context.h(16)),
          Text(
            'Loading your trips...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: context.fs(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: context.w(70), color: Colors.red[300]),
            SizedBox(height: context.h(16)),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: context.fs(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(8)),
            Text(
              message,
              style: TextStyle(fontSize: context.fs(13), color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(24)),
            ElevatedButton.icon(
              onPressed: _retryFetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(24),
                  vertical: context.h(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              icon: Icon(Icons.refresh, size: context.w(18)),
              label: Text(
                'RETRY',
                style: TextStyle(
                  fontSize: context.fs(13),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retryFetch() {
    final prefs = sl<PreferencesManager>();
    final userData = prefs.getUserData();
    final userEmail = userData?['email'] as String? ?? '';
    if (userEmail.isNotEmpty) {
      _bloc.add(FetchUpcomingTrips(userEmail: userEmail));
    }
  }

  Widget _buildTripList(List<TripItem> trips) {
    return ListView.builder(
      padding: EdgeInsets.all(context.w(16)),
      physics: const BouncingScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(trips[index]);
      },
    );
  }

  Widget _buildTripCard(TripItem trip) {
    return Container(
      margin: EdgeInsets.only(bottom: context.h(14)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(3),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
                child: Text(
                  'Ref: ${trip.refId}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  '${trip.destination} — ${trip.type}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: context.fs(14),
                    color: Colors.grey[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(8)),

          Row(
            children: [
              Icon(Icons.person_outline,
                  size: context.w(14), color: Colors.blueGrey[400]),
              SizedBox(width: context.w(4)),
              Text(
                '${trip.applicantCount} applicant(s)',
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: context.fs(12),
                ),
              ),
              SizedBox(width: context.w(8)),
              Container(
                width: context.w(4),
                height: context.w(4),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.w(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(trip.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Text(
                  trip.status,
                  style: TextStyle(
                    color: _getStatusColor(trip.status),
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(12)),
          Divider(color: Colors.grey[200], thickness: context.h(1)),
          SizedBox(height: context.h(10)),

          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: context.w(13), color: Colors.grey[500]),
              SizedBox(width: context.w(6)),
              Text(
                'Booked: ${trip.bookedDate}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: context.fs(12),
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(10)),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total (${_currentCurrency})',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: context.fs(11),
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      trip.getFormattedPrice(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.fs(17),
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ),

              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD32F2F)),
                  foregroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(6)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(6),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: context.fs(12)),
                ),
              ),

              SizedBox(width: context.w(8)),

              ElevatedButton(
                onPressed: () {
                  // Navigate to details
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(6)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(6),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                ),
                child: Text(
                  'View details',
                  style: TextStyle(fontSize: context.fs(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: context.w(100),
              height: context.w(100),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: context.w(50),
                color: Colors.grey[350],
              ),
            ),
            SizedBox(height: context.h(24)),
            Text(
              title,
              style: TextStyle(
                fontSize: context.fs(17),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(8)),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: context.fs(13),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(32)),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => FlightScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(28),
                  vertical: context.h(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                elevation: 0,
              ),
              child: Text(
                'PLAN A TRIP',
                style: TextStyle(
                  letterSpacing: 1,
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending')) return Colors.orange;
    if (s.contains('confirm')) return Colors.green;
    if (s.contains('cancel')) return Colors.red;
    if (s.contains('process')) return Colors.blue;
    if (s.contains('complet')) return Colors.teal;
    return Colors.grey;
  }
}