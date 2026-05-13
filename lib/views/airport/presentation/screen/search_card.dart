import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../common_widgets/dopdown.dart';
import '../../../../common_widgets/loadingScreen.dart';
import '../../domain/entities/airport_entities.dart';
import '../bloc/airport_bloc.dart';
import '../bloc/airport_event.dart';
import '../bloc/airport_state.dart';
import '../../../flight_search/presentation/screen/flight_search_screen.dart';

class SearchCard extends StatefulWidget {
  const SearchCard({super.key});

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  bool isRoundTrip = false;

  // Store selected airports
  AirportEntity? fromAirport;
  AirportEntity? toAirport;
  DateTime? departureDate;
  DateTime? returnDate;

  int adults = 1;
  int children = 0;
  int infants = 0;

  String travelClass = "Economy";
  bool _isLoadingAirports = true;

  // void _performSearch() async {
  //   print(' All validations passed - starting search');
  //
  //   try {
  //     await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => ProfessionalLoadingScreen(
  //           searchParams: {
  //             'fromAirport': fromAirport,
  //             'toAirport': toAirport,
  //             'departureDate': departureDate,
  //             'returnDate': returnDate,
  //             'adults': adults,
  //             'children': children,
  //             'infants': infants,
  //             'class': travelClass,
  //             'isRoundTrip': isRoundTrip,
  //           },
  //
  //           onLoadingComplete: () async {
  //             print(' Loading complete - opening flight screen');
  //
  //             // FIRST close loading screen
  //             Navigator.of(context).pop();
  //
  //             // IMPORTANT
  //             await Future.delayed(const Duration(milliseconds: 300));
  //
  //             if (!mounted) return;
  //
  //             Navigator.of(context).push(
  //               MaterialPageRoute(
  //                 builder: (_) => FlightSearchScreen(
  //                   from: fromAirport!.cityName,
  //                   to: toAirport!.cityName,
  //                   fromCode: fromAirport!.airportCode,
  //                   toCode: toAirport!.airportCode,
  //                   fromAirport: fromAirport!.airportName,
  //                   toAirport: toAirport!.airportName,
  //                   date: departureDate,
  //                   travellers: adults + children + infants,
  //                   adults: adults,
  //                   children: children,
  //                   infants: infants,
  //                   travelClass: travelClass,
  //                   isRoundTrip: isRoundTrip,
  //                   returnDate: returnDate,
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     print('❌ Search navigation error: $e');
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: ${e.toString()}')),
  //     );
  //   }
  // }

