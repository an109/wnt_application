import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../countries/domain/entities/country_entity.dart';
import '../../../countries/presentation/bloc/country_bloc.dart';
import '../../../countries/presentation/bloc/country_state.dart';
import '../bloc/AKInsurance_bloc.dart';
import '../bloc/AKInsurance_state.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import 'ins_common.dart';
import 'ins_search_card.dart';

/// "Edit Your Search" — the top drawer the quotes screen opens from its edit
/// pencil, in place of a pushed screen.
///
/// Slides down from the top over a dimmed page with a circular × floating
/// below it, the same shape the holiday and transfer flows use for their edit
/// drawers. The body is the landing form itself: reusing [InsSearchCard] in
/// its `light` mode means the two can never drift apart, and a field added to
/// one is automatically in the other.
///
/// Returns the edited query, or null when the traveller dismisses it — so the
/// caller only re-quotes on a deliberate MODIFY SEARCH.
Future<InsSearchQuery?> showInsEditSearchDrawer(
  BuildContext context, {
  required InsSearchQuery query,
  required AkInsuranceBloc bloc,
}) {
  return showGeneralDialog<InsSearchQuery>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Edit your search',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 300),
    // The bloc lives on the quotes route, so it has to be handed down
    // rather than read off the dialog's own context.
    pageBuilder: (_, __, ___) => BlocProvider<AkInsuranceBloc>.value(
      value: bloc,
      child: _InsEditSearchDrawer(query: query),
    ),
    transitionBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
        child: child,
      );
    },
  );
}

class _InsEditSearchDrawer extends StatefulWidget {
  final InsSearchQuery query;

  const _InsEditSearchDrawer({required this.query});

  @override
  State<_InsEditSearchDrawer> createState() => _InsEditSearchDrawerState();
}

class _InsEditSearchDrawerState extends State<_InsEditSearchDrawer> {
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
    final radius = Radius.circular(context.r(24));

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        // The insurance form is taller than the drawer on a short phone, and
        // the student variant taller still, so the whole drawer scrolls
        // rather than overflowing.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: radius,
                    bottomRight: radius,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // stretch, not start: the form's rows size themselves
                    // against a tight width, the way the scroll view used to
                    // hand them one on the old screen.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.w(18),
                          context.h(14),
                          context.w(18),
                          0,
                        ),
                        child: Text(
                          'Edit Your Search',
                          style: TextStyle(
                            fontSize: context.fs(18),
                            fontWeight: FontWeight.w600,
                            color: InsTokens.navy,
                          ),
                        ),
                      ),
                      _form(context),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.h(14)),
              // Close — floats outside the drawer, bottom centre.
              _closeButton(context),
              SizedBox(height: context.h(16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return BlocBuilder<CountryBloc, CountryState>(
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

            return InsSearchCard(
              light: true,
              ctaLabel: 'MODIFY SEARCH',
              query: _query,
              // The checklist is already cached by the time this drawer
              // opens; if it somehow isn't, keep at least the current type
              // so the tab row is never empty.
              policyTypes: types.isEmpty ? [_query.policyType] : types,
              countries: countries,
              heroImage: null,
              onChanged: (q) => setState(() => _query = q),
              onExplore: _modify,
            );
          },
        );
      },
    );
  }

  Widget _closeButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: context.w(38),
        height: context.w(38),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          size: context.w(21),
          color: InsTokens.navy,
        ),
      ),
    );
  }
}
