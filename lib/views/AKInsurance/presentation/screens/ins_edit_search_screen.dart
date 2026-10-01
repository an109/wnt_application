import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../countries/domain/entities/country_entity.dart';
import '../../../countries/presentation/bloc/country_bloc.dart';
import '../../../countries/presentation/bloc/country_state.dart';
import '../bloc/AKInsurance_bloc.dart';
import '../bloc/AKInsurance_state.dart';
import '../state/ins_search_query.dart';
import '../widgets/ins_common.dart';
import '../widgets/ins_search_card.dart';

/// "Edit Your Search" — Figma `Select plan Individual edit`.
///
/// The same form the landing hero shows, on a white page: reusing
/// [InsSearchCard] in its `light` mode means the two can never drift apart,
/// and a field added to one is automatically in the other.
class InsEditSearchScreen extends StatefulWidget {
  final InsSearchQuery query;

  const InsEditSearchScreen({super.key, required this.query});

  /// Returns the edited query, or null when the traveller backs out.
  static Future<InsSearchQuery?> show(
    BuildContext context, {
    required InsSearchQuery query,
    required AkInsuranceBloc bloc,
  }) {
    return Navigator.of(context).push<InsSearchQuery>(
      MaterialPageRoute(
        builder: (_) => BlocProvider<AkInsuranceBloc>.value(
          value: bloc,
          child: InsEditSearchScreen(query: query),
        ),
      ),
    );
  }

  @override
  State<InsEditSearchScreen> createState() => _InsEditSearchScreenState();
}

class _InsEditSearchScreenState extends State<InsEditSearchScreen> {
  late InsSearchQuery _query = widget.query;

  void _modify() {
    final error = _query.validationError;
    if (error != null) {
      insSnack(context, error, isError: true);
      return;
    }
    Navigator.of(context).pop(_query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: insAppBar(context, title: 'Edit Your Search'),
      body: BlocBuilder<CountryBloc, CountryState>(
        builder: (context, countryState) {
          final countries = countryState is CountryLoaded
              ? countryState.countries
              : <CountryEntity>[_query.fromCountry];

          return BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
            builder: (context, akState) {
              final types = [
                for (final code in akState.checklist?.policyTypes ?? const [])
                  InsPolicyType.fromCode(code),
              ];

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: context.h(20)),
                child: InsSearchCard(
                  light: true,
                  ctaLabel: 'MODIFY SEARCH',
                  query: _query,
                  // The checklist is already cached by the time this screen
                  // opens; if it somehow isn't, keep at least the current
                  // type so the tab row is never empty.
                  policyTypes:
                      types.isEmpty ? [_query.policyType] : types,
                  countries: countries,
                  heroImage: null,
                  onChanged: (q) => setState(() => _query = q),
                  onExplore: _modify,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