  void _performSearch() async {
    print('All validations passed - opening flight screen');

    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FlightSearchScreen(
            from: fromAirport!.cityName,
            to: toAirport!.cityName,
            fromCode: fromAirport!.airportCode,
            toCode: toAirport!.airportCode,
            fromAirport: fromAirport!.airportName,
            toAirport: toAirport!.airportName,
            date: departureDate,
            travellers: adults + children + infants,
            adults: adults,
            children: children,
            infants: infants,
            travelClass: travelClass,
            isRoundTrip: isRoundTrip,
            returnDate: returnDate,
          ),
        ),
      );
    } catch (e) {
      print(' Search navigation error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  @override
  void initState() {
    super.initState();
    print(' [SearchCard] initState called');

    // Load airports for default country
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(' [SearchCard] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
      context.read<AirportBloc>().add(LoadAirports());
    });
  }

  @override
  void dispose() {
    print(' [SearchCard] dispose called');
    super.dispose();
  }
  void _openTravellerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// ADULTS
                  _travellerSection(
                    title: "Adults (Above 12 Years)",
                    selectedValue: adults,
                    onSelected: (val) {
                      setModalState(() => adults = val);
                    },
                  ),

                  const SizedBox(height: 18),

                  /// CHILDREN
                  _travellerSection(
                    title: "Children (2–12 Years)",
                    selectedValue: children,
                    onSelected: (val) {
                      setModalState(() => children = val);
                    },
                  ),

                  const SizedBox(height: 18),

                  /// INFANTS
                  _travellerSection(
                    title: "Infants (0–23 Months)",
                    selectedValue: infants,
                    onSelected: (val) {
                      setModalState(() => infants = val);
                    },
                  ),

                  const SizedBox(height: 24),

                  /// TRAVEL CLASS TITLE
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Travel Class",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// CLASS OPTIONS
                  Row(
                    children: [
                      Expanded(
                        child: _classRadio(
                          title: "Economy",
                          value: "Economy",
                          groupValue: travelClass,
                          onChanged: (val) {
                            setModalState(() => travelClass = val!);
                          },
                        ),
                      ),
                      Expanded(
                        child: _classRadio(
                          title: "Premium Economy",
                          value: "Premium Economy",
                          groupValue: travelClass,
                          onChanged: (val) {
                            setModalState(() => travelClass = val!);
                          },
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _classRadio(
                          title: "Business",
                          value: "Business",
                          groupValue: travelClass,
                          onChanged: (val) {
                            setModalState(() => travelClass = val!);
                          },
                        ),
                      ),
                      Expanded(
                        child: _classRadio(
                          title: "First",
                          value: "First",
                          groupValue: travelClass,
                          onChanged: (val) {
                            setModalState(() => travelClass = val!);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// APPLY BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "APPLY",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// NUMBER SELECTOR SECTION
  Widget _travellerSection({
    required String title,
    required int selectedValue,
    required Function(int) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// TITLE + COUNT
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              selectedValue.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// NUMBER CIRCLES
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            10,
                (index) => GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedValue == index
                      ? const Color(0xFF2962FF)
                      : Colors.white,
                  border: Border.all(
                    color: selectedValue == index
                        ? const Color(0xFF2962FF)
                        : Colors.grey.shade300,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  index.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selectedValue == index
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// RADIO BUTTON
  Widget _classRadio({
    required String title,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          activeColor: Colors.red,
          onChanged: onChanged,
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print(' [SearchCard] build called');

    return BlocConsumer<AirportBloc, AirportState>(
      listener: (context, state) {
        if (state is AirportError) {
          print(' [SearchCard] Airport loading error: ${state.message}');
        } else if (state is AirportLoaded) {
          setState(() => _isLoadingAirports = false);
          print(' [SearchCard] Airports loaded: ${state.airports.length} airports');
        }
      },
      builder: (context, airportState) {
        final airports = airportState is AirportLoaded ? airportState.airports : const <AirportEntity>[];
        final isLoading = airportState is AirportLoading;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              /// Trip Type Toggle
              Row(
                children: [
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: isRoundTrip,
                        activeColor: Colors.red,
                        onChanged: (val) {
                          print('[SearchCard] Trip type: ${val == true ? "Round Trip" : "One Way"}');
                          setState(() => isRoundTrip = val!);
                        },
                      ),
                      const Text("One Way"),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: isRoundTrip,
                        activeColor: Colors.red,
                        onChanged: (val) {
                          print(' [SearchCard] Trip type: ${val == true ? "Round Trip" : "One Way"}');
                          setState(() => isRoundTrip = val!);
                        },
                      ),
                      const Text("Round Trip"),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),


              /// FROM - TO with Dynamic Airports
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        // FROM field with dynamic airports
                        CustomAutocompleteGeneric<AirportEntity>(
                          options: airports,
                          label: "From",
                          displayStringForOption: (airport) =>
                          "${airport.cityName} (${airport.airportCode})",
                          searchStringForOption: (airport) =>
                          "${airport.airportName} ${airport.airportCode} ${airport.cityName}",
                          initialText: fromAirport != null
                              ? "${fromAirport!.cityName} (${fromAirport!.airportCode})"
                              : null,
                          debounceDuration: const Duration(milliseconds: 500), // Longer for API
                          onSearchChanged: (query) {  //  ADD THIS BLOCK
                            print('>>>>>>> SEARCHING FOR: "$query"');
                            if (query.trim().isNotEmpty) {
                              // Call API with search query
                              context.read<AirportBloc>().add(LoadAirports(searchQuery: query));
                            } else {
                              // Load default airports when empty
                              context.read<AirportBloc>().add(LoadAirports());
                            }
                          },
                          onSelected: (airport) {
                            if (toAirport != null && toAirport!.airportCode == airport.airportCode) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Origin and destination cannot be the same airport'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              fromAirport = airport;
                            });
                          },
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Colors.grey.shade300, thickness: 1),
                        ),

                        // TO field with dynamic airports
                        CustomAutocompleteGeneric<AirportEntity>(
                          options: airports,
                          label: "To",
                          displayStringForOption: (airport) =>
                          "${airport.cityName} (${airport.airportCode})",
                          searchStringForOption: (airport) =>
                          "${airport.airportName} ${airport.airportCode} ${airport.cityName}",
                          initialText: toAirport != null
                              ? "${toAirport!.cityName} (${toAirport!.airportCode})"
                              : null,
                          debounceDuration: const Duration(milliseconds: 500),
                          onSearchChanged: (query) {  //  ADD THIS
                            print('>>>>>>>> SEARCHING FOR: "$query"');
                            if (query.trim().isNotEmpty) {
                              context.read<AirportBloc>().add(LoadAirports(searchQuery: query));
                            } else {
                              context.read<AirportBloc>().add(LoadAirports());
                            }
                          },
                          onSelected: (airport) {
                            if (fromAirport != null && fromAirport!.airportCode == airport.airportCode) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Origin and destination cannot be the same airport'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              toAirport = airport;
                            });
                          },
                        ),
                      ],
                    ),

                    /// Swap Button
                    GestureDetector(
                      onTap: () {
                        print(' [SearchCard] Swapping airports');
                        setState(() {
                          final temp = fromAirport;
                          fromAirport = toAirport;
                          toAirport = temp;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.swap_vert, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// DATE + TRAVELLER
              Row(
                children: [
                  Expanded(
                    child: _dateTile("Departure", departureDate, () => _pickDate(isReturn: false)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: isRoundTrip ? () => _pickDate(isReturn: true) : null,
                      child: Opacity(
                        opacity: isRoundTrip ? 1 : 0.5,
                        child: _dateTile(
                          "Return",
                          isRoundTrip ? returnDate : null,
                          isRoundTrip ? () => _pickDate(isReturn: true) : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              InkWell(
                onTap: _openTravellerSheet,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${adults + children + infants} Traveller${(adults + children + infants) > 1 ? 's' : ''} ( $travelClass class )",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// SEARCH BUTTON
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _performSearch();
                    },
                    icon: const Icon(Icons.search, size: 18, color: Colors.white),
                    label: const Text(
                      "Search",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  Widget _dateTile(String title, DateTime? date, VoidCallback? onTap) {
    return GestureDetector(
      onTap: () {
        print(' [SearchCard] Date tapped: $title');
        if (onTap != null) onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              date == null ? "Select date" : DateFormat('dd MMM').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate({required bool isReturn}) async {
    print(' [SearchCard] Opening date picker - isReturn: $isReturn');

    DateTime now = DateTime.now();
    final ThemeData theme = Theme.of(context);

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isReturn && departureDate != null && departureDate!.isAfter(now)
          ? departureDate!
          : now,
      firstDate: now,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF3B30),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      print(' [SearchCard] Date picked: ${DateFormat('dd MMM yyyy').format(picked)}');
      setState(() {
        if (isReturn) {
          if (departureDate != null && picked.isBefore(departureDate!)) {
            returnDate = departureDate;
          } else {
            returnDate = picked;
          }
        } else {
          departureDate = picked;
          if (returnDate != null && picked.isAfter(returnDate!)) {
            returnDate = null;
          }
        }
      });
    }
  }
}