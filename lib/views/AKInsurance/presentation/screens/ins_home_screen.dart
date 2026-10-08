import 'package:flutter/material.dart';
import 'package:wander_nova/views/home/presentation/widgets/home_top_widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/app_loader.dart';
import '../../../../common_widgets/custom_drawer.dart';
import '../../../../injection_container.dart' as di;
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../countries/domain/entities/country_entity.dart';
import '../../../countries/presentation/bloc/country_bloc.dart';
import '../../../countries/presentation/bloc/country_event.dart';
import '../../../countries/presentation/bloc/country_state.dart';
import '../../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../../home/presentation/screens/deals.dart';
import '../../../trending_route/presentation/screen/trending_routes.dart';
import '../bloc/AKInsurance_bloc.dart';
import '../bloc/AKInsurance_event.dart';
import '../bloc/AKInsurance_state.dart';
import '../state/ins_search_query.dart';
import '../widgets/ins_common.dart';
import '../widgets/ins_search_card.dart';
import 'ins_quotes_screen.dart';

/// Insurance landing screen — Figma `insurance 1`…`insurance 5`.
///
/// Owns the [InsSearchQuery] the hero form edits and the single
/// [AkInsuranceBloc] the whole flow shares, so the quotes screen can keep
/// reading the same bloc instance instead of re-issuing the search.
///
/// Everything the form offers is live: the policy-type tabs come from
/// ProviderChecklist and the country lists from `CountryBloc` — the same
/// sources the previous screen used.
class InsHomeScreen extends StatefulWidget {
  const InsHomeScreen({super.key});

  @override
  State<InsHomeScreen> createState() => _InsHomeScreenState();
}

class _InsHomeScreenState extends State<InsHomeScreen> {
  late final AkInsuranceBloc _bloc;

  /// Null until both the checklist and the country list have arrived — the
  /// query cannot be built without a real policy type and origin country.
  InsSearchQuery? _query;

  @override
  void initState() {
    super.initState();
    _bloc = di.sl<AkInsuranceBloc>()
      ..add(const LoadAkInsuranceProviderChecklistEvent());

    if (context.read<CountryBloc>().state is! CountryLoaded) {
      context.read<CountryBloc>().add(const LoadCountriesEvent());
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Builds the form state the first time both feeds are in, and keeps it
  /// afterwards so a rebuild never discards what the traveller has typed.
  InsSearchQuery? _ensureQuery(
    List<InsPolicyType> types,
    List<CountryEntity> countries,
  ) {
    final existing = _query;
    if (existing != null) {
      // The checklist can land after the query was seeded from a fallback;
      // re-point the selected tab at the real type with the same code.
      if (types.isNotEmpty &&
          !types.any((t) => t.code == existing.policyType.code)) {
        return _query = existing.copyWith(policyType: types.first);
      }
      return existing;
    }
    if (types.isEmpty || countries.isEmpty) return null;

    return _query = InsSearchQuery.initial(
      policyType: types.first,
      // India is where this agency sells from, so it is the sensible
      // starting origin — but it is matched against the live country list
      // rather than invented, and falls back to the first country the API
      // returns if it isn't there.
      //
      // Written as a filter rather than firstWhere(orElse:): the bloc hands
      // back a List<CountryModel> behind a List<CountryEntity> reference, and
      // an orElse closure returning CountryEntity fails that list's runtime
      // type check.
      fromCountry: _defaultOrigin(countries),
    );
  }

  static CountryEntity _defaultOrigin(List<CountryEntity> countries) {
    for (final c in countries) {
      if (c.name.toLowerCase() == 'india') return c;
    }
    return countries.first;
  }

  void _explore() {
    final query = _query;
    if (query == null) return;

    final error = query.validationError;
    if (error != null) {
      insSnack(context, error, isError: true);
      return;
    }

    _bloc.add(LoadAkInsuranceQuotesEvent(query.toQuotesRequest()));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<AkInsuranceBloc>.value(
          value: _bloc,
          child: InsQuotesScreen(query: query),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // White page (no hero photo), so the status bar icons go dark.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        drawer: const CustomDrawer(),
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        body: BlocBuilder<CountryBloc, CountryState>(
          builder: (context, countryState) {
            final countries = countryState is CountryLoaded
                ? countryState.countries
                : const <CountryEntity>[];

            return BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
              bloc: _bloc,
              builder: (context, akState) {
                final types = [
                  for (final code in akState.checklist?.policyTypes ?? const [])
                    InsPolicyType.fromCode(code),
                ];
                final query = _ensureQuery(types, countries);

                return CustomScrollView(
                  physics: context.scrollPhysics,
                  slivers: [
                    SliverToBoxAdapter(
                      child: query == null
                          ? _heroPlaceholder(context)
                          : InsSearchCard(
                              query: query,
                              policyTypes: types,
                              countries: countries,
                              heroImage: null,
                              onChanged: (q) => setState(() => _query = q),
                              onExplore: _explore,
                            ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: context.h(24))),
                    SliverToBoxAdapter(
                      child: BlocProvider<ExclusiveDealsBloc>(
                        create: (_) => di.sl<ExclusiveDealsBloc>(),
                        // child: const DealsSection(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                          child: const HomeOffersCarousel(categories: ['insurance']),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: context.h(24))),
                    const SliverToBoxAdapter(child: PopularDestinations()),
                    SliverToBoxAdapter(child: SizedBox(height: context.h(15))),
                    const SliverToBoxAdapter(child: TrendingPackages()),
                    SliverToBoxAdapter(child: SizedBox(height: context.h(28))),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Shown only while ProviderChecklist and the country list are still in
  /// flight — the form cannot be drawn before it knows the real policy
  /// types, and showing a half-populated form would be worse.
  Widget _heroPlaceholder(BuildContext context) {
    return AppLoadingView(
      message: 'Loading insurance options…',
      height: context.fx(420),
    );
  }
}
