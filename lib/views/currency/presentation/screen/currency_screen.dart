import 'package:flutter/material.dart';

import '../../../../UI_helper/currency_converter.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

/// "Currency" — Figma `CHOOSE Currency 1` / `2`.
///
/// Replaces the dialog the drawer used to open. The list is the same
/// [CurrencyConverter.supportedCurrencies], and saving still goes through
/// [CurrencyConverter.setManualCurrency] / [CurrencyConverter.enableAutoDetect],
/// so nothing about how the app stores or broadcasts the currency changed.
///
/// One difference from the dialog: the choice is staged. The dialog applied a
/// currency the moment it was tapped, whereas the design has a
/// **SAVE & PROCEED** button, so the tap only moves the tick and the save
/// applies it. Backing out leaves the currency as it was.
///
/// Pops the saved currency code, or null if the traveller backed out.
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

/// One row's worth of copy. Held here rather than added to
/// [CurrencyConverter] so that formatting prices everywhere else is untouched
/// — `getSymbol` has no entry for several of these and is used for real
/// amounts, where a wrong symbol would matter.
class _CurrencyRow {
  final String code;
  final String country;
  final String name;
  final String symbol;

  const _CurrencyRow({
    required this.code,
    required this.country,
    required this.name,
    required this.symbol,
  });

  /// `US Dollar • USD ($)`
  String get detail => '$name • $code ($symbol)';

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return country.toLowerCase().contains(q) ||
        name.toLowerCase().contains(q) ||
        code.toLowerCase().contains(q);
  }
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  /// Sentinel for the "detect by location" row. Not a currency code, so it
  /// can never collide with one.
  static const _auto = 'AUTO';

  static const _countries = <String, String>{
    'USD': 'USA',
    'INR': 'India',
    'EUR': 'Europe',
    'GBP': 'UK',
    'AED': 'UAE',
    'AUD': 'Australia',
    'CAD': 'Canada',
    'SGD': 'Singapore',
    'JPY': 'Japan',
    'CNY': 'China',
  };

  static const _symbols = <String, String>{
    'USD': '\$',
    'INR': '₹',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'SGD': 'S\$',
    'JPY': '¥',
    'CNY': '¥',
  };

  late String _selected;
  bool _searching = false;
  String _query = '';
  bool _saving = false;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  late final List<_CurrencyRow> _rows = [
    for (final entry in CurrencyConverter.supportedCurrencies.entries)
      _CurrencyRow(
        code: entry.key,
        country: _countries[entry.key] ?? entry.key,
        name: entry.value,
        symbol: _symbols[entry.key] ?? entry.key,
      ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = CurrencyConverter.isAutoDetectEnabled()
        ? _auto
        : CurrencyConverter.getPreferredCurrency();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<_CurrencyRow> get _visible =>
      _rows.where((r) => r.matches(_query)).toList();

  /// "Auto" only makes sense in the unfiltered list, and while searching for
  /// a currency by name.
  bool get _showAuto {
    final q = _query.trim().toLowerCase();
    return q.isEmpty || 'auto detect location'.contains(q);
  }

  void _closeSearch() {
    setState(() {
      _searching = false;
      _query = '';
      _searchCtrl.clear();
    });
    _searchFocus.unfocus();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    String applied;
    try {
      if (_selected == _auto) {
        applied = await CurrencyConverter.enableAutoDetect();
      } else {
        await CurrencyConverter.setManualCurrency(_selected);
        applied = _selected;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not change the currency. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(applied);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: (visible.isEmpty && !_showAuto)
                  ? _empty(context)
                  : ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        context.w(16),
                        context.h(10),
                        context.w(16),
                        context.h(16),
                      ),
                      children: [
                        // if (_showAuto) _autoTile(context),
                        for (final row in visible) _tile(context, row),
                      ],
                    ),
            ),
            _saveBar(context),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------- header

  Widget _header(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        context.w(12),
        context.h(8),
        context.w(12),
        context.h(28),
      ),
      child: Row(
        children: [
          _iconButton(
            context,
            icon: Icons.arrow_back_rounded,
            onTap: _saving
                ? null
                : () {
              if (_searching) {
                _closeSearch();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          SizedBox(width: context.w(6)),
          if (_searching) ...[
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(
                  fontSize: context.fs(16),
                  color: AppColors.navy,
                ),
                decoration: InputDecoration(
                  hintText: 'Search Currency',
                  hintStyle: TextStyle(
                    fontSize: context.fs(13),
                    color: const Color(0xFF9AA4B2),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: context.h(8),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD9DEE5)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD9DEE5)),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.w(6)),
            _iconButton(
              context,
              icon: Icons.close_rounded,
              onTap: _closeSearch,
            ),
          ] else ...[
            Expanded(
              child: Text(
                'Currency',
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy,
                ),
              ),
            ),
            _iconButton(
              context,
              icon: Icons.search_rounded,
              onTap: () => setState(() => _searching = true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(context.w(8)),
        child: Icon(icon, size: context.w(18), color: AppColors.navy),
      ),
    );
  }

  // --------------------------------------------------------------- tiles

  Widget _autoTile(BuildContext context) {
    final selected = _selected == _auto;
    return _card(
      context,
      selected: selected,
      onTap: () => setState(() => _selected = _auto),
      leading: Container(
        width: context.w(46),
        height: context.h(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6FD),
          borderRadius: BorderRadius.circular(context.r(6)),
        ),
        child: Icon(
          Icons.my_location_rounded,
          size: context.w(18),
          color: AppColors.AppBlue,
        ),
      ),
      title: 'Auto',
      detail: 'Detect by location',
    );
  }

  Widget _tile(BuildContext context, _CurrencyRow row) {
    return _card(
      context,
      selected: _selected == row.code,
      onTap: () => setState(() => _selected = row.code),
      leading: _flag(context, row.code),
      title: row.country,
      detail: row.detail,
    );
  }

  /// The flag chip. The app ships no flag images, so the emoji the rest of
  /// the app already uses is boxed to read as the design's flag tile.
  Widget _flag(BuildContext context, String code) {
    return Container(
      width: context.w(46),
      height: context.h(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(6)),
        // border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Text(
        CurrencyConverter.getFlag(code),
        style: TextStyle(fontSize: context.fs(25)),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required bool selected,
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    required String detail,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: selected ? AppColors.AppBlue : AppColors.lightsubhead,
          width: selected ? 1 : 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _saving ? null : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(12),
          ),
          child: Row(
            children: [
              leading,
              SizedBox(width: context.w(14)),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                flex: 2,
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                    color: AppColors.subhead,
                  ),
                ),
              ),
              if (selected) ...[
                SizedBox(width: context.w(24)),
                Image.asset(
                  'assets/NewIcons/tick.png',
                  width: context.w(24),
                  height: context.w(24),
                  color: AppColors.AppBlue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: context.w(40),
              color: const Color(0xFFC6CDD6),
            ),
            SizedBox(height: context.h(12)),
            Text(
              'No currency matches "$_query".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(14),
                color: const Color(0xFF7A8798),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- save bar

  Widget _saveBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(12),
        context.w(16),
        context.h(0),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.OrangeColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.OrangeColor.withOpacity(0.6),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: context.h(14)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(12)),
            ),
          ),
          child: _saving
              ? SizedBox(
                  width: context.w(20),
                  height: context.w(20),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'SAVE & PROCEED',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
        ),
      ),
    );
  }
}
