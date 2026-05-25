import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/trip_model.dart';

class UpcomingTripsScreen extends StatefulWidget {
  const UpcomingTripsScreen({super.key});

  @override
  State<UpcomingTripsScreen> createState() => _UpcomingTripsScreenState();
}

class _UpcomingTripsScreenState extends State<UpcomingTripsScreen> {
  int _selectedFilterIndex = 0;

  // Mock Data based on Image 1
  final List<TripItem> _trips = [
    TripItem(refId: "WNVISA18", destination: "India", type: "30 Days Tourist E-Visa", price: 150, status: "Payment pending", bookedDate: "25 May 2026", applicantCount: "1"),
    TripItem(refId: "WNVISA17", destination: "India", type: "30 Days Tourist E-Visa", price: 150, status: "Payment pending", bookedDate: "25 May 2026", applicantCount: "1"),
    TripItem(refId: "WNVISA12", destination: "Switzerland", type: "Switzerland Tourist Visa", price: 200, status: "Payment pending", bookedDate: "21 May 2026", applicantCount: "1"),
    TripItem(refId: "WNVISA11", destination: "Switzerland", type: "Switzerland Tourist Visa", price: 200, status: "Payment pending", bookedDate: "21 May 2026", applicantCount: "1"),
    TripItem(refId: "WNVISA10", destination: "Switzerland", type: "Switzerland Tourist Visa", price: 200, status: "Payment pending", bookedDate: "21 May 2026", applicantCount: "1"),
    TripItem(refId: "WNVISA9", destination: "Switzerland", type: "Switzerland Tourist Visa", price: 200, status: "Payment pending", bookedDate: "21 May 2026", applicantCount: "1"),
  ];

  // Filter Categories
  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.handshake_outlined},
    {'label': 'Flight', 'icon': Icons.flight_takeoff},
    {'label': 'Hotel', 'icon': Icons.hotel},
    {'label': 'Transport', 'icon': Icons.directions_car},
    {'label': 'Visa', 'icon': Icons.card_membership},
    {'label': 'Holidays', 'icon': Icons.beach_access},
  ];

  void _onFilterTap(int index) {
    setState(() {
      _selectedFilterIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we are in "Flight" mode to show empty state
    bool isFlightMode = _categories[_selectedFilterIndex]['label'] == 'Flight';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.account_circle_outlined, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              "My Account",
              style: TextStyle(color: Colors.blue[700], fontSize: 14),
            ),
            const Text(" > ", style: TextStyle(color: Colors.grey)),
            Text(
              "Upcoming Trips",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- HEADER & FILTERS ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEBF4FF), Color(0xFFFCE4EC)], // Subtle gradient like web
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Sort By & Search Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text("SORT BY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Text("Travel Date", style: TextStyle(fontSize: 12)),
                            Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text("SEARCH", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Horizontal Scrollable Filters (Touch Responsive)
                SizedBox(
                  height: 82, // Fixed height for the filter area
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedFilterIndex == index;
                      return GestureDetector(
                        onTap: () => _onFilterTap(index),
                        child: Container(
                          width: 70, // Touch friendly width
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                child: Icon(
                                  _categories[index]['icon'],
                                  color: isSelected ? Colors.red[700] : Colors.grey,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _categories[index]['label'],
                                style: TextStyle(
                                  color: isSelected ? Colors.red[700] : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
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

          // --- MAIN CONTENT ---
          Expanded(
            child: isFlightMode
                ? _buildEmptyState()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return _buildTripCard(trip);
      },
    );
  }

  Widget _buildTripCard(TripItem trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ref and Title
          Row(
            children: [
              Text("Ref: ${trip.refId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${trip.destination} — ${trip.type}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            "${trip.applicantCount} applicant(s) • ${trip.status}",
            style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
          ),

          const SizedBox(height: 12),

          // Divider
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 4),

          // Footer: Price and Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Booked: ${trip.bookedDate}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),

              // Middle: Price
              Text(
                "${trip.price}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(width: 16),

              // Right: Buttons
              Container(
                height: 36,
                child: Row(
                  children: [
                    // Cancel Button (Outline)
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
                        minimumSize: Size.zero,
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    // View Details Button (Filled Red)
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F), // Red color
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
                        minimumSize: Size.zero,
                      ),
                      child: const Text("View details", style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Empty State Widget (Based on Image 2)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              "Looks like empty, you've no bookings.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Try using search to find the perfect place for you.",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("PLAN A TRIP", style: TextStyle(letterSpacing: 1, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}