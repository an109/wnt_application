import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../injection_container.dart' as di;
import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../../../Visa_popularDestinaton/presentation/bloc/visa_destination_bloc.dart';
import '../../../Visa_popularDestinaton/presentation/bloc/visa_destination_event.dart';
import '../../../Visa_popularDestinaton/presentation/bloc/visa_destination_state.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import '../widgets/visa_destination_card.dart';
import '../widgets/visa_home_widgets.dart';
import '../widgets/visa_sheets.dart';
import 'visa_landing_screen.dart';
import 'visa_search_screen.dart';

const _domain = 'thewandernova.com';

/// Visa home (Figma 1801:7266).
class VisaScreen extends StatelessWidget {
  const VisaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VisaPopularDestinationBloc>(
      create: (_) => di.sl<VisaPopularDestinationBloc>()..add(const LoadVisaDestinations(domain: _domain)),
      child: const _VisaHomeView(),
    );
  }
}

class _VisaHomeView extends StatefulWidget {
  const _VisaHomeView();

  @override
  State<_VisaHomeView> createState() => _VisaHomeViewState();
}

class _VisaHomeViewState extends State<_VisaHomeView> {
  VisaDelivery? _delivery;
  VisaKind? _kind;
  VisaDocs? _docs;
  DateTimeRange? _holiday;

  bool get _hasFilters => _delivery != null || _kind != null || _docs != null || _holiday != null;

  List<VisaPopularDestinationEntity> _apply(
    List<VisaPopularDestinationEntity> all, {
    bool skipDelivery = false,
    bool skipKind = false,
    bool skipDocs = false,
  }) {
    final now = DateTime.now();
    return all.where((d) {
      if (!skipDelivery && _delivery != null) {
        final p = d.fastestProcessing;
        if (p == null || !_delivery!.matches(p.duration)) return false;
      }
      if (!skipKind && _kind != null && !d.kinds.contains(_kind)) return false;
      if (!skipDocs && _docs != null && d.docs != _docs) return false;
      if (_holiday != null) {
        final p = d.fastestProcessing;
        if (p == null || p.guaranteedFrom(now).isAfter(_holiday!.start)) return false;
      }
      return true;
    }).toList();
  }

  void _open(VisaPopularDestinationEntity d) {
    Navigator.push(context, VisaLandingScreen.route(d));
  }

