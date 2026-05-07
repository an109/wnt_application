import 'package:flutter/material.dart';

import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/logo.dart';
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
  String _selectedSort = "Recommended";
  String _selectedFilter = "All Airlines";
  int currentIndex = 0;
  String _selectedTab = "Best Value";

  // Date options for the carousel
  final List<Map<String, dynamic>> _dateOptions = [
    {"day": "Wed", "date": "6 May", "price": 7947, "selected": true},
    {"day": "Thu", "date": "7 May", "price": 6670, "selected": false},
    {"day": "Fri", "date": "8 May", "price": 6566, "selected": false},
    {"day": "Sat", "date": "9 May", "price": 6566, "selected": false},
    {"day": "Sun", "date": "10 May", "price": 6566, "selected": false},
    {"day": "Mon", "date": "11 May", "price": 6436, "selected": false},
    {"day": "Tue", "date": "12 May", "price": 6436, "selected": false},
  ];

  final List<Map<String, dynamic>> _flights = [
    {
      "airline": "Indigo",
      "airlineCode": "6E",
      "flightNo": "6599",
      "departure": "16:50",
      "arrival": "20:55",
      "duration": "04 Hr. 05 Min.",
      "stops": 1,
      "stopCity": "Indore",
      "price": 9747,
      "currency": "₹",
      "nonStop": false,
      "departureAirport": "Mumbai",
      "arrivalAirport": "Delhi",
      "arrivalNextDay": false,
    },
    {
      "airline": "Air India Express",
      "airlineCode": "IX",
      "flightNo": "1363",
      "departure": "21:35",
      "arrival": "23:40",
      "duration": "02 Hr. 05 Min.",
      "stops": 0,
      "stopCity": "",
      "price": 7947,
      "currency": "₹",
      "nonStop": true,
      "departureAirport": "Navi Mumbai",
      "arrivalAirport": "Delhi",
      "arrivalNextDay": false,
      "additionalFlights": 1,
    },
    {
      "airline": "Indigo",
      "airlineCode": "6E",
      "flightNo": "6802",
      "departure": "17:10",
      "arrival": "23:00",
      "duration": "05 Hr. 50 Min.",
      "stops": 1,
      "stopCity": "Nagpur",
      "price": 8019,
      "currency": "₹",
      "nonStop": false,
    },
    {
      "airline": "Indigo",
      "airlineCode": "6E",
      "flightNo": "6082",
      "departure": "16:45",
      "arrival": "18:55",
      "duration": "02 Hr. 10 Min.",
      "stops": 0,
      "stopCity": "",
      "price": 8357,
      "currency": "₹",
      "nonStop": true,
    },
  ];

  List<Map<String, dynamic>> get _filteredFlights {
    var flights = List<Map<String, dynamic>>.from(_flights);

    if (_selectedFilter != "All Airlines") {
      flights = flights.where((f) => f["airline"] == _selectedFilter).toList();
    }

    if (_selectedSort == "Price: Low to High") {
      flights.sort((a, b) => (a["price"] as int).compareTo(b["price"] as int));
    } else if (_selectedSort == "Price: High to Low") {
      flights.sort((a, b) => (b["price"] as int).compareTo(a["price"] as int));
    } else if (_selectedSort == "Duration: Shortest") {
      flights.sort((a, b) {
        int getMinutes(String duration) {
          final parts = duration.split(" ");
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[2]);
          return hours * 60 + minutes;
        }
        return getMinutes(a["duration"]).compareTo(getMinutes(b["duration"]));
      });
    } else if (_selectedSort == "Departure: Earliest") {
      flights.sort((a, b) => a["departure"].compareTo(b["departure"]));
    }

    return flights;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
      body: CustomScrollView(
        slivers: [
          // Date Selector Carousel
          SliverToBoxAdapter(
            child: _buildDateSelector(),
          ),

          // Filter Tabs
          SliverToBoxAdapter(
            child: _buildFilterTabs(),
          ),

          // Search Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchSummary(),
            ),
          ),

          // Results Header with Sort
          SliverToBoxAdapter(
            child: _buildResultsHeader(),
          ),

          // Flight List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index == _filteredFlights.length) {
                    return _buildLoadMoreButton();
                  }
                  return _buildFlightCard(_filteredFlights[index]);
                },
                childCount: _filteredFlights.length + 1,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
      ),
    );
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
                  for (var d in _dateOptions) {
                    d["selected"] = false;
                  }
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
                    Text(
                      "${date["day"]}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date["date"],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "₹${date["price"]}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.green.shade700,
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
        onTap: () {
          setState(() {
            _selectedTab = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.15) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? activeColor : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? activeColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // From
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fromCode,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.from,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Flight icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flight,
              size: 16,
              color: Color(0xFFFF3B30),
            ),
          ),

          // To
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.toCode,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.to,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "Showing ${_filteredFlights.length} of ${_flights.length} Flights found",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _showSortOptions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedSort,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey.shade700),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REDESIGNED FLIGHT CARD ====================
  Widget _buildFlightCard(Map<String, dynamic> flight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // onTap: () => _showBookingSheet(flight),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Airline row
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
                          flight["airlineCode"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Airline name and non-stop badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                flight["airline"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: flight["nonStop"]
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  flight["nonStop"] ? "Non Stop" : "${flight["stops"]} stop",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: flight["nonStop"]
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Time and duration row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Departure
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    flight["departure"],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    flight["departureAirport"] ?? widget.from,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),

                              // Duration and stops
                              Column(
                                children: [
                                  Text(
                                    flight["duration"],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Container(
                                    width: 60,
                                    height: 1,
                                    color: Colors.grey.shade300,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                  if (!flight["nonStop"])
                                    Text(
                                      "Via ${flight["stopCity"]}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),

                              // Arrival
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    flight["arrival"],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        flight["arrivalAirport"] ?? widget.to,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (flight["arrivalNextDay"] == true)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Text(
                                            "+1",
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.red.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),

                    // Price and button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${flight["currency"]} ${_formatPrice(flight["price"])}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {},
                          // onPressed: () => _showBookingSheet(flight),
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
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: const Text(
                              "View",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Additional flights info
                if (flight["additionalFlights"] != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "${flight["additionalFlights"]} more at same price",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  Color _getAirlineColor(String airline) {
    switch (airline) {
      case "Air India":
        return Colors.red.shade700;
      case "Air India Express":
        return Colors.orange.shade700;
      case "Indigo":
        return Colors.indigo.shade700;
      case "Akasa Air":
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [

          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Filters",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Airlines
              const Text(
                "Airlines",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...["All Airlines", "Indigo", "Air India Express", "Air India"].map((airline) {
                return RadioListTile<String>(
                  title: Text(airline),
                  value: airline,
                  groupValue: _selectedFilter,
                  activeColor: const Color(0xFFFF3B30),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                );
              }),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Apply Filters",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sort by",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...["Recommended", "Price: Low to High", "Price: High to Low", "Duration: Shortest", "Departure: Earliest"].map((sort) {
                return ListTile(
                  title: Text(sort),
                  trailing: _selectedSort == sort
                      ? const Icon(Icons.check, color: Color(0xFFFF3B30))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedSort = sort;
                    });
                    Navigator.pop(context);
                  },
                );
              }
              ),
            ],
          ),
        );
      },
    );
  }
}