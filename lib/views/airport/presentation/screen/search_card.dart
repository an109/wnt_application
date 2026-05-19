import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../domain/entities/airport_entities.dart';
import '../bloc/airport_bloc.dart';
import '../bloc/airport_event.dart';
import '../../../flight_search/presentation/screen/flight_search_screen.dart';
import '../widgets/airport_dropdown.dart';

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

  @override
  void initState() {
    super.initState();
    // Load initial airports when widget first builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AirportBloc>().add(LoadAirports());
    });
  }

  void _performSearch() async {
    if (fromAirport == null || toAirport == null || departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: TextStyle(fontSize: context.bodyMedium),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isRoundTrip && returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select return date for round trip',
            style: TextStyle(fontSize: context.bodyMedium),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: TextStyle(fontSize: context.bodyMedium),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.wp(3.5)),
      padding: EdgeInsets.all(context.wp(3.5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: context.wp(5),
            offset: context.shadowOffsetMedium,
          ),
        ],
      ),
      child: Column(
        children: [
          /// Trip Type Toggle
          Container(
            padding: EdgeInsets.all(context.gapXSmall),
            decoration: BoxDecoration(
              color: const Color(0xffF5F6FA),
              borderRadius: BorderRadius.circular(context.borderRadiusLarge),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _tripButton(
                    title: "One Way",
                    selected: !isRoundTrip,
                    onTap: () => setState(() => isRoundTrip = false),
                  ),
                ),
                Expanded(
                  child: _tripButton(
                    title: "Round Trip",
                    selected: isRoundTrip,
                    onTap: () => setState(() => isRoundTrip = true),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.gapMedium),

          /// FROM - TO with Swap Button
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  // FROM field
                  AirportSearchDropdown(
                    title: "FROM",
                    hint: "Search airports...",
                    initialSubtitle: "Select origin airport",
                    selectedAirport: fromAirport,
                    onAirportSelected: (airport) {
                      if (airport == null) {
                        setState(() {
                          fromAirport = null;
                        });
                        return;
                      }

                      if (toAirport != null &&
                          toAirport!.airportCode == airport.airportCode) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Origin and destination cannot be the same airport',
                              style: TextStyle(fontSize: context.bodyMedium),
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: context.gapMedium.toInt()),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        fromAirport = airport;
                      });
                    },
                  ),

                  SizedBox(height: context.gapSmall),
                  Divider(
                    color: Colors.grey,
                    height: context.dividerThin,
                    thickness: context.dividerThin,
                  ),
                  SizedBox(height: context.gapSmall),

                  // TO field
                  AirportSearchDropdown(
                    title: "TO",
                    hint: "Search airports...",
                    initialSubtitle: "Select destination airport",
                    selectedAirport: toAirport,
                    onAirportSelected: (airport) {
                      if (airport == null) {
                        setState(() {
                          toAirport = null;
                        });
                        return;
                      }

                      if (fromAirport != null &&
                          fromAirport!.airportCode == airport.airportCode) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Origin and destination cannot be the same airport',
                              style: TextStyle(fontSize: context.bodyMedium),
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: context.gapMedium.toInt()),
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
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      final temp = fromAirport;
                      fromAirport = toAirport;
                      toAirport = temp;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(context.gapXXSmall),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: context.avatarRadius,
                      backgroundColor: const Color(0xff1663F7),
                      child: Icon(
                        Icons.swap_vert,
                        color: Colors.white,
                        size: context.iconSmall,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapMedium),

          /// Date Fields
          Row(
            children: [
              Expanded(
                child: _clickableDateTile(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: "DEPARTURE",
                  date: departureDate,
                  placeholder: "Select date",
                  onTap: () => _pickDate(isReturn: false),
                ),
              ),
              SizedBox(width: context.wp(2.5)),
              Expanded(
                child: _clickableDateTile(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: "RETURN",
                  date: returnDate,
                  placeholder: isRoundTrip ? "Select date" : "One way",
                  enabled: isRoundTrip,
                  onTap: isRoundTrip ? () => _pickDate(isReturn: true) : null,
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapMedium),

          /// Travellers & Class Section
          _clickableInfoTile(
            context,
            icon: Icons.person_outline,
            title: "TRAVELLERS & CLASS",
            subtitle: "${adults + children + infants} Traveller${(adults + children + infants) > 1 ? 's' : ''}",
            additionalText: travelClass,
            onTap: _openTravellerSheet,
          ),

          SizedBox(height: context.gapLarge),

          /// SEARCH Button
          SizedBox(
            width: double.infinity,
            height: context.buttonHeight + context.gapXXSmall,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF97316),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                ),
              ),
              onPressed: _performSearch,
              icon: Icon(Icons.search, size: context.iconMedium),
              label: Text(
                "Search Flights",
                style: TextStyle(
                  fontSize: context.titleSmall,
                  fontWeight: FontWeight.w700,
                  letterSpacing: context.letterSpacingNormal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: context.hp(1.5)),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff1663F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.bodyLarge,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade700,
              letterSpacing: context.letterSpacingNormal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _clickableDateTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required DateTime? date,
        required String placeholder,
        bool enabled = true,
        VoidCallback? onTap,
      }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.borderRadiusMedium),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.wp(3),
              vertical: context.hp(1.8),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: context.dividerThin),
              borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: context.iconSmall,
                      color: const Color(0xff0D1B3D),
                    ),
                    SizedBox(width: context.gapSmall),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                        letterSpacing: context.letterSpacingWider,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.gapXXSmall),
                Text(
                  date != null
                      ? "${DateFormat('dd MMM').format(date)}\n${DateFormat('EEEE').format(date)}"
                      : placeholder,
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: date != null ? const Color(0xff0D1B3D) : Colors.grey.shade500,
                    height: 1.3,
                    letterSpacing: context.letterSpacingNormal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _clickableInfoTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required String additionalText,
        required VoidCallback onTap,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(3),
          vertical: context.hp(1.3),
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: context.dividerThin),
          borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: context.iconMedium,
              color: const Color(0xff0D1B3D),
            ),
            SizedBox(width: context.gapMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                      letterSpacing: context.letterSpacingWider,
                    ),
                  ),
                  SizedBox(height: context.gapXXSmall),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.bodyLarge,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff0D1B3D),
                      letterSpacing: context.letterSpacingNormal,
                    ),
                  ),
                  Text(
                    additionalText,
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: Colors.grey.shade600,
                      letterSpacing: context.letterSpacingNormal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: context.iconMedium,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _openTravellerSheet() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: context.wp(5),
                vertical: context.hp(1),
              ),
              contentPadding: EdgeInsets.all(context.dialogContentPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.dialogBorderRadius),
              ),
              content: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: context.screenHeight * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _travellerSection(
                        title: "Adults (Above 12 Years)",
                        selectedValue: adults,
                        onSelected: (val) {
                          setDialogState(() => adults = val);
                        },
                      ),
                      SizedBox(height: context.gapMedium),
                      _travellerSection(
                        title: "Children (2–12 Years)",
                        selectedValue: children,
                        onSelected: (val) {
                          setDialogState(() => children = val);
                        },
                      ),
                      SizedBox(height: context.gapMedium),
                      _travellerSection(
                        title: "Infants (0–23 Months)",
                        selectedValue: infants,
                        onSelected: (val) {
                          setDialogState(() => infants = val);
                        },
                      ),
                      SizedBox(height: context.gapLarge),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Travel Class",
                          style: TextStyle(
                            fontSize: context.titleMedium,
                            fontWeight: FontWeight.w700,
                            letterSpacing: context.letterSpacingNormal,
                          ),
                        ),
                      ),
                      SizedBox(height: context.gapSmall),
                      Row(
                        children: [
                          Expanded(
                            child: _classRadio(
                              title: "Economy",
                              value: "Economy",
                              groupValue: travelClass,
                              onChanged: (val) {
                                setDialogState(() => travelClass = val!);
                              },
                            ),
                          ),
                          Expanded(
                            child: _classRadio(
                              title: "Premium Economy",
                              value: "Premium Economy",
                              groupValue: travelClass,
                              onChanged: (val) {
                                setDialogState(() => travelClass = val!);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.gapXSmall),
                      Row(
                        children: [
                          Expanded(
                            child: _classRadio(
                              title: "Business",
                              value: "Business",
                              groupValue: travelClass,
                              onChanged: (val) {
                                setDialogState(() => travelClass = val!);
                              },
                            ),
                          ),
                          Expanded(
                            child: _classRadio(
                              title: "First",
                              value: "First",
                              groupValue: travelClass,
                              onChanged: (val) {
                                setDialogState(() => travelClass = val!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      fontSize: context.labelMedium,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: context.letterSpacingWide,
                    ),
                  ),
                ),
                SizedBox(width: context.gapXSmall),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF97316),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.wp(6),
                      vertical: context.hp(1.5),
                    ),
                  ),
                  child: Text(
                    "APPLY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.labelMedium,
                      fontWeight: FontWeight.bold,
                      letterSpacing: context.letterSpacingWide,
                    ),
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.symmetric(
                horizontal: context.dialogContentPadding,
                vertical: context.gapMedium,
              ),
              actionsAlignment: MainAxisAlignment.end,
            );
          },
        );
      },
    );
  }

  Widget _travellerSection({
    required String title,
    required int selectedValue,
    required Function(int) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: context.bodyMedium,
                fontWeight: FontWeight.w600,
                letterSpacing: context.letterSpacingNormal,
              ),
            ),
            Text(
              selectedValue.toString(),
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.bold,
                letterSpacing: context.letterSpacingNormal,
              ),
            ),
          ],
        ),
        SizedBox(height: context.gapSmall),
        Wrap(
          spacing: context.gapXSmall,
          runSpacing: context.gapXSmall,
          children: List.generate(
            10,
                (index) => GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                width: context.wp(7.5), // 30px on 400px
                height: context.hp(3.25), // 26px on 800px
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedValue == index
                      ? const Color(0xff1663F7)
                      : Colors.white,
                  border: Border.all(
                    color: selectedValue == index
                        ? const Color(0xff1663F7)
                        : Colors.grey.shade300,
                    width: context.dividerThin,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  index.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.bodySmall,
                    color: selectedValue == index
                        ? Colors.white
                        : Colors.black87,
                    letterSpacing: context.letterSpacingNormal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _classRadio({
    required String title,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Transform.scale(
          scale: context.radioSize / 20, // Scale radio relative to 20px base
          child: Radio<String>(
            value: value,
            groupValue: groupValue,
            activeColor: const Color(0xff1663F7),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: context.gapXXSmall),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.bodySmall,
              letterSpacing: context.letterSpacingNormal,
            ),
          ),
        ),
      ],
    );
  }

  void _pickDate({required bool isReturn}) async {
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
              primary: Color(0xff1663F7),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
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