  void _openSearch(List<VisaPopularDestinationEntity> all, {bool voice = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisaSearchScreen(destinations: all, startWithVoice: voice)),
    );
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<VisaPopularDestinationBloc, VisaPopularDestinationState>(
        builder: (context, state) {
          final all = state is VisaDestinationLoaded
              ? state.destinations.where((d) => d.isActive).toList()
              : <VisaPopularDestinationEntity>[];
          return RefreshIndicator(
            color: VisaColors.primary,
            onRefresh: () async => context
                .read<VisaPopularDestinationBloc>()
                .add(const RefreshVisaDestinations(domain: _domain)),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _hero(all)),
                ..._body(state, all),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _body(VisaPopularDestinationState state, List<VisaPopularDestinationEntity> all) {
    if (state is VisaDestinationError) {
      return [
        SliverToBoxAdapter(
          child: _message(
            'Could not load visas',
            'Check your connection and try again.',
            action: 'RETRY',
            onAction: () => context
                .read<VisaPopularDestinationBloc>()
                .add(const LoadVisaDestinations(domain: _domain)),
          ),
        ),
      ];
    }
    if (state is! VisaDestinationLoaded) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator(color: VisaColors.primary, strokeWidth: 2)),
          ),
        ),
      ];
    }

    final popular = all.where((d) => d.showInPopular && d.cardImage.isNotEmpty).toList();
    final results = _apply(all)..sort(_byPopularThenOrder);
    final tough = (all.where((d) => d.cardImage.isNotEmpty && d.fastestProcessing != null).toList()
          ..sort((a, b) => b.fastestProcessing!.duration.compareTo(a.fastestProcessing!.duration)))
        .take(6)
        .toList();

    final firstBlock = results.take(4).toList();
    final rest = results.skip(4).toList();

    return [
      if (popular.isNotEmpty)
        SliverToBoxAdapter(child: VisaPopularCircles(destinations: popular, onTap: _open)),
      const SliverToBoxAdapter(child: SizedBox(height: 26)),
      if (results.isEmpty)
        SliverToBoxAdapter(
          child: _message(
            'No visas match these filters',
            'Try a different delivery time, type or document.',
            action: 'CLEAR FILTERS',
            onAction: () => setState(() {
              _delivery = null;
              _kind = null;
              _docs = null;
              _holiday = null;
            }),
          ),
        ),
      _grid(firstBlock),
      if (!_hasFilters && tough.length >= 3)
        SliverToBoxAdapter(child: VisaToughCarousel(destinations: tough, onOpen: _open)),
      if (rest.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        _grid(rest),
      ],
    ];
  }

  int _byPopularThenOrder(VisaPopularDestinationEntity a, VisaPopularDestinationEntity b) {
    if (a.showInPopular != b.showInPopular) return a.showInPopular ? -1 : 1;
    final ai = a.cardImage.isNotEmpty, bi = b.cardImage.isNotEmpty;
    if (ai != bi) return ai ? -1 : 1;
    return 0;
  }

  Widget _grid(List<VisaPopularDestinationEntity> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.crossAxisExtent - 12) / 2;
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 32,
              mainAxisExtent: cardWidth * 4 / 3 + 38,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => VisaDestinationCard(destination: items[i], onTap: () => _open(items[i])),
          );
        },
      ),
    );
  }

  Widget _hero(List<VisaPopularDestinationEntity> all) {
    final top = MediaQuery.of(context).padding.top;
    final height = top + 230.0;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.88,
              child: Image.asset(
                'assets/visa/visa_home_hero.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.15),
              ),
            ),
          ),
          // Soft white fade under the filter chips.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0), Colors.white],
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 10,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _back,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: SvgPicture.asset('assets/visa/ic_back.svg', width: 24, height: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('Visa', style: visaText(20, weight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => _openSearch(all),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: VisaColors.stroke),
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/visa/ic_search.gif', width: 18, height: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Search places',
                              style: visaText(10, weight: FontWeight.w500, color: VisaColors.text)),
                        ),
                        GestureDetector(
                          onTap: () => _openSearch(all, voice: true),
                          child: SvgPicture.asset('assets/visa/ic_mic.svg', width: 18, height: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 39,
            height: 40,
            child: _filters(all),
          ),
        ],
      ),
    );
  }

  Widget _filters(List<VisaPopularDestinationEntity> all) {
    final forDelivery = _apply(all, skipDelivery: true);
    final forKind = _apply(all, skipKind: true);
    final forDocs = _apply(all, skipDocs: true);

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        VisaFilterChip(
          iconAsset: 'assets/visa/ic_bolt.svg',
          label: 'Visa Delivery',
          value: _delivery?.label ?? 'Anytime',
          active: _delivery != null,
          onTap: (chip) async {
            final picked = await showVisaFilterMenu<VisaDelivery>(chip, [
              VisaFilterOption(null, 'Any Time', forDelivery.length),
              for (final v in VisaDelivery.values)
                VisaFilterOption(
                  v,
                  v.label,
                  forDelivery.where((d) {
                    final p = d.fastestProcessing;
                    return p != null && v.matches(p.duration);
                  }).length,
                ),
            ], _delivery);
            if (picked != null) setState(() => _delivery = picked.value);
          },
        ),
        const SizedBox(width: 8),
        VisaFilterChip(
          iconAsset: 'assets/visa/ic_flight_land.svg',
          label: 'Type',
          value: _kind?.label ?? 'Any',
          active: _kind != null,
          onTap: (chip) async {
            final picked = await showVisaFilterMenu<VisaKind>(chip, [
              VisaFilterOption(null, 'All Visa Types', forKind.length),
              for (final k in VisaKind.values)
                VisaFilterOption(k, k.label, forKind.where((d) => d.kinds.contains(k)).length),
            ], _kind);
            if (picked != null) setState(() => _kind = picked.value);
          },
        ),
        const SizedBox(width: 8),
        VisaFilterChip(
          iconAsset: 'assets/visa/ic_document.svg',
          label: 'Document',
          value: _docs == null ? 'Any' : _docs!.label,
          active: _docs != null,
          onTap: (chip) async {
            final picked = await showVisaFilterMenu<VisaDocs>(chip, [
              VisaFilterOption(null, 'Any Documents', forDocs.length),
              for (final v in VisaDocs.values)
                VisaFilterOption(v, v.label, forDocs.where((d) => d.docs == v).length),
            ], _docs);
            if (picked != null) setState(() => _docs = picked.value);
          },
        ),
        const SizedBox(width: 8),
        VisaFilterChip(
          iconAsset: 'assets/visa/ic_beach.svg',
          iconHeight: 16,
          label: 'Holiday date',
          value: _holiday == null ? 'Any' : visaDateFormat.format(_holiday!.start),
          active: _holiday != null,
          onTap: (_) async {
            final range = await showVisaSheet<DateTimeRange>(
              context,
              VisaHolidaySheet(initial: _holiday),
            );
            if (range != null) setState(() => _holiday = range);
          },
        ),
        if (_hasFilters) ...[
          const SizedBox(width: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _delivery = null;
                _kind = null;
                _docs = null;
                _holiday = null;
              }),
              child: Text('Clear', style: visaText(11, weight: FontWeight.w600, color: VisaColors.primary)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _message(String title, String subtitle, {required String action, required VoidCallback onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: visaText(14, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: visaText(11, color: VisaColors.text)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAction,
            child: Text(action, style: visaText(12, weight: FontWeight.w700, color: VisaColors.primary)),
          ),
        ],
      ),
    );
  }
}
