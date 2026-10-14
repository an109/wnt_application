import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import '../widgets/visa_checkout_sheets.dart' show visaValidityDays;
import '../widgets/visa_flag.dart';
import '../widgets/visa_sheets.dart';
import '../widgets/visa_tracker_sheet.dart';
import 'visa_apply_flow_screen.dart';

/// Details page of visas that are not visa-free / on arrival
/// (Figma "View more costvisa…", Indonesia sample).
class VisaCostInfoScreen extends StatefulWidget {
  final VisaPopularDestinationEntity destination;
  final VisaTypeEntity? initialType;

  const VisaCostInfoScreen({super.key, required this.destination, this.initialType});

  @override
  State<VisaCostInfoScreen> createState() => _VisaCostInfoScreenState();
}

enum _Tab { price, document, timeline, faqs }

class _VisaCostInfoScreenState extends State<VisaCostInfoScreen> {
  static const _employment = [
    ('Employed', Icons.work_outline, Color(0xFF2563EB)),
    ('Self Employed', Icons.storefront_outlined, Color(0xFFF07A2D)),
    ('Not Working', Icons.home_outlined, Color(0xFF0EA5E9)),
    ('Student', Icons.school_outlined, Color(0xFFDC2626)),
  ];

  final _scroll = ScrollController();
  final _keys = {for (final t in _Tab.values) t: GlobalKey()};
  _Tab _tab = _Tab.price;
  bool _tabScrolling = false;

  late VisaTypeEntity? _type = widget.initialType ?? _d.primaryType;
  late final DateTime _visaOn;
  late DateTime _enter;
  int _travellers = 1;
  String _employmentStatus = 'Employed';
  bool _docsOpen = true;
  final Set<String> _ticked = {};
  String _faqQuery = '';

  VisaPopularDestinationEntity get _d => widget.destination;
  String get _country => _d.shortName;
  VisaProcessing? get _processing => _type?.parsedProcessing ?? _d.fastestProcessing;

