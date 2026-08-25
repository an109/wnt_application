import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/airport_entities.dart';
import '../bloc/airport_bloc.dart';
import '../bloc/airport_event.dart';
import '../bloc/airport_state.dart';

enum _ActiveField { from, to }

/// Full-screen destination picker — replaces the old inline dropdown
/// overlay. Shows FROM and TO stacked (matching the Figma reference), lets
/// the user switch which one they're editing, offers a Popular Searches
/// chip grid plus the live airport search list, and returns both
/// selections together so one visit can fill in whichever field is still
/// empty (auto-advances from FROM to TO and vice versa).
class DestinationSearchScreen extends StatefulWidget {
  final AirportEntity? initialFrom;
  final AirportEntity? initialTo;
  final bool startWithFrom;

  const DestinationSearchScreen({
    super.key,
    this.initialFrom,
    this.initialTo,
    this.startWithFrom = true,
  });

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  static const List<String> _popularCities = [
    'Mumbai',
    'New Delhi',
    'Bangkok',
    'Bengaluru',
    'Pune',
    'Hyderabad',
    'Kolkata',
    'Dubai',
  ];

  late final AirportBloc _bloc;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  late _ActiveField _active;
  AirportEntity? _from;
  AirportEntity? _to;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AirportBloc>();
    _bloc.add(LoadAirports());
    _from = widget.initialFrom;
    _to = widget.initialTo;
    _active = widget.startWithFrom ? _ActiveField.from : _ActiveField.to;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _bloc.close();
    super.dispose();
  }

  void _switchActive(_ActiveField field) {
    if (_active == field) {
      _focusNode.requestFocus();
      return;
    }
    setState(() {
      _active = field;
      _controller.clear();
    });
    _bloc.add(LoadAirports());
  }

  void _onQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {}); // toggle Popular Searches vs results immediately
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = query.trim();
      _bloc.add(
        trimmed.length >= 2
            ? LoadAirports(searchQuery: trimmed)
            : LoadAirports(),
      );
    });
  }

  void _selectAirport(AirportEntity airport) {
    final other = _active == _ActiveField.from ? _to : _from;
    if (other != null && other.airportCode == airport.airportCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Origin and destination cannot be the same airport',
            style: TextStyle(fontSize: context.bodyMedium),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pickedFrom = _active == _ActiveField.from;
    setState(() {
      if (pickedFrom) {
        _from = airport;
      } else {
        _to = airport;
      }
      _controller.clear();
    });

    // Guide the user straight to whichever field is still empty; once both
    // are filled, hand control back to the caller.
    if (pickedFrom && _to == null) {
      _switchActive(_ActiveField.to);
    } else if (!pickedFrom && _from == null) {
      _switchActive(_ActiveField.from);
    } else {
      Navigator.of(context).pop({'from': _from, 'to': _to});
    }
  }

  void _selectCityByName(String cityName) {
    final state = _bloc.state;
    AirportEntity? match;
    if (state is AirportLoaded) {
      for (final airport in state.airports) {
        if (airport.cityName.toLowerCase() == cityName.toLowerCase()) {
          match = airport;
          break;
        }
      }
    }
    if (match != null) {
      _selectAirport(match);
    } else {
      // Not in the currently-loaded list — fall back to a live search.
      setState(() => _controller.text = cityName);
      _bloc.add(LoadAirports(searchQuery: cityName));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(4),
                context.h(24),
                context.w(16),
                context.h(4),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  border: Border.all(color: AppColors.fieldBorder),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Column(
                  children: [
                    _fieldRow(
                      field: _ActiveField.from,
                      icon: Icons.arrow_back,
                      placeholder: 'From',
                      airport: _from,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.fieldBorder,
                      indent: context.w(44),
                    ),
                    _fieldRow(
                      field: _ActiveField.to,
                      icon: Icons.flight_land,
                      placeholder: 'To',
                      airport: _to,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.h(14)),

            Expanded(
              child: BlocBuilder<AirportBloc, AirportState>(
                bloc: _bloc,
                builder: (context, state) {
                  final showPopular = _controller.text.trim().isEmpty;
                  return ListView(
                    padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                    children: [
                      if (showPopular) ...[
                        Text(
                          'Popular Searches',
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: context.h(10)),
                        Wrap(
                          spacing: context.w(10),
                          runSpacing: context.h(10),
                          children: _popularCities
                              .map((city) => _popularChip(city))
                              .toList(),
                        ),
                        SizedBox(height: context.h(16)),
                      ] else
                        _resultsList(state),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow({
    required _ActiveField field,
    required IconData icon,
    required String placeholder,
    required AirportEntity? airport,
  }) {
    final isActive = _active == field;
    return InkWell(
      onTap: () => _switchActive(field),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.w(18), color: AppColors.navy),
            SizedBox(width: context.w(11)),
            Expanded(
              child: isActive
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: placeholder,
                        hintStyle: TextStyle(
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff7D849B),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                      onChanged: _onQueryChanged,
                    )
                  : Text(
                      airport != null
                          ? '${airport.cityName}  ${airport.airportName}'
                          : placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w700,
                        color: airport != null
                            ? AppColors.navy
                            : const Color(0xff9CA3AF),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popularChip(String city) {
    return InkWell(
      onTap: () => _selectCityByName(city),
      borderRadius: BorderRadius.circular(context.r(8)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(8),
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.fieldBorder),
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        child: Text(
          city,
          style: TextStyle(
            fontSize: context.fs(13),
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ),
    );
  }

  Widget _resultsList(AirportState state) {
    if (state is AirportLoading) {
      return Padding(
        padding: EdgeInsets.all(context.w(24)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state is AirportError) {
      return Padding(
        padding: EdgeInsets.all(context.w(24)),
        child: Center(
          child: Text(
            'Unable to load airports',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: context.bodyMedium,
            ),
          ),
        ),
      );
    }
    if (state is AirportLoaded) {
      if (state.airports.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(context.w(24)),
          child: Center(
            child: Text(
              'No airports found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: context.bodyMedium,
              ),
            ),
          ),
        );
      }
      return Column(
        children: state.airports.map((airport) {
          return ListTile(
            leading: Icon(
              Icons.local_airport,
              color: AppColors.navy,
              size: context.iconMedium,
            ),
            title: Text(
              "${airport.cityName}, ${airport.countryCode}",
              style: TextStyle(
                fontSize: context.bodyMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            subtitle: Text(
              "${airport.airportName} (${airport.airportCode})",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade600,
              ),
            ),
            onTap: () => _selectAirport(airport),
          );
        }).toList(),
      );
    }
    return const SizedBox.shrink();
  }
}
