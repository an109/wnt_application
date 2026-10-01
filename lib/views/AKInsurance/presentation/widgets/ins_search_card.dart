import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../countries/domain/entities/country_entity.dart';
import '../screens/ins_date_screen.dart';
import '../screens/ins_destination_screen.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import 'ins_common.dart';
import 'ins_traveller_sheet.dart';

/// The hero search form on the insurance landing screen — Figma
/// `insurance 1`-`insurance 5`.
///
/// Stateless on purpose: the query lives on [InsHomeScreen] so the tab row,
/// the pickers and the CTA all read and write one [InsSearchQuery] rather
/// than each keeping a private copy of the trip.
class InsSearchCard extends StatelessWidget {
  final InsSearchQuery query;
  final List<InsPolicyType> policyTypes;
  final List<CountryEntity> countries;
  final String? heroImage;
  final ValueChanged<InsSearchQuery> onChanged;
  final VoidCallback onExplore;

  /// `false` is the landing hero (white text over the photo); `true` is the
  /// "Edit Your Search" screen, which is the same form on a plain white
  /// page with a grey tab bar and a full-width CTA.
  final bool light;

  /// The CTA's wording — "Explore Plans" on the hero, "MODIFY SEARCH" on
  /// the edit screen.
  final String ctaLabel;

