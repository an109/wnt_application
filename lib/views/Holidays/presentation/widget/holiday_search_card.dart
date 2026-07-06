import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../../Holiday_destination/domain/entities/holiday_destination_entity.dart';
import '../../../Holiday_destination/presentation/bloc/holiday_destination_bloc.dart';
import '../../../Holiday_destination/presentation/bloc/holiday_destination_event.dart';
import '../../../Holiday_destination/presentation/bloc/holiday_destination_state.dart';
import 'Holdays_Search_Result.dart';

const List<String> _departureCities = [
  'Bangalore',
  'Chennai',
  'Cochin',
  'Hyderabad',
  'Kolkata',
  'Mumbai',
  'New Delhi',
  'Pune',
  'Agartala',
  'Agatti',
  'Ahmedabad',
  'Jaipur',
  'Goa',
];

class HolidaysSearchCard extends StatefulWidget {
  const HolidaysSearchCard({super.key});

  @override
  State<HolidaysSearchCard> createState() => _HolidaysSearchCardState();
}

class _HolidaysSearchCardState extends State<HolidaysSearchCard> {
  String? _fromCity;
  HolidayDestinationEntity? _selectedDestination;

  DateTime? _departureDate;

  int _Infants = 1;
  int _adults = 2;
  int _children = 0;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xffFF3B3B),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _departureDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat("dd MMM").format(date);
  }

  String _formatDay(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEEE').format(date);
  }

  void _showGuestSelector() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        int tempInfants = _Infants;
        int tempAdults = _adults;
        int tempChildren = _children;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: const Color(0xffFF3B3B),
                    size: context.iconMedium,
                  ),
                  SizedBox(width: context.w(8)),
                  Text(
                    "Rooms & Guests",
                    style: TextStyle(
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCounterRow(
                      title: "Adults",
                      value: tempAdults,
                      icon: Icons.person,
                      onChanged: (val) {
                        setDialogState(() => tempAdults = val);
                      },
                    ),
                    // Divider(height: context.h(16), thickness: 0.5),
                    // _buildCounterRow(
                    //   title: "Children",
                    //   value: tempChildren,
                    //   icon: Icons.child_care,
                    //   onChanged: (val) {
                    //     setDialogState(() => tempChildren = val);
                    //   },
                    // ),
                    Divider(height: context.h(16), thickness: 0.5),
                    _buildCounterRow(
                      title: "Infants",
                      value: tempInfants,
                      icon: Icons.bed,
                      onChanged: (val) {
                        setDialogState(() => tempInfants = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    "CANCEL",
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _Infants = tempInfants;
                      _adults = tempAdults;
                      _children = tempChildren;
                    });
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF3B3B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(20),
                      vertical: context.h(10),
                    ),
                  ),
                  child: Text(
                    "APPLY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCounterRow({
    required String title,
    required int value,
    required IconData icon,
    required Function(int) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: context.iconMedium, color: const Color(0xffFF3B3B)),
            SizedBox(width: context.w(12)),
            Text(
              title,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (value > 0) {
                  onChanged(value - 1);
                }
              },
              child: Container(
                width: context.w(32),
                height: context.w(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.remove,
                  size: context.iconSmall,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            SizedBox(width: context.w(16)),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: context.w(16)),
            GestureDetector(
              onTap: () {
                onChanged(value + 1);
              },
              child: Container(
                width: context.w(32),
                height: context.w(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.add,
                  size: context.iconSmall,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  bool _isSearchEnabled() {
    return _fromCity != null &&
        _selectedDestination != null &&
        _departureDate != null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(22)),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.w(20),
            spreadRadius: context.w(1),
            offset: Offset(0, context.h(8)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.w(14)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// FROM & TO SECTION
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
              child: Column(
                children: [
                  _CitySearchField(
                    label: "FROM CITY",
                    hint: "Select departure city",
                    selectedValue: _fromCity,
                    onSelected: (city) => setState(() => _fromCity = city),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade300,
                    indent: context.w(41),
                  ),
                  _DestinationSearchField(
                    label: "TO CITY / COUNTRY / CATEGORY",
                    hint: "Select destination",
                    selectedDestination: _selectedDestination,
                    onSelected: (destination) =>
                        setState(() => _selectedDestination = destination),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.h(14)),

            /// DEPARTURE DATE
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(10),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: context.iconSmall,
                      color: const Color(0xffFF3B3B),
                    ),
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DEPARTURE DATE",
                            style: TextStyle(
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                              letterSpacing: context.letterSpacingWider,
                            ),
                          ),
                          SizedBox(height: context.h(2)),
                          Text(
                            _formatDate(_departureDate),
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (_departureDate != null)
                            Text(
                              _formatDay(_departureDate),
                              style: TextStyle(
                                fontSize: context.fs(11),
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: context.iconSmall,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.h(12)),

            /// ROOMS & GUESTS & FILTER
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(6),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
              child: Row(
                children: [
                  /// GUESTS
                  Expanded(
                    child: GestureDetector(
                      onTap: _showGuestSelector,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: context.h(6)),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: context.iconSmall,
                              color: const Color(0xffFF3B3B),
                            ),
                            SizedBox(width: context.w(10)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "GUESTS",
                                    style: TextStyle(
                                      fontSize: context.fs(10),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade600,
                                      letterSpacing: context.letterSpacingWider,
                                    ),
                                  ),
                                  SizedBox(height: context.h(2)),
                                  Text(
                                    "$_adults Adult${_adults > 1 ? 's' : ''}",
                                    style: TextStyle(
                                      fontSize: context.fs(13),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "$_Infants Room${_Infants > 1 ? 's' : ''}",
                                    style: TextStyle(
                                      fontSize: context.fs(11),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: context.iconSmall,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),

            SizedBox(height: context.h(16)),

            /// SEARCH Button
            SizedBox(
              width: double.infinity,
              height: context.h(44),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFF3B3B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
                ),
                onPressed: _isSearchEnabled() ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HolidayResultsScreen(
                        fromCity: _fromCity,
                        destination: _selectedDestination,
                        departureDate: _departureDate,
                        adults: _adults,
                        children: _children,
                        Infants: _Infants,
                        // packageType: _selectedPackageType,
                      ),
                    ),
                  );
                } : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: context.iconSmall),
                    SizedBox(width: context.w(8)),
                    Text(
                      "Search Holidays",
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        letterSpacing: context.letterSpacingWide,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Inline typeahead field for the FROM CITY, styled and behaving like
/// [AirportSearchDropdown] in the flight SearchCard: a text field embedded in
/// the card whose options overlay appears directly below it.
class _CitySearchField extends StatefulWidget {
  final String label;
  final String hint;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  const _CitySearchField({
    required this.label,
    required this.hint,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  State<_CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<_CitySearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _suppressNextOverlay = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedValue != null) {
      _controller.text = widget.selectedValue!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _CitySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _controller.text = widget.selectedValue ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _closeOverlay();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (_suppressNextOverlay) return;
      _openOverlay();
    } else {
      _closeOverlay();
    }
  }

  void _onSearchChanged(String value) {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    } else if (_focusNode.hasFocus) {
      _openOverlay();
    }
  }

  void _select(String city) {
    _suppressNextOverlay = true;
    _closeOverlay();
    setState(() => _controller.text = city);
    _focusNode.unfocus();
    widget.onSelected(city);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _suppressNextOverlay = false;
    });
  }

  void _openOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.markNeedsBuild();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus || _suppressNextOverlay) return;

      try {
        if (_overlayEntry != null) return;

        final overlay = Overlay.of(context);
        final renderBox = context.findRenderObject() as RenderBox;

        _overlayEntry = OverlayEntry(
          builder: (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _focusNode.unfocus();
                    _closeOverlay();
                  },
                ),
              ),
              Positioned(
                width: renderBox.size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, renderBox.size.height + 8),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(context.borderRadius),
                    child: Container(
                      constraints: BoxConstraints(maxHeight: context.hp(25)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.borderRadius),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        overlay.insert(_overlayEntry!);
      } catch (e) {
        debugPrint('Error opening city dropdown overlay: $e');
      }
    });
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildContent() {
    final query = _controller.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _departureCities
        : _departureCities.where((c) => c.toLowerCase().contains(query)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No cities found', style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final city = filtered[index];
        return ListTile(
          dense: true,
          // leading: const Icon(Icons.flight_takeoff, color: Color(0xffFF3B3B)),
          title: Text(city, style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () => _select(city),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        constraints: BoxConstraints(minHeight: context.h(54)),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(8),
        ),
        child: Row(
          children: [
            // Icon(
            //   Icons.flight_takeoff,
            //   size: context.w(18),
            //   color: const Color(0xffFF3B3B),
            // ),
            // SizedBox(width: context.w(11)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: context.letterSpacingWider,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline typeahead field for TO CITY / COUNTRY / CATEGORY, backed by
/// [HolidayBloc] (GET /api/holidays-popular-destinations/). Filters on
/// destination name, city, and country as the user types, matching the
/// AirportSearchDropdown overlay pattern used in the flight SearchCard.
class _DestinationSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final HolidayDestinationEntity? selectedDestination;
  final ValueChanged<HolidayDestinationEntity?> onSelected;

  const _DestinationSearchField({
    required this.label,
    required this.hint,
    required this.selectedDestination,
    required this.onSelected,
  });

  @override
  State<_DestinationSearchField> createState() => _DestinationSearchFieldState();
}

class _DestinationSearchFieldState extends State<_DestinationSearchField> {
  late final HolidayBloc _bloc;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _suppressNextOverlay = false;

  @override
  void initState() {
    super.initState();
    _bloc = sl<HolidayBloc>();
    _bloc.add(const GetPopularDestinationsEvent());
    if (widget.selectedDestination != null) {
      _controller.text = widget.selectedDestination!.name;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _DestinationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDestination != oldWidget.selectedDestination) {
      _controller.text = widget.selectedDestination?.name ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _closeOverlay();
    _focusNode.dispose();
    _controller.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (_suppressNextOverlay) return;
      _openOverlay();
    } else {
      _closeOverlay();
    }
  }

  void _onSearchChanged(String value) {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    } else if (_focusNode.hasFocus) {
      _openOverlay();
    }
  }

  void _select(HolidayDestinationEntity destination) {
    _suppressNextOverlay = true;
    _closeOverlay();
    setState(() => _controller.text = destination.name);
    _focusNode.unfocus();
    widget.onSelected(destination);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _suppressNextOverlay = false;
    });
  }

  void _openOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.markNeedsBuild();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus || _suppressNextOverlay) return;

      try {
        if (_overlayEntry != null) return;

        final overlay = Overlay.of(context);
        final renderBox = context.findRenderObject() as RenderBox;

        _overlayEntry = OverlayEntry(
          builder: (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _focusNode.unfocus();
                    _closeOverlay();
                  },
                ),
              ),
              Positioned(
                width: renderBox.size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, renderBox.size.height + 8),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(context.borderRadius),
                    child: Container(
                      constraints: BoxConstraints(maxHeight: context.hp(28)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.borderRadius),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        overlay.insert(_overlayEntry!);
      } catch (e) {
        debugPrint('Error opening destination dropdown overlay: $e');
      }
    });
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildContent() {
    return BlocBuilder<HolidayBloc, HolidayState>(
      bloc: _bloc,
      builder: (context, state) {
        if (state is HolidayLoadingState || state is HolidayInitialState) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is HolidayErrorState) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load destinations',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          );
        }

        if (state is HolidaySuccessState) {
          final query = _controller.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? state.destinations
              : state.destinations.where((d) {
                  return d.name.toLowerCase().contains(query) ||
                      d.city.toLowerCase().contains(query) ||
                      d.country.toLowerCase().contains(query);
                }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No destinations found', style: TextStyle(color: Colors.grey.shade600)),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final destination = filtered[index];
              final subtitle = [destination.city, destination.country]
                  .where((s) => s.isNotEmpty)
                  .join(', ');
              return ListTile(
                dense: true,
                // leading: const Icon(Icons.location_on_outlined, color: Color(0xffFF3B3B)),
                title: Text(destination.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: subtitle.isNotEmpty
                    ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: destination.type.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xffF5F6FA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          destination.type,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      )
                    : null,
                onTap: () => _select(destination),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        constraints: BoxConstraints(minHeight: context.h(54)),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(8),
        ),
        child: Row(
          children: [
            // Icon(
            //   Icons.location_on_outlined,
            //   size: context.w(18),
            //   color: const Color(0xffFF3B3B),
            // ),
            // SizedBox(width: context.w(11)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: context.letterSpacingWider,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
