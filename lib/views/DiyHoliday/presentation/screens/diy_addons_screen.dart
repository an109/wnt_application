import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';

/// Add-on picker used **before** a trip exists.
///
/// The list comes from **API 11 — GET /packages/{share_id}/addons/**; the
/// ids picked here feed **API 14 (customise)** for a live quote and
/// **API 15 (enquiry)** as `add_on_ids`.
class DiyAddonsPickerScreen extends StatefulWidget {
  final List<DiyAddon> addons;
  final Set<String> initiallySelected;
  final String currency;

  const DiyAddonsPickerScreen({
    super.key,
    required this.addons,
    required this.initiallySelected,
    this.currency = 'INR',
  });

  @override
  State<DiyAddonsPickerScreen> createState() => _DiyAddonsPickerScreenState();
}

class _DiyAddonsPickerScreenState extends State<DiyAddonsPickerScreen> {
  late final Set<String> _selected = {...widget.initiallySelected};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      appBar: diyAppBar(context, title: 'Add-ons'),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          context.w(14),
          context.h(12),
          context.w(14),
          context.h(20),
        ),
        itemCount: widget.addons.length,
        itemBuilder: (context, i) {
          final addon = widget.addons[i];
          final selected = _selected.contains(addon.id);
          return Padding(
            padding: EdgeInsets.only(bottom: context.h(10)),
            child: DiyAddonTile(
              addon: addon,
              currency: widget.currency,
              selected: selected,
              onTap: () => setState(() {
                if (selected) {
                  _selected.remove(addon.id);
                } else {
                  _selected.add(addon.id);
                }
              }),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          context.w(14),
          context.h(10),
          context.w(14),
          context.h(10) + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: DiyTokens.line)),
        ),
        child: DiyPrimaryButton(
          label: _selected.isEmpty
              ? 'CONTINUE WITHOUT ADD-ONS'
              : 'APPLY ${_selected.length} ADD-ON${_selected.length == 1 ? '' : 'S'}',
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ),
    );
  }
}

/// Add-on management for a **live trip**: selecting one calls
/// **API 12 — POST /trips/{trip_id}/activities/** and removing one calls
/// **API 13 — DELETE /trips/{trip_id}/activities/{id}/**. Every add returns
/// the whole trip with a refreshed grand total.
class DiyTripAddonsScreen extends StatefulWidget {
  /// The trip being edited — add/remove answer with a partial trip, so this
  /// is the base they are merged onto.
  final DiyTrip trip;
  final List<DiyAddon> addons;

  /// addon id → the trip-activity id returned when it was added. Only
  /// add-ons added through the app carry a removable handle: the trip's own
  /// ACTIVITY rows do not expose one.
  final Map<String, String> addedIds;

  const DiyTripAddonsScreen({
    super.key,
    required this.trip,
    required this.addons,
    required this.addedIds,
  });

  String get tripId => trip.tripId;
  String get currency => trip.currency;
  List<DiyDay> get days => trip.days;

  @override
  State<DiyTripAddonsScreen> createState() => _DiyTripAddonsScreenState();
}

