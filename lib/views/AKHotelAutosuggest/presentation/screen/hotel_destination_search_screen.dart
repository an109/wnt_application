import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/injection_container.dart';

import '../../domain/entity/AKHotelAutosuggest_entity.dart';
import '../bloc/AKHotelAutosuggest_bloc.dart';
import '../bloc/AKHotelAutosuggest_event.dart';
import '../bloc/AKHotelAutosuggest_state.dart';

/// Full-screen hotel destination picker — the same pattern the flight
/// SearchCard uses for its From / To fields ([DestinationSearchScreen]), but
/// with a single field backed by the Akbar Hotels Autosuggest API. Pops the
/// picked [AkHotelLocationEntity] (or null on back).
///
/// Figma "Hotel destination search" (node 640:9567).
class HotelDestinationSearchScreen extends StatefulWidget {
  final AkHotelLocationEntity? initialLocation;

  const HotelDestinationSearchScreen({super.key, this.initialLocation});

  @override
  State<HotelDestinationSearchScreen> createState() =>
      _HotelDestinationSearchScreenState();
}

class _HotelDestinationSearchScreenState
    extends State<HotelDestinationSearchScreen> {
  static const List<String> _popularCities = [
    'Mumbai',
    'New Delhi',
    'Goa',
    'Bengaluru',
    'Jaipur',
    'Dubai',
    'Bangkok',
    'Singapore',
  ];

  static const _navy = Color(0xFF071638);
  static const _stroke = Color(0xFFCCCCCC);

  late final AkHotelAutosuggestBloc _bloc;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AkHotelAutosuggestBloc>();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = query.trim();
      if (trimmed.length >= 2) {
        _bloc.add(SearchAkHotelLocationsEvent(trimmed));
      }
    });
  }

  void _searchCity(String city) {
    setState(() => _controller.text = city);
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _debounce?.cancel();
    _bloc.add(SearchAkHotelLocationsEvent(city));
    _focusNode.requestFocus();
  }

  void _select(AkHotelLocationEntity location) {
    _debounce?.cancel();
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- header ----
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.w(6), context.h(6), context.w(16), context.h(6)),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Image.asset(
                      'assets/NewIcons/arrowBack.png',
                      width: context.w(17),
                      height: context.w(17),
                      color: AppColors.black,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Select Destination',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(20),
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.h(12)),

            // ---- search field ----
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: Container(
                height: context.h(46),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.AppBlue, width: 1.5),
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.w(12)),
                      child: Icon(Icons.search,
                          size: context.w(20), color: AppColors.subhead),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'City, area or hotel name',
                          hintStyle: TextStyle(
                            fontSize: context.fs(13),
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: context.fs(13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        onChanged: _onQueryChanged,
                      ),
                    ),
                    if (query.isNotEmpty)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _debounce?.cancel();
                          setState(() => _controller.clear());
                          _focusNode.requestFocus();
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: context.w(12)),
                          child: Icon(Icons.close,
                              size: context.w(18), color: const Color(0xffBCC1CA)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.h(16)),

            Expanded(
              child: query.length < 2
                  ? _popular()
                  : BlocBuilder<AkHotelAutosuggestBloc, AkHotelAutosuggestState>(
                      bloc: _bloc,
                      builder: (context, state) => _results(state),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popular() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      children: [
        Text(
          'Popular Searches',
          style: TextStyle(
            fontSize: context.fs(12),
            fontWeight: FontWeight.w600,
            color: _navy,
          ),
        ),
        SizedBox(height: context.h(12)),
        Wrap(
          spacing: context.w(10),
          runSpacing: context.h(10),
          children: _popularCities
              .map((city) => InkWell(
                    onTap: () => _searchCity(city),
                    borderRadius: BorderRadius.circular(context.r(8)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.w(14), vertical: context.h(8)),
                      decoration: BoxDecoration(
                        border: Border.all(color: _stroke),
                        borderRadius: BorderRadius.circular(context.r(8)),
                      ),
                      child: Text(
                        city,
                        style: TextStyle(
                          fontSize: context.fs(13),
                          fontWeight: FontWeight.w600,
                          color: _navy,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _results(AkHotelAutosuggestState state) {
    if (state is AkHotelAutosuggestLoading) {
      return Padding(
        padding: EdgeInsets.all(context.w(24)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state is AkHotelAutosuggestFailed) {
      return _empty('Unable to load destinations', Icons.error_outline);
    }
    if (state is AkHotelAutosuggestLoaded) {
      if (state.locations.isEmpty) {
        return _empty('No results found', Icons.info_outline);
      }
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: context.w(8)),
        itemCount: state.locations.length,
        itemBuilder: (context, i) {
          final l = state.locations[i];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(
                horizontal: context.w(12), vertical: context.h(2)),
            leading: Icon(
              l.type == 'hotel'
                  ? Icons.hotel_outlined
                  : Icons.location_on_outlined,
              size: context.w(22),
              color: _navy,
            ),
            title: Text(
              l.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            subtitle: Text(
              l.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(11),
                color: const Color(0xFF6B7280),
              ),
            ),
            onTap: () => _select(l),
          );
        },
      );
    }
    return _empty('Type to search destinations', Icons.search);
  }

  Widget _empty(String message, IconData icon) {
    return Padding(
      padding: EdgeInsets.all(context.w(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.w(30), color: Colors.grey.shade400),
          SizedBox(height: context.h(8)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: context.fs(13), color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
