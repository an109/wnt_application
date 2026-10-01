import 'package:flutter/material.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../countries/domain/entities/country_entity.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';

/// "Select destination" — Figma `Select Destinations search travelling to`
/// and `Select Destinations search from`.
///
/// One screen serves both: [pickMany] is the multi-select "travelling to"
/// picker with its ADD DESTINATION button, [pickSingle] is the "from
/// country" variant that closes as soon as a row is tapped.
///
/// The list is the live country list the app already caches through
/// `CountryBloc`; nothing on this screen is a built-in list of countries.
class InsDestinationScreen extends StatefulWidget {
  final List<CountryEntity> countries;
  final List<CountryEntity> initial;
  final bool multi;
  final String title;
  final String subtitle;

  const InsDestinationScreen({
    super.key,
    required this.countries,
    required this.initial,
    required this.multi,
    required this.title,
    required this.subtitle,
  });

  /// Multi-select. Returns null when the traveller backs out.
  static Future<List<CountryEntity>?> pickMany(
      BuildContext context, {
        required List<CountryEntity> countries,
        required List<CountryEntity> initial,
      }) {
    return Navigator.of(context).push<List<CountryEntity>>(
      MaterialPageRoute(
        builder: (_) => InsDestinationScreen(
          countries: countries,
          initial: initial,
          multi: true,
          title: 'Select destination',
          subtitle: 'You can select multiple travel destination',
        ),
      ),
    );
  }

  /// Single-select, for "from country".
  static Future<CountryEntity?> pickSingle(
      BuildContext context, {
        required List<CountryEntity> countries,
        required CountryEntity? initial,
        required String title,
        required String subtitle,
      }) async {
    final result = await Navigator.of(context).push<List<CountryEntity>>(
      MaterialPageRoute(
        builder: (_) => InsDestinationScreen(
          countries: countries,
          initial: initial == null ? const [] : [initial],
          multi: false,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
    return (result == null || result.isEmpty) ? null : result.first;
  }

  @override
  State<InsDestinationScreen> createState() => _InsDestinationScreenState();
}

class _InsDestinationScreenState extends State<InsDestinationScreen> {
  final _search = TextEditingController();

  /// Keyed by country code so a country selected from the "Selected" block
  /// and the same country in the full list stay in step.
  late final Map<String, CountryEntity> _picked = {
    for (final c in widget.initial) c.code: c,
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim().toLowerCase();

  List<CountryEntity> get _matches {
    final q = _query;
    if (q.isEmpty) return widget.countries;
    return widget.countries
        .where((c) =>
    c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q))
        .toList();
  }

  void _toggle(CountryEntity c, bool on) {
    setState(() {
      if (!widget.multi) {
        _picked
          ..clear()
          ..[c.code] = c;
      } else if (on) {
        _picked[c.code] = c;
      } else {
        _picked.remove(c.code);
      }
    });

    // The single-select variant has no confirm button — tapping is the
    // choice, same as the mock's "from" picker.
    if (!widget.multi) {
      Navigator.of(context).pop(_picked.values.toList());
    }
  }

  void _done() {
    if (widget.multi && _picked.isEmpty) {
      insSnack(context, 'Pick at least one destination', isError: true);
      return;
    }
    Navigator.of(context).pop(_picked.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    final selected = _picked.values.toList();
    final matches = _matches;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: widget.countries.isEmpty
                  ? const InsLoading(message: 'Loading countries…')
                  : matches.isEmpty
                  ? InsEmpty(
                title: 'No country matches "${_search.text.trim()}"',
                message: 'Try a different spelling.',
              )
                  : ListView(
                padding: EdgeInsets.fromLTRB(
                  context.w(18),
                  context.h(18),
                  context.w(18),
                  context.h(24),
                ),
                children: [
                  // "Selected" only appears once something is
                  // chosen, and is hidden while searching so the
                  // results read as one list.
                  if (selected.isNotEmpty && _query.isEmpty) ...[
                    _sectionTitle(context, 'Selected'),
                    for (final c in selected) _row(context, c),
                    SizedBox(height: context.h(20)),
                  ],
                  _sectionTitle(
                    context,
                    _query.isEmpty ? 'All destinations' : 'Results',
                  ),
                  for (final c in matches) _row(context, c),
                ],
              ),
            ),
            if (widget.multi) _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      // Full-bleed: fills the whole width, touching both edges.
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        // Shadow only on the bottom edge so it lifts off the list.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: context.r(12),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(6),
        context.w(18),
        context.h(14),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(context.w(4)),
                  child: Icon(Icons.close_rounded,
                      size: context.w(18), color: InsTokens.navy),
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                        color: InsTokens.navy,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w400,
                        color: InsTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: context.fs(12), color: InsTokens.navy),
            decoration: InputDecoration(
              hintText: 'Search Region/Country',
              hintStyle: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w500,
                color: InsTokens.labelGrey,
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.w(16),
                vertical: context.h(14),
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                icon: Icon(Icons.clear_rounded, size: context.w(18)),
                onPressed: () => setState(_search.clear),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
                borderSide: const BorderSide(color: InsTokens.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
                borderSide: const BorderSide(color: InsTokens.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
                borderSide: const BorderSide(color: InsTokens.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(12),
          fontWeight: FontWeight.w700,
          color: InsTokens.navy,
        ),
      ),
    );
  }

  Widget _row(BuildContext context, CountryEntity c) {
    final on = _picked.containsKey(c.code);
    return GestureDetector(
      onTap: () => _toggle(c, !on),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(10)),
        child: Row(
          children: [
            InsCheckbox(value: on, onChanged: (v) => _toggle(c, v)),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Text(
                c.name,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w400,
                  color: InsTokens.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      // Full-bleed: fills the whole width, touching both edges.
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        // Shadow only on the top edge so it lifts off the list.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: context.r(12),
            offset: Offset(0, -context.h(4)),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(12),
        context.w(18),
        context.h(12),
      ),
      child: SafeArea(
        top: false,
        child: InsPrimaryButton(label: 'ADD DESTINATION', onPressed: _done),
      ),
    );
  }
}
