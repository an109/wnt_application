import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../../injection_container.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/loadingScreen.dart';
import '../../../../common_widgets/logo.dart';
import '../../domain/entities/flight_entity.dart';
import '../../domain/entities/flight_search_request_entity.dart';
import '../bloc/flight_search_bloc.dart';
import '../bloc/flight_search_event.dart';
import '../bloc/flight_search_state.dart';
import 'detail_popup.dart';
import 'filter_drawer.dart';

class FlightSearchScreen extends StatefulWidget {
  final String from;
  final String to;
  final String fromCode;
  final String toCode;
  final String fromAirport;
  final String toAirport;
  final DateTime? date;
  final int travellers;
  final int adults;
  final int children;
  final int infants;
  final String travelClass;
  final bool isRoundTrip;
  final DateTime? returnDate;

  const FlightSearchScreen({
    super.key,
    required this.from,
    required this.to,
    required this.fromCode,
    required this.toCode,
    required this.fromAirport,
    required this.toAirport,
    required this.date,
    required this.travellers,
    required this.adults,
    required this.children,
    required this.infants,
    required this.travelClass,
    required this.isRoundTrip,
    this.returnDate,
  });

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen>
    with SingleTickerProviderStateMixin {
  late FlightSearchBloc _flightSearchBloc;
  String _selectedSort = "Recommended";
  String _selectedFilter = "All Airlines";
  int currentIndex = 0;
  String _selectedTab = "Best Value";
  bool _isApiCalled = false;
  late TabController _tabController;

  // Filter state
  bool _showFilters = false;
  Set<String> _selectedAirlines = {};
  RangeValues _priceRange = const RangeValues(0, 50000);
  double _maxPrice = 50000;

  // Stops filter
  int? _selectedStops; // null = all, 0 = non-stop, 1 = 1 stop, 2 = 2+ stops

  final List<Map<String, dynamic>> _dateOptions = [
    {"day": "Wed", "date": "6 May", "price": 7947, "selected": true},
    {"day": "Thu", "date": "7 May", "price": 6670, "selected": false},
    {"day": "Fri", "date": "8 May", "price": 6566, "selected": false},
    {"day": "Sat", "date": "9 May", "price": 6566, "selected": false},
    {"day": "Sun", "date": "10 May", "price": 6566, "selected": false},
    {"day": "Mon", "date": "11 May", "price": 6436, "selected": false},
    {"day": "Tue", "date": "12 May", "price": 6436, "selected": false},
  ];

  @override
  void initState() {
    super.initState();
    _flightSearchBloc = sl<FlightSearchBloc>();
    _tabController = TabController(length: 3, vsync: this);
    _triggerFlightSearch();
  }

  @override
  void dispose() {
    _flightSearchBloc.close();
    _tabController.dispose();
    super.dispose();
  }

  void _triggerFlightSearch() {
    if (_isApiCalled) return;
    _isApiCalled = true;

    final request = _buildRequest();
    _flightSearchBloc.add(SearchFlightsEvent(request));
  }

  FlightSearchRequestEntity _buildRequest() {
    final segments = <FlightSegmentEntity>[
      FlightSegmentEntity(
        origin: widget.fromCode,
        destination: widget.toCode,
        flightCabinClass: _getCabinClassInt(widget.travelClass),
        preferredDepartureTime: _formatDateForAPI(widget.date),
        preferredArrivalTime: _formatDateForAPI(widget.date),
      ),
    ];

    if (widget.isRoundTrip && widget.returnDate != null) {
      segments.add(
        FlightSegmentEntity(
          origin: widget.toCode,
          destination: widget.fromCode,
          flightCabinClass: _getCabinClassInt(widget.travelClass),
          preferredDepartureTime: _formatDateForAPI(widget.returnDate),
          preferredArrivalTime: _formatDateForAPI(widget.returnDate),
        ),
      );
    }

    return FlightSearchRequestEntity(
      endUserIp: '203.0.113.10',
      adultCount: widget.adults,
      childCount: widget.children,
      infantCount: widget.infants,
      journeyType: widget.isRoundTrip ? 2 : 1,
      segments: segments,
    );
  }

  String _formatDateForAPI(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00';
  }

  int _getCabinClassInt(String travelClass) {
    switch (travelClass.toLowerCase()) {
      case 'economy':
        return 2;
      case 'premium economy':
        return 3;
      case 'business':
        return 4;
      case 'first':
        return 5;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FlightSearchBloc>(
      create: (_) => _flightSearchBloc,
      child: Scaffold(
        drawer: const FlightFilterDrawer(),
        appBar: AppBar(
          title: const WanderNovaLogo(scaleFactor: 0.6),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset("assets/images/wander_nova_logo.jpg", height: 35),
            )
          ],
        ),
        backgroundColor: Colors.grey.shade50,
        body: BlocBuilder<FlightSearchBloc, FlightSearchState>(
          builder: (context, state) {
            if (state is FlightSearchLoading) {
              return ProfessionalLoadingScreen(
                searchParams: {
                  'fromAirport': widget.fromAirport,
                  'toAirport': widget.toAirport,
                  'departureDate': widget.date,
                  'returnDate': widget.returnDate,
                  'adults': widget.adults,
                  'children': widget.children,
                  'infants': widget.infants,
                  'class': widget.travelClass,
                  'isRoundTrip': widget.isRoundTrip,
                },
                onLoadingComplete: () {},
              );
            }

            if (state is FlightSearchError) {
              return _buildErrorState(state.message);
            }

            if (state is FlightSearchLoaded) {
              _updateMaxPrice(state.flights);
              return _buildMainContent(state.flights);
            }

            return _buildEmptyState();
          },
        ),
        bottomNavigationBar: const CustomBottomNav(
          currentIndex: 0,
        ),
      ),
    );
  }


