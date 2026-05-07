// flight_filter_drawer.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class FlightFilterDrawer extends StatefulWidget {
  const FlightFilterDrawer({super.key});

  @override
  State<FlightFilterDrawer> createState() => _FlightFilterDrawerState();
}

class _FlightFilterDrawerState extends State<FlightFilterDrawer> {
  bool nonStop = true;
  bool oneStop = false;

  final Map<String, bool> departureTimes = {
    '05am-12pm': false,
    '12pm-6pm': false,
    '6pm-11pm': false,
    '11pm-05am': false,
  };

  final Map<String, bool> arrivalTimes = {
    '05am-12pm': false,
    '12pm-6pm': false,
    '6pm-11pm': false,
    '11pm-05am': false,
  };

  final Map<String, bool> airlines = {
    'Air India': true,
    'Air India Express': true,
    'Indigo': true,
  };

  final Map<String, int> airlinePrices = {
    'Air India': 9102,
    'Air India Express': 7335,
    'Indigo': 14430,
  };

  final Map<String, int> airlineCounts = {
    'Air India': 74,
    'Air India Express': 2,
    'Indigo': 5,
  };

  RangeValues priceRange = const RangeValues(7335, 56700);

  final List<String> airports = [
    'Ahmedabad',
    'Bangalore',
    'Chennai',
    'Hyderabad',
    'Jaipur',
  ];

  final Set<String> selectedAirports = {};

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _header(),

              /// CONTENT
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [

                    /// STOPS
                    _title("Stops"),
                    const SizedBox(height: 10),
                    _buildStops(),

                    const SizedBox(height: 20),

                    /// FARE TYPE
                    _title("Fare Type"),
                    const SizedBox(height: 6),
                    _buildFareType(),

                    const SizedBox(height: 20),

                    /// DEPARTURE TIME
                    _title("Departure Time"),
                    const SizedBox(height: 10),
                    _buildTimeGrid(departureTimes),

                    const SizedBox(height: 20),

                    /// ARRIVAL TIME
                    _title("Arrival Times"),
                    const SizedBox(height: 10),
                    _buildTimeGrid(arrivalTimes),


                    /// AIRLINES
                    const SizedBox(height: 20),
                    _title("Airlines"),
                    const SizedBox(height: 10),
                    _buildAirlines(),

                    /// PRICE RANGE
                    const SizedBox(height: 20),
                    _title("Price Range"),
                    const SizedBox(height: 10),
                    _buildPrice(),

                    /// CONNECTING AIRPORTS
                    const SizedBox(height: 20),
                    _title("Connecting Airports"),
                    const SizedBox(height: 10),
                    _buildAirports(),
                  ],
                ),
              ),

              _bottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: const Text(
        "Filters",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------- TITLE ----------------
  Widget _title(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }

  // ---------------- STOPS ----------------
  Widget _buildStops() {
    return Row(
      children: [
        _stopCard("Non Stop", "7,538", nonStop, () {
          setState(() => nonStop = !nonStop);
        }),
        const SizedBox(width: 12),
        _stopCard("1", "10,460", oneStop, () {
          setState(() => oneStop = !oneStop);
        }),
      ],
    );
  }

  Widget _stopCard(String title, String price, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: selected
                  ? const LinearGradient(
                colors: [Color(0xFF5B86E5), Color(0xFF6A5AE0)],
              )
                  : null,
              color: selected ? null : Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FARE TYPE ----------------
  Widget _buildFareType() {
    return Column(
      children: [
        _checkTile("Refundable"),
        _checkTile("Non-refundable"),
      ],
    );
  }

  Widget _checkTile(String text) {
    return CheckboxListTile(
      value: false,
      onChanged: (v) {},
      title: Text(text, style: const TextStyle(fontSize: 13)),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  // ---------------- TIME GRID ----------------
  Widget _buildTimeGrid(Map<String, bool> map) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: map.keys.map((time) {
        bool selected = map[time]!;

        return GestureDetector(
          onTap: () {
            setState(() {
              map[time] = !selected;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? Colors.blue : Colors.grey.shade300,
              ),
              color: selected ? Colors.blue.withOpacity(0.08) : Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(time, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------- BUTTONS ----------------
  Widget _bottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              child: const Text("Reset"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Apply"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirlines() {
    return Column(
      children: [
        /// SELECT ALL
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Select All", style: TextStyle(fontSize: 13)),
            Checkbox(
              value: airlines.values.every((e) => e),
              onChanged: (val) {
                setState(() {
                  airlines.updateAll((key, value) => val!);
                });
              },
            )
          ],
        ),

        /// LIST
        ...airlines.keys.map((name) {
          return Row(
            children: [
              const Icon(Icons.flight, size: 18),

              const SizedBox(width: 8),

              Expanded(
                child: Text(name, style: const TextStyle(fontSize: 13)),
              ),

              Text(
                "(${airlineCounts[name]})  ${airlinePrices[name]}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),

              Checkbox(
                value: airlines[name],
                onChanged: (v) {
                  setState(() {
                    airlines[name] = v!;
                  });
                },
              )
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPrice() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${priceRange.start.toInt()}",
                style: const TextStyle(color: Colors.blue)),
            Text("${priceRange.end.toInt()}",
                style: const TextStyle(color: Colors.blue)),
          ],
        ),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: RangeSlider(
            values: priceRange,
            min: 0,
            max: 60000,
            activeColor: Colors.blue,
            onChanged: (v) {
              setState(() => priceRange = v);
            },
          ),
        )
      ],
    );
  }

  // Connecting airports

  Widget _buildAirports() {
    return Column(
      children: airports.map((airport) {
        return CheckboxListTile(
          value: selectedAirports.contains(airport),
          onChanged: (v) {
            setState(() {
              if (v!) {
                selectedAirports.add(airport);
              } else {
                selectedAirports.remove(airport);
              }
            });
          },
          title: Text(airport, style: const TextStyle(fontSize: 13)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}