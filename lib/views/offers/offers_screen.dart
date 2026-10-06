import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';
import 'package:wander_nova/common_widgets/fast_network_image_cache_manager.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../newUIWidgets/Home_nav.dart';
import '../ExclusiveDeals/domain/entities/exclusive_deal_entity.dart';
import '../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../ExclusiveDeals/presentation/bloc/exclusive_deals_event.dart';
import '../ExclusiveDeals/presentation/bloc/exclusive_deals_state.dart';
import '../ExclusiveDeals/presentation/screen/dealDetails_Screen.dart';
import '../home/presentation/widgets/home_sections.dart' show HomeCroppedImage;
import '../home/presentation/widgets/home_top_widgets.dart';

// "Offers" screen from the Figma file (node 2760:14566, 412px frame, hence
// `context.fx`). Everything comes from the Exclusive Deals API.

const Color _grey = Color(0xFF757575);
const Color _stroke = Color(0xFFCCCCCC);

/// Offer categories as the API names them, in display order.
enum OfferCategory {
  flight('flight', 'Flights', 'Flight Offers'),
  hotel('hotel', 'Hotels', 'Hotel Offers'),
  holidays('holidays', 'Holiday', 'Holiday Offers'),
  visa('visa', 'Visa', 'Visa Offers');

  final String apiKey;
  final String chipLabel;
  final String sectionTitle;

  const OfferCategory(this.apiKey, this.chipLabel, this.sectionTitle);

  static OfferCategory? of(ExclusiveDealEntity deal) {
    final key = (deal.category.isNotEmpty ? deal.category : deal.ownerTab)
        .toLowerCase();
    for (final c in values) {
      if (key == c.apiKey || key.startsWith(c.apiKey) || c.apiKey.startsWith(key)) {
        return c;
      }
    }
    return null;
  }

  /// Small 3D icon for the chip — crops of the same sprite sheets the home
  /// service grid uses.
  Widget icon() {
    switch (this) {
      case OfferCategory.flight:
        return const HomeCroppedImage(asset: 'assets/home/services_row1.png', width: 20, height: 20, imageWidthFactor: 5.0895, imageHeightFactor: 1.6941, leftFactor: -0.1469, topFactor: -0.3765);
      case OfferCategory.hotel:
        return const HomeCroppedImage(asset: 'assets/home/services_row1.png', width: 20, height: 20, imageWidthFactor: 5.0895, imageHeightFactor: 1.6941, leftFactor: -1.4116, topFactor: -0.3471);
      case OfferCategory.holidays:
        return const HomeCroppedImage(asset: 'assets/home/services_row1.png', width: 20, height: 20, imageWidthFactor: 5.0895, imageHeightFactor: 1.6941, leftFactor: -2.6175, topFactor: -0.4059);
      case OfferCategory.visa:
        return const HomeCroppedImage(asset: 'assets/home/services_row2.png', width: 20, height: 20.6, imageWidthFactor: 3.9512, imageHeightFactor: 1.2857, leftFactor: -0.1951, topFactor: -0.2143);
    }
  }
}

/// First readable line of an offer — its short description, else the first
/// bullet of the full terms, else the discount text.
String offerSummary(ExclusiveDealEntity deal) {
  final short = deal.shortDescription.trim();
  if (short.isNotEmpty) return short;
  final discount = deal.discountText.trim();
  if (discount.isNotEmpty) return discount;
  for (final line in deal.description.split(RegExp(r'[\r\n]+'))) {
    final text = line.replaceFirst(RegExp(r'^[\s*•\-]+'), '').trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

/// Active offers, newest first.
List<ExclusiveDealEntity> latestOffers(List<ExclusiveDealEntity> deals) {
  return deals.where((d) => d.isActive && d.title.trim().isNotEmpty).toList()
    ..sort((a, b) => b.created.compareTo(a.created));
}

void _openDeal(BuildContext context, ExclusiveDealEntity deal) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DealDetailsScreen(deal: deal)),
  );
}

