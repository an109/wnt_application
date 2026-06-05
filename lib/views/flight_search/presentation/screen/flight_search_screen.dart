// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
// import '../../../../../injection_container.dart';
// import '../../../../UI_helper/currency_converter.dart';
// import '../../../../common_widgets/custom_bottom_nav.dart';
// import '../../../../common_widgets/loadingScreen.dart';
// import '../../../../common_widgets/logo.dart';
// import '../../../../core/utils/storage/shared_preference.dart';
// import '../../domain/entities/flight_entity.dart';
// import '../../domain/entities/flight_search_request_entity.dart';
// import '../bloc/flight_search_bloc.dart';
// import '../bloc/flight_search_event.dart';
// import '../bloc/flight_search_state.dart';
// import 'detail_popup.dart';
// import 'filter_drawer.dart';
//
// class FlightSearchScreen extends StatefulWidget {
//   final String from;
//   final String to;
//   final String fromCode;
//   final String toCode;
//   final String fromAirport;
//   final String toAirport;
//   final DateTime? date;
//   final int travellers;
//   final int adults;
//   final int children;
//   final int infants;
//   final String travelClass;
//   final bool isRoundTrip;
//   final DateTime? returnDate;
//
//   const FlightSearchScreen({
//     super.key,
//     required this.from,
//     required this.to,
//     required this.fromCode,
//     required this.toCode,
//     required this.fromAirport,
//     required this.toAirport,
//     required this.date,
//     required this.travellers,
//     required this.adults,
//     required this.children,
//     required this.infants,
//     required this.travelClass,
//     required this.isRoundTrip,
//     this.returnDate,
//   });
//
//   @override
//   State<FlightSearchScreen> createState() => _FlightSearchScreenState();
// }
//
// class _FlightSearchScreenState extends State<FlightSearchScreen>
//     with SingleTickerProviderStateMixin {
//   late FlightSearchBloc _flightSearchBloc;
//   String _selectedSort = "Recommended";
//   String _selectedFilter = "All Airlines";
//   int currentIndex = 0;
//   String _selectedTab = "Best Value";
//   bool _isApiCalled = false;
//   late TabController _tabController;
//   late List<Map<String, dynamic>> _dateOptions;
//
//   // Filter state
//   bool _showFilters = false;
//   Set<String> _selectedAirlines = {};
//   RangeValues _priceRange = const RangeValues(0, 50000);
//   double _maxPrice = 50000;
//
//   // Stops filter
//   int? _selectedStops; // null = all, 0 = non-stop, 1 = 1 stop, 2 = 2+ stops
//
//   void _initDateOptions() {
//     final now = DateTime.now();
//     _dateOptions = List.generate(7, (index) {
//       final date = now.add(Duration(days: index));
//       final dayFormat = DateFormat('EEE').format(date);
//       final dateFormat = DateFormat('d MMM').format(date);
//
//       return {
//         "day": dayFormat,
//         "date": dateFormat,
//         "price": 0, // You can fetch prices or keep as placeholder
//         "selected": index == 0, // First date selected by default
//         "dateTime": date, // Store actual DateTime object
//       };
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _flightSearchBloc = sl<FlightSearchBloc>();
//     _tabController = TabController(length: 3, vsync: this);
//     _triggerFlightSearch();
//     _initDateOptions();
//   }
//
//   @override
//   void dispose() {
//     _flightSearchBloc.close();
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   void _triggerFlightSearch() {
//     if (_isApiCalled) return;
//     _isApiCalled = true;
//
//     final request = _buildRequest();
//     _flightSearchBloc.add(SearchFlightsEvent(request));
//   }
//
//   void _onDateSelected(int selectedIndex, DateTime newDate) {
//     // Update UI selection state
//     for (var i = 0; i < _dateOptions.length; i++) {
//       _dateOptions[i]["selected"] = i == selectedIndex;
//     }
//
//     // Update the departure date in widget
//     setState(() {
//       // This will trigger a rebuild with the new selection
//     });
//
//     // Create new request with updated date
//     final updatedRequest = FlightSearchRequestEntity(
//       endUserIp: '203.0.113.10',
//       adultCount: widget.adults,
//       childCount: widget.children,
//       infantCount: widget.infants,
//       journeyType: widget.isRoundTrip ? 2 : 1,
//       segments: [
//         FlightSegmentEntity(
//           origin: widget.fromCode,
//           destination: widget.toCode,
//           flightCabinClass: _getCabinClassInt(widget.travelClass),
//           preferredDepartureTime: _formatDateForAPI(newDate),
//           preferredArrivalTime: _formatDateForAPI(newDate),
//         ),
//       ],
//     );
//
//     // Add return segment if round trip
//     if (widget.isRoundTrip && widget.returnDate != null) {
//       updatedRequest.segments.add(
//         FlightSegmentEntity(
//           origin: widget.toCode,
//           destination: widget.fromCode,
//           flightCabinClass: _getCabinClassInt(widget.travelClass),
//           preferredDepartureTime: _formatDateForAPI(widget.returnDate),
//           preferredArrivalTime: _formatDateForAPI(widget.returnDate),
//         ),
//       );
//     }
//
//     // Trigger new search
//     _flightSearchBloc.add(SearchFlightsEvent(updatedRequest));
//   }
//
//   FlightSearchRequestEntity _buildRequest() {
//     final segments = <FlightSegmentEntity>[
//       FlightSegmentEntity(
//         origin: widget.fromCode,
//         destination: widget.toCode,
//         flightCabinClass: _getCabinClassInt(widget.travelClass),
//         preferredDepartureTime: _formatDateForAPI(widget.date),
//         preferredArrivalTime: _formatDateForAPI(widget.date),
//       ),
//     ];
//
//     if (widget.isRoundTrip && widget.returnDate != null) {
//       segments.add(
//         FlightSegmentEntity(
//           origin: widget.toCode,
//           destination: widget.fromCode,
//           flightCabinClass: _getCabinClassInt(widget.travelClass),
//           preferredDepartureTime: _formatDateForAPI(widget.returnDate),
//           preferredArrivalTime: _formatDateForAPI(widget.returnDate),
//         ),
//       );
//     }
//
//     return FlightSearchRequestEntity(
//       endUserIp: '203.0.113.10',
//       adultCount: widget.adults,
//       childCount: widget.children,
//       infantCount: widget.infants,
//       journeyType: widget.isRoundTrip ? 2 : 1,
//       segments: segments,
//     );
//   }
//
//   String _formatDateForAPI(DateTime? date) {
//     if (date == null) return '';
//     return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00';
//   }
//
//   int _getCabinClassInt(String travelClass) {
//     switch (travelClass.toLowerCase()) {
//       case 'economy':
//         return 2;
//       case 'premium economy':
//         return 3;
//       case 'business':
//         return 4;
//       case 'first':
//         return 5;
//       default:
//         return 2;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider<FlightSearchBloc>(
//       create: (_) => _flightSearchBloc,
//       child: Scaffold(
//         drawer: const FlightFilterDrawer(),
//         appBar: AppBar(
//           title: const WanderNovaLogo(scaleFactor: 0.6),
//           backgroundColor: Colors.white,
//           elevation: 0,
//           actions: [
//             Padding(
//               padding: EdgeInsets.all(context.w(8)),
//               child: Image.asset("assets/images/wander_nova_logo.png", height: context.h(35)),
//             )
//           ],
//         ),
//         backgroundColor: Colors.grey.shade50,
//         body: BlocBuilder<FlightSearchBloc, FlightSearchState>(
//           builder: (context, state) {
//             if (state is FlightSearchLoading) {
//               return ProfessionalLoadingScreen(
//                 searchParams: {
//                   'fromAirport': widget.fromAirport,
//                   'toAirport': widget.toAirport,
//                   'departureDate': widget.date,
//                   'returnDate': widget.returnDate,
//                   'adults': widget.adults,
//                   'children': widget.children,
//                   'infants': widget.infants,
//                   'class': widget.travelClass,
//                   'isRoundTrip': widget.isRoundTrip,
//                 },
//                 onLoadingComplete: () {},
//               );
//             }
//
//             if (state is FlightSearchError) {
//               return _buildErrorState(state.message);
//             }
//
//             if (state is FlightSearchLoaded) {
//               _updateMaxPrice(state.flights);
//               return _buildMainContent(state.flights);
//             }
//
//             return _buildEmptyState();
//           },
//         ),
//         bottomNavigationBar: const CustomBottomNav(
//           currentIndex: 0,
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildMainContent(List<FlightEntity> flights) {
//     final filteredFlights = _applyAdvancedFilters(flights);
//
//     return Column(
//       children: [
//         _buildDateSelector(),
//         // _buildSortAndFilterBar(),
//         Expanded(
//           child: _showFilters
//               ? _buildFilterPanel(filteredFlights, flights)
//               : _buildFlightList(filteredFlights),
//         ),
//       ],
//     );
//   }
//
//
//   int _getMonthNumber(String monthAbbr) {
//     const months = {
//       'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
//       'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
//     };
//     return months[monthAbbr] ?? DateTime.now().month;
//   }
//
//   String _formatDuration(int? minutes) {
//     if (minutes == null || minutes == 0) return '0';
//
//     final hours = minutes ~/ 60;
//     final remainingMinutes = minutes % 60;
//
//     if (hours > 0 && remainingMinutes > 0) {
//       return '$hours hr $remainingMinutes min';
//     } else if (hours > 0) {
//       return '$hours hr';
//     } else {
//       return '$remainingMinutes min';
//     }
//   }
//
//   Widget _buildDateSelector() {
//     return Container(
//       color: Colors.white,
//       padding: EdgeInsets.symmetric(vertical: context.h(8)),
//       child: SizedBox(
//         height: context.h(65),
//         child: ListView.separated(
//           scrollDirection: Axis.horizontal,
//           padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
//           itemCount: _dateOptions.length,
//           separatorBuilder: (context, index) => SizedBox(width: context.gapSmall),
//           itemBuilder: (context, index) {
//             final date = _dateOptions[index];
//             final isSelected = date["selected"] as bool;
//
//             return GestureDetector(
//               onTap: () {
//                 // Parse the selected date from the date option
//                 final dateStr = date["date"] as String;
//                 final day = int.parse(dateStr.split(' ')[0]);
//                 final month = _getMonthNumber(dateStr.split(' ')[1]);
//                 final year = DateTime.now().year;
//
//                 final selectedDate = DateTime(year, month, day);
//
//                 // Call the date selection handler
//                 _onDateSelected(index, selectedDate);
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 width: context.w(68),
//                 decoration: BoxDecoration(
//                   color: isSelected ? const Color(0xFF0A2463) : Colors.white,
//                   borderRadius: BorderRadius.circular(context.borderRadius),
//                   border: Border.all(
//                     color: isSelected ? const Color(0xFF0A2463) : Colors.grey.shade200,
//                     width: 1.5,
//                   ),
//                   boxShadow: isSelected
//                       ? [BoxShadow(
//                     color: const Color(0xFF0A2463).withOpacity(0.2),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   )]
//                       : null,
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       date["day"],
//                       style: TextStyle(
//                         fontSize: context.labelSmall,
//                         fontWeight: FontWeight.w500,
//                         color: isSelected ? Colors.white : Colors.grey.shade600,
//                       ),
//                     ),
//                     SizedBox(height: context.gapXXSmall),
//                     Text(
//                       date["date"],
//                       style: TextStyle(
//                         fontSize: context.labelSmall,
//                         fontWeight: FontWeight.w600,
//                         color: isSelected ? Colors.white : Colors.grey.shade800,
//                       ),
//                     ),
//                     // SizedBox(height: context.gapXXSmall),
//                     // Text(
//                     //   "₹${date["price"]}",
//                     //   style: TextStyle(
//                     //     fontSize: context.labelMedium,
//                     //     fontWeight: FontWeight.bold,
//                     //     color: isSelected ? Colors.white : const Color(0xFF00A859),
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   String _convertFlightPrice(double amount, String? apiCurrency) {
//     try {
//       final prefs = sl<PreferencesManager>();
//       final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';
//
//       // Default to INR if no currency provided
//       final fromCurrency = apiCurrency ?? 'INR';
//
//       // Skip conversion if same currency
//       if (fromCurrency.toUpperCase() == targetCurrency.toUpperCase()) {
//         return _formatPrice(amount.toInt());
//       }
//
//       // Convert using cached rates
//       final converted = CurrencyConverter.convert(
//         amount: amount,
//         fromCurrency: fromCurrency,
//         toCurrency: targetCurrency,
//       );
//
//       // Format based on target currency
//       if (targetCurrency.toUpperCase() == 'INR') {
//         return '₹${_formatIndianNumber(converted.toInt())}';
//       }
//
//       final symbol = CurrencyConverter.getSymbol(targetCurrency);
//       return '$symbol${converted.toStringAsFixed(0)}';
//
//     } catch (e) {
//       print('FlightSearchScreen: Price conversion error: $e');
//       return _formatPrice(amount.toInt());
//     }
//   }
//
//   String _formatIndianNumber(int num) {
//     if (num < 1000) return num.toString();
//     final str = num.toString();
//     final lastThree = str.substring(str.length - 3);
//     final remaining = str.substring(0, str.length - 3);
//     var formatted = '';
//     for (int i = 0; i < remaining.length; i++) {
//       if (i > 0 && (remaining.length - i) % 2 == 0) {
//         formatted += ',';
//       }
//       formatted += remaining[i];
//     }
//     return '$formatted,$lastThree';
//   }
//
//   Widget _buildFilterPanel(List<FlightEntity> filteredFlights, List<FlightEntity> allFlights) {
//     return Container(
//       color: Colors.white,
//       child: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.all(context.w(12)),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Filters',
//                       style: TextStyle(
//                         fontSize: context.titleMedium,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         setState(() {
//                           _selectedAirlines.clear();
//                           _priceRange =  RangeValues(0, _maxPrice);
//                           _selectedStops = null;
//                         });
//                       },
//                       child: Text(
//                         'Reset',
//                         style: TextStyle(
//                           color: const Color(0xFFFF3B30),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: context.gapMedium),
//                 // Price Range
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Price Range',
//                       style: TextStyle(
//                         fontSize: context.titleSmall,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: context.gapSmall),
//                     RangeSlider(
//                       values: _priceRange,
//                       min: 0,
//                       max: _maxPrice,
//                       divisions: 100,
//                       activeColor: const Color(0xFFFF3B30),
//                       inactiveColor: Colors.grey.shade300,
//                       labels: RangeLabels(
//                         '₹${_priceRange.start.round()}',
//                         '₹${_priceRange.end.round()}',
//                       ),
//                       onChanged: (values) {
//                         setState(() {
//                           _priceRange = values;
//                         });
//                       },
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           '₹${_priceRange.start.round()}',
//                           style: TextStyle(
//                             fontSize: context.labelSmall,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                         Text(
//                           '₹${_priceRange.end.round()}',
//                           style: TextStyle(
//                             fontSize: context.labelSmall,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: context.gapLarge),
//                 // Stops Filter
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Stops',
//                       style: TextStyle(
//                         fontSize: context.titleSmall,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: context.gapSmall),
//                     Row(
//                       children: [
//                         _buildStopOption("Any", null),
//                         SizedBox(width: context.gapSmall),
//                         _buildStopOption("Non-stop", 0),
//                         SizedBox(width: context.gapSmall),
//                         _buildStopOption("1 Stop", 1),
//                         SizedBox(width: context.gapSmall),
//                         _buildStopOption("2+ Stops", 2),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Divider(height: 1, color: Colors.grey.shade200),
//           Row(
//             children: [
//               Expanded(
//                 child: TextButton(
//                   onPressed: () => setState(() => _showFilters = false),
//                   style: TextButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: context.gapMedium),
//                   ),
//                   child: Text(
//                     'Cancel',
//                     style: TextStyle(
//                       fontSize: context.titleSmall,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ),
//               ),
//               Container(
//                 height: context.hp(5),
//                 width: 1,
//                 color: Colors.grey.shade200,
//               ),
//               Expanded(
//                 child: TextButton(
//                   onPressed: () => setState(() => _showFilters = false),
//                   style: TextButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: context.gapMedium),
//                   ),
//                   child: Text(
//                     'Apply (${filteredFlights.length})',
//                     style: TextStyle(
//                       fontSize: context.titleSmall,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFFFF3B30),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStopOption(String label, int? stops) {
//     final isSelected = _selectedStops == stops;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => _selectedStops = stops),
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: context.h(8)),
//           decoration: BoxDecoration(
//             color: isSelected ? const Color(0xFFFF3B30).withOpacity(0.1) : Colors.transparent,
//             borderRadius: BorderRadius.circular(context.borderRadius),
//             border: Border.all(
//               color: isSelected ? const Color(0xFFFF3B30) : Colors.grey.shade300,
//             ),
//           ),
//           child: Center(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: context.labelSmall,
//                 fontWeight: FontWeight.w500,
//                 color: isSelected ? const Color(0xFFFF3B30) : Colors.grey.shade700,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFlightList(List<FlightEntity> flights) {
//     final filteredFlights = _applyFiltersAndSort(flights);
//
//     return CustomScrollView(
//       slivers: [
//         SliverToBoxAdapter(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
//             child: _buildResultsHeader(filteredFlights.length, flights.length),
//           ),
//         ),
//         SliverPadding(
//           padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
//           sliver: SliverList(
//             delegate: SliverChildBuilderDelegate(
//                   (context, index) {
//                 if (index == filteredFlights.length) {
//                   return SizedBox(height: context.gapLarge);
//                 }
//                 return _buildEnhancedFlightCard(filteredFlights[index]);
//               },
//               childCount: filteredFlights.length,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Widget _buildEnhancedFlightCard(FlightEntity flight) {
//   //   return Container(
//   //     margin: EdgeInsets.only(bottom: context.gapMedium),
//   //     decoration: BoxDecoration(
//   //       color: Colors.white,
//   //       borderRadius: BorderRadius.circular(context.borderRadius),
//   //       boxShadow: [
//   //         BoxShadow(
//   //           color: Colors.black.withOpacity(0.05),
//   //           blurRadius: 10,
//   //           offset: const Offset(0, 2),
//   //         ),
//   //       ],
//   //     ),
//   //     child: Material(
//   //       color: Colors.transparent,
//   //       child: InkWell(
//   //         onTap: () => _showFlightDetails(flight),
//   //         borderRadius: BorderRadius.circular(context.borderRadius),
//   //         child: Padding(
//   //           padding: EdgeInsets.all(context.w(12)),
//   //           child: Column(
//   //             children: [
//   //               Row(
//   //                 crossAxisAlignment: CrossAxisAlignment.start,
//   //                 children: [
//   //                   // Airline logo
//   //                   Container(
//   //                     width: context.wp(12),
//   //                     height: context.wp(12),
//   //                     decoration: BoxDecoration(
//   //                       gradient: LinearGradient(
//   //                         begin: Alignment.topLeft,
//   //                         end: Alignment.bottomRight,
//   //                         colors: [
//   //                           const Color(0xFFFF3B30).withOpacity(0.15),
//   //                           const Color(0xFFFF3B30).withOpacity(0.05),
//   //                         ],
//   //                       ),
//   //                       borderRadius: BorderRadius.circular(context.borderRadius),
//   //                     ),
//   //                     child: Center(
//   //                       child: Text(
//   //                         flight.airlineCode?.substring(0, 2) ?? '--',
//   //                         style: TextStyle(
//   //                           fontSize: context.titleLarge,
//   //                           fontWeight: FontWeight.bold,
//   //                           color: const Color(0xFFFF3B30),
//   //                         ),
//   //                       ),
//   //                     ),
//   //                   ),
//   //                   SizedBox(width: context.gapMedium),
//   //
//   //                   // Flight details
//   //                   Expanded(
//   //                     child: Column(
//   //                       crossAxisAlignment: CrossAxisAlignment.start,
//   //                       children: [
//   //                         Row(
//   //                           children: [
//   //                             Text(
//   //                               flight.airlineName ?? 'Unknown',
//   //                               style: TextStyle(
//   //                                 fontWeight: FontWeight.bold,
//   //                                 fontSize: context.titleMedium,
//   //                               ),
//   //                             ),
//   //                             SizedBox(width: context.gapSmall),
//   //                             Container(
//   //                               padding: EdgeInsets.symmetric(
//   //                                 horizontal: context.gapXSmall,
//   //                                 vertical: context.gapXXSmall,
//   //                               ),
//   //                               decoration: BoxDecoration(
//   //                                 color: (flight.seatsAvailable ?? 9) > 5
//   //                                     ? Colors.green.withOpacity(0.1)
//   //                                     : Colors.orange.withOpacity(0.1),
//   //                                 borderRadius: BorderRadius.circular(context.borderRadiusSmall),
//   //                               ),
//   //                               child: Text(
//   //                                 (flight.seatsAvailable ?? 9) > 5 ? "Available" : "Few seats",
//   //                                 style: TextStyle(
//   //                                   fontSize: context.labelSmall,
//   //                                   color: (flight.seatsAvailable ?? 9) > 5
//   //                                       ? Colors.green.shade700
//   //                                       : Colors.orange.shade700,
//   //                                   fontWeight: FontWeight.w500,
//   //                                 ),
//   //                               ),
//   //                             ),
//   //                           ],
//   //                         ),
//   //                         SizedBox(height: context.gapSmall),
//   //
//   //                         // Time and route with enhanced design
//   //                         Row(
//   //                           children: [
//   //                             Expanded(
//   //                               child: Column(
//   //                                 crossAxisAlignment: CrossAxisAlignment.start,
//   //                                 children: [
//   //                                   Text(
//   //                                     _formatTime(flight.departureTime),
//   //                                     style: TextStyle(
//   //                                       fontSize: context.titleLarge,
//   //                                       fontWeight: FontWeight.bold,
//   //                                     ),
//   //                                   ),
//   //                                   SizedBox(height: context.gapXXSmall),
//   //                                   Text(
//   //                                     flight.origin ?? '--',
//   //                                     style: TextStyle(
//   //                                       fontSize: context.labelSmall,
//   //                                       color: Colors.grey.shade600,
//   //                                     ),
//   //                                   ),
//   //                                 ],
//   //                               ),
//   //                             ),
//   //                             Expanded(
//   //                               child: Column(
//   //                                 children: [
//   //                                   Text(
//   //                                     _formatDuration(flight.duration != null ? int.tryParse(flight.duration!) : null),
//   //                                     style: TextStyle(
//   //                                       fontSize: context.labelSmall,
//   //                                       color: Colors.grey.shade500,
//   //                                     ),
//   //                                   ),
//   //                                   SizedBox(height: context.gapXXSmall),
//   //                                   Stack(
//   //                                     alignment: Alignment.center,
//   //                                     children: [
//   //                                       Container(
//   //                                         width: double.infinity,
//   //                                         height: 1,
//   //                                         color: Colors.grey.shade300,
//   //                                       ),
//   //                                       Container(
//   //                                         padding: EdgeInsets.all(context.gapXXSmall),
//   //                                         decoration: BoxDecoration(
//   //                                           color: Colors.white,
//   //                                           shape: BoxShape.circle,
//   //                                           border: Border.all(
//   //                                             color: Colors.grey.shade300,
//   //                                           ),
//   //                                         ),
//   //                                         child: Icon(
//   //                                           Icons.flight_takeoff,
//   //                                           size: context.iconXSmall,
//   //                                           color: const Color(0xFFFF3B30),
//   //                                         ),
//   //                                       ),
//   //                                     ],
//   //                                   ),
//   //                                   SizedBox(height: context.gapXXSmall),
//   //                                   Text(
//   //                                     'Non-stop',
//   //                                     style: TextStyle(
//   //                                       fontSize: context.labelSmall,
//   //                                       color: Colors.green.shade600,
//   //                                       fontWeight: FontWeight.w500,
//   //                                     ),
//   //                                   ),
//   //                                 ],
//   //                               ),
//   //                             ),
//   //                             Expanded(
//   //                               child: Column(
//   //                                 crossAxisAlignment: CrossAxisAlignment.end,
//   //                                 children: [
//   //                                   Text(
//   //                                     _formatTime(flight.arrivalTime),
//   //                                     style: TextStyle(
//   //                                       fontSize: context.titleLarge,
//   //                                       fontWeight: FontWeight.bold,
//   //                                     ),
//   //                                   ),
//   //                                   SizedBox(height: context.gapXXSmall),
//   //                                   Text(
//   //                                     flight.destination ?? '--',
//   //                                     style: TextStyle(
//   //                                       fontSize: context.labelSmall,
//   //                                       color: Colors.grey.shade600,
//   //                                     ),
//   //                                   ),
//   //                                 ],
//   //                               ),
//   //                             ),
//   //                           ],
//   //                         ),
//   //                       ],
//   //                     ),
//   //                   ),
//   //                 ],
//   //               ),
//   //               SizedBox(height: context.gapMedium),
//   //
//   //               // Bottom section with price and booking
//   //               Divider(height: 1, color: Colors.grey.shade200),
//   //               SizedBox(height: context.gapMedium),
//   //
//   //               Row(
//   //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //                 children: [
//   //                   // Fare type badge
//   //                   Container(
//   //                     padding: EdgeInsets.symmetric(
//   //                       horizontal: context.gapSmall,
//   //                       vertical: context.gapXXSmall,
//   //                     ),
//   //                     decoration: BoxDecoration(
//   //                       color: const Color(0xFFFF3B30).withOpacity(0.1),
//   //                       borderRadius: BorderRadius.circular(context.borderRadiusSmall),
//   //                     ),
//   //                     child: Row(
//   //                       mainAxisSize: MainAxisSize.min,
//   //                       children: [
//   //                         Icon(
//   //                           Icons.luggage_outlined,
//   //                           size: context.iconXSmall,
//   //                           color: const Color(0xFFFF3B30),
//   //                         ),
//   //                         SizedBox(width: context.gapXXSmall),
//   //                         Text(
//   //                           'Inclusive of taxes',
//   //                           style: TextStyle(
//   //                             fontSize: context.labelSmall,
//   //                             color: const Color(0xFFFF3B30),
//   //                             fontWeight: FontWeight.w500,
//   //                           ),
//   //                         ),
//   //                       ],
//   //                     ),
//   //                   ),
//   //
//   //                   Row(
//   //                     children: [
//   //                       Column(
//   //                         crossAxisAlignment: CrossAxisAlignment.end,
//   //                         children: [
//   //                           // Text(
//   //                           //   "${flight.currency ?? '₹'} ${_formatPrice((flight.totalFare ?? 0).toInt())}",
//   //                           //   style: TextStyle(
//   //                           //     fontSize: context.titleLarge,
//   //                           //     fontWeight: FontWeight.bold,
//   //                           //     color: const Color(0xFFFF3B30),
//   //                           //   ),
//   //                           // ),
//   //                           Text(
//   //                             _convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency),
//   //                             style: TextStyle(
//   //                               fontSize: context.titleLarge,
//   //                               fontWeight: FontWeight.bold,
//   //                               color: const Color(0xFFFF3B30),
//   //                             ),
//   //                           ),
//   //                           Text(
//   //                             'per passenger',
//   //                             style: TextStyle(
//   //                               fontSize: context.labelSmall,
//   //                               color: Colors.grey.shade600,
//   //                             ),
//   //                           ),
//   //                         ],
//   //                       ),
//   //                       SizedBox(width: context.gapSmall),
//   //                       Container(
//   //                         decoration: BoxDecoration(
//   //                           gradient: const LinearGradient(
//   //                             colors: [Color(0xFFFF3B30), Color(0xFFFF6B4A)],
//   //                           ),
//   //                           borderRadius: BorderRadius.circular(context.borderRadius),
//   //                         ),
//   //                         child: ElevatedButton(
//   //                           onPressed: () => _showFlightDetails(flight),
//   //                           style: ElevatedButton.styleFrom(
//   //                             backgroundColor: Colors.transparent,
//   //                             shadowColor: Colors.transparent,
//   //                             padding: EdgeInsets.symmetric(
//   //                               horizontal: context.gapLarge,
//   //                               vertical: context.gapSmall,
//   //                             ),
//   //                             shape: RoundedRectangleBorder(
//   //                               borderRadius: BorderRadius.circular(context.borderRadius),
//   //                             ),
//   //                           ),
//   //                           child: Text(
//   //                             "View Details",
//   //                             style: TextStyle(
//   //                               fontWeight: FontWeight.w600,
//   //                               fontSize: context.labelMedium,
//   //                               color: Colors.white,
//   //                             ),
//   //                           ),
//   //                         ),
//   //                       ),
//   //                     ],
//   //                   ),
//   //                 ],
//   //               ),
//   //             ],
//   //           ),
//   //         ),
//   //       ),
//   //     ),
//   //   );
//   // }
//
//
//   Widget _buildEnhancedFlightCard(FlightEntity flight) {
//     return Container(
//       margin: EdgeInsets.only(bottom: context.h(8)),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => _showFlightDetails(flight),
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: EdgeInsets.fromLTRB(context.w(12), context.h(12), context.w(12), context.h(8)),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header - Airline Info
//                 Row(
//                   children: [
//                     Container(
//                       width: context.w(36),
//                       height:  context.w(36),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             const Color(0xFFFF3B30).withOpacity(0.2),
//                             const Color(0xFFFF3B30).withOpacity(0.05),
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Center(
//                         child: Text(
//                           flight.airlineCode?.substring(0, 2).toUpperCase() ?? 'AI',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: const Color(0xFFFF3B30),
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             flight.airlineName ?? 'Airline',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 15,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           Text(
//                             'Flight ${flight.flightNumber ?? ''}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     // Price
//                     Text(
//                       _convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency),
//                       style: TextStyle(
//                         fontSize: context.fs(20),
//                         fontWeight: FontWeight.bold,
//                         color: const Color(0xFF0A2463),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 SizedBox(height: 12),
//
//                 // Flight Times - Main Row
//                 // Row(
//                 //   children: [
//                 //     // Departure
//                 //     Expanded(
//                 //       flex: 2,
//                 //       child: Column(
//                 //         crossAxisAlignment: CrossAxisAlignment.start,
//                 //         children: [
//                 //           Text(
//                 //             _formatTime(flight.departureTime),
//                 //             style: TextStyle(
//                 //               fontSize: context.fs(24),
//                 //               fontWeight: FontWeight.bold,
//                 //               color: Colors.black87,
//                 //             ),
//                 //           ),
//                 //           Text(
//                 //             flight.originName ?? flight.origin ?? '',  // Use airport name, fallback to code
//                 //             style: TextStyle(
//                 //               fontSize: context.fs(13),  // Responsive font size
//                 //               color: Colors.grey.shade600,
//                 //               fontWeight: FontWeight.w500,
//                 //             ),
//                 //             maxLines: 1,
//                 //             overflow: TextOverflow.ellipsis,  // Handle long names
//                 //           ),
//                 //           // Text(
//                 //           //   flight.origin ?? '',
//                 //           //   style: TextStyle(
//                 //           //     fontSize: 13,
//                 //           //     color: Colors.grey.shade600,
//                 //           //     fontWeight: FontWeight.w500,
//                 //           //   ),
//                 //           // ),
//                 //         ],
//                 //       ),
//                 //     ),
//                 //
//                 //     // Duration & Line
//                 //     Expanded(
//                 //       flex: 2,
//                 //       child: Column(
//                 //         children: [
//                 //           Row(
//                 //             mainAxisAlignment: MainAxisAlignment.center,
//                 //             children: [
//                 //               Container(
//                 //                 width: 6,
//                 //                 height: 6,
//                 //                 decoration: BoxDecoration(
//                 //                   color: const Color(0xFFFF3B30),
//                 //                   shape: BoxShape.circle,
//                 //                 ),
//                 //               ),
//                 //               Expanded(
//                 //                 child: Container(
//                 //                   height: 2,
//                 //                   decoration: BoxDecoration(
//                 //                     gradient: LinearGradient(
//                 //                       colors: [
//                 //                         const Color(0xFFFF3B30).withOpacity(0.3),
//                 //                         const Color(0xFFFF3B30).withOpacity(0.6),
//                 //                       ],
//                 //                     ),
//                 //                   ),
//                 //                 ),
//                 //               ),
//                 //               Icon(
//                 //                 Icons.flight,
//                 //                 size: 16,
//                 //                 color: const Color(0xFFFF3B30),
//                 //               ),
//                 //               Expanded(
//                 //                 child: Container(
//                 //                   height: 2,
//                 //                   decoration: BoxDecoration(
//                 //                     gradient: LinearGradient(
//                 //                       colors: [
//                 //                         const Color(0xFFFF3B30).withOpacity(0.6),
//                 //                         const Color(0xFFFF3B30).withOpacity(0.3),
//                 //                       ],
//                 //                     ),
//                 //                   ),
//                 //                 ),
//                 //               ),
//                 //               Container(
//                 //                 width: 6,
//                 //                 height: 6,
//                 //                 decoration: BoxDecoration(
//                 //                   color: const Color(0xFFFF3B30),
//                 //                   shape: BoxShape.circle,
//                 //                 ),
//                 //               ),
//                 //             ],
//                 //           ),
//                 //           SizedBox(height: 4),
//                 //           Text(
//                 //             _formatDuration(flight.duration != null ? int.tryParse(flight.duration!) : null),
//                 //             style: TextStyle(
//                 //               fontSize: 12,
//                 //               color: Colors.grey.shade700,
//                 //               fontWeight: FontWeight.w600,
//                 //             ),
//                 //           ),
//                 //           Text(
//                 //             'Non-stop',
//                 //             style: TextStyle(
//                 //               fontSize: 11,
//                 //               color: Colors.green.shade600,
//                 //               fontWeight: FontWeight.w500,
//                 //             ),
//                 //           ),
//                 //         ],
//                 //       ),
//                 //     ),
//                 //
//                 //     // Arrival
//                 //     Expanded(
//                 //       flex: 2,
//                 //       child: Column(
//                 //         crossAxisAlignment: CrossAxisAlignment.end,
//                 //         children: [
//                 //           Text(
//                 //             _formatTime(flight.arrivalTime),
//                 //             style: TextStyle(
//                 //               fontSize: context.fs(24),
//                 //               fontWeight: FontWeight.bold,
//                 //               color: Colors.black87,
//                 //             ),
//                 //           ),
//                 //           Text(
//                 //             flight.destinationName ?? flight.destination ?? '',  // Use airport name, fallback to code
//                 //             style: TextStyle(
//                 //               fontSize: context.fs(13),  // Responsive font size
//                 //               color: Colors.grey.shade600,
//                 //               fontWeight: FontWeight.w500,
//                 //             ),
//                 //             maxLines: 1,
//                 //             overflow: TextOverflow.ellipsis,  // Handle long names
//                 //           ),
//                 //           // Text(
//                 //           //   flight.destination ?? '',
//                 //           //   style: TextStyle(
//                 //           //     fontSize: 13,
//                 //           //     color: Colors.grey.shade600,
//                 //           //     fontWeight: FontWeight.w500,
//                 //           //   ),
//                 //           // ),
//                 //         ],
//                 //       ),
//                 //     ),
//                 //   ],
//                 // ),
// // Flight Times - Main Row (More Responsive)
//                 LayoutBuilder(
//                   builder: (context, constraints) {
//                     bool isSmallScreen = constraints.maxWidth < 350;
//
//                     return Row(
//                       children: [
//                         // Departure
//                         Expanded(
//                           flex: 2,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 _formatTime(flight.departureTime),
//                                 style: TextStyle(
//                                   fontSize: context.fs(isSmallScreen ? 20 : 24),
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                               SizedBox(height: context.h(2)),
//                               Text(
//                                 flight.originName ?? flight.origin ?? '',
//                                 style: TextStyle(
//                                   fontSize: context.fs(isSmallScreen ? 11 : 13),
//                                   color: Colors.grey.shade600,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         // Duration & Line
//                         Expanded(
//                           flex: isSmallScreen ? 3 : 2,
//                           child: Column(
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Container(
//                                     width: context.w(6),
//                                     height: context.h(6),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFFFF3B30),
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                   Expanded(
//                                     child: Container(
//                                       height: 2,
//                                       decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             const Color(0xFFFF3B30).withOpacity(0.3),
//                                             const Color(0xFFFF3B30).withOpacity(0.6),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Icon(
//                                     Icons.flight,
//                                     size: context.w(isSmallScreen ? 14 : 16),
//                                     color: const Color(0xFFFF3B30),
//                                   ),
//                                   Expanded(
//                                     child: Container(
//                                       height: 2,
//                                       decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             const Color(0xFFFF3B30).withOpacity(0.6),
//                                             const Color(0xFFFF3B30).withOpacity(0.3),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Container(
//                                     width: context.w(6),
//                                     height: context.h(6),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFFFF3B30),
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: context.h(4)),
//                               Text(
//                                 _formatDuration(flight.duration != null ? int.tryParse(flight.duration!) : null),
//                                 style: TextStyle(
//                                   fontSize: context.fs(isSmallScreen ? 11 : 12),
//                                   color: Colors.grey.shade700,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               Text(
//                                 'Non-stop',
//                                 style: TextStyle(
//                                   fontSize: context.fs(isSmallScreen ? 10 : 11),
//                                   color: Colors.green.shade600,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         // Arrival
//                         Expanded(
//                           flex: 2,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Text(
//                                 _formatTime(flight.arrivalTime),
//                                 style: TextStyle(
//                                   fontSize: context.fs(isSmallScreen ? 20 : 24),
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                               SizedBox(height: context.h(2)),
//                               Text(
//                                 flight.destinationName ?? flight.destination ?? '',
//                                 style: TextStyle(
//                                   fontSize: context.fs(isSmallScreen ? 11 : 13),
//                                   color: Colors.grey.shade600,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//                 SizedBox(height: 10),
//
//                 // Promotional Offers
//                 // Container(
//                 //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 //   decoration: BoxDecoration(
//                 //     color: const Color(0xFF00A859).withOpacity(0.08),
//                 //     borderRadius: BorderRadius.circular(6),
//                 //   ),
//                 //   child: Row(
//                 //     children: [
//                 //       Icon(
//                 //         Icons.local_offer_outlined,
//                 //         size: 14,
//                 //         color: const Color(0xFF00A859),
//                 //       ),
//                 //       SizedBox(width: 6),
//                 //       Expanded(
//                 //         child: Text(
//                 //           'Get Flat ₹ 370 OFF using code MMTSUPER',
//                 //           style: TextStyle(
//                 //             fontSize: 11,
//                 //             color: const Color(0xFF00A859),
//                 //             fontWeight: FontWeight.w600,
//                 //           ),
//                 //           maxLines: 1,
//                 //           overflow: TextOverflow.ellipsis,
//                 //         ),
//                 //       ),
//                 //     ],
//                 //   ),
//                 // ),
//
//                 // SizedBox(height: 6),
//                 //
//                 // Row(
//                 //   children: [
//                 //     Icon(
//                 //       Icons.event_seat_outlined,
//                 //       size: 14,
//                 //       color: Colors.grey.shade600,
//                 //     ),
//                 //     SizedBox(width: 6),
//                 //     Text(
//                 //       'Free Seat with VISA Signature*',
//                 //       style: TextStyle(
//                 //         fontSize: 11,
//                 //         color: Colors.grey.shade600,
//                 //       ),
//                 //     ),
//                 //   ],
//                 // ),
//                 //
//                 // SizedBox(height: 8),
//
//                 // Lock Price Button
//                 Container(
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         const Color(0xFF1976D2).withOpacity(0.1),
//                         const Color(0xFF1976D2).withOpacity(0.05),
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: const Color(0xFF1976D2).withOpacity(0.3),
//                       width: 1,
//                     ),
//                   ),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       onTap: () => _showFlightDetails(flight),
//                       borderRadius: BorderRadius.circular(8),
//                       child: Padding(
//                         padding: EdgeInsets.symmetric(vertical: 10),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.lock_outline,
//                               size: 16,
//                               color: const Color(0xFF1976D2),
//                             ),
//                             SizedBox(width: 8),
//                             Text(
//                               'View Price Detail',
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: const Color(0xFF1976D2),
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Icon(
//                               Icons.arrow_forward_ios,
//                               size: 12,
//                               color: const Color(0xFF1976D2),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showFlightDetails(FlightEntity flight) {
//     FlightDetailsPopup.show(
//       context,
//       airlineName: flight.airlineName ?? "Unknown",
//       airlineCode: flight.airlineName ?? "--",
//       flightNumber: flight.flightNumber ?? "--",
//       fromCode: flight.origin ?? "--",
//       toCode: flight.destination ?? "--",
//       departureTime: _formatTime(flight.departureTime),
//       arrivalTime: _formatTime(flight.arrivalTime),
//       traceId: flight.traceId,
//       resultIndex: flight.resultIndex,
//       duration: "${flight.duration ?? '--'} min",
//       // price: _formatPrice((flight.totalFare ?? 0).toInt()),
//       price: _convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency),
//     );
//   }
//
//   List<FlightEntity> _applyAdvancedFilters(List<FlightEntity> flights) {
//     var result = List<FlightEntity>.from(flights);
//
//     // Filter by price range
//     result = result.where((f) {
//       final price = f.totalFare ?? 0;
//       return price >= _priceRange.start && price <= _priceRange.end;
//     }).toList();
//
//     // Filter by stops (you'll need to add stops info to FlightEntity)
//     if (_selectedStops != null) {
//       // Add stops filtering logic based on your data structure
//     }
//
//     // Apply sort and other filters
//     return _applyFiltersAndSort(result);
//   }
//
//   List<FlightEntity> _applyFiltersAndSort(List<FlightEntity> flights) {
//     var result = List<FlightEntity>.from(flights);
//
//     if (_selectedFilter != "All Airlines" && _selectedFilter.isNotEmpty) {
//       result = result
//           .where((f) => f.airlineName?.toLowerCase() == _selectedFilter.toLowerCase())
//           .toList();
//     }
//
//     if (_selectedSort == "Price: Low to High") {
//       result.sort((a, b) => (a.totalFare ?? 0).compareTo(b.totalFare ?? 0));
//     } else if (_selectedSort == "Price: High to Low") {
//       result.sort((a, b) => (b.totalFare ?? 0).compareTo(a.totalFare ?? 0));
//     } else if (_selectedSort == "Duration: Shortest") {
//       result.sort((a, b) {
//         int aDur = int.tryParse(a.duration ?? '0') ?? 9999;
//         int bDur = int.tryParse(b.duration ?? '0') ?? 9999;
//         return aDur.compareTo(bDur);
//       });
//     } else if (_selectedSort == "Departure: Earliest") {
//       result.sort((a, b) => (a.departureTime ?? '').compareTo(b.departureTime ?? ''));
//     }
//
//     return result;
//   }
//
//   void _updateMaxPrice(List<FlightEntity> flights) {
//     final maxPrice = flights.fold<double>(
//       0,
//           (max, f) => (f.totalFare ?? 0) > max ? (f.totalFare ?? 0) : max,
//     );
//     if (maxPrice > _maxPrice) {
//       setState(() {
//         _maxPrice = maxPrice;
//         _priceRange = RangeValues(0, maxPrice);
//       });
//     }
//   }
//
//
//   Widget _buildResultsHeader(int showing, int total) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: context.h(8)),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             "$showing of $total Flights",
//             style: TextStyle(
//               fontSize: context.labelMedium,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorState(String message) {
//     return Center(
//       child: Padding(
//         padding: context.horizontalPadding,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: context.iconXLarge, color: Colors.red.shade400),
//             SizedBox(height: context.gapLarge),
//             Text(
//               'Failed to load flights',
//               style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.w600),
//             ),
//             SizedBox(height: context.gapSmall),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: context.bodyMedium, color: Colors.grey.shade600),
//             ),
//             SizedBox(height: context.gapXLarge),
//             ElevatedButton(
//               onPressed: _triggerFlightSearch,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFFF3B30),
//                 padding: EdgeInsets.symmetric(
//                   horizontal: context.buttonWidth,
//                   vertical: context.gapMedium,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(context.borderRadius),
//                 ),
//               ),
//               child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.flight_takeoff, size: context.iconXLarge * 1.5, color: Colors.grey.shade400),
//           SizedBox(height: context.gapLarge),
//           Text(
//             'Search for flights',
//             style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.w600),
//           ),
//           SizedBox(height: context.gapSmall),
//           Text(
//             'Enter your travel details to find the best flights',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: context.bodyMedium, color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatTime(String? isoTime) {
//     if (isoTime == null || isoTime.isEmpty) return '--:--';
//     try {
//       final dt = DateTime.parse(isoTime);
//       return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
//     } catch (_) {
//       return isoTime;
//     }
//   }
//
//   String _formatPrice(int price) {
//     return price.toString().replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//           (Match m) => '${m[1]},',
//     );
//   }
//
//
//   String _getMonthAbbr(int month) {
//     const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     return months[month - 1];
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../../injection_container.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/loadingScreen.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../domain/entities/flight_entity.dart';
import '../../domain/entities/flight_search_request_entity.dart';
import '../bloc/flight_search_bloc.dart';
import '../bloc/flight_search_event.dart';
import '../bloc/flight_search_state.dart';
import 'booking_screen.dart';
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
  final int BookingMode;

  const FlightSearchScreen({
    super.key,
    required this.from, required this.to, required this.fromCode, required this.toCode,
    required this.fromAirport, required this.toAirport, required this.date,
    required this.travellers, required this.adults, required this.children,
    required this.infants, required this.travelClass, required this.isRoundTrip,
    this.returnDate,
    required this.BookingMode,
  });

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> with SingleTickerProviderStateMixin {
  late FlightSearchBloc _flightSearchBloc;
  String _selectedSort = "Recommended";
  String _selectedFilter = "All Airlines";
  int currentIndex = 0;
  String _selectedTab = "Best Value";
  bool _isApiCalled = false;
  late TabController _tabController;
  late List<Map<String, dynamic>> _dateOptions;

  bool _showFilters = false;
  Set<String> _selectedAirlines = {};
  RangeValues _priceRange = const RangeValues(0, 50000);
  double _maxPrice = 50000;
  int? _selectedStops;

  void _initDateOptions() {
    final now = DateTime.now();
    _dateOptions = List.generate(7, (index) {
      final date = now.add(Duration(days: index));
      return {
        "day": DateFormat('EEE').format(date),
        "date": DateFormat('d MMM').format(date),
        "price": 0,
        "selected": index == 0,
        "dateTime": date,
      };
    });
  }

  @override
  void initState() {
    super.initState();
    _flightSearchBloc = sl<FlightSearchBloc>();
    _tabController = TabController(length: 3, vsync: this);
    _triggerFlightSearch();
    _initDateOptions();
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
    _flightSearchBloc.add(SearchFlightsEvent(_buildRequest()));
  }

  void _onDateSelected(int selectedIndex, DateTime newDate) {
    for (var i = 0; i < _dateOptions.length; i++) {
      _dateOptions[i]["selected"] = i == selectedIndex;
    }
    setState(() {});

    final updatedRequest = FlightSearchRequestEntity(
      endUserIp: '203.0.113.10',
      adultCount: widget.adults,
      childCount: widget.children,
      infantCount: widget.infants,
      journeyType: widget.isRoundTrip ? 2 : 1,
      BookingMode: 5,
      segments: [
        FlightSegmentEntity(
          origin: widget.fromCode, destination: widget.toCode,
          flightCabinClass: _getCabinClassInt(widget.travelClass),
          preferredDepartureTime: _formatDateForAPI(newDate),
          preferredArrivalTime: _formatDateForAPI(newDate),
        ),
      ],
    );

    if (widget.isRoundTrip && widget.returnDate != null) {
      updatedRequest.segments.add(
        FlightSegmentEntity(
          origin: widget.toCode, destination: widget.fromCode,
          flightCabinClass: _getCabinClassInt(widget.travelClass),
          preferredDepartureTime: _formatDateForAPI(widget.returnDate),
          preferredArrivalTime: _formatDateForAPI(widget.returnDate),
        ),
      );
    }
    _flightSearchBloc.add(SearchFlightsEvent(updatedRequest));
  }

  FlightSearchRequestEntity _buildRequest() {
    final segments = <FlightSegmentEntity>[
      FlightSegmentEntity(
        origin: widget.fromCode, destination: widget.toCode,
        flightCabinClass: _getCabinClassInt(widget.travelClass),
        preferredDepartureTime: _formatDateForAPI(widget.date),
        preferredArrivalTime: _formatDateForAPI(widget.date),
      ),
    ];
    if (widget.isRoundTrip && widget.returnDate != null) {
      segments.add(
        FlightSegmentEntity(
          origin: widget.toCode, destination: widget.fromCode,
          flightCabinClass: _getCabinClassInt(widget.travelClass),
          preferredDepartureTime: _formatDateForAPI(widget.returnDate),
          preferredArrivalTime: _formatDateForAPI(widget.returnDate),
        ),
      );
    }
    return FlightSearchRequestEntity(
      endUserIp: '203.0.113.10', adultCount: widget.adults,
      childCount: widget.children, infantCount: widget.infants,
      journeyType: widget.isRoundTrip ? 2 : 1, segments: segments,
      BookingMode: 5,
    );
  }

  String _formatDateForAPI(DateTime? date) => date == null ? '' : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00';
  int _getCabinClassInt(String travelClass) {
    switch (travelClass.toLowerCase()) {
      case 'premium economy': return 3;
      case 'business': return 4;
      case 'first': return 5;
      default: return 2;
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
          backgroundColor: Colors.white, elevation: 0,
          actions: [
            Padding(
              padding: EdgeInsets.all(context.w(8)),
              child: Image.asset("assets/images/wander_nova_logo.png", height: context.h(35)),
            )
          ],
        ),
        backgroundColor: Colors.grey.shade50,
        body: BlocBuilder<FlightSearchBloc, FlightSearchState>(
          builder: (context, state) {
            if (state is FlightSearchLoading) {
              return ProfessionalLoadingScreen(
                searchParams: {
                  'fromAirport': widget.fromAirport, 'toAirport': widget.toAirport,
                  'departureDate': widget.date, 'returnDate': widget.returnDate,
                  'adults': widget.adults, 'children': widget.children,
                  'infants': widget.infants, 'class': widget.travelClass,
                  'isRoundTrip': widget.isRoundTrip,
                },
                onLoadingComplete: () {},
              );
            }
            if (state is FlightSearchError) return _buildErrorState(state.message);
            if (state is FlightSearchLoaded) {
              _updateMaxPrice(state.flights);
              return _buildMainContent(state.flights);
            }
            return _buildEmptyState();
          },
        ),
        bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
      ),
    );
  }

  Widget _buildMainContent(List<FlightEntity> flights) {
    final filteredFlights = _applyAdvancedFilters(flights);
    return Column(
      children: [
        _buildDateSelector(),
        Expanded(
          child: _showFilters ? _buildFilterPanel(filteredFlights, flights) : _buildFlightList(filteredFlights),
        ),
      ],
    );
  }

  int _getMonthNumber(String monthAbbr) {
    const months = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12};
    return months[monthAbbr] ?? DateTime.now().month;
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return '0';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0 && remainingMinutes > 0) return '$hours hr $remainingMinutes min';
    if (hours > 0) return '$hours hr';
    return '$remainingMinutes min';
  }

  Widget _buildDateSelector() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: SizedBox(
        height: context.h(65),
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
                final dateStr = date["date"] as String;
                final day = int.parse(dateStr.split(' ')[0]);
                final month = _getMonthNumber(dateStr.split(' ')[1]);
                _onDateSelected(index, DateTime(DateTime.now().year, month, day));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: context.w(68),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0A2463) : Colors.white,
                  borderRadius: BorderRadius.circular(context.r(12)),
                  border: Border.all(color: isSelected ? const Color(0xFF0A2463) : Colors.grey.shade200, width: 1.5),
                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0A2463).withOpacity(0.2), blurRadius: context.w(8), offset: Offset(0, context.h(2)))] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(date["day"], style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.grey.shade600)),
                    SizedBox(height: context.h(2)),
                    Text(date["date"], style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade800)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _convertFlightPrice(double amount, String? apiCurrency) {
    try {
      final prefs = sl<PreferencesManager>();
      final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';
      final fromCurrency = apiCurrency ?? 'INR';
      if (fromCurrency.toUpperCase() == targetCurrency.toUpperCase()) return _formatPrice(amount.toInt());
      final converted = CurrencyConverter.convert(amount: amount, fromCurrency: fromCurrency, toCurrency: targetCurrency);
      if (targetCurrency.toUpperCase() == 'INR') return '₹${_formatIndianNumber(converted.toInt())}';
      final symbol = CurrencyConverter.getSymbol(targetCurrency);
      return '$symbol${converted.toStringAsFixed(0)}';
    } catch (e) {
      return _formatPrice(amount.toInt());
    }
  }

  String _formatIndianNumber(int num) {
    if (num < 1000) return num.toString();
    final str = num.toString();
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    var formatted = '';
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) formatted += ',';
      formatted += remaining[i];
    }
    return '$formatted,$lastThree';
  }

  Widget _buildFilterPanel(List<FlightEntity> filteredFlights, List<FlightEntity> allFlights) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(context.w(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters', style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() { _selectedAirlines.clear(); _priceRange = RangeValues(0, _maxPrice); _selectedStops = null; }),
                      child: Text('Reset', style: TextStyle(color: const Color(0xFFFF3B30), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price Range', style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600)),
                    SizedBox(height: context.h(8)),
                    RangeSlider(
                      values: _priceRange, min: 0, max: _maxPrice, divisions: 100,
                      activeColor: const Color(0xFFFF3B30), inactiveColor: Colors.grey.shade300,
                      labels: RangeLabels('₹${_priceRange.start.round()}', '₹${_priceRange.end.round()}'),
                      onChanged: (values) => setState(() => _priceRange = values),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${_priceRange.start.round()}', style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600)),
                        Text('₹${_priceRange.end.round()}', style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: context.h(16)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stops', style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600)),
                    SizedBox(height: context.h(8)),
                    Row(
                      children: [
                        _buildStopOption("Any", null), SizedBox(width: context.w(8)),
                        _buildStopOption("Non-stop", 0), SizedBox(width: context.w(8)),
                        _buildStopOption("1 Stop", 1), SizedBox(width: context.w(8)),
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
                  style: TextButton.styleFrom(padding: EdgeInsets.symmetric(vertical: context.h(12))),
                  child: Text('Cancel', style: TextStyle(fontSize: context.fs(16), color: Colors.grey.shade600)),
                ),
              ),
              Container(height: context.h(40), width: context.w(1), color: Colors.grey.shade200),
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _showFilters = false),
                  style: TextButton.styleFrom(padding: EdgeInsets.symmetric(vertical: context.h(12))),
                  child: Text('Apply (${filteredFlights.length})', style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.bold, color: const Color(0xFFFF3B30))),
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
          padding: EdgeInsets.symmetric(vertical: context.h(8)),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF3B30).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: isSelected ? const Color(0xFFFF3B30) : Colors.grey.shade300),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w500, color: isSelected ? const Color(0xFFFF3B30) : Colors.grey.shade700))),
        ),
      ),
    );
  }

  Widget _buildFlightList(List<FlightEntity> flights) {
    final filteredFlights = _applyFiltersAndSort(flights);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(padding: EdgeInsets.symmetric(horizontal: context.gapMedium), child: _buildResultsHeader(filteredFlights.length, flights.length)),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildEnhancedFlightCard(filteredFlights[index]),
              childCount: filteredFlights.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFlightCard(FlightEntity flight) {
    final bool isRoundTrip = flight.isRoundTrip;
    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: context.w(10), offset: Offset(0, context.h(3))),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFlightDetails(flight),
          borderRadius: BorderRadius.circular(context.r(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Airline header row ──────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(context.w(14), context.h(14), context.w(14), context.h(8)),
                child: Row(
                  children: [
                    // Airline logo box
                    Container(
                      width: context.w(38),
                      height: context.w(38),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(context.r(8)),
                        border: Border.all(color: const Color(0xFFDDE5FF), width: context.w(1)),
                      ),
                      child: Center(
                        child: Text(
                          (flight.airlineCode ?? 'AI').substring(0, (flight.airlineCode ?? 'AI').length.clamp(0, 2)).toUpperCase(),
                          style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.bold, color: const Color(0xFF1A3C8F)),
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flight.airlineName ?? 'Airline',
                            style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                          Text(
                            'Flight ${flight.flightNumber ?? ''} • ${widget.travelClass}',
                            style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency),
                          style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.bold, color: const Color(0xFF0A2463)),
                        ),
                        Text(
                          'per person',
                          style: TextStyle(fontSize: context.fs(10), color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(height: context.h(1), color: Colors.grey.shade100, indent: context.w(14), endIndent: context.w(14)),

              // ── Outbound leg ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(12)),
                child: _buildLegRow(
                  depTime: flight.departureTime,
                  arrTime: flight.arrivalTime,
                  origin: flight.origin ?? '',
                  destination: flight.destination ?? '',
                  duration: flight.duration,
                  isReturn: false,
                ),
              ),

              // ── Return leg (round trip only) ────────────────────────────
              if (isRoundTrip) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                  child: Row(
                    children: [
                      Expanded(child: Divider(height: context.h(1), color: Colors.grey.shade200)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.w(8)),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FF),
                            borderRadius: BorderRadius.circular(context.r(20)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync_alt, size: context.w(11), color: const Color(0xFF1A3C8F)),
                              SizedBox(width: context.w(4)),
                              Text('Return', style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w600, color: const Color(0xFF1A3C8F))),
                            ],
                          ),
                        ),
                      ),
                      Expanded(child: Divider(height: context.h(1), color: Colors.grey.shade200)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(12)),
                  child: _buildLegRow(
                    depTime: flight.returnDepartureTime,
                    arrTime: flight.returnArrivalTime,
                    origin: flight.returnOrigin ?? '',
                    destination: flight.returnDestination ?? '',
                    duration: flight.returnDuration,
                    isReturn: true,
                  ),
                ),
              ],

              // ── Bottom bar: tags + Book button ──────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(context.r(12)),
                    bottomRight: Radius.circular(context.r(12)),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade100, width: context.w(1))),
                ),
                padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(10)),
                child: Row(
                  children: [
                    // Refundable tag
                    _buildTag('Non-refundable', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                    SizedBox(width: context.w(6)),
                    // Fare type tag
                    _buildTag(isRoundTrip ? 'Round Trip' : 'One Way', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                    const Spacer(),
                    // Book Now button
                    GestureDetector(
                      onTap: () => _showFlightDetails(flight),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: context.w(18), vertical: context.h(8)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2463),
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                        child: Text(
                          'Book',
                          style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegRow({
    required String? depTime,
    required String? arrTime,
    required String origin,
    required String destination,
    required String? duration,
    required bool isReturn,
  }) {
    final int? durationMins = duration != null ? int.tryParse(duration) : null;
    return Row(
      children: [
        // Departure
        SizedBox(
          width: context.w(72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTime(depTime),
                style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                origin,
                style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        // Centre: line + duration + stops
        Expanded(
          child: Column(
            children: [
              // Duration label
              Text(
                _formatDuration(durationMins),
                style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.h(4)),
              // Flight line
              Row(
                children: [
                  Container(
                    width: context.w(7), height: context.w(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400, width: context.w(1.5)),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: context.h(1.5),
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Transform.rotate(
                    angle: isReturn ? 3.14159 : 0,
                    child: Icon(Icons.flight, size: context.w(16), color: const Color(0xFF0A2463)),
                  ),
                  Expanded(
                    child: Container(
                      height: context.h(1.5),
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Container(
                    width: context.w(7), height: context.w(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0A2463),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(4)),
              // Non-stop label
              Text(
                'Non-stop',
                style: TextStyle(fontSize: context.fs(10), color: Colors.green.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        // Arrival
        SizedBox(
          width: context.w(72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(arrTime),
                style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                destination,
                style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(context.r(6))),
      child: Text(label, style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w600, color: fg)),
    );
  }

  void _showFlightDetails(FlightEntity flight) {
    final prefs = sl<PreferencesManager>();
    final isLoggedIn = prefs.isLoggedIn();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlightBookingScreen(
          routes: [

            FlightRouteSegment(

              from: flight.origin ?? "--",
              price: _convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency),
              to: flight.destination ?? "--",
              traceId:  flight.traceId,
              resultIndex: flight.resultIndex,

              departureTime: _formatTime(flight.departureTime),
              arrivalTime: _formatTime(flight.arrivalTime),

              duration: "${flight.duration ?? '--'} min",

              airline: flight.airlineName ?? "Unknown",

              flightNo: flight.flightNumber ?? "--",
            ),

          ],

          totalPrice: _convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency),
          traceId: flight.traceId,
          resultIndex: flight.resultIndex,
          price: _convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency),

          isLoggedIn: isLoggedIn,
        ),
      ),
    );
  }

  List<FlightEntity> _applyAdvancedFilters(List<FlightEntity> flights) {
    var result = List<FlightEntity>.from(flights);
    result = result.where((f) {
      final price = f.totalFare ?? 0;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();
    if (_selectedStops != null) {
      // Add stops filtering logic based on your data structure
    }
    return _applyFiltersAndSort(result);
  }

  List<FlightEntity> _applyFiltersAndSort(List<FlightEntity> flights) {
    var result = List<FlightEntity>.from(flights);
    if (_selectedFilter != "All Airlines" && _selectedFilter.isNotEmpty) {
      result = result.where((f) => f.airlineName?.toLowerCase() == _selectedFilter.toLowerCase()).toList();
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
    final maxPrice = flights.fold<double>(0, (max, f) => (f.totalFare ?? 0) > max ? (f.totalFare ?? 0) : max);
    if (maxPrice > _maxPrice) {
      setState(() { _maxPrice = maxPrice; _priceRange = RangeValues(0, maxPrice); });
    }
  }

  Widget _buildResultsHeader(int showing, int total) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$showing of $total Flights", style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
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
            Text('Failed to load flights', style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600)),
            SizedBox(height: context.gapSmall),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: context.fs(14), color: Colors.grey.shade600)),
            SizedBox(height: context.gapXLarge),
            ElevatedButton(
              onPressed: _triggerFlightSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                padding: EdgeInsets.symmetric(horizontal: context.buttonWidth, vertical: context.gapMedium),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
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
          Text('Search for flights', style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600)),
          SizedBox(height: context.gapSmall),
          Text('Enter your travel details to find the best flights', textAlign: TextAlign.center, style: TextStyle(fontSize: context.fs(14), color: Colors.grey.shade600)),
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
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
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
