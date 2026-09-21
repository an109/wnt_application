import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/T_locationEntity.dart';
import '../bloc/T_locationBloc.dart';
import '../bloc/T_locationEvent.dart';
import '../bloc/T_locationState.dart';

const String _recentLocationsKey = 'transport_recent_locations';
const int _maxRecentLocations = 5;

/// Single-field pickup/drop-off search — one screen instance per field
/// (FROM and TO each push their own), matching the Figma. Same
/// [T_locationBloc]/[T_locationEntity] plumbing as before; adds a working
/// "Use current location" (via geolocator + reverse geocoding) and a real
/// recently-picked-locations list persisted locally.
class TLocationSearchScreen extends StatefulWidget {
  final String fieldLabel;
  final String hint;
  final bool showUseCurrentLocation;
  final T_locationEntity? initialLocation;

  const TLocationSearchScreen({
    super.key,
    required this.fieldLabel,
    required this.hint,
    this.showUseCurrentLocation = false,
    this.initialLocation,
  });

  @override
  State<TLocationSearchScreen> createState() => _TLocationSearchScreenState();
}

class _TLocationSearchScreenState extends State<TLocationSearchScreen> {
  late final T_locationBloc _bloc;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  bool _locatingCurrent = false;
  List<T_locationEntity> _recentLocations = [];