  Widget _buildSearchSummaryCard() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.gapMedium,
        vertical: context.gapSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.gapSmall,
                vertical: context.gapXSmall,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.fromCode} → ${widget.toCode}',
                    style: TextStyle(
                      fontSize: context.titleSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.gapXXSmall),
                  Text(
                    '${_formatDate(widget.date)} • ${widget.travelClass} • ${widget.adults + widget.children} Travellers',
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: context.gapSmall),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapSmall,
              vertical: context.gapXSmall,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit, size: 16, color: Color(0xFFFF3B30)),
                SizedBox(width: context.gapXXSmall),
                Text(
                  'Modify',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(List<FlightEntity> flights) {
    final filteredFlights = _applyAdvancedFilters(flights);

    return Column(
      children: [
        _buildDateSelector(),
        // _buildSortAndFilterBar(),
        Expanded(
          child: _showFilters
              ? _buildFilterPanel(filteredFlights, flights)
              : _buildFlightList(filteredFlights),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: context.gapSmall),
      child: SizedBox(
        height: context.hp(11),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
          itemCount: _dateOptions.length,
          separatorBuilder: (context, index) => SizedBox(width: context.gapSmall),
          itemBuilder: (context, index) {
            final date = _dateOptions[index];
            final isSelected = date["selected"] as bool;

            return GestureDetector(
              onTap: () {
                setState(() {
                  for (var d in _dateOptions) d["selected"] = false;
                  _dateOptions[index]["selected"] = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: context.wp(18),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0A2463) : Colors.white,
                  borderRadius: BorderRadius.circular(context.borderRadius),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0A2463) : Colors.grey.shade200,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                    color: const Color(0xFF0A2463).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date["day"],
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: context.gapXXSmall),
                    Text(
                      date["date"],
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: context.gapXXSmall),
                    Text(
                      "₹${date["price"]}",
                      style: TextStyle(
                        fontSize: context.labelMedium,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF00A859),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildFilterPanel(List<FlightEntity> filteredFlights, List<FlightEntity> allFlights) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(context.gapMedium),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: context.titleMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedAirlines.clear();
                          _priceRange =  RangeValues(0, _maxPrice);
                          _selectedStops = null;
                        });
                      },
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: const Color(0xFFFF3B30),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.gapMedium),
                // Price Range
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Range',
                      style: TextStyle(
                        fontSize: context.titleSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.gapSmall),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: _maxPrice,
                      divisions: 100,
                      activeColor: const Color(0xFFFF3B30),
                      inactiveColor: Colors.grey.shade300,
                      labels: RangeLabels(
                        '₹${_priceRange.start.round()}',
                        '₹${_priceRange.end.round()}',
                      ),
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_priceRange.start.round()}',
                          style: TextStyle(
                            fontSize: context.labelSmall,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '₹${_priceRange.end.round()}',
                          style: TextStyle(
                            fontSize: context.labelSmall,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: context.gapLarge),
                // Stops Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stops',
                      style: TextStyle(
                        fontSize: context.titleSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.gapSmall),
                    Row(
                      children: [
                        _buildStopOption("Any", null),
                        SizedBox(width: context.gapSmall),
                        _buildStopOption("Non-stop", 0),
                        SizedBox(width: context.gapSmall),
                        _buildStopOption("1 Stop", 1),
                        SizedBox(width: context.gapSmall),
                        _buildStopOption("2+ Stops", 2),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _showFilters = false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.gapMedium),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: context.titleSmall,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              Container(
                height: context.hp(5),
                width: 1,
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _showFilters = false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.gapMedium),
                  ),
                  child: Text(
                    'Apply (${filteredFlights.length})',
                    style: TextStyle(
                      fontSize: context.titleSmall,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF3B30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopOption(String label, int? stops) {
    final isSelected = _selectedStops == stops;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStops = stops),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.gapSmall),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF3B30).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(context.borderRadius),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF3B30) : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.labelSmall,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFFFF3B30) : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlightList(List<FlightEntity> flights) {
    final filteredFlights = _applyFiltersAndSort(flights);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
            child: _buildResultsHeader(filteredFlights.length, flights.length),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (index == filteredFlights.length) {
                  return SizedBox(height: context.gapLarge);
                }
                return _buildEnhancedFlightCard(filteredFlights[index]);
              },
              childCount: filteredFlights.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFlightCard(FlightEntity flight) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFlightDetails(flight),
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Padding(
            padding: EdgeInsets.all(context.gapMedium),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Airline logo
                    Container(
                      width: context.wp(12),
                      height: context.wp(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF3B30).withOpacity(0.15),
                            const Color(0xFFFF3B30).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(context.borderRadius),
                      ),
                      child: Center(
                        child: Text(
                          flight.airlineCode?.substring(0, 2) ?? '--',
                          style: TextStyle(
                            fontSize: context.titleLarge,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.gapMedium),

                    // Flight details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                flight.airlineName ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.titleMedium,
                                ),
                              ),
                              SizedBox(width: context.gapSmall),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.gapXSmall,
                                  vertical: context.gapXXSmall,
                                ),
                                decoration: BoxDecoration(
                                  color: (flight.seatsAvailable ?? 9) > 5
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                                ),
                                child: Text(
                                  (flight.seatsAvailable ?? 9) > 5 ? "Available" : "Few seats",
                                  style: TextStyle(
                                    fontSize: context.labelSmall,
                                    color: (flight.seatsAvailable ?? 9) > 5
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.gapSmall),

                          // Time and route with enhanced design
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatTime(flight.departureTime),
                                      style: TextStyle(
                                        fontSize: context.titleLarge,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: context.gapXXSmall),
                                    Text(
                                      flight.origin ?? '--',
                                      style: TextStyle(
                                        fontSize: context.labelSmall,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      flight.duration != null
                                          ? '${flight.duration} min'
                                          : '--',
                                      style: TextStyle(
                                        fontSize: context.labelSmall,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    SizedBox(height: context.gapXXSmall),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: 1,
                                          color: Colors.grey.shade300,
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(context.gapXXSmall),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.flight_takeoff,
                                            size: context.iconXSmall,
                                            color: const Color(0xFFFF3B30),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: context.gapXXSmall),
                                    Text(
                                      'Non-stop',
                                      style: TextStyle(
                                        fontSize: context.labelSmall,
                                        color: Colors.green.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatTime(flight.arrivalTime),
                                      style: TextStyle(
                                        fontSize: context.titleLarge,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: context.gapXXSmall),
                                    Text(
                                      flight.destination ?? '--',
                                      style: TextStyle(
                                        fontSize: context.labelSmall,
                                        color: Colors.grey.shade600,
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
                  ],
                ),
                SizedBox(height: context.gapMedium),

                // Bottom section with price and booking
                Divider(height: 1, color: Colors.grey.shade200),
                SizedBox(height: context.gapMedium),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fare type badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.gapSmall,
                        vertical: context.gapXXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.luggage_outlined,
                            size: context.iconXSmall,
                            color: const Color(0xFFFF3B30),
                          ),
                          SizedBox(width: context.gapXXSmall),
                          Text(
                            'Inclusive of taxes',
                            style: TextStyle(
                              fontSize: context.labelSmall,
                              color: const Color(0xFFFF3B30),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${flight.currency ?? '₹'} ${_formatPrice((flight.totalFare ?? 0).toInt())}",
                              style: TextStyle(
                                fontSize: context.titleLarge,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF3B30),
                              ),
                            ),
                            Text(
                              'per passenger',
                              style: TextStyle(
                                fontSize: context.labelSmall,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: context.gapSmall),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF3B30), Color(0xFFFF6B4A)],
                            ),
                            borderRadius: BorderRadius.circular(context.borderRadius),
                          ),
                          child: ElevatedButton(
                            onPressed: () => _showFlightDetails(flight),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                horizontal: context.gapLarge,
                                vertical: context.gapSmall,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(context.borderRadius),
                              ),
                            ),
                            child: Text(
                              "View Details",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: context.labelMedium,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFlightDetails(FlightEntity flight) {
    FlightDetailsPopup.show(
      context,
      airlineName: flight.airlineName ?? "Unknown",
      airlineCode: flight.airlineCode ?? "--",
      flightNumber: flight.flightNumber ?? "--",
      fromCode: flight.origin ?? "--",
      toCode: flight.destination ?? "--",
      departureTime: _formatTime(flight.departureTime),
      arrivalTime: _formatTime(flight.arrivalTime),
      traceId: flight.traceId,
      resultIndex: flight.resultIndex,
      duration: "${flight.duration ?? '--'} min",
      price: _formatPrice((flight.totalFare ?? 0).toInt()),
    );
  }

  List<FlightEntity> _applyAdvancedFilters(List<FlightEntity> flights) {
    var result = List<FlightEntity>.from(flights);

    // Filter by price range
    result = result.where((f) {
      final price = f.totalFare ?? 0;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // Filter by stops (you'll need to add stops info to FlightEntity)
    if (_selectedStops != null) {
      // Add stops filtering logic based on your data structure
    }

    // Apply sort and other filters
    return _applyFiltersAndSort(result);
  }

  List<FlightEntity> _applyFiltersAndSort(List<FlightEntity> flights) {
    var result = List<FlightEntity>.from(flights);

    if (_selectedFilter != "All Airlines" && _selectedFilter.isNotEmpty) {
      result = result
          .where((f) => f.airlineName?.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }

    if (_selectedSort == "Price: Low to High") {
      result.sort((a, b) => (a.totalFare ?? 0).compareTo(b.totalFare ?? 0));
    } else if (_selectedSort == "Price: High to Low") {
      result.sort((a, b) => (b.totalFare ?? 0).compareTo(a.totalFare ?? 0));
    } else if (_selectedSort == "Duration: Shortest") {
      result.sort((a, b) {
        int aDur = int.tryParse(a.duration ?? '0') ?? 9999;
        int bDur = int.tryParse(b.duration ?? '0') ?? 9999;
        return aDur.compareTo(bDur);
      });
    } else if (_selectedSort == "Departure: Earliest") {
      result.sort((a, b) => (a.departureTime ?? '').compareTo(b.departureTime ?? ''));
    }

    return result;
  }

  void _updateMaxPrice(List<FlightEntity> flights) {
    final maxPrice = flights.fold<double>(
      0,
          (max, f) => (f.totalFare ?? 0) > max ? (f.totalFare ?? 0) : max,
    );
    if (maxPrice > _maxPrice) {
      setState(() {
        _maxPrice = maxPrice;
        _priceRange = RangeValues(0, maxPrice);
      });
    }
  }


  Widget _buildResultsHeader(int showing, int total) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.gapSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$showing of $total Flights",
            style: TextStyle(
              fontSize: context.labelMedium,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: context.horizontalPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: context.iconXLarge, color: Colors.red.shade400),
            SizedBox(height: context.gapLarge),
            Text(
              'Failed to load flights',
              style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: context.gapSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.bodyMedium, color: Colors.grey.shade600),
            ),
            SizedBox(height: context.gapXLarge),
            ElevatedButton(
              onPressed: _triggerFlightSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                padding: EdgeInsets.symmetric(
                  horizontal: context.buttonWidth,
                  vertical: context.gapMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: context.iconXLarge * 1.5, color: Colors.grey.shade400),
          SizedBox(height: context.gapLarge),
          Text(
            'Search for flights',
            style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'Enter your travel details to find the best flights',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: context.bodyMedium, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day} ${_getMonthAbbr(date.month)} ${date.year}';
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}