  const InsSearchCard({
    super.key,
    required this.query,
    required this.policyTypes,
    required this.countries,
    required this.heroImage,
    required this.onChanged,
    required this.onExplore,
    this.light = false,
    this.ctaLabel = 'Explore Plans',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!light) Positioned.fill(child: _Backdrop(heroImage: heroImage)),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: light ? context.h(4) : context.statusBarHeight + context.h(8),
            ),
            _TypeTabs(
              types: policyTypes,
              selected: query.policyType,
              light: light,
              onSelected: (t) => onChanged(
                query.copyWith(
                  policyType: t,
                  // Tenure only exists on a student policy; drop it when the
                  // traveller switches away so the next quote doesn't carry
                  // a stale month count.
                  clearTenure: !t.isStudent,
                  tenureMonths: t.isStudent ? (query.tenureMonths ?? 3) : null,
                  // Switching type can both tighten the party size (Family's
                  // 6 → Individual's 1) and change what relation co-
                  // travellers must carry, so the list is trimmed and
                  // re-relationed in one step. Dates of birth already
                  // entered are kept.
                  travellers: [
                    for (int i = 0;
                        i < query.travellers.length && i < t.maxTravellers;
                        i++)
                      i == 0
                          ? query.travellers[i]
                          : query.travellers[i].copyWith(
                              relation: t.isFriends ? 'MEMBER' : 'SPOUSE',
                            ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.h(14)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(14)),
              child: Column(
                children: [
                  _countryRow(context),
                  SizedBox(height: context.h(10)),
                  query.isStudent
                      ? _studentDateRow(context)
                      : _dateCard(context),
                  SizedBox(height: context.h(10)),
                  _travellersCard(context),
                ],
              ),
            ),
            SizedBox(height: context.h(22)),
            light
                ? Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: context.w(14)),
                    child: InsPrimaryButton(
                      label: ctaLabel,
                      onPressed: onExplore,
                      trailing: Icon(Icons.arrow_forward_rounded,
                          size: context.w(18)),
                    ),
                  )
                : _exploreButton(context),
            SizedBox(height: context.h(26)),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------- from / travelling to

  Widget _countryRow(BuildContext context) {
    // IntrinsicHeight so the two cards match height: a bare `stretch` here
    // would be laid out against the hero Column's unbounded height.
    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _FieldCard(
            light: light,
            label: 'FROM COUNTRY',
            chevron: true,
            icon: Icons.public_rounded,
            value: query.fromCountry.name,
            onTap: () => _pickFromCountry(context),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: _FieldCard(
            light: light,
            label: 'TRAVELLING TO',
            chevron: true,
            icon: Icons.travel_explore_rounded,
            value: query.destinations.isEmpty ? 'Select' : null,
            valueWidget: query.destinations.isEmpty
                ? null
                : _destinationValue(context),
            placeholder: query.destinations.isEmpty,
            onTap: () => _pickDestinations(context),
          ),
        ),
      ],
      ),
    );
  }

  /// `Thailand, UAE +2` with the overflow count in blue, as the mock shows.
  Widget _destinationValue(BuildContext context) {
    final names = query.destinations.map((c) => c.name).toList();
    final shown = names.take(2).join(', ');
    final extra = names.length - 2;

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        text: shown,
        style: TextStyle(
          fontSize: context.fs(14),
          fontWeight: FontWeight.w700,
          color: InsTokens.navy,
        ),
        children: [
          if (extra > 0)
            TextSpan(
              text: ' +$extra',
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w700,
                color: InsTokens.blue,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickFromCountry(BuildContext context) async {
    final picked = await InsDestinationScreen.pickSingle(
      context,
      countries: countries,
      initial: query.fromCountry,
      title: 'Select origin',
      subtitle: 'Where the trip starts from',
    );
    if (picked != null) onChanged(query.copyWith(fromCountry: picked));
  }

  Future<void> _pickDestinations(BuildContext context) async {
    final picked = await InsDestinationScreen.pickMany(
      context,
      countries: countries,
      initial: query.destinations,
    );
    if (picked != null) onChanged(query.copyWith(destinations: picked));
  }

  // -------------------------------------------------------------- dates

  Widget _dateCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      decoration: insCard(context, border: light, shadow: !light),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDates(context, startFirst: true),
              behavior: HitTestBehavior.opaque,
              child: _dateColumn(context, 'START DATE', query.startDate),
            ),
          ),
          _dayPill(context),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDates(context, startFirst: false),
              behavior: HitTestBehavior.opaque,
              child: _dateColumn(
                context,
                'END DATE',
                query.resolvedEndDate,
                alignEnd: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentDateRow(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDates(context, startFirst: true),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(14),
                vertical: context.h(12),
              ),
              decoration: insCard(context, border: light, shadow: !light),
              child: _dateColumn(context, 'START DATE', query.startDate),
            ),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: _TenureField(
            light: light,
            months: query.tenureMonths ?? 3,
            onChanged: (m) => onChanged(query.copyWith(tenureMonths: m)),
          ),
        ),
      ],
      ),
    );
  }

  Widget _dateColumn(
    BuildContext context,
    String label,
    DateTime? date, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FieldLabel(label),
        SizedBox(height: context.h(6)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/NewIcons/departureCalendar.png',
              width: context.w(22),
              height: context.h(22),
              color: AppColors.AppBlue,
            ),
            SizedBox(width: context.w(8)),
            Text(
              date == null ? 'Select' : InsTokens.searchDate(date),
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: date == null ? InsTokens.labelGrey : InsTokens.navy,
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(2)),
        Padding(
          padding: EdgeInsets.only(left: alignEnd ? 0 : context.w(27)),
          child: Text(
            date == null ? '—' : InsTokens.weekday(date),
            style: TextStyle(
              fontSize: context.fs(10),
              color: InsTokens.subGrey,
            ),
          ),
        ),
      ],
    );
  }

  /// The orange-underlined "5 Day" chip between the two dates.
  Widget _dayPill(BuildContext context) {
    final n = query.days;
    return Padding(
      // padding: EdgeInsets.symmetric(horizontal: context.w(8)),
      padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.w(32),
            height: context.h(1),
            color: InsTokens.orange,
          ),
          SizedBox(height: context.h(8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(8),
              vertical: context.h(2),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(20)),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Text(
              n == null ? '—' : '$n Day${n == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3BB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDates(
    BuildContext context, {
    required bool startFirst,
  }) async {
    // A student policy derives its end date from the tenure, so only the
    // start date is pickable there.
    final result = await InsDateScreen.pick(
      context,
      start: query.startDate,
      end: query.resolvedEndDate,
      editEndDate: !query.isStudent,
      focusEnd: !startFirst,
    );
    if (result == null) return;
    onChanged(
      query.copyWith(
        startDate: result.start,
        endDate: result.end,
        clearEndDate: result.end == null,
      ),
    );
  }

  // --------------------------------------------------------- travellers

  Widget _travellersCard(BuildContext context) {
    final lead = query.travellers.first.dob;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      decoration: insCard(context, border: light, shadow: !light),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _FieldLabel('TRAVELLERS WITH DATE OF BIRTH'),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Icon(Icons.person_rounded,
                  size: context.w(22), color: InsTokens.blue),
              SizedBox(width: context.w(8)),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openTravellerSheet(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(12),
                      vertical: context.h(9),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.r(10)),
                      border: Border.all(color: InsTokens.line),
                    ),
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${query.travellerCount} ',
                              style: TextStyle(
                                fontSize: context.fs(12),
                                fontWeight: FontWeight.w600,
                                color: InsTokens.navy,
                              ),
                            ),
                            TextSpan(
                              text: lead == null
                                  ? '(add date of birth)'
                                  : '(${_slashDate(lead)})',
                              style: TextStyle(
                                fontSize: context.fs(10),
                                fontWeight: FontWeight.w600,
                                color: lead == null
                                    ? InsTokens.labelGrey
                                    : InsTokens.labelGrey,
                              ),
                            ),
                          ],
                        ),
                      )
                  ),
                ),
              ),
              SizedBox(width: context.w(10)),
              InsStepper(
                value: query.travellerCount,
                max: query.policyType.maxTravellers,
                onChanged: (n) => _setTravellerCount(context, n),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _slashDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}';

  void _setTravellerCount(BuildContext context, int next) {
    final current = query.travellers;
    if (next == current.length) return;

    if (next > current.length) {
      onChanged(query.copyWith(travellers: [
        ...current,
        for (int i = current.length; i < next; i++)
          InsTraveller(relation: query.policyType.isFriends ? 'MEMBER' : 'SPOUSE'),
      ]));
    } else {
      onChanged(query.copyWith(travellers: current.sublist(0, next)));
    }
  }

  Future<void> _openTravellerSheet(BuildContext context) async {
    final result = await InsTravellerSheet.showGeneral(context, query: query);
    if (result == null) return;
    onChanged(
      query.copyWith(
        travellers: result.travellers,
        // Only a student policy's sheet carries a tenure stepper.
        tenureMonths: result.tenureMonths,
      ),
    );
  }

  // ------------------------------------------------------------- button

  Widget _exploreButton(BuildContext context) {
    return Center(
      child: SizedBox(
        height: context.h(42),
        child: ElevatedButton(
          onPressed: onExplore,
          style: ElevatedButton.styleFrom(
            backgroundColor: InsTokens.orange,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: InsTokens.orange.withOpacity(0.45),
            padding: EdgeInsets.symmetric(horizontal: context.w(28)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(30)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Explore Plans',
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: context.w(12)),
              Icon(Icons.arrow_forward_rounded, size: context.w(16)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- pieces

/// Small uppercase label above a field value.
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool chevron;

  const _FieldLabel(this.text, {this.chevron = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: context.fs(8.5),
            fontWeight: FontWeight.w700,
            color: AppColors.subhead,
            letterSpacing: 0.5,
          ),
        ),
        if (chevron) ...[
          SizedBox(width: context.w(3)),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: context.w(14), color: InsTokens.labelGrey),
        ],
      ],
    );
  }
}

/// A white card with a label, a leading icon and a tappable value.
class _FieldCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final Widget? valueWidget;
  final bool chevron;
  final bool placeholder;
  final bool light;
  final VoidCallback onTap;

  const _FieldCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.value,
    this.valueWidget,
    this.chevron = false,
    this.placeholder = false,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(11),
        ),
        decoration: insCard(context, border: light, shadow: !light),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FieldLabel(label, chevron: chevron),
            SizedBox(height: context.h(7)),
            Row(
              children: [
                Icon(icon, size: context.w(21), color: InsTokens.blue),
                SizedBox(width: context.w(7)),
                Expanded(
                  child: valueWidget ??
                      Text(
                        value ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(13),
                          fontWeight: FontWeight.w700,
                          color: placeholder
                              ? InsTokens.labelGrey
                              : InsTokens.navy,
                        ),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// STUDENT-only tenure picker, in the slot the end date occupies otherwise.
class _TenureField extends StatelessWidget {
  final int months;
  final bool light;
  final ValueChanged<int> onChanged;

  const _TenureField({
    required this.months,
    required this.onChanged,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(11),
      ),
      decoration: insCard(context, border: light, shadow: !light),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _FieldLabel('TENURE (MONTHS)', chevron: true),
          SizedBox(height: context.h(4)),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: context.w(21), color: InsTokens.blue),
              SizedBox(width: context.w(7)),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: months,
                    isDense: true,
                    isExpanded: true,
                    icon: const SizedBox.shrink(),
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: InsTokens.navy,
                    ),
                    items: [
                      for (int m = 1; m <= 24; m++)
                        DropdownMenuItem(value: m, child: Text('$m')),
                    ],
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The frosted pill row of policy types across the top of the hero.
class _TypeTabs extends StatelessWidget {
  final List<InsPolicyType> types;
  final InsPolicyType selected;
  final ValueChanged<InsPolicyType> onSelected;

  /// Grey track with dark labels (edit screen) instead of a frosted track
  /// with white labels (hero).
  final bool light;

  const _TypeTabs({
    required this.types,
    required this.selected,
    required this.onSelected,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return SizedBox(height: context.h(46));

    final row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(children: [for (final t in types) _tab(context, t)]),
    );

    // Only the track is clipped. The "New" badge sits above the top edge of
    // its pill, so clipping the row along with the track would shave the top
    // off it.
    final track = DecoratedBox(
      decoration: BoxDecoration(
        color: light
            ? const Color(0xFFF3F5F9)
            : Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(context.r(26)),
      ),
      child: const SizedBox.expand(),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(6),
        // Room for the badge to overhang without being cut off by the
        // Column above.
        context.h(8),
        context.w(6),
        context.h(8),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.r(26)),
              // The frosted look only makes sense over the photo.
              child: light
                  ? track
                  : BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: track,
                    ),
            ),
          ),
          Padding(padding: EdgeInsets.all(context.w(5)), child: row),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, InsPolicyType type) {
    final isSelected = type == selected;

    final pill = GestureDetector(
      onTap: () => onSelected(type),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(8),
          vertical: context.h(6),
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(context.r(22)),
        ),
        child: Text(
          type.label,
          style: TextStyle(
            fontSize: context.fs(11),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? InsTokens.blue
                : (light ? InsTokens.subGrey : Colors.white),
          ),
        ),
      ),
    );

    // Every tab reserves the badge's overhang at the top so the pills stay
    // on one baseline whether or not they carry a badge — and so the badge
    // never has to overflow the horizontally scrolling row, which clips.
    final overhang = context.h(1);

    if (!type.isNew) {
      return
        Padding
          (
            padding: EdgeInsets.all(3),
          child: pill);
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(padding: EdgeInsets.only(top: overhang), child: pill),
        Positioned(
          top: -context.h(8),
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(6),
                vertical: context.h(2),
              ),
              decoration: BoxDecoration(
                color: InsTokens.orange,
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Text(
                'New',
                style: TextStyle(
                  fontSize: context.fs(8),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero photo behind the form, with the white fade that melts it into the
/// page below.
class _Backdrop extends StatelessWidget {
  final String? heroImage;

  const _Backdrop({required this.heroImage});

  @override
  Widget build(BuildContext context) {
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A90E2), Color(0xFF87CEEB)],
        ),
      ),
    );

    final hero = heroImage;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hero != null && hero.isNotEmpty)
          Image.network(
            hero,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : fallback,
          )
        else
          fallback,

        // Darken the very top so the white tab text stays readable.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.20),
                Colors.black.withOpacity(0.0),
              ],
              stops: const [0.0, 0.28],
            ),
          ),
        ),

        // Melt the photo into the white page beneath the CTA.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(120),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.35),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
