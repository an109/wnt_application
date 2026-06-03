import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/MyBookings/presentation/bloc/MyBooking_bloc.dart';

import '../../../../UI_helper/currency_converter.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';

import '../../domain/entity/MyBooking_entity.dart';
import '../bloc/MyBooking_event.dart';
import '../bloc/MyBooking_state.dart';
import 'My_booking_detailsScreen.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  int _selectedFilterIndex = 0;
  late final MyBookingBloc _bookingBloc;
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
    _bookingBloc.add(const FetchBookings());
    _initializeCurrency();
  }

  Future<void> _initializeCurrency() async {
    // This will set the preferred currency based on geolocation
    await ExchangeRateService.initializeUserCurrency();
    setState(() {
      _displayCurrency = CurrencyConverter.getPreferredCurrency();
      _currencyInitialized = true;
    });
  }

  @override
  void dispose() {
    _bookingBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterTap(int index) {
    setState(() => _selectedFilterIndex = index);
  }

  // Functional Filtering Logic
  List<BookingEntity> _filterBookings(List<BookingEntity> bookings) {
    String selectedCategory = _categories[_selectedFilterIndex]['label'];

    return bookings.where((booking) {
      bool categoryMatch =
          selectedCategory == 'All' || booking.category == selectedCategory;
      bool searchMatch =
          _searchQuery.isEmpty ||
          booking.destination.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          booking.confirmationNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          booking.type.toLowerCase().contains(_searchQuery.toLowerCase());
      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const WanderNovaLogo(scaleFactor: 0.6),
        centerTitle: false,
        actions: [
          Container(
            margin: EdgeInsets.only(right: context.w(16)),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF0F2F5),
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.grey[700],
                size: context.w(20),
              ),
            ),
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _bookingBloc,
        child: Column(
          children: [
            // Breadcrumb
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: context.w(20),
                vertical: context.h(12),
              ),
              child: Row(
                children: [
                  Text(
                    'My Account',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: context.fs(13),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: context.w(16),
                    color: Colors.grey[400],
                  ),
                  Text(
                    'My Booking',
                    style: TextStyle(
                      color: const Color(0xFFD32F2F),
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Filter Section
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                bottom: context.h(12),
                top: context.h(8),
              ),
              child: Column(
                children: [
                  // Search & Sort Row
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(20),
                      vertical: context.h(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: context.h(42),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(
                                context.r(12),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search bookings...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: context.fs(14),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.grey[500],
                                  size: context.w(20),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: context.h(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: context.w(12)),
                        Container(
                          height: context.h(42),
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(16),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(context.r(12)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Sort",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: context.fs(13),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: context.w(4)),
                              Icon(
                                Icons.swap_vert_rounded,
                                color: Colors.grey[600],
                                size: context.w(18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Chips
                  SizedBox(
                    height: context.h(52),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedFilterIndex == index;
                        return GestureDetector(
                          onTap: () => _onFilterTap(index),
                          child: Container(
                            margin: EdgeInsets.only(right: context.w(12)),
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(18),
                              vertical: context.h(8),
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(
                                context.r(30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _categories[index]['icon'],
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: context.w(18),
                                ),
                                SizedBox(width: context.w(8)),
                                Text(
                                  _categories[index]['label'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.fs(13),
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
            ),

            // Stats Bar & Booking List
            Expanded(
              child: BlocBuilder<MyBookingBloc, BookingState>(
                builder: (context, state) {
                  if (state is BookingLoading)
                    return const Center(child: CircularProgressIndicator());

                  if (state is BookingLoaded) {
                    final filteredBookings = _filterBookings(state.bookings);

                    return Column(
                      children: [
                        // Stats Bar
                        Container(
                          margin: EdgeInsets.fromLTRB(
                            context.w(20),
                            context.h(16),
                            context.w(20),
                            context.h(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filteredBookings.length} Bookings Found',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: context.fs(13),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_selectedFilterIndex != 0 ||
                                  _searchQuery.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.w(10),
                                    vertical: context.h(4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFD32F2F,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      context.r(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.filter_list_rounded,
                                        color: const Color(0xFFD32F2F),
                                        size: context.w(16),
                                      ),
                                      SizedBox(width: context.w(4)),
                                      Text(
                                        'Filter Applied',
                                        style: TextStyle(
                                          color: const Color(0xFFD32F2F),
                                          fontSize: context.fs(11),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Booking List
                        Expanded(
                          child: filteredBookings.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    context.w(20),
                                    0,
                                    context.w(20),
                                    context.h(20),
                                  ),
                                  itemCount: filteredBookings.length,
                                  itemBuilder: (context, index) =>
                                      _buildModernTripCard(
                                        filteredBookings[index],
                                      ),
                                ),
                        ),
                      ],
                    );
                  }
                  return Center(child: Text('Error loading bookings'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTripCard(BookingEntity booking) {
    bool isPending = booking.status.toLowerCase().contains('pending');
    bool isCancelled = booking.status.toLowerCase().contains('cancelled');
    Color statusColor = isPending
        ? const Color(0xFFFFA726)
        : (isCancelled ? const Color(0xFFE53935) : const Color(0xFF4CAF50));

    return Container(
      margin: EdgeInsets.only(bottom: context.h(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
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
            height: context.h(4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.r(16)),
                topRight: Radius.circular(context.r(16)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(10),
                        vertical: context.h(4),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(context.r(8)),
                      ),
                      child: Text(
                        booking.confirmationNumber,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(4),
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.r(8)),
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
                            size: context.w(12),
                            color: statusColor,
                          ),
                          SizedBox(width: context.w(4)),
                          Text(
                            booking.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: context.fs(11),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.w(8)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(context.r(12)),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: const Color(0xFFD32F2F),
                        size: context.w(20),
                      ),
                    ),
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.destination,
                            style: TextStyle(
                              fontSize: context.fs(16),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: context.h(2)),
                          Text(
                            booking.type,
                            style: TextStyle(
                              fontSize: context.fs(12),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(14)),
                Divider(color: Colors.grey[200], height: context.h(1)),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: context.w(14),
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: context.w(6)),
                          Text(
                            'Booked: ${booking.bookedDate}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: context.fs(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: context.w(14),
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: context.w(6)),
                        Text(
                          '${booking.applicantCount} applicant(s)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: context.fs(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: context.h(16)),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: context.fs(11),
                          ),
                        ),
                        SizedBox(height: context.h(2)),
                        Text(
                          _getConvertedAmountText(booking),
                          style: TextStyle(
                            fontSize: context.fs(22),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (booking.canCancel && !isCancelled) ...[
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(10)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(16),
                            vertical: context.h(10),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: context.fs(13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: context.w(12)),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.OrangeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(10)),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(16),
                          vertical: context.h(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "View Details",
                        style: TextStyle(
                          fontSize: context.fs(13),
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

  String _getConvertedAmountText(BookingEntity booking) {
    if (!_currencyInitialized) {
      return '${booking.currency} ${booking.totalPrice}';
    }

    try {
      // Parse the total price from booking
      final originalAmount =
          double.tryParse(booking.totalPrice.toString()) ?? 0.0;
      final originalCurrency = booking.currency.toUpperCase();
      final targetCurrency = _displayCurrency;

      // If same currency, show original
      if (originalCurrency == targetCurrency) {
        return '${CurrencyConverter.getSymbol(originalCurrency)} ${originalAmount.toStringAsFixed(0)}';
      }

      // Get cached rates
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

      // Fallback to original
      return '${booking.currency} ${booking.totalPrice}';
    } catch (e) {
      print('Currency conversion error: $e');
      return '${booking.currency} ${booking.totalPrice}';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: context.w(140),
            height: context.w(140),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F2F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: context.w(64),
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: context.h(24)),
          Text(
            "No bookings found",
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: context.h(8)),
          Text(
            "Try changing your filters or search query",
            style: TextStyle(fontSize: context.fs(14), color: Colors.grey[600]),
          ),
          SizedBox(height: context.h(32)),
          // ElevatedButton(
          //   onPressed: () => setState(() {
          //     _selectedFilterIndex = 0;
          //     _searchController.clear();
          //     _searchQuery = '';
          //   }),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: AppColors.OrangeColor,
          //     padding: EdgeInsets.symmetric(
          //       horizontal: context.w(32),
          //       vertical: context.h(14),
          //     ),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(context.r(12)),
          //     ),
          //     elevation: 0,
          //   ),
          //   child: Text(
          //     "CLEAR FILTERS",
          //     style: TextStyle(
          //       fontSize: context.fs(14),
          //       fontWeight: FontWeight.w600,
          //       letterSpacing: context.letterSpacingWider,
          //       color: Colors.white,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
