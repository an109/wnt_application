import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../../core/error/data_state.dart';
import '../../../../../injection_container.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/constants/urls.dart';
import '../../domain/entities/flight_entity.dart';
import '../../domain/entities/flight_search_request_entity.dart';
import '../bloc/flight_search_bloc.dart';
import '../bloc/flight_search_event.dart';
import '../bloc/flight_search_state.dart';
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

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  late FlightSearchBloc _flightSearchBloc;
  String _selectedSort = "Recommended";
  String _selectedFilter = "All Airlines";
  int currentIndex = 0;
  String _selectedTab = "Best Value";
  bool _isApiCalled = false;

  final List<Map<String, dynamic>> _dateOptions = [
    {"day": "Wed", "date": "6 May", "price": 7947, "selected": true},
    {"day": "Thu", "date": "7 May", "price": 6670, "selected": false},
    {"day": "Fri", "date": "8 May", "price": 6566, "selected": false},
    {"day": "Sat", "date": "9 May", "price": 6566, "selected": false},
    {"day": "Sun", "date": "10 May", "price": 6566, "selected": false},
    {"day": "Mon", "date": "11 May", "price": 6436, "selected": false},
    {"day": "Tue", "date": "12 May", "price": 6436, "selected": false},
  ];


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

  @override
  void initState() {
    super.initState();
    _flightSearchBloc = sl<FlightSearchBloc>();
  }

  @override
  void dispose() {
    _flightSearchBloc.close();
    super.dispose();
  }

  void _triggerFlightSearch() {
    if (_isApiCalled) return; // Prevent multiple API calls
    _isApiCalled = true;

    print('🎯 TRIGGERING FLIGHT SEARCH API');
    print('   From: ${widget.fromCode}');
    print('   To: ${widget.toCode}');
    print('   Date: ${widget.date}');
    print('   Adults: ${widget.adults}');
    print('   RoundTrip: ${widget.isRoundTrip}');

    final segments = <FlightSegmentEntity>[
      FlightSegmentEntity(
        origin: widget.fromCode,
        destination: widget.toCode,
        flightCabinClass: _getCabinClassInt(widget.travelClass),
        preferredDepartureTime: _formatDateForAPI(widget.date),
        preferredArrivalTime: _formatDateForAPI(widget.date),
      ),
    ];

    // Add return segment for round trip
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

    final request = FlightSearchRequestEntity(
      endUserIp: '203.0.113.10',
      adultCount: widget.adults,
      childCount: widget.children,
      infantCount: widget.infants,
      journeyType: widget.isRoundTrip ? 2 : 1, // 1=OneWay, 2=RoundTrip
      segments: segments,
    );

    print('📤 API Request: ${request.toString()}');
    _flightSearchBloc.add(SearchFlightsEvent(request));
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
      create: (_) {
        final bloc = sl<FlightSearchBloc>();

        final request = FlightSearchRequestEntity(
          endUserIp: '203.0.113.10',
          adultCount: widget.adults,
          childCount: widget.children,
          infantCount: widget.infants,
          journeyType: widget.isRoundTrip ? 2 : 1,
          segments: [
            FlightSegmentEntity(
              origin: widget.fromCode,
              destination: widget.toCode,
              flightCabinClass: _getCabinClassInt(widget.travelClass),
              preferredDepartureTime: _formatDateForAPI(widget.date),
              preferredArrivalTime: _formatDateForAPI(widget.date),
            ),
          ],
        );

        print('📤 API PAYLOAD');
        print(request.toString());

        bloc.add(SearchFlightsEvent(request));

        return bloc;
      },
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
              return const Center(child: CircularProgressIndicator());
            }

            if (state is FlightSearchError) {
              print(state.message);
              return _buildErrorState(state.message);
            }

            if (state is FlightSearchLoaded) {
              return _buildFlightList(state.flights);
            }

            return _buildEmptyState();
          },
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: currentIndex,
          onTap: (i) => setState(() => currentIndex = i),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: context.iconLarge, color: Colors.red.shade400),
          SizedBox(height: context.gapMedium),
          Text(
            'Failed to load flights',
            style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: context.gapSmall),
          Padding(
            padding: context.horizontalPadding,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.bodyMedium, color: Colors.grey.shade600),
            ),
          ),
          SizedBox(height: context.gapLarge),
          ElevatedButton(
            onPressed: _triggerFlightSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              padding: EdgeInsets.symmetric(horizontal: context.buttonWidth * 0.4, vertical: context.gapMedium),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius)),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: context.iconLarge * 1.5, color: Colors.grey.shade400),
          SizedBox(height: context.gapMedium),
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

  Widget _buildFlightList(List<FlightEntity> flights) {
    final filteredFlights = _applyFiltersAndSort(flights);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildDateSelector()),
        SliverToBoxAdapter(child: _buildFilterTabs()),
        SliverToBoxAdapter(
          child: Padding(
            padding: context.responsivePadding,
            child: _buildSearchSummary(),
          ),
        ),
        SliverToBoxAdapter(child: _buildResultsHeader(filteredFlights.length, flights.length)),
        SliverPadding(
          padding: context.horizontalPadding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (index == filteredFlights.length) {
                  return _buildLoadMoreButton();
                }
                return _buildFlightCard(filteredFlights[index]);
              },
              childCount: filteredFlights.length + 1,
            ),
          ),
        ),
      ],
    );
  }

  List<FlightEntity> _applyFiltersAndSort(List<FlightEntity> flights) {
    var result = List<FlightEntity>.from(flights);

    // Filter by airline name
    if (_selectedFilter != "All Airlines" && _selectedFilter.isNotEmpty) {
      result = result
          .where((f) =>
      f.airlineName?.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }

    // Sort options
    if (_selectedSort == "Price: Low to High") {
      result.sort((a, b) => (a.totalFare ?? 0).compareTo(b.totalFare ?? 0));
    } else if (_selectedSort == "Price: High to Low") {
      result.sort((a, b) => (b.totalFare ?? 0).compareTo(a.totalFare ?? 0));
    } else if (_selectedSort == "Duration: Shortest") {
      // Parse duration string if needed, or use a default
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

  Widget _buildDateSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _dateOptions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
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
              child: Container(
                width: 75,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0A2463) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0A2463) : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF0A2463).withOpacity(0.3), blurRadius: 8)]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${date["day"]}", style: TextStyle(fontSize: context.labelSmall, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Text(date["date"], style: TextStyle(fontSize: context.labelSmall, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade800)),
                    const SizedBox(height: 6),
                    Text("₹${date["price"]}", style: TextStyle(fontSize: context.labelMedium, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.green.shade700)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildFilterTab("Best Value", Icons.workspace_premium),
          const SizedBox(width: 8),
          _buildFilterTab("Cost-Effective", Icons.savings_outlined),
          const SizedBox(width: 8),
          _buildFilterTab("Fastest", Icons.speed),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, IconData icon) {
    final isSelected = _selectedTab == label;
    final Color activeColor = label == "Best Value"
        ? const Color(0xFFC49A6C)
        : label == "Cost-Effective"
        ? Colors.green.shade700
        : Colors.blue.shade700;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.15) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? activeColor : Colors.grey.shade200, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? activeColor : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: context.labelSmall, fontWeight: FontWeight.w600, color: isSelected ? activeColor : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.fromCode, style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.bold)), SizedBox(height: 2), Text(widget.from, style: TextStyle(fontSize: context.labelSmall, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)])),
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFF3B30).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.flight, size: 16, color: Color(0xFFFF3B30))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(widget.toCode, style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.bold)), SizedBox(height: 2), Text(widget.to, style: TextStyle(fontSize: context.labelSmall, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)])),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int showing, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text("Showing $showing of $total Flights found", style: TextStyle(fontSize: context.labelSmall, color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: _showSortOptions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Text(_selectedSort, style: TextStyle(fontSize: context.labelSmall, color: Colors.grey.shade700, fontWeight: FontWeight.w500)), const SizedBox(width: 4), Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey.shade700)]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(FlightEntity flight) {
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
          onTap: () {},
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Padding(
            padding: context.responsivePadding,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Airline logo placeholder
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          flight.airlineCode ?? '--',
                          style: TextStyle(
                            fontSize: context.titleSmall,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Flight details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Airline name
                          Row(
                            children: [
                              Text(
                                flight.airlineName ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.titleMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (flight.seatsAvailable ?? 9) > 5
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (flight.seatsAvailable ?? 9) > 5
                                      ? "Available"
                                      : "Few seats",
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

                          // Time and route
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Departure
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTime(flight.departureTime),
                                    style: TextStyle(
                                      fontSize: context.titleLarge,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    flight.origin ?? '--',
                                    style: TextStyle(
                                      fontSize: context.labelSmall,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),

                              // Duration
                              Column(
                                children: [
                                  Text(
                                    flight.duration != null
                                        ? '${flight.duration} min'
                                        : '--',
                                    style: TextStyle(
                                      fontSize: context.labelSmall,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Container(
                                    width: 60,
                                    height: 1,
                                    color: Colors.grey.shade300,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                  ),
                                ],
                              ),

                              // Arrival
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTime(flight.arrivalTime),
                                    style: TextStyle(
                                      fontSize: context.titleLarge,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    flight.destination ?? '--',
                                    style: TextStyle(
                                      fontSize: context.labelSmall,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: context.gapSmall),

                    // Price and button
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
                        SizedBox(height: context.gapSmall),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF3B30),
                            side: const BorderSide(color: Color(0xFFFF3B30)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                          ),
                          child: const Text(
                            "View",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildLoadMoreButton() {
    return Container(margin: EdgeInsets.all(context.gapMedium), child: Center(child: Text("No more flights", style: TextStyle(fontSize: context.bodySmall, color: Colors.grey.shade500))));
  }

  void _showSortOptions() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) {
      return Container(padding: context.responsivePadding, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Sort by", style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold)), SizedBox(height: context.gapMedium), ...["Recommended", "Price: Low to High", "Price: High to Low", "Duration: Shortest", "Departure: Earliest"].map((sort) => ListTile(title: Text(sort, style: TextStyle(fontSize: context.bodyMedium)), trailing: _selectedSort == sort ? const Icon(Icons.check, color: Color(0xFFFF3B30)) : null, onTap: () { setState(() => _selectedSort = sort); Navigator.pop(context); })),]));
    });
  }
}