import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/models/diy_models.dart';
import 'diy_common.dart';

/// One row of the search results — the package summary returned by
/// **API 3 — GET /packages/**.
class DiyPackageCard extends StatelessWidget {
  final DiyPackageSummary package;
  final bool withFlight;
  final VoidCallback onTap;

  const DiyPackageCard({
    super.key,
    required this.package,
    required this.withFlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = package.priceFor(withFlight);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                DiyImage(
                  url: package.image,
                  width: double.infinity,
                  height: context.h(150),
                ),
                Positioned(
                  left: context.w(10),
                  top: context.h(10),
                  child: _badge(
                    context,
                    '${package.days}D / ${package.nights}N',
                    background: Colors.black.withOpacity(0.55),
                  ),
                ),
                if (package.hasCabItinerary)
                  Positioned(
                    right: context.w(10),
                    top: context.h(10),
                    child: _badge(
                      context,
                      'Cab included',
                      background: DiyTokens.blue.withOpacity(0.92),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(context.w(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w700,
                      color: DiyTokens.navy,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Row(
                    children: [
                      Icon(
                        Icons.flight_takeoff_rounded,
                        size: context.w(13),
                        color: DiyTokens.subGrey,
                      ),
                      SizedBox(width: context.w(5)),
                      Expanded(
                        child: Text(
                          'From ${package.origin} · ${package.destination}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(11.5),
                            color: DiyTokens.subGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (package.themes.isNotEmpty) ...[
                    SizedBox(height: context.h(8)),
                    Wrap(
                      spacing: context.w(6),
                      runSpacing: context.h(6),
                      children: [
                        for (final theme in package.themes)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(8),
                              vertical: context.h(3),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F4F9),
                              borderRadius:
                                  BorderRadius.circular(context.r(20)),
                            ),
                            child: Text(
                              theme,
                              style: TextStyle(
                                fontSize: context.fs(10),
                                fontWeight: FontWeight.w600,
                                color: DiyTokens.subGrey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  SizedBox(height: context.h(10)),
                  const Divider(height: 1, color: DiyTokens.line),
                  SizedBox(height: context.h(10)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              withFlight
                                  ? 'Total with flight'
                                  : 'Total without flight',
                              style: TextStyle(
                                fontSize: context.fs(10),
                                color: DiyTokens.labelGrey,
                              ),
                            ),
                            SizedBox(height: context.h(2)),
                            Text(
                              diyMoney(price, currency: package.currency),
                              style: TextStyle(
                                fontSize: context.fs(18),
                                fontWeight: FontWeight.w800,
                                color: DiyTokens.navy,
                              ),
                            ),
                            Text(
                              'for ${package.adults} adult'
                              '${package.adults == 1 ? '' : 's'}'
                              '${package.children > 0 ? ' + ${package.children} child' : ''}',
                              style: TextStyle(
                                fontSize: context.fs(10),
                                color: DiyTokens.subGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(14),
                          vertical: context.h(8),
                        ),
                        decoration: BoxDecoration(
                          color: DiyTokens.orange,
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                        child: Text(
                          'View',
                          style: TextStyle(
                            fontSize: context.fs(13),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (package.priceIsStale) ...[
                    SizedBox(height: context.h(8)),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: context.w(13),
                          color: DiyTokens.orange,
                        ),
                        SizedBox(width: context.w(5)),
                        Expanded(
                          child: Text(
                            'Indicative price — we will reprice it for your dates.',
                            style: TextStyle(
                              fontSize: context.fs(10),
                              color: DiyTokens.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, String text, {required Color background}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.r(20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(10),
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