void _copyCoupon(BuildContext context, String code) {
  Clipboard.setData(ClipboardData(text: code));
  HapticFeedback.selectionClick();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Coupon code $code copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

class OffersScreen extends StatefulWidget {
  /// Offer to lead the banner with (the one tapped on the home screen).
  final int? focusDealId;

  const OffersScreen({super.key, this.focusDealId});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  /// `null` = "All".
  OfferCategory? _filter;
  OfferCategory? _exclusiveTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<ExclusiveDealsBloc>();
      if (bloc.state is! ExclusiveDealsLoaded) {
        bloc.add(const LoadExclusiveDeals());
      }
    });
  }

  Future<void> _refresh() async {
    final bloc = context.read<ExclusiveDealsBloc>();
    bloc.add(const LoadExclusiveDeals());
    await bloc.stream
        .firstWhere((s) => s is! ExclusiveDealsLoading)
        .timeout(const Duration(seconds: 20), onTimeout: () => bloc.state);
  }

  void _onNavTap(int index) {
    // Home lives underneath this screen; the other tabs aren't built yet
    // (same as on the home screen).
    if (index == 0) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: context.h(12)),
            child: CustomBottomNav(currentIndex: 2, onItemSelected: _onNavTap),
          ),
        ),
        body: BlocBuilder<ExclusiveDealsBloc, ExclusiveDealsState>(
          builder: (context, state) {
            if (state is ExclusiveDealsLoaded) {
              return RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.AppBlue,
                child: _buildContent(context, latestOffers(state.deals)),
              );
            }
            if (state is ExclusiveDealsError) {
              return _ErrorState(
                message: state.message,
                onRetry: () => context.read<ExclusiveDealsBloc>().add(
                  const LoadExclusiveDeals(),
                ),
              );
            }
            return const AppLoadingView(message: 'Loading offers…');
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ExclusiveDealEntity> offers) {
    final gutter = context.fx(16);
    final categories = [
      for (final c in OfferCategory.values)
        if (offers.any((d) => OfferCategory.of(d) == c)) c,
    ];
    final shown = _filter == null
        ? offers
        : offers.where((d) => OfferCategory.of(d) == _filter).toList();

    // Banner: the offer tapped on home first, then the newest — 3 at most.
    final focus = offers.where((d) => d.id == widget.focusDealId);
    final bannerDeals = [
      ...focus,
      ...shown.where((d) => d.id != widget.focusDealId),
    ].take(3).toList();

    final holidayDeals = shown
        .where((d) => OfferCategory.of(d) == OfferCategory.holidays && d.imageUrl.isNotEmpty)
        .toList();

    final exclusiveTab = categories.contains(_exclusiveTab)
        ? _exclusiveTab
        : (categories.contains(_filter) ? _filter : (categories.isEmpty ? null : categories.first));
    final exclusiveDeals = offers
        .where((d) => OfferCategory.of(d) == exclusiveTab && d.imageUrl.isNotEmpty)
        .toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              MediaQuery.paddingOf(context).top + context.fx(36),
              gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offers',
                  style: TextStyle(
                    fontSize: context.ffs(24),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: context.fx(2)),
                Text(
                  'Unmissable deals for unforgettable journeys',
                  style: TextStyle(
                    fontSize: context.ffs(12),
                    fontWeight: FontWeight.w500,
                    color: _grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: context.fx(20))),
        SliverToBoxAdapter(
          child: SizedBox(
            height: context.fx(32),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: gutter),
              children: [
                _CategoryChip(
                  label: 'All',
                  icon: Icon(Icons.grid_view_rounded, size: context.fx(16), color: _filter == null ? Colors.white : AppColors.AppBlue),
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final c in categories) ...[
                  SizedBox(width: context.fx(12)),
                  _CategoryChip(
                    label: c.chipLabel,
                    icon: c.icon(),
                    selected: _filter == c,
                    onTap: () => setState(() {
                      _filter = c;
                      _exclusiveTab = c;
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: context.fx(24))),
        if (shown.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(context.fx(32)),
              child: Text(
                'No offers in this category right now.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: context.ffs(13), color: _grey),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: HomeInfoCarousel(
                key: ValueKey('banner-$_filter'),
                slides: [
                  for (final d in bannerDeals)
                    HomeInfoSlide(
                      title: d.title.trim(),
                      body: offerSummary(d),
                      onAction: () => _openDeal(context, d),
                    ),
                ],
              ),
            ),
          ),
          for (final c in OfferCategory.values)
            if (shown.any((d) => OfferCategory.of(d) == c)) ...[
              SliverToBoxAdapter(child: SizedBox(height: context.fx(32))),
              SliverToBoxAdapter(child: _SectionTitle(c.sectionTitle)),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: SliverList.separated(
                  itemCount: shown.where((d) => OfferCategory.of(d) == c).length,
                  separatorBuilder: (_, __) => SizedBox(height: context.fx(16)),
                  itemBuilder: (context, i) => _CouponCard(
                    deal: shown.where((d) => OfferCategory.of(d) == c).elementAt(i),
                  ),
                ),
              ),
            ],
          if (holidayDeals.isNotEmpty) ...[
            SliverToBoxAdapter(child: SizedBox(height: context.fx(32))),
            const SliverToBoxAdapter(child: _SectionTitle('Holiday Destinations')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: context.fx(160),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  itemCount: holidayDeals.length,
                  separatorBuilder: (_, __) => SizedBox(width: context.fx(14)),
                  itemBuilder: (context, i) => _DestinationOfferCard(deal: holidayDeals[i]),
                ),
              ),
            ),
          ],
        ],
        if (categories.isNotEmpty) ...[
          SliverToBoxAdapter(child: SizedBox(height: context.fx(36))),
          SliverToBoxAdapter(
            child: _ExclusiveHeader(
              categories: categories,
              selected: exclusiveTab,
              onSelect: (c) => setState(() => _exclusiveTab = c),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: context.fx(20))),
          SliverToBoxAdapter(
            child: SizedBox(
              height: context.fx(140),
              child: exclusiveDeals.isEmpty
                  ? Center(
                      child: Text(
                        'No exclusive offers here yet.',
                        style: TextStyle(fontSize: context.ffs(12), color: _grey),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      itemCount: exclusiveDeals.length,
                      separatorBuilder: (_, __) => SizedBox(width: context.fx(14)),
                      itemBuilder: (context, i) => _ExclusiveOfferCard(deal: exclusiveDeals[i]),
                    ),
            ),
          ),
        ],
        // Room for the floating bottom bar.
        SliverToBoxAdapter(child: SizedBox(height: context.fx(140))),
      ],
    );
  }
}

