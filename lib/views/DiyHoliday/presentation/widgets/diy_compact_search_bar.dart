import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/diy_search_query.dart';
import 'diy_common.dart';
import 'diy_trip_day_card.dart';

/// The search, folded down to one line once the full form has scrolled out
/// of sight — Figma `On scroll Holiday` and `on scroll select Holiday 2`.
///
/// On the home screen it carries SEARCH ([onSearch]); on the results it
/// carries the edit pencil ([onEdit]). Tapping the summary itself calls
/// [onTapSummary], which the home screen uses to scroll back to the form.
class DiyCompactSearchBar extends StatelessWidget {
  final DiySearchQuery query;
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final VoidCallback? onEdit;
  final VoidCallback? onTapSummary;

  const DiyCompactSearchBar({
    super.key,
    required this.query,
    this.title = 'Holiday',
    this.onBack,
    this.onSearch,
    this.onEdit,
    this.onTapSummary,
  });

  String get _route =>
      '${query.origin.name} - ${query.destination?.name ?? 'Anywhere'}';

  String get _details {
    final d = query.departureDate;
    final people = [
      '${query.adults} Adult${query.adults == 1 ? '' : 's'}',
      if (query.children > 0)
        '${query.children} Child${query.children == 1 ? '' : 'ren'}',
    ].join(', ');
    return [
      if (d != null) DateFormat('d MMM yyyy, EEEE').format(d),
      people,
    ].join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(14),
            context.h(10),
            context.w(14),
            context.h(12),
          ),
          child: onEdit != null
              ? _editVariant(context)
              : _searchVariant(context),
        ),
      ),
    );
  }

  /// Home: back + title, the route and party, then a full-width SEARCH.
  Widget _searchVariant(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null)
              GestureDetector(
                onTap: onBack,
                child: Padding(
                  padding: EdgeInsets.only(right: context.w(10)),
                  child: Icon(
                    Icons.arrow_back,
                    size: context.w(20),
                    color: Colors.black,
                  ),
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(10)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTapSummary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _route,
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                _details,
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: DiyTripStyle.grey,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(10)),
        SizedBox(
          width: double.infinity,
          height: context.h(40),
          child: ElevatedButton(
            onPressed: onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: DiyTripStyle.orange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
            ),
            child: Text(
              'SEARCH',
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Results: one outlined field — back, the route and party, edit.
  Widget _editVariant(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(8),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: DiyTokens.blue),
      ),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Padding(
                padding: EdgeInsets.only(right: context.w(10)),
                child: Icon(
                  Icons.arrow_back,
                  size: context.w(20),
                  color: Colors.black,
                ),
              ),
            ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${query.origin.name} To ${query.destination?.name ?? 'Anywhere'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(9),
                      color: DiyTripStyle.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Icon(
              Icons.edit_rounded,
              size: context.w(18),
              color: DiyTokens.blue,
            ),
          ),
        ],
      ),
    );
  }
}