  @override
  void initState() {
    super.initState();
    _visaOn = _processing?.guaranteedFrom(DateTime.now()) ?? DateTime.now().add(const Duration(days: 7));
    _enter = DateUtils.dateOnly(_visaOn);
    _scroll.addListener(_syncTab);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Highlights the tab of the section at the top of the viewport.
  void _syncTab() {
    if (_tabScrolling) return;
    _Tab current = _Tab.price;
    for (final t in _Tab.values) {
      final ctx = _keys[t]!.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox;
      if (box.localToGlobal(Offset.zero).dy < 200) current = t;
    }
    if (current != _tab) setState(() => _tab = current);
  }

  Future<void> _jump(_Tab t) async {
    final ctx = _keys[t]!.currentContext;
    if (ctx == null) return;
    setState(() {
      _tab = t;
      _tabScrolling = true;
    });
    await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    _tabScrolling = false;
  }

  String get _purpose {
    final t = (_type?.title ?? '').toLowerCase();
    if (t.contains('business')) return 'Business';
    if (t.contains('transit')) return 'Transit';
    if (t.contains('student') || t.contains('study')) return 'Study';
    return 'Tourism';
  }

  int get _validityDays => visaValidityDays(_type?.validity ?? '', fallback: 90);

  int get _stayDays => visaValidityDays(_type?.stay ?? '', fallback: _validityDays).clamp(1, _validityDays);

  String _money(double amount, String currency) {
    final preferred = CurrencyConverter.getPreferredCurrency();
    if (currency.toUpperCase() == preferred.toUpperCase()) return visaMoney(amount);
    final converted = CurrencyConverter.convert(amount: amount, fromCurrency: currency, toCurrency: preferred);
    // No cached rate: show the fee in its own currency, never a wrong symbol.
    if (converted == amount) return CurrencyConverter.format(amount, currency);
    return visaMoney(converted);
  }

  Future<void> _pickType() async {
    if (_d.visaTypes.length < 2) return;
    final t = await showVisaSheet<VisaTypeEntity>(
      context,
      VisaOptionList<VisaTypeEntity>(options: _d.visaTypes, labelOf: (t) => t.title, selected: _type),
    );
    if (t != null) setState(() => _type = t);
  }

  Future<void> _pickEnter() async {
    final d = await showVisaSheet<DateTime>(
      context,
      VisaDatePickerSheet(
        initial: _enter,
        firstDate: DateUtils.dateOnly(_visaOn),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      ),
      showHandle: false,
    );
    if (d != null) setState(() => _enter = d);
  }

  void _openTracker(VisaPortalStatus portal) {
    showVisaSheet<void>(context, VisaTrackerSheet(country: _country, portal: portal));
  }

  void _start() {
    final type = _type;
    if (type == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisaApplyFlowScreen(
          destination: _d,
          visaType: type,
          travellerCount: _travellers,
          travelDate: _enter,
          employment: _employmentStatus,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final portal = VisaPortalStatus.from(_d.appInsights, _country);
    final faqs = _d.faqs
        .where((f) =>
            _faqQuery.isEmpty ||
            f['q']!.toLowerCase().contains(_faqQuery) ||
            f['a']!.toLowerCase().contains(_faqQuery))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            _tabs(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KeyedSubtree(
                      key: _keys[_Tab.price],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _title('General info'),
                          _generalInfo(),
                          const SizedBox(height: 20),
                          _title('Price Details'),
                          _priceDetails(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    KeyedSubtree(
                      key: _keys[_Tab.document],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_title('Required Document'), _documents()],
                      ),
                    ),
                    const SizedBox(height: 20),
                    KeyedSubtree(
                      key: _keys[_Tab.timeline],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _title("Your visa's timeline"),
                          _timeline(portal),
                          ..._intelligence(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    KeyedSubtree(
                      key: _keys[_Tab.faqs],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _title('Frequently asked questions'),
                          _faqSearch(),
                          const SizedBox(height: 10),
                          if (_d.faqs.isEmpty)
                            Text('Questions? Our visa experts answer on chat and WhatsApp.',
                                style: visaText(10, color: VisaColors.text))
                          else if (faqs.isEmpty)
                            Text('No matching questions', style: visaText(10, color: VisaColors.text))
                          else
                            for (final f in faqs) _faq(f['q']!, f['a']!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: VisaColors.title),
            onPressed: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                VisaFlag(countryCode: _d.countryCode, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$_country visa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.goblinOne(fontSize: 14, color: VisaColors.title, letterSpacing: 0.5)),
                ),
                GestureDetector(
                  onTap: _pickType,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9BD8F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_purpose, style: visaText(9, weight: FontWeight.w600, color: Colors.white)),
                        if (_d.visaTypes.length > 1)
                          const Icon(Icons.keyboard_arrow_down, size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tabs() {
    const labels = {_Tab.price: 'Price', _Tab.document: 'Document', _Tab.timeline: 'Timeline', _Tab.faqs: 'FAQs'};
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 3)),
      ),
      child: Row(
        children: [
          for (final t in _Tab.values)
            Expanded(
              child: InkWell(
                onTap: () => _jump(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: t == _tab ? VisaColors.primary : Colors.transparent, width: 2),
                    ),
                  ),
                  child: Text(
                    labels[t]!,
                    textAlign: TextAlign.center,
                    style: visaText(10,
                        weight: t == _tab ? FontWeight.w600 : FontWeight.w500,
                        color: t == _tab ? VisaColors.primary : VisaColors.text),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: visaText(13, weight: FontWeight.w600, color: VisaColors.title)),
      );

  Widget _grey({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: VisaColors.surface, borderRadius: BorderRadius.circular(8)),
        child: child,
      );

  Widget _whiteBox({required Widget child, EdgeInsets padding = const EdgeInsets.all(10)}) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: child,
      );

  Widget _generalInfo() {
    final type = _type;
    final kind = type == null ? VisaKind.eVisa : _d.kindOf(type);
    final validTill = _enter.add(Duration(days: _validityDays - 1));
    final returnOn = _enter.add(Duration(days: _stayDays - 1));
    final window = DateFormat("d MMM, ''yy");
    final fraction = (_stayDays / _validityDays).clamp(0.35, 1.0);

    return _grey(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _infoBox('VISA PROCESS', kind == VisaKind.sticker ? 'Embassy' : 'Digital')),
              const SizedBox(width: 8),
              Expanded(
                child: _infoBox(
                  'NUMBER OF ENTRIES',
                  (type?.entry.trim().isNotEmpty ?? false) ? type!.entry.trim() : 'Single',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('VISA VALID WINDOW', style: visaText(7.5, weight: FontWeight.w500, color: VisaColors.text)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(window.format(_enter).toUpperCase(), style: visaText(8.5, color: VisaColors.text)),
              const Expanded(child: _DashedLine(label: 'TO')),
              Text(window.format(validTill).toUpperCase(), style: visaText(8.5, color: VisaColors.text)),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickEnter,
            child: Container(
              height: 30,
              decoration: BoxDecoration(color: const Color(0xFFCDEBF8), borderRadius: BorderRadius.circular(6)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction,
                  heightFactor: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: const Color(0xFF4FA3D9), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                        ),
                        Expanded(
                          child: Text('$_stayDays Days Stay',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: visaText(8.5, weight: FontWeight.w500, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _pickEnter,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Enter ', style: visaText(9, color: VisaColors.text)),
                  TextSpan(
                      text: DateFormat('d MMM').format(_enter),
                      style: visaText(9, weight: FontWeight.w600, color: VisaColors.primary)),
                ])),
              ),
              const Spacer(),
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Return ', style: visaText(9, color: VisaColors.text)),
                TextSpan(
                    text: DateFormat('d MMM').format(returnOn),
                    style: visaText(9, weight: FontWeight.w600, color: VisaColors.primary)),
              ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value) => _whiteBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: visaText(7.5, weight: FontWeight.w500, color: VisaColors.text)),
            const SizedBox(height: 3),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: visaText(11, weight: FontWeight.w500, color: VisaColors.title)),
          ],
        ),
      );

  Widget _priceDetails() {
    final type = _type;
    final fee = type == null ? 0.0 : type.feesInr.toDouble() * _travellers;
    final feeText = type == null ? '—' : (type.isFree ? 'Free' : _money(fee, type.feesCurrency));
    return _grey(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Row(
              children: [
                const Icon(Icons.person, size: 16, color: VisaColors.title),
                const SizedBox(width: 8),
                Text('Travellers', style: visaText(11, weight: FontWeight.w500, color: VisaColors.title)),
                const Spacer(),
                _stepButton(Icons.remove, _travellers > 1 ? () => setState(() => _travellers--) : null),
                SizedBox(
                  width: 24,
                  child: Text('$_travellers',
                      textAlign: TextAlign.center, style: visaText(10, weight: FontWeight.w600)),
                ),
                _stepButton(Icons.add, _travellers < 9 ? () => setState(() => _travellers++) : null),
              ],
            ),
          ),
          _whiteBox(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance, size: 12, color: VisaColors.primary),
                    const SizedBox(width: 6),
                    Text('Government Fees', style: visaText(9.5, color: VisaColors.title)),
                    const Spacer(),
                    Text(feeText, style: visaText(10, weight: FontWeight.w600, color: VisaColors.title)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: _DashedLine()),
                Row(
                  children: [
                    Text('Total Amount', style: visaText(11, weight: FontWeight.w600, color: VisaColors.title)),
                    const Spacer(),
                    Text(feeText, style: visaText(12, weight: FontWeight.w700, color: VisaColors.green)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(icon, size: 11, color: onTap == null ? VisaColors.stroke : VisaColors.title),
        ),
      );

  Widget _documents() {
    final user = di.sl<PreferencesManager>().getUserData() ?? {};
    final name = (user['name'] ?? '').toString().trim();
    final items = _d.requiredDocuments.isNotEmpty ? _d.requiredDocuments : _d.requirementsItems;
    final docs = items.isEmpty ? const ['Passport'] : items;

    return _grey(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
            child: Text(name.isEmpty ? 'Traveller 1' : name,
                style: visaText(11, weight: FontWeight.w600, color: VisaColors.title)),
          ),
          SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _employment.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final (label, icon, color) = _employment[i];
                final selected = label == _employmentStatus;
                return GestureDetector(
                  onTap: () => setState(() => _employmentStatus = label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: selected ? VisaColors.primarySoft : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: selected ? VisaColors.primary : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 11, color: color),
                        const SizedBox(width: 4),
                        Text(label, style: visaText(8.5, weight: FontWeight.w500, color: VisaColors.title)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _whiteBox(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _docsOpen = !_docsOpen),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Text('Required to apply',
                            style: visaText(10, weight: FontWeight.w500, color: VisaColors.title)),
                        const Spacer(),
                        Icon(_docsOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 18, color: VisaColors.text),
                      ],
                    ),
                  ),
                ),
                if (_docsOpen)
                  for (final doc in docs) _docRow(doc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _docRow(String doc) {
    final ticked = _ticked.contains(doc);
    final isPassport = doc.toLowerCase().trim() == 'passport';
    return InkWell(
      onTap: () => setState(() => ticked ? _ticked.remove(doc) : _ticked.add(doc)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: ticked ? VisaColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: ticked ? VisaColors.primary : VisaColors.stroke),
              ),
              child: ticked ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc, style: visaText(9.5, weight: FontWeight.w500, color: VisaColors.title)),
                  if (isPassport)
                    Text('The page with your photo & personal details',
                        style: visaText(8, color: VisaColors.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline(VisaPortalStatus? portal) {
    final visaOn = DateFormat('d MMM, h:mm a').format(_visaOn);
    return Column(
      children: [
        _step(1, 'Apply now', 'Only pay the government fee when you submit.'),
        _step(2, 'Your document are verified', 'Wander Nova performs extensive checks before submitting.'),
        _step(
          3,
          'Your visa gets processed',
          'We track government portals in real time',
          extra: Column(
            children: [
              if (portal != null && portal.uptimePercent != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _openTracker(portal),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VisaColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  VisaFlag(countryCode: _d.countryCode, size: 12),
                                  const SizedBox(width: 6),
                                  Text(portal.name,
                                      style: visaText(10, weight: FontWeight.w600, color: VisaColors.title)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${visaPercent(portal.uptimePercent!)} uptime in last '
                                '${portal.daily.isEmpty ? 90 : portal.daily.length} days',
                                style: visaText(9,
                                    weight: FontWeight.w500,
                                    color: VisaColors.primary,
                                    decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: VisaColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _TimelineCalendar(from: DateTime.now(), to: _visaOn),
            ],
          ),
        ),
        _step(4, 'Visa on $visaOn', 'Delivered straight to your inbox and WhatsApp', last: true),
      ],
    );
  }

  Widget _step(int n, String title, String subtitle, {Widget? extra, bool last = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: VisaColors.primary, borderRadius: BorderRadius.circular(3)),
                  child: Text('$n', style: visaText(9, weight: FontWeight.w700, color: Colors.white)),
                ),
                if (!last)
                  // A painter, not a LayoutBuilder: this sits inside IntrinsicHeight.
                  const Expanded(child: CustomPaint(size: Size(1, double.infinity), painter: _VerticalDashPainter())),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: visaText(11, weight: FontWeight.w600, color: VisaColors.title)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: visaText(8.5, color: VisaColors.text)),
                  if (extra != null) extra,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Processing time intelligence": only from admin-entered stats.
  List<Widget> _intelligence() {
    final insights = _d.appInsights;
    final forecast = (insights['forecast'] as List?)
            ?.whereType<Map>()
            .map((f) => (
                  label: (f['label'] ?? '').toString(),
                  percent: (num.tryParse('${f['percent']}') ?? 0).toDouble().clamp(0, 100).toDouble(),
                ))
            .where((f) => f.label.isNotEmpty)
            .toList() ??
        const [];
    final bestDays = (insights['best_days'] as List?)
            ?.map((v) => (num.tryParse('$v') ?? 0).toDouble().clamp(0, 100).toDouble())
            .toList() ??
        const <double>[];
    if (forecast.isEmpty && bestDays.length != 7) return const [];
    final sample = insights['forecast_sample_size'];

    return [
      const SizedBox(height: 20),
      Text('Processing time intelligence', style: visaText(13, weight: FontWeight.w600, color: VisaColors.title)),
      if (sample != null)
        Text('Data across last ${NumberFormat.decimalPattern('en_IN').format(num.tryParse('$sample') ?? 0)} visas',
            style: visaText(8.5, color: VisaColors.text)),
      const SizedBox(height: 10),
      if (forecast.isNotEmpty)
        _whiteBox(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visa Arrival Forecast', style: visaText(10, weight: FontWeight.w600, color: VisaColors.title)),
              const SizedBox(height: 10),
              for (var i = 0; i < forecast.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: i == 0 ? VisaColors.primarySoft : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(forecast[i].label,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: visaText(8.5, weight: i == 0 ? FontWeight.w600 : FontWeight.w400)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: forecast[i].percent / 100,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE5F3FA),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF4FA3D9)),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text('${forecast[i].percent.round()}%',
                            textAlign: TextAlign.right, style: visaText(8.5, color: VisaColors.title)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      if (bestDays.length == 7) ...[
        const SizedBox(height: 10),
        _whiteBox(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Best time of the week to apply',
                  style: visaText(10, weight: FontWeight.w600, color: VisaColors.title)),
              Text('Days that yield the fastest turn-around time', style: visaText(7.5, color: VisaColors.text)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        children: [
                          Text(const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][i],
                              style: visaText(8.5, color: VisaColors.text)),
                          const SizedBox(height: 8),
                          _DayBar(value: bestDays[i] / 100),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _faqSearch() {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: VisaColors.primarySoft.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6ECF7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 15, color: VisaColors.text),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _faqQuery = v.trim().toLowerCase()),
              style: visaText(10, color: VisaColors.title),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: 'Ask us anything about $_country Visa...',
                hintStyle: visaText(9, color: VisaColors.text),
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: VisaColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_upward, size: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          expandedAlignment: Alignment.centerLeft,
          title: Text(q, style: visaText(10, weight: FontWeight.w500, color: VisaColors.title)),
          children: [Text(a, style: visaText(9.5, color: VisaColors.text, height: 1.5))],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Visa on ${DateFormat('d MMM, h:mm a').format(_visaOn)}',
                      style: visaText(11, weight: FontWeight.w700, color: VisaColors.title)),
                  Text('On time', style: visaText(9.5, weight: FontWeight.w600, color: VisaColors.primary)),
                ],
              ),
            ),
            SizedBox(
              width: 150,
              height: 38,
              child: ElevatedButton(
                onPressed: _type == null ? null : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VisaColors.cta,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text('START NOW', style: visaText(12, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Month of the processing window: days from applying to the visa date in
/// blue, the visa date as a filled circle ("Auto calculated").
class _TimelineCalendar extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  const _TimelineCalendar({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final start = DateUtils.dateOnly(from);
    final end = DateUtils.dateOnly(to);
    final month = DateTime(end.year, end.month);
    final lead = month.weekday % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final rows = ((lead + days) / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final h in const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
              Expanded(child: Center(child: Text(h, style: visaText(8.5, color: VisaColors.text)))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(DateFormat('MMMM, yyyy').format(month),
                style: visaText(11, weight: FontWeight.w700, color: VisaColors.title)),
            const Spacer(),
            Text('Auto calculated', style: visaText(8, color: VisaColors.text)),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _cell(r * 7 + c - lead + 1, days, month, start, end)),
            ],
          ),
      ],
    );
  }

  Widget _cell(int day, int days, DateTime month, DateTime start, DateTime end) {
    if (day < 1 || day > days) return const SizedBox(height: 28);
    final d = DateTime(month.year, month.month, day);
    final isEnd = d == end;
    final inWindow = !d.isBefore(start) && d.isBefore(end);
    return SizedBox(
      height: 28,
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: isEnd ? const BoxDecoration(color: VisaColors.primary, shape: BoxShape.circle) : null,
          child: Text(
            '$day',
            style: visaText(10,
                weight: isEnd || inWindow ? FontWeight.w600 : FontWeight.w400,
                color: isEnd ? Colors.white : (inWindow ? VisaColors.primary : VisaColors.title)),
          ),
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final double value;
  const _DayBar({required this.value});

  @override
  Widget build(BuildContext context) {
    const height = 90.0;
    final dot = (height - 10) * (1 - value.clamp(0.0, 1.0));
    return SizedBox(
      width: 12,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 8,
            decoration: BoxDecoration(color: const Color(0xFFE5F3FA), borderRadius: BorderRadius.circular(4)),
          ),
          Positioned(
            top: dot + 5,
            bottom: 0,
            child: Container(
              width: 8,
              decoration: BoxDecoration(color: const Color(0xFFBFE2F5), borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Positioned(
            top: dot,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDashPainter extends CustomPainter {
  const _VerticalDashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VisaColors.stroke
      ..strokeWidth = 1;
    for (double y = 4; y < size.height - 2; y += 6) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedLine extends StatelessWidget {
  final String? label;
  const _DashedLine({this.label});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final count = (c.maxWidth / 6).floor().clamp(0, 400);
      final dashes = List.generate(count, (_) => Container(width: 3, height: 1, color: VisaColors.stroke));
      final line = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: dashes);
      if (label == null) return Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: line);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            line,
            Container(
              color: VisaColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(label!, style: visaText(7, color: VisaColors.text)),
            ),
          ],
        ),
      );
    });
  }
}
