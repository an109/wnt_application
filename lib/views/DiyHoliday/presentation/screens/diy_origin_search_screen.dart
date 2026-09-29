import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/diy_origins.dart';
import '../../data/diy_search_query.dart';
import '../widgets/diy_common.dart';

/// "Starting From" picker — Figma `Search from holiday`.
///
/// The DIY backend has no origins endpoint (`/destinations/` is the
/// travelling-to list), so the list comes from [DiyOrigins]; "Use current
/// location" snaps to the nearest listed departure city.
class DiyOriginSearchScreen extends StatefulWidget {
  final DiyOrigin? initial;

  const DiyOriginSearchScreen({super.key, this.initial});

  @override
  State<DiyOriginSearchScreen> createState() => _DiyOriginSearchScreenState();
}

class _DiyOriginSearchScreenState extends State<DiyOriginSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<DiyOrigin> _recent = const [];
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    DiySearchStore.recentOrigins().then((value) {
      if (mounted) setState(() => _recent = value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _select(DiyOrigin origin) {
    DiySearchStore.addRecentOrigin(origin);
    Navigator.of(context).pop(origin);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are turned off.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission was denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      _select(DiyOrigins.nearest(position.latitude, position.longitude));
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    final results = DiyOrigins.search(query);
    final showRecent = query.trim().isEmpty && _recent.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _searchField(),
            SizedBox(height: context.h(12)),
            _currentLocationRow(),
            const Divider(height: 1, color: DiyTokens.line),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: context.h(24)),
                children: [
                  if (showRecent) ...[
                    _sectionLabel('RECENT SEARCHES'),
                    for (final origin in _recent)
                      _originTile(origin, recent: true),
                    SizedBox(height: context.h(8)),
                    _sectionLabel('POPULAR DEPARTURE CITIES'),
                  ],
                  for (final origin in results) _originTile(origin),
                  if (results.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(context.w(24)),
                      child: Text(
                        'No departure city matches "$query".',
                        style: TextStyle(
                          fontSize: context.fs(13),
                          color: DiyTokens.subGrey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(10),
        context.w(14),
        0,
      ),
      child: Container(
        height: context.h(46),
        padding: EdgeInsets.symmetric(horizontal: context.w(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: DiyTokens.blue, width: 1.4),
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(
                Icons.arrow_back,
                size: context.w(20),
                color: DiyTokens.subGrey,
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Starting From...',
                  hintStyle: TextStyle(
                    fontSize: context.fs(14),
                    color: DiyTokens.labelGrey,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: context.fs(14),
                  color: DiyTokens.navy,
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: () => setState(_controller.clear),
                child: Icon(
                  Icons.close,
                  size: context.w(18),
                  color: DiyTokens.labelGrey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _currentLocationRow() {
    return InkWell(
      onTap: _locating ? null : _useCurrentLocation,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(10),
        ),
        child: Row(
          children: [
            if (_locating)
              SizedBox(
                width: context.w(16),
                height: context.w(16),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(DiyTokens.navy),
                ),
              )
            else
              Icon(
                Icons.near_me,
                size: context.w(18),
                color: DiyTokens.navy,
              ),
            SizedBox(width: context.w(12)),
            Text(
              _locating ? 'Finding you…' : 'Use current location',
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w600,
                color: DiyTokens.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(14),
        context.w(16),
        context.h(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(10),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: DiyTokens.labelGrey,
        ),
      ),
    );
  }

  Widget _originTile(DiyOrigin origin, {bool recent = false}) {
    return InkWell(
      onTap: () => _select(origin),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(11),
        ),
        child: Row(
          children: [
            Icon(
              recent ? Icons.history : Icons.location_on_outlined,
              size: context.w(18),
              color: recent ? DiyTokens.blue : const Color(0xFFC7CCD6),
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    origin.name,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w600,
                      color: DiyTokens.navy,
                    ),
                  ),
                  if (origin.state.isNotEmpty && origin.state != origin.name)
                    Text(
                      origin.state,
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: DiyTokens.subGrey,
                      ),
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