// ===========================================================================
// Pieces
// ===========================================================================

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.fx(16), 0, context.fx(16), context.fx(16)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.ffs(18),
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: context.fx(10)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.AppBlue : Colors.white,
          borderRadius: BorderRadius.circular(context.fx(16)),
          border: selected ? null : Border.all(color: _stroke),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x3D000000), blurRadius: 3, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(width: context.fx(6)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.ffs(12),
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : _grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text coupon card: ticket icon, title, one-line description, and the
/// dashed coupon strip with a copy button.
class _CouponCard extends StatelessWidget {
  final ExclusiveDealEntity deal;

  const _CouponCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final code = deal.couponCode.trim();
    final summary = offerSummary(deal);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.fx(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.fx(12)),
        onTap: () => _openDeal(context, deal),
        child: Container(
          padding: EdgeInsets.all(context.fx(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.fx(12)),
            border: Border.all(color: _stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: context.fx(20), color: AppColors.AppBlue),
                  SizedBox(width: context.fx(8)),
                  Expanded(
                    child: Text(
                      deal.title.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.ffs(14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.AppBlue,
                      ),
                    ),
                  ),
                ],
              ),
              if (summary.isNotEmpty) ...[
                SizedBox(height: context.fx(4)),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.ffs(10), color: _grey),
                ),
              ],
              if (code.isNotEmpty) ...[
                SizedBox(height: context.fx(12)),
                _CouponStrip(code: code),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponStrip extends StatelessWidget {
  final String code;

  const _CouponStrip({required this.code});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: _stroke,
        radius: context.fx(8),
      ),
      child: SizedBox(
        height: context.fx(32),
        child: Row(
          children: [
            SizedBox(width: context.fx(14)),
            Expanded(
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.ffs(12),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                  color: AppColors.OrangeColor,
                ),
              ),
            ),
            _CopyButton(code: code),
          ],
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String code;
  final bool filled;

  const _CopyButton({required this.code, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.copy_rounded, size: context.fx(16), color: AppColors.AppBlue);
    return Semantics(
      button: true,
      label: 'Copy coupon code $code',
      child: InkWell(
        borderRadius: BorderRadius.circular(context.fx(6)),
        onTap: () => _copyCoupon(context, code),
        child: Padding(
          padding: EdgeInsets.all(context.fx(8)),
          child: filled
              ? Container(
                  padding: EdgeInsets.all(context.fx(5)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.fx(6)),
                  ),
                  child: icon,
                )
              : icon,
        ),
      ),
    );
  }
}

/// Destination card: the photo side of the offer creative, the destination
/// name and the discount pill.
class _DestinationOfferCard extends StatelessWidget {
  final ExclusiveDealEntity deal;

  const _DestinationOfferCard({required this.deal});

  /// "Malaysia Holiday Packages – Flat 25% Off" → "MALAYSIA".
  String get _destination {
    final country = deal.country.trim();
    if (country.isNotEmpty) return country.toUpperCase();
    final title = deal.title.trim();
    final cut = RegExp(r'\s+(holiday|package|tour)|\s+[–\-]', caseSensitive: false)
        .firstMatch(title);
    return (cut == null ? title : title.substring(0, cut.start)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final discount = deal.discountText.trim();
    return GestureDetector(
      onTap: () => _openDeal(context, deal),
      child: Container(
        width: context.fx(132),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.fx(12)),
          border: Border.all(color: _stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: context.fx(100),
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _OfferImage(url: deal.imageUrl, alignment: Alignment.centerRight),
                  Positioned(
                    top: context.fx(6),
                    right: context.fx(6),
                    child: Container(
                      width: context.fx(20),
                      height: context.fx(20),
                      decoration: const BoxDecoration(color: Color(0xFFFF383C), shape: BoxShape.circle),
                      child: Icon(Icons.local_offer, size: context.fx(11), color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.fx(6)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.ffs(12),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    if (discount.isNotEmpty) ...[
                      SizedBox(height: context.fx(6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.fx(8),
                          vertical: context.fx(3),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDFF),
                          borderRadius: BorderRadius.circular(context.fx(10)),
                        ),
                        child: Text(
                          discount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.ffs(9),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3D5AFE),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExclusiveHeader extends StatelessWidget {
  final List<OfferCategory> categories;
  final OfferCategory? selected;
  final ValueChanged<OfferCategory> onSelect;

  const _ExclusiveHeader({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: context.fx(16)),
        Text(
          'Exclusive\nOffers',
          style: TextStyle(
            fontSize: context.ffs(18),
            fontWeight: FontWeight.w500,
            height: 1.25,
            color: Colors.black,
          ),
        ),
        SizedBox(width: context.fx(14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: context.fx(32),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(right: context.fx(16)),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => SizedBox(width: context.fx(10)),
                  itemBuilder: (context, i) => _CategoryChip(
                    label: categories[i].chipLabel,
                    icon: categories[i].icon(),
                    selected: categories[i] == selected,
                    onTap: () => onSelect(categories[i]),
                  ),
                ),
              ),
              SizedBox(height: context.fx(8)),
              Padding(
                padding: EdgeInsets.only(right: context.fx(16)),
                child: const _StarsDivider(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Gold line with three stars in the middle, under the Exclusive Offers tabs.
class _StarsDivider extends StatelessWidget {
  const _StarsDivider();

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF5B91E);
    Widget line(Alignment from) => Expanded(
      child: Container(
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: from,
            end: -from,
            colors: [gold.withValues(alpha: 0), gold],
          ),
        ),
      ),
    );
    return Row(
      children: [
        line(Alignment.centerLeft),
        SizedBox(width: context.fx(6)),
        for (final s in const [8.0, 11.0, 8.0])
          Icon(Icons.star_rounded, size: context.fx(s), color: gold),
        SizedBox(width: context.fx(6)),
        line(Alignment.centerRight),
      ],
    );
  }
}

/// The offer creative as-is (it already carries its headline and discount),
/// with the coupon strip from the design along the bottom.
class _ExclusiveOfferCard extends StatelessWidget {
  final ExclusiveDealEntity deal;

  const _ExclusiveOfferCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final code = deal.couponCode.trim();
    return GestureDetector(
      onTap: () => _openDeal(context, deal),
      child: Container(
        width: context.fx(202),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.fx(12)),
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.fx(12)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _OfferImage(url: deal.imageUrl),
              if (code.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(context.fx(12), context.fx(10), context.fx(4), context.fx(4)),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xCC000000), Color(0x00000000)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.ffs(12),
                              fontWeight: FontWeight.w700,
                              color: AppColors.OrangeColor,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.OrangeColor,
                            ),
                          ),
                        ),
                        _CopyButton(code: code, filled: true),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferImage extends StatelessWidget {
  final String url;
  final Alignment alignment;

  const _OfferImage({required this.url, this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: Icon(Icons.local_offer_outlined, color: AppColors.AppBlue.withValues(alpha: 0.5)),
    );
    if (url.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: FastNetworkImageCacheManager.instance,
      fit: BoxFit.cover,
      alignment: alignment,
      // The creatives are ~1500px wide; decode only what a card needs.
      memCacheWidth: 600,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.fx(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: context.fx(40), color: _grey),
            SizedBox(height: context.fx(12)),
            Text(
              'Couldn’t load offers',
              style: TextStyle(fontSize: context.ffs(16), fontWeight: FontWeight.w600),
            ),
            SizedBox(height: context.fx(6)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.ffs(12), color: _grey),
            ),
            SizedBox(height: context.fx(16)),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.AppBlue),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.5),
        Radius.circular(radius),
      ));
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