class _DiyTripAddonsScreenState extends State<DiyTripAddonsScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();

  late final Map<String, String> _added = {...widget.addedIds};
  DiyTrip? _latestTrip;
  String? _busyAddonId;

  Future<void> _toggle(DiyAddon addon) async {
    final existingId = _added[addon.id];

    // Added, but the API never handed back a trip-activity id, so there is
    // nothing to address the DELETE to. Say so rather than firing a request
    // that comes back 405/404.
    if (existingId != null && existingId.isEmpty) {
      diySnack(
        context,
        'Added to your trip. Removing it needs a consultant — the booking '
        'system does not return a handle for it yet.',
      );
      return;
    }

    setState(() => _busyAddonId = addon.id);
    try {
      if (existingId != null) {
        await _api.removeActivity(
          tripId: widget.tripId,
          tripActivityId: existingId,
        );
        if (!mounted) return;
        setState(() => _added.remove(addon.id));
        // DELETE answers with no body on some builds — re-read the trip so
        // the caller still gets a fresh grand total.
        _latestTrip = await _api.getTrip(widget.tripId);
        if (mounted) setState(() {});
      } else {
        final day = await _pickDay(addon);
        if (day == null || !mounted) return;
        final result = await _api.addActivity(
          tripId: widget.tripId,
          activityId: addon.id,
          day: day,
          previous: _latestTrip ?? widget.trip,
        );
        if (!mounted) return;
        setState(() {
          _added[addon.id] = result.id;
          _latestTrip = result.trip;
        });
      }
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busyAddonId = null);
    }
  }

  /// The API takes the day number the activity belongs to; offer the days
  /// that are actually in this trip, with the ones in the add-on's own
  /// destination first.
  Future<int?> _pickDay(DiyAddon addon) {
    final matching = widget.days
        .where(
          (d) =>
              addon.destination.isEmpty ||
              d.destination.toLowerCase() == addon.destination.toLowerCase(),
        )
        .toList();
    final days = matching.isEmpty ? widget.days : matching;

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(18)),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(20),
                context.h(16),
                context.w(20),
                context.h(8),
              ),
              child: Text(
                'Which day?',
                style: TextStyle(
                  fontSize: context.fs(17),
                  fontWeight: FontWeight.w700,
                  color: DiyTokens.navy,
                ),
              ),
            ),
            for (final day in days)
              ListTile(
                title: Text(
                  'Day ${day.day} · ${day.label.isEmpty ? day.destination : day.label}',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    color: DiyTokens.navy,
                  ),
                ),
                subtitle: Text(
                  diyDayDate(day.date),
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTokens.subGrey,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(day.day),
              ),
            SizedBox(height: context.h(8)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(
          context,
        ).pop(DiyTripAddonsResult(trip: _latestTrip, addedIds: _added));
      },
      child: Scaffold(
        backgroundColor: DiyTokens.pageBg,
        appBar: diyAppBar(context, title: 'Add-ons'),
        body: Column(
          children: [
            if (_latestTrip != null) _totalBanner(_latestTrip!),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  context.w(14),
                  context.h(12),
                  context.w(14),
                  context.h(20),
                ),
                itemCount: widget.addons.length,
                itemBuilder: (context, i) {
                  final addon = widget.addons[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.h(10)),
                    child: DiyAddonTile(
                      addon: addon,
                      currency: widget.currency,
                      selected: _added.containsKey(addon.id),
                      busy: _busyAddonId == addon.id,
                      onTap: () => _toggle(addon),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalBanner(DiyTrip trip) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(10),
      ),
      color: const Color(0xFFE8F4FC),
      child: Text(
        'New trip total: ${diyMoney(trip.grandTotal, currency: trip.currency)}',
        style: TextStyle(
          fontSize: context.fs(13),
          fontWeight: FontWeight.w700,
          color: DiyTokens.navy,
        ),
      ),
    );
  }
}

/// What [DiyTripAddonsScreen] hands back: the freshest trip it saw (null if
/// nothing changed) plus the add-on → trip-activity id map to keep.
class DiyTripAddonsResult {
  final DiyTrip? trip;
  final Map<String, String> addedIds;

  const DiyTripAddonsResult({required this.trip, required this.addedIds});
}

class DiyAddonTile extends StatelessWidget {
  final DiyAddon addon;
  final String currency;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  const DiyAddonTile({
    super.key,
    required this.addon,
    required this.selected,
    required this.onTap,
    this.currency = 'INR',
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(
              color: selected ? DiyTokens.blue : DiyTokens.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          padding: EdgeInsets.all(context.w(10)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiyImage(
                url: addon.image,
                width: context.w(74),
                height: context.w(74),
                radius: BorderRadius.circular(context.r(10)),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addon.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color: DiyTokens.navy,
                      ),
                    ),
                    SizedBox(height: context.h(3)),
                    Text(
                      [
                        addon.destination,
                        addon.category,
                        if (addon.durationMinutes > 0)
                          diyDuration(addon.durationMinutes),
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(
                        fontSize: context.fs(10.5),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                    SizedBox(height: context.h(5)),
                    Text(
                      addon.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(10.5),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                    SizedBox(height: context.h(7)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            addon.isComplimentary
                                ? 'Complimentary'
                                : '${diyMoney(addon.pricePerPerson, currency: currency)} / person',
                            style: TextStyle(
                              fontSize: context.fs(12.5),
                              fontWeight: FontWeight.w800,
                              color: addon.isComplimentary
                                  ? Colors.green.shade700
                                  : DiyTokens.navy,
                            ),
                          ),
                        ),
                        if (busy)
                          SizedBox(
                            width: context.w(18),
                            height: context.w(18),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(12),
                              vertical: context.h(5),
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? DiyTokens.blue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                context.r(20),
                              ),
                              border: Border.all(color: DiyTokens.blue),
                            ),
                            child: Text(
                              selected ? 'Added' : 'Add',
                              style: TextStyle(
                                fontSize: context.fs(11.5),
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : DiyTokens.blue,
                              ),
                            ),
                          ),
                      ],
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
}