  @override
  void initState() {
    super.initState();
    _bloc = sl<T_locationBloc>();
    if (widget.initialLocation != null) {
      _controller.text = widget.initialLocation!.label;
    }
    _loadRecents();
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
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _bloc.add(const ClearT_locationsEvent());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _bloc.add(SearchT_locationsEvent(searchQuery: trimmed));
    });
  }

  Future<void> _finish(T_locationEntity location) async {
    await _saveRecent(location);
    if (!mounted) return;
    Navigator.of(context).pop(location);
  }

  // ---------------------------------------------------------- CURRENT LOCATION

  Future<void> _useCurrentLocation() async {
    setState(() => _locatingCurrent = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are turned off.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'Location permission was denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      String address = 'Current location';
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.name, p.subLocality, p.locality, p.administrativeArea]
              .where((s) => s != null && s.trim().isNotEmpty)
              .toSet() // drop immediate duplicates like name == locality
              .toList();
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {
        // Reverse geocoding failing shouldn't block using the raw coordinates.
      }

      final location = T_locationEntity(
        id: 'current_${position.latitude}_${position.longitude}',
        source: 'device',
        type: 'place',
        label: address,
        displayName: address,
        name: 'Current Location',
        description: address,
        formattedAddress: address,
        fullAddress: address,
        address: address,
        city: '',
        country: '',
        iataCode: '',
        icaoCode: '',
        placeId: '',
        lat: position.latitude,
        lng: position.longitude,
        timezone: '',
        raw: null,
      );

      if (!mounted) return;
      await _finish(location);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locatingCurrent = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is String ? e : 'Could not detect your location.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // -------------------------------------------------------------- RECENTS

  Future<void> _loadRecents() async {
    try {
      final prefs = await PreferencesManager.create(await SharedPreferences.getInstance());
      final raw = prefs.getString(_recentLocationsKey);
      if (raw == null || !mounted) return;
      final decoded = jsonDecode(raw) as List;
      final locations = decoded
          .map((e) => _locationFromJson((e as Map).cast<String, dynamic>()))
          .whereType<T_locationEntity>()
          .toList();
      setState(() => _recentLocations = locations);
    } catch (e) {
      debugPrint('Error loading recent transport locations: $e');
    }
  }

  Future<void> _saveRecent(T_locationEntity location) async {
    try {
      final prefs = await PreferencesManager.create(await SharedPreferences.getInstance());
      final updated = [
        location,
        ..._recentLocations.where((l) => l.id != location.id),
      ].take(_maxRecentLocations).toList();
      await prefs.setString(_recentLocationsKey, jsonEncode(updated.map(_locationToJson).toList()));
    } catch (e) {
      debugPrint('Error saving recent transport location: $e');
    }
  }

  Map<String, dynamic> _locationToJson(T_locationEntity l) => {
        'id': l.id,
        'source': l.source,
        'type': l.type,
        'label': l.label,
        'displayName': l.displayName,
        'name': l.name,
        'description': l.description,
        'formattedAddress': l.formattedAddress,
        'fullAddress': l.fullAddress,
        'address': l.address,
        'city': l.city,
        'country': l.country,
        'iataCode': l.iataCode,
        'icaoCode': l.icaoCode,
        'placeId': l.placeId,
        'lat': l.lat,
        'lng': l.lng,
        'timezone': l.timezone,
      };

  T_locationEntity? _locationFromJson(Map<String, dynamic> json) {
    if (json['id'] == null) return null;
    return T_locationEntity(
      id: json['id'] ?? '',
      source: json['source'] ?? '',
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      displayName: json['displayName'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      iataCode: json['iataCode'] ?? '',
      icaoCode: json['icaoCode'] ?? '',
      placeId: json['placeId'] ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      timezone: json['timezone'] ?? '',
      raw: null,
    );
  }

  // ---------------------------------------------------------------- BUILD

  @override
  Widget build(BuildContext context) {
    final showResults = _controller.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(context.w(16)),
              child: _fieldBox(context),
            ),
            Expanded(
              child: showResults
                  ? BlocBuilder<T_locationBloc, T_locationState>(
                      bloc: _bloc,
                      builder: (context, state) => _resultsList(context, state),
                    )
                  : _suggestions(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldBox(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(10)),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.AppBlue, width: 1.4),
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_rounded, color: Colors.black54, size: context.w(22)),
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.fieldLabel,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w700,
                    color: AppColors.AppBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: context.h(2)),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(fontSize: context.fs(15), color: Colors.grey.shade400),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w500, color: AppColors.black),
                  onChanged: _onQueryChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestions(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      children: [
        if (widget.showUseCurrentLocation) ...[
          SizedBox(height: context.h(8)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _locatingCurrent ? null : _useCurrentLocation,
            child: Row(
              children: [
                _locatingCurrent
                    ? SizedBox(
                        width: context.w(20),
                        height: context.w(20),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.AppBlue),
                      )
                    : Icon(Icons.my_location_rounded, color: AppColors.AppBlue, size: context.w(20)),
                SizedBox(width: context.w(14)),
                Text(
                  'Use current location',
                  style: TextStyle(color: AppColors.AppBlue, fontSize: context.fs(14.5), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(28)),
        ],
        if (_recentLocations.isNotEmpty) ...[
          Text(
            'RECENT SEARCHES',
            style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5),
          ),
          SizedBox(height: context.h(10)),
          for (final location in _recentLocations) _recentTile(context, location),
        ],
      ],
    );
  }

  Widget _recentTile(BuildContext context, T_locationEntity location) {
    return InkWell(
      onTap: () => _finish(location),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.w(36),
              height: context.w(36),
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFF1F3F6), shape: BoxShape.circle),
              child: Icon(Icons.history_rounded, size: context.w(18), color: Colors.black87),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    location.name.isNotEmpty ? location.name : location.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w600, color: AppColors.black),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    location.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultsList(BuildContext context, T_locationState state) {
    if (state is T_locationsLoading || state is T_locationsSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is T_locationsLoaded || state is T_locationsSearchLoaded) {
      final locations = state is T_locationsLoaded
          ? state.locations
          : (state as T_locationsSearchLoaded).locations;

      if (locations.isEmpty) {
        return Center(
          child: Text(
            'No locations found',
            style: TextStyle(color: Colors.grey.shade600, fontSize: context.fs(13)),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: context.w(16)),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: context.h(2)),
            leading: Icon(
              _iconForType(location.type),
              size: context.w(20),
              color: AppColors.black,
            ),
            title: Text(
              location.name,
              style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: AppColors.black),
            ),
            subtitle: Text(
              location.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600),
            ),
            onTap: () => _finish(location),
          );
        },
      );
    }

    if (state is T_locationsError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.w(24)),
          child: Text(
            state.message,
            style: TextStyle(color: Colors.red.shade700, fontSize: context.fs(13)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'airport':
        return Icons.airplanemode_active;
      case 'port':
        return Icons.directions_boat;
      case 'city':
        return Icons.location_city;
      case 'place':
        return Icons.place;
      default:
        return Icons.location_on_outlined;
    }
  }
}
