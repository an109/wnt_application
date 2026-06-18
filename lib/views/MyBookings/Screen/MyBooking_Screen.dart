import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/MyBookings/Hotels/domain/entity/HotelBookingEntity.dart';
import 'package:wander_nova/views/MyBookings/Transport/domain/entity/MyBooking_entity.dart';

import '../../../UI_helper/currency_converter.dart';
import '../../../common_widgets/logo.dart';
import '../../../core/resources/app_colours.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../../../core/utils/storage/shared_preference.dart';
import '../../../injection_container.dart';

import '../../Dashboard/dashboardScreen.dart';
import '../Hotels/bloc/BookingListBloc.dart';
import '../Hotels/bloc/BookingListEvent.dart';
import '../Hotels/bloc/BookingListState.dart';
import '../Transport/bloc/MyBooking_bloc.dart';
import '../Transport/bloc/MyBooking_event.dart';
import '../Transport/bloc/MyBooking_state.dart';
import 'HotelBookingList_DetailScreen.dart';
import 'TransPortBooking_DetailScreen.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  int _selectedFilterIndex = 0;

  // BLoCs
  late final MyBookingBloc _bookingBloc;
  late final HotelBookingListBloc _hotelBloc;

  // Data Lists
  List<BookingEntity> _generalBookings = [];
  List<HotelBookingListEntity> _hotelBookings = [];

  // Hotel Fetch State
  bool _hotelFetched = false;
  bool _isHotelLoading = false;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _displayCurrency = 'USD';
  bool _currencyInitialized = false;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.apps_rounded},
    {'label': 'Flight', 'icon': Icons.flight_takeoff_rounded},
    {'label': 'Hotel', 'icon': Icons.hotel_rounded},
    {'label': 'Transport', 'icon': Icons.electric_car_rounded},
    {'label': 'Visa', 'icon': Icons.description_rounded},
    {'label': 'Holidays', 'icon': Icons.beach_access_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _bookingBloc = sl<MyBookingBloc>();
    _hotelBloc = sl<HotelBookingListBloc>();

    _bookingBloc.add(const FetchBookings());
    _initializeCurrency();
    _hotelBloc.add(const FetchHotelBookings());

    _hotelBloc.stream.listen((state) {
      if (state is HotelLoaded) {
        setState(() {
          _hotelBookings = state.bookings;
          _isHotelLoading = false;
          _hotelFetched = true;
        });
      } else if (state is HotelLoading) {
        setState(() => _isHotelLoading = true);
      } else if (state is HotelError) {
        setState(() {
          _isHotelLoading = false;
          _hotelFetched = true;
        });
      }
    });
  }

  Future<void> _initializeCurrency() async {
    await ExchangeRateService.initializeUserCurrency();
    setState(() {
      _displayCurrency = CurrencyConverter.getPreferredCurrency();
      _currencyInitialized = true;
    });
  }

  @override
  void dispose() {
    _bookingBloc.close();
    _hotelBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterTap(int index) {
    setState(() => _selectedFilterIndex = index);

    String selectedCategory = _categories[index]['label'];
    if ((selectedCategory == 'Hotel' || selectedCategory == 'All') &&
        !_hotelFetched &&
        !_isHotelLoading) {
      _hotelBloc.add(const FetchHotelBookings());
    }
  }

  List<dynamic> _getCombinedBookings() {
    String selectedCategory = _categories[_selectedFilterIndex]['label'];
    List<dynamic> result = [];

    if (selectedCategory == 'All') {
      result.addAll(_generalBookings);
      result.addAll(_hotelBookings);
    } else if (selectedCategory == 'Hotel') {
      result.addAll(_hotelBookings);
    } else {
      result.addAll(
        _generalBookings.where((b) => b.category == selectedCategory),
      );
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((item) {
        if (item is BookingEntity) {
          return item.destination.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
              item.confirmationNumber.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              item.type.toLowerCase().contains(_searchQuery.toLowerCase());
        } else if (item is HotelBookingListEntity) {
          return item.hotelName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
              item.confirmationNumber.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              item.roomType.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        return false;
      }).toList();
    }

    return result;
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final prefManager = await PreferencesManager.create(prefs);

    setState(() {
      _isLoggedIn = prefManager.isLoggedIn();
      if (_isLoggedIn) {
        final userData = prefManager.getUserData();
        _userName = userData?['name'] ?? '';
        _userEmail = userData?['email'] ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocProvider.value(
        value: _bookingBloc,
        child: Column(
          children: [
            SizedBox(height: context.w(35)),
            // Breadcrumb
            _buildBreadcrumb(),
            // Filter Section
            _buildFilterSection(),
            // Stats Bar & Booking List
            Expanded(
              child: BlocBuilder<MyBookingBloc, BookingState>(
                builder: (context, state) {
                  if (state is BookingLoading && _generalBookings.isEmpty) {
                    return _buildLoadingState();
                  }

                  if (state is BookingLoaded) {
                    _generalBookings = state.bookings;
                  }

                  String selectedCategory =
                  _categories[_selectedFilterIndex]['label'];
                  if (selectedCategory == 'Hotel' && _isHotelLoading) {
                    return _buildLoadingState();
                  }

                  final combinedBookings = _getCombinedBookings();

                  return Column(
                    children: [
                      _buildStatsBar(combinedBookings.length),
                      Expanded(
                        child: combinedBookings.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            context.w(16),
                            0,
                            context.w(16),
                            context.h(16),
                          ),
                          itemCount: combinedBookings.length,
                          itemBuilder: (context, index) {
                            final item = combinedBookings[index];
                            if (item is HotelBookingListEntity) {
                              return _buildHotelCard(item);
                            } else if (item is BookingEntity) {
                              return _buildModernTripCard(item);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BREADCRUMB ---
  Widget _buildBreadcrumb() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(
                    userEmail: _userEmail,
                    userName: _userName,
                  ),
                ),
              );
            },
            child: Text(
              'My Account',
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: context.fs(12),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: context.w(14),
            color: const Color(0xFFD1D5DB),
          ),
          Text(
            'My Booking',
            style: TextStyle(
              color: const Color(0xFFD32F2F),
              fontSize: context.fs(12),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- FILTER SECTION ---
  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        bottom: context.h(10),
        top: context.h(6),
      ),
      child: Column(
        children: [
          // Search Row
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: context.h(38),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search bookings...',
                        hintStyle: TextStyle(
                          color: const Color(0xFF9CA3AF),
                          fontSize: context.fs(12),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: const Color(0xFF9CA3AF),
                          size: context.w(18),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: context.h(8),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.w(10)),
                Container(
                  height: context.h(38),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(14),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Sort",
                        style: TextStyle(
                          color: const Color(0xFF4B5563),
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: context.w(4)),
                      Icon(
                        Icons.swap_vert_rounded,
                        color: const Color(0xFF6B7280),
                        size: context.w(16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Filter Chips
          SizedBox(
            height: context.h(44),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedFilterIndex == index;
                return GestureDetector(
                  onTap: () => _onFilterTap(index),
                  child: Container(
                    margin: EdgeInsets.only(right: context.w(10)),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(14),
                      vertical: context.h(6),
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(
                        context.r(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _categories[index]['icon'],
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          size: context.w(16),
                        ),
                        SizedBox(width: context.w(6)),
                        Text(
                          _categories[index]['label'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4B5563),
                            fontWeight: FontWeight.w600,
                            fontSize: context.fs(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- STATS BAR ---
  Widget _buildStatsBar(int count) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(12),
        context.w(16),
        context.h(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count Bookings',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: context.fs(12),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_selectedFilterIndex != 0 || _searchQuery.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(3),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withOpacity(0.08),
                borderRadius: BorderRadius.circular(
                  context.r(10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: const Color(0xFFD32F2F),
                    size: context.w(14),
                  ),
                  SizedBox(width: context.w(4)),
                  Text(
                    'Filter Applied',
                    style: TextStyle(
                      color: const Color(0xFFD32F2F),
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- LOADING STATE ---
  Widget _buildLoadingState() {
    return Center(
      child: SizedBox(
        width: context.w(24),
        height: context.w(24),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFD32F2F),
        ),
      ),
    );
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: context.w(100),
            height: context.w(100),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: context.w(44),
              color: const Color(0xFFD1D5DB),
            ),
          ),
          SizedBox(height: context.h(16)),
          Text(
            "No bookings found",
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: context.h(4)),
          Text(
            "Try changing your filters or search query",
            style: TextStyle(
              fontSize: context.fs(12),
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // --- TRIP CARD ---
  Widget _buildModernTripCard(BookingEntity booking) {
    bool isPending = booking.status.toLowerCase().contains('pending');
    bool isCancelled = booking.status.toLowerCase().contains('cancelled');
    Color statusColor = isPending
        ? const Color(0xFFFFA726)
        : (isCancelled ? const Color(0xFFE53935) : const Color(0xFF4CAF50));

    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: context.h(3),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.r(14)),
                topRight: Radius.circular(context.r(14)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.w(14)),
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
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(context.r(6)),
                      ),
                      child: Text(
                        booking.confirmationNumber,
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(6),
                        vertical: context.h(3),
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(context.r(6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPending
                                ? Icons.hourglass_empty_rounded
                                : (isCancelled
                                ? Icons.cancel_rounded
                                : Icons.check_circle_rounded),
                            size: context.w(10),
                            color: statusColor,
                          ),
                          SizedBox(width: context.w(3)),
                          Text(
                            booking.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.w(6)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(context.r(10)),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: const Color(0xFFD32F2F),
                        size: context.w(16),
                      ),
                    ),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.destination,
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            booking.type,
                            style: TextStyle(
                              fontSize: context.fs(11),
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Divider(
                  color: const Color(0xFFE5E7EB),
                  height: context.h(1),
                ),
                SizedBox(height: context.h(10)),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: context.w(12),
                            color: const Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: context.w(4)),
                          Text(
                            'Booked: ${booking.bookedDate}',
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: context.fs(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: context.w(12),
                          color: const Color(0xFF9CA3AF),
                        ),
                        SizedBox(width: context.w(4)),
                        Text(
                          '${booking.applicantCount}',
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: context.fs(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: const Color(0xFF9CA3AF),
                            fontSize: context.fs(10),
                          ),
                        ),
                        Text(
                          _getConvertedAmountText(booking),
                          style: TextStyle(
                            fontSize: context.fs(18),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailsScreen(booking: booking),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.OrangeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(14),
                          vertical: context.h(8),
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        "Details",
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  // --- HOTEL CARD ---
  Widget _buildHotelCard(HotelBookingListEntity booking) {
    bool isPending = booking.status.toLowerCase().contains('pending');
    bool isCancelled = booking.status.toLowerCase().contains('cancelled');
    Color statusColor = isPending
        ? const Color(0xFFFFA726)
        : (isCancelled ? const Color(0xFFE53935) : const Color(0xFF4CAF50));

    String checkInFormatted = _formatDate(booking.checkIn);
    String checkOutFormatted = _formatDate(booking.checkOut);

    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: context.h(3),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.r(14)),
                topRight: Radius.circular(context.r(14)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.w(14)),
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
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(context.r(6)),
                      ),
                      child: Text(
                        booking.confirmationNumber,
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(6),
                        vertical: context.h(3),
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(context.r(6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPending
                                ? Icons.hourglass_empty_rounded
                                : (isCancelled
                                ? Icons.cancel_rounded
                                : Icons.check_circle_rounded),
                            size: context.w(10),
                            color: statusColor,
                          ),
                          SizedBox(width: context.w(3)),
                          Text(
                            booking.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(context.r(10)),
                      child: booking.hotelImage.isNotEmpty
                          ? Image.network(
                        booking.hotelImage,
                        width: context.w(52),
                        height: context.w(52),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            _buildHotelPlaceholder(),
                      )
                          : _buildHotelPlaceholder(),
                    ),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.hotelName.isNotEmpty
                                ? booking.hotelName
                                : 'Unknown Hotel',
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            booking.roomType,
                            style: TextStyle(
                              fontSize: context.fs(11),
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (booking.hotelAddress.isNotEmpty) ...[
                            Text(
                              booking.hotelAddress,
                              style: TextStyle(
                                fontSize: context.fs(10),
                                color: const Color(0xFF9CA3AF),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Divider(
                  color: const Color(0xFFE5E7EB),
                  height: context.h(1),
                ),
                SizedBox(height: context.h(10)),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: context.w(12),
                            color: const Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: context.w(4)),
                          Expanded(
                            child: Text(
                              '$checkInFormatted - $checkOutFormatted',
                              style: TextStyle(
                                color: const Color(0xFF6B7280),
                                fontSize: context.fs(10),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: context.w(12),
                          color: const Color(0xFF9CA3AF),
                        ),
                        SizedBox(width: context.w(4)),
                        Text(
                          '${booking.adults}A${booking.children > 0 ? ' ${booking.children}C' : ''}',
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: context.fs(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: const Color(0xFF9CA3AF),
                            fontSize: context.fs(10),
                          ),
                        ),
                        Text(
                          '${booking.currency} ${booking.totalFare}',
                          style: TextStyle(
                            fontSize: context.fs(18),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HotelBookingDetailsScreen(booking: booking),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.OrangeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(14),
                          vertical: context.h(8),
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        "Details",
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildHotelPlaceholder() {
    return Container(
      width: context.w(52),
      height: context.w(52),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Icon(
        Icons.hotel_rounded,
        color: const Color(0xFFD32F2F),
        size: context.w(24),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateString);
      List<String> months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (e) {
      return dateString;
    }
  }

  String _getConvertedAmountText(BookingEntity booking) {
    if (!_currencyInitialized)
      return '${booking.currency} ${booking.totalPrice}';
    try {
      final originalAmount =
          double.tryParse(booking.totalPrice.toString()) ?? 0.0;
      final originalCurrency = booking.currency.toUpperCase();
      final targetCurrency = _displayCurrency;
      if (originalCurrency == targetCurrency)
        return '${CurrencyConverter.getSymbol(originalCurrency)} ${originalAmount.toStringAsFixed(0)}';
      final prefs = sl<PreferencesManager>();
      final rates = prefs.getCachedExchangeRates();
      if (rates != null &&
          rates.containsKey(originalCurrency) &&
          rates.containsKey(targetCurrency)) {
        final convertedAmount = CurrencyConverter.convert(
          amount: originalAmount,
          fromCurrency: originalCurrency,
          toCurrency: targetCurrency,
        );
        return '${CurrencyConverter.getSymbol(targetCurrency)} ${convertedAmount.toStringAsFixed(0)}';
      }
      return '${booking.currency} ${booking.totalPrice}';
    } catch (e) {
      return '${booking.currency} ${booking.totalPrice}';
    }
  }
}