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
    setState(() {});
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
            SizedBox(height: context.h(24)),

            // From Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: _buildSingleField(
                field: _ActiveField.from,
                placeholder: 'From',
                airport: _from,
                isActive: _active == _ActiveField.from,
              ),
            ),

            SizedBox(height: context.h(10)),

            // To Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: _buildSingleField(
                field: _ActiveField.to,
                placeholder: 'To',
                airport: _to,
                isActive: _active == _ActiveField.to,
              ),
            ),

            SizedBox(height: context.h(16)),

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
                        SizedBox(height: context.h(12)),
                        Wrap(
                          spacing: context.w(10),
                          runSpacing: context.h(10),
                          children: _popularCities
                              .map((city) => _popularChip(city))
                              .toList(),
                        ),
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

  Widget _buildSingleField({
    required _ActiveField field,
    required String placeholder,
    required AirportEntity? airport,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _switchActive(field),
      child: Container(
        height: context.h(42),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFCCCCCC),
            // color: isActive ? AppColors.blue : const Color(0xFFCCCCCC),
            width: isActive ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(14)),
              child: Image.asset(
                field == _ActiveField.from
                    ? 'assets/NewIcons/arrowBack.png'
                    : 'assets/NewIcons/destinationIcon.png',
                width: _active == _ActiveField.from
                    ? context.w(16)  // Blue for From/Departure
                    : context.w(20),
                // width: context.w(20),
                height: _active == _ActiveField.from
                    ? context.h(16)  // Blue for From/Departure
                    : context.h(20),
                // height: context.w(20),
                color: field == _ActiveField.from
                    ? AppColors.subhead  // Blue for From/Departure
                    : Color(0xFFCCCCCC), // Orange for To/Arrival
              ),
            ),
            Expanded(
              child: isActive
                  ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
                onChanged: _onQueryChanged,
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    airport?.cityName ?? placeholder,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: airport != null
                          ? AppColors.navy
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  if (airport != null)
                    Text(
                      airport.airportName,
                      style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
            if (!isActive && airport == null)
              Padding(
                padding: EdgeInsets.only(right: context.w(14)),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color(0xFF9CA3AF),
                  size: context.w(20),
                ),
              ),
          ],
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
            leading: Image.asset(
              _active == _ActiveField.from
                  ? 'assets/NewIcons/arrowBack.png'
                  : 'assets/NewIcons/destinationIcon.png',
              width: _active == _ActiveField.from
                  ? context.w(16)
                  : context.w(20),
              // width: context.w(20),
              height: _active == _ActiveField.from
                  ? context.h(16)  // Blue for From/Departure
                  : context.h(20),
              // height: context.w(20),
              color: _active == _ActiveField.from
                  ? AppColors.subhead  // Blue for From/Departure
                  : Color(0xFFCCCCCC), // Orange for To/Arrival
            ),
            title: Text(
              airport.cityName,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            subtitle: Text(
              airport.airportName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(11),
                color: const Color(0xFF6B7280),
              ),
            ),
            onTap: () => _selectAirport(airport),
          );
        }).toList(),
      );
    }
    return const SizedBox.shrink();
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
          border: Border.all(color: const Color(0xFFCCCCCC)),
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


}
