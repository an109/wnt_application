import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/services/exchange_rate_service.dart';
import 'holiday_traveller_details_screen.dart';

const Color _kAccent = Color(0xffFF3B3B);
const Color _kInk = Color(0xff1A1A2E);

class HolidayPackageDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> package;
  final int adults;
  final int children;
  final int Infants;

  /// The departure date the user picked on the holiday search card, carried
  /// through so the eventual booking's check-in reflects what was searched.
  final DateTime? departureDate;

  const HolidayPackageDetailsScreen({
    super.key,
    required this.package,
    this.adults = 2,
    this.children = 0,
    this.Infants = 1,
    this.departureDate,
  });

  @override
  State<HolidayPackageDetailsScreen> createState() => _HolidayPackageDetailsScreenState();
}

class _HolidayPackageDetailsScreenState extends State<HolidayPackageDetailsScreen> {
  bool _showFullInclusions = false;
  bool _showFullExclusions = false;
  String _currency = 'INR';

  Map<String, dynamic> get _pkg => widget.package;

  int get _travellersCount => (widget.adults + widget.children).clamp(1, 999);

  double get _basePrice => double.tryParse('${_pkg['package_price'] ?? 0}') ?? 0;

  double? get _originalPrice {
    final raw = _pkg['original_price'];
    if (raw == null) return null;
    final parsed = double.tryParse('$raw');
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  double get _gstPercent => double.tryParse('${_pkg['gst_percent'] ?? 0}') ?? 0;

  @override
  void initState() {
    super.initState();
    _currency = CurrencyConverter.getPreferredCurrency();
    _resolvePreferredCurrency();
  }

  Future<void> _resolvePreferredCurrency() async {
    await ExchangeRateService.initializeUserCurrency();
    if (!mounted) return;
    final resolved = CurrencyConverter.getPreferredCurrency();
    if (resolved != _currency) {
      setState(() => _currency = resolved);
    }
  }

  double _convert(double amountInInr) {
    if (_currency.toUpperCase() == 'INR') return amountInInr;
    return CurrencyConverter.convert(amount: amountInInr, fromCurrency: 'INR', toCurrency: _currency);
  }

  String _format(double amountInInr) => CurrencyConverter.format(_convert(amountInInr), _currency);

  String get _locationLabel {
    final parts = [_pkg['city'], _pkg['state'], _pkg['country']]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.take(2).join(', ') : '';
  }

  List<String> _splitList(String? raw, {String pattern = ','}) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw.split(pattern == ',' ? ',' : RegExp(pattern)).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  IconData _activityIcon(String? key) {
    switch (key) {
      case 'sun':
        return Icons.wb_sunny_outlined;
      case 'moon':
        return Icons.nights_stay_outlined;
      case 'meals':
        return Icons.restaurant_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_pkg['title'] as String?) ?? 'Holiday Package';
    final imageUrl = (_pkg['image_url'] as String?) ?? '';
    final nights = _pkg['nights'] ?? 0;
    final days = _pkg['days'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroAppBar(title: title, imageUrl: imageUrl, nights: nights, days: days),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(context.w(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionWrapper(_buildOverviewSection()),
                  _sectionWrapper(_buildItinerarySection()),
                  _sectionWrapper(_buildStaySection()),
                  _sectionWrapper(_buildInclusionsSection()),
                  // SizedBox(height: context.h(2)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFareCardBar(),
    );
  }

  Widget _sectionWrapper(Widget child) => Padding(padding: EdgeInsets.only(bottom: context.h(14)), child: child);

  // ---------------------------------------------------------------------
  // Hero background image
  // ---------------------------------------------------------------------

  Widget _buildHeroAppBar({required String title, required String imageUrl, required dynamic nights, required dynamic days}) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: context.hp(34),
      backgroundColor: _kInk,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 1080,
                    placeholder: (context, url) => Container(color: Colors.grey.shade300),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade400,
                      child: Icon(Icons.image, size: context.iconLarge, color: Colors.white70),
                    ),
                  )
                : Container(color: Colors.grey.shade400),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.75)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              left: context.w(16),
              right: context.w(16),
              bottom: context.h(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pkg['is_wander_nova_choice'] == true)
                    Container(
                      margin: EdgeInsets.only(bottom: context.h(8)),
                      padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(4)),
                      decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(context.r(4))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: context.iconXSmall, color: Colors.white),
                          SizedBox(width: context.w(4)),
                          Text('WanderNova Choice',
                              style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(19), fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: context.h(6)),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: context.iconXSmall, color: Colors.white70),
                      SizedBox(width: context.w(4)),
                      Expanded(
                        child: Text(
                          _locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: context.fs(12), color: Colors.white70),
                        ),
                      ),
                      SizedBox(width: context.w(8)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(context.r(10)),
                        ),
                        child: Text('${nights}N / ${days}D',
                            style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------

  Widget _sectionCard({required String title, required Widget child, IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: context.iconMedium, color: _kAccent),
                SizedBox(width: context.w(8)),
              ],
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: context.fs(17),
                  fontWeight: FontWeight.w900,
                  color: _kInk,
                ),
              ),
              // Text(title, style: TextStyle(fontSize: context.fs(17), fontWeight: FontWeight.w900, color: _kInk)),
            ],
          ),
          SizedBox(height: context.h(12)),
          child,
        ],
      ),
    );
  }

  Widget _bulletRow(String text, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: context.iconXSmall, color: color),
          SizedBox(width: context.w(8)),
          Expanded(child: Text(text, style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade800))),
        ],
      ),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(5)),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: context.fs(11), color: _kAccent, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildOverviewSection() {
    final itineraryText = (_pkg['itinerary_text'] as String?) ?? '';
    final highlights = _splitList(_pkg['highlights'] as String?);
    final themes = (_pkg['holiday_themes'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final originalPrice = _originalPrice;
    final discountPercent = (originalPrice != null && originalPrice > _basePrice)
        ? (((originalPrice - _basePrice) / originalPrice) * 100).round()
        : null;

    return _sectionCard(
      title: 'Overview',
      // icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_format(_basePrice),
                  style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.bold, color: _kInk)),
              SizedBox(width: context.w(6)),
              Text('/Person', style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600)),
              if (originalPrice != null) ...[
                SizedBox(width: context.w(8)),
                Text(_format(originalPrice),
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    )),
              ],
              if (discountPercent != null) ...[
                SizedBox(width: context.w(6)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(2)),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(context.r(4))),
                  child: Text('$discountPercent% OFF',
                      style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                ),
              ],
            ],
          ),
          SizedBox(height: context.h(12)),
          if (itineraryText.isNotEmpty)
            Text(itineraryText, style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade800, height: 1.5))
          else
            Text('No overview available for this package yet.',
                style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade600)),
          if (highlights.isNotEmpty) ...[
            SizedBox(height: context.h(12)),
            ...highlights.map((h) => _bulletRow(h, Icons.check_circle, _kAccent)),
          ],
          if (themes.isNotEmpty) ...[
            SizedBox(height: context.h(8)),
            Wrap(spacing: context.w(8), runSpacing: context.h(8), children: themes.map(_tagChip).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildItinerarySection() {
    final days = (_pkg['itinerary_days'] as List?) ?? const [];
    final itinerarySummary = (_pkg['itinerary'] as String?) ?? '';

    return _sectionCard(
      title: 'Day by Day Itinerary',
      // icon: Icons.map_outlined,
      child: days.isEmpty
          ? Text(
              itinerarySummary.isNotEmpty ? itinerarySummary : 'Day-wise itinerary will be shared upon booking.',
              style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade700),
            )
          : Column(children: days.map((d) => _dayTile(d as Map)).toList()),
    );
  }

  Widget _dayTile(Map day) {
    final dayNumber = day['day_number'] ?? '';
    final title = (day['title'] as String?) ?? '';
    final details = (day['details'] as String?) ?? '';
    final activities = ((day['activities'] as List?) ?? const [])
        .where((a) => ((a as Map)['text'] as String?)?.trim().isNotEmpty == true)
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: context.h(10)),
        leading: CircleAvatar(
          radius: context.w(14),
          backgroundColor: _kAccent.withValues(alpha: 0.1),
          child: Text('$dayNumber', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.bold, color: _kAccent)),
        ),
        title: Text(title, style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w600, color: _kInk)),
        children: [
          if (details.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: context.w(38), right: context.w(4), bottom: context.h(8)),
              child: Text(details, style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade700, height: 1.4)),
            ),
          if (activities.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: context.w(38), right: context.w(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: activities.map((raw) {
                  final a = raw as Map;
                  final time = a['time'] as String?;
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.h(4)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_activityIcon(a['icon'] as String?), size: context.iconXSmall, color: _kAccent),
                        SizedBox(width: context.w(6)),
                        Expanded(
                          child: Text(
                            time != null && time.isNotEmpty ? '$time: ${a['text']}' : '${a['text']}',
                            style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStaySection() {
    final tiers = (_pkg['accommodation_tiers'] as List?) ?? const [];

    return _sectionCard(
      title: "Where You'll Stay",
      // icon: Icons.bed_outlined,
      child: tiers.isEmpty
          ? Text('Stay details will be confirmed at booking.', style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade600))
          : Column(children: tiers.map((t) => _hotelTile(t as Map)).toList()),
    );
  }

  Widget _hotelTile(Map tier) {
    final name = (tier['name'] as String?) ?? '';
    final stars = (tier['stars'] is num) ? (tier['stars'] as num).toInt() : 0;
    final nights = tier['nights'];
    final location = (tier['location'] as String?) ?? '';
    final imageUrl = (tier['image_url'] as String?) ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: context.h(10)),
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.r(10))),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(8)),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: context.w(60),
              height: context.w(60),
              fit: BoxFit.cover,
              memCacheWidth: 200,
              errorWidget: (context, url, error) => Container(
                width: context.w(60),
                height: context.w(60),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kAccent.withValues(alpha: 0.2),
                      _kAccent.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '🏨',
                    style: TextStyle(
                      fontSize: context.fs(24),
                      fontWeight: FontWeight.bold,
                      color: _kAccent,
                    ),
                  ),
                ),
              ),
            )
                : Container(
              width: context.w(50),
              height: context.w(50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _kAccent.withValues(alpha: 0.2),
                    _kAccent.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '🏨',
                  style: TextStyle(
                    fontSize: context.fs(24),
                    fontWeight: FontWeight.bold,
                    color: _kAccent,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w600, color: _kInk),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (stars > 0) ...[
                  SizedBox(height: context.h(4)),
                  Row(children: List.generate(stars, (i) => Icon(Icons.star, size: context.iconXSmall, color: Colors.amber.shade600))),
                ],
                SizedBox(height: context.h(4)),
                Text(
                  [if (nights != null) '$nights Night${nights == 1 ? '' : 's'}', if (location.isNotEmpty) location].join(' • '),
                  style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionsSection() {
    final inclusions = _splitList(
      (_pkg['inclusions_detail'] as String?) ?? (_pkg['inclusions'] as String?),
      pattern: r'[\r\n]+',
    );
    final exclusions = _splitList(_pkg['exclusions'] as String?, pattern: r'[\r\n]+');

    // Determine which items to show
    final displayInclusions = _showFullInclusions ? inclusions : inclusions.take(5).toList();
    final displayExclusions = _showFullExclusions ? exclusions : exclusions.take(5).toList();
    final hasMoreInclusions = inclusions.length > 5;
    final hasMoreExclusions = exclusions.length > 5;

    return _sectionCard(
      title: 'Inclusions & Exclusions',
      icon: Icons.checklist_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inclusions.isNotEmpty) ...[
            Text('Included', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: Colors.green.shade700)),
            SizedBox(height: context.h(8)),
            ...displayInclusions.map((e) => _bulletRow(e, Icons.check_circle_outline, Colors.green.shade600)),
            if (hasMoreInclusions) ...[
              SizedBox(height: context.h(4)),
              GestureDetector(
                onTap: () => setState(() => _showFullInclusions = !_showFullInclusions),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showFullInclusions ? 'Read less' : 'Read more (${inclusions.length - 5} more)',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: _kInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(
                      _showFullInclusions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: context.iconXSmall,
                      color: _kInk,
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (exclusions.isNotEmpty) ...[
            SizedBox(height: context.h(12)),
            Text('Excluded', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: Colors.red.shade700)),
            SizedBox(height: context.h(8)),
            ...displayExclusions.map((e) => _bulletRow(e, Icons.cancel_outlined, Colors.red.shade400)),
            if (hasMoreExclusions) ...[
              SizedBox(height: context.h(4)),
              GestureDetector(
                onTap: () => setState(() => _showFullExclusions = !_showFullExclusions),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showFullExclusions ? 'Read less' : 'Read more (${exclusions.length - 5} more)',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: _kInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(
                      _showFullExclusions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: context.iconXSmall,
                      color: _kInk,
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (inclusions.isEmpty && exclusions.isEmpty)
            Text('No inclusion details available.', style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Fare card + payment
  // ---------------------------------------------------------------------

  Widget _buildFareCardBar() {
    final total = _basePrice * _travellersCount;
    final gst = total * (_gstPercent / 100);
    final grandTotal = total + gst;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showFareBreakdown(total, gst, grandTotal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_format(grandTotal), style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.bold, color: _kInk)),
                        SizedBox(width: context.w(4)),
                        Icon(Icons.keyboard_arrow_up, size: context.iconSmall, color: Colors.grey.shade600),
                      ],
                    ),
                    Text(
                      'For $_travellersCount traveller${_travellersCount > 1 ? 's' : ''} • View fare breakup',
                      style: TextStyle(fontSize: context.fs(10), color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: context.w(12)),
            ElevatedButton(
              onPressed: () => _showFareBreakdown(total, gst, grandTotal),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
                padding: EdgeInsets.symmetric(horizontal: context.w(26), vertical: context.h(14)),
              ),
              child: Text('Proceed to Pay', style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFareBreakdown(double total, double gst, double grandTotal) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20)))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.w(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fare Details', style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.bold, color: _kInk)),
                SizedBox(height: context.h(16)),
                _fareRow('Base price × $_travellersCount traveller${_travellersCount > 1 ? 's' : ''}', _format(total)),
                if (_gstPercent > 0) _fareRow('GST (${_gstPercent.toStringAsFixed(0)}%)', _format(gst)),
                Divider(height: context.h(24)),
                _fareRow('Total Amount', _format(grandTotal), bold: true),
                SizedBox(height: context.h(20)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _onProceedToPay(total, gst, grandTotal);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: context.h(14)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
                    ),
                    child: Text('Continue', style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fareRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: context.fs(bold ? 14 : 12),
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: bold ? _kInk : Colors.grey.shade700,
              )),
          Text(value,
              style: TextStyle(
                fontSize: context.fs(bold ? 14 : 12),
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: bold ? _kAccent : Colors.black87,
              )),
        ],
      ),
    );
  }

  void _onProceedToPay(double total, double gst, double grandTotal) {
    final title = (_pkg['title'] as String?) ?? 'Holiday Package';
    final imageUrl = (_pkg['image_url'] as String?) ?? '';
    final packageId = (_pkg['id'] as num?)?.toInt() ?? 0;
    final packageSlug = (_pkg['slug'] as String?) ?? '';
    final city = (_pkg['city'] as String?) ?? '';
    final nights = (_pkg['nights'] as num?)?.toInt() ?? 0;
    final days = (_pkg['days'] as num?)?.toInt() ?? 0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HolidayTravellerDetailsScreen(
          packageTitle: title,
          packageImage: imageUrl,
          packageLocation: _locationLabel,
          travellersCount: _travellersCount,
          grandTotalInr: grandTotal,
          baseTotalDisplay: _format(total),
          gstDisplay: _format(gst),
          grandTotalDisplay: _format(grandTotal),
          gstPercent: _gstPercent,
          packageInventoryId: packageId,
          packageSlug: packageSlug,
          city: city,
          nights: nights,
          days: days,
          packageSnapshot: {'id': packageId, 'slug': packageSlug, 'title': title},
          departureDate: widget.departureDate,
        ),
      ),
    );
  }
}
