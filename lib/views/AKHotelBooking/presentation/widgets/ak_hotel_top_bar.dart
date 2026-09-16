import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

/// Replaces [AkHotelResultsScreen]'s old AppBar with the destination /
/// dates / guests summary card + currency chip from the Figma reference.
/// Every value shown comes from the search this screen was opened with
/// ([locationName]/[checkIn]/[checkOut]/[adults]/[children]/[roomCount], the
/// exact same widget fields the old AppBar's title used) or from the live
/// [CurrencyConverter] state — nothing here is static.
class AkHotelTopBar extends StatelessWidget {
  final String locationName;
  /// 'MM/dd/yyyy', matching how every caller of [AkHotelResultsScreen]
  /// already formats these (see hotel_search_card.dart /
  /// hotel_recent_searches_section.dart).
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final int roomCount;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const AkHotelTopBar({
    super.key,
    required this.locationName,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.roomCount,
    required this.onBack,
    required this.onEdit,
  });

  String _formatDate(String raw) {
    try {
      return DateFormat('d MMM').format(DateFormat('MM/dd/yyyy').parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final guests = adults + children;
    final meta = '${_formatDate(checkIn)} - ${_formatDate(checkOut)}  |  '
        '$guests Guest${guests == 1 ? '' : 's'}  |  '
        '$roomCount Room${roomCount == 1 ? '' : 's'}';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.w(16), context.h(8), context.w(16), context.h(8)),
        child: Row(
          children: [

            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(10)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.r(8)),
                  border: Border.all(color: AppColors.lightsubhead),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(Icons.arrow_back, size: context.w(20), color: AppColors.subhead),
                    ),
                    SizedBox(width: context.w(13)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            locationName.isNotEmpty ? locationName : 'Search results',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(12),
                              fontWeight: FontWeight.w500,
                              color: AppColors.navy,
                            ),
                          ),
                          SizedBox(height: context.h(2)),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(8),
                              color: AppColors.subhead,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    GestureDetector(
                      onTap: onEdit,
                      behavior: HitTestBehavior.opaque,
                      child: Image.asset(
                          'assets/NewIcons/edit.png',
                          width: context.w(15.83),
                          height: context.h(15.83),
                          color: AppColors.AppBlue
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: context.w(10)),
            const _CurrencyChip(),
          ],
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: CurrencyConverter.currencyListenable,
      builder: (context, currency, _) {
        return GestureDetector(
          onTap: () => _showCurrencyPicker(context, currency),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(10)),
            decoration: BoxDecoration(
              color: AppColors.AppBlue,
              borderRadius: BorderRadius.circular(context.r(10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FlagGlyph(currency: currency),
                SizedBox(width: context.w(5)),
                Text(
                  CurrencyConverter.getSymbol(currency),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: context.fs(13)),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: context.w(16)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context, String current) {
    final selected = CurrencyConverter.isAutoDetectEnabled() ? 'AUTO' : current;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: EdgeInsets.all(sheetContext.gapMedium),
            padding: EdgeInsets.symmetric(horizontal: sheetContext.gapLarge, vertical: sheetContext.gapMedium),
            constraints: BoxConstraints(maxHeight: sheetContext.screenHeight * 0.6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(sheetContext.r(16))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose currency',
                  style: TextStyle(fontSize: sheetContext.titleLarge, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                SizedBox(height: sheetContext.gapSmall),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: 'AUTO',
                          groupValue: selected,
                          activeColor: AppColors.AppBlue,
                          title: const Text('Auto (detect by location)'),
                          onChanged: (_) async {
                            Navigator.pop(sheetContext);
                            await CurrencyConverter.enableAutoDetect();
                          },
                        ),
                        const Divider(height: 1),
                        for (final entry in CurrencyConverter.supportedCurrencies.entries)
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: entry.key,
                            groupValue: selected,
                            activeColor: AppColors.AppBlue,
                            title: Text('${entry.key} · ${entry.value}'),
                            onChanged: (_) async {
                              Navigator.pop(sheetContext);
                              await CurrencyConverter.setManualCurrency(entry.key);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small drawn tricolor for INR (the app has no flag asset/package); every
/// other currency falls back to a generic globe glyph rather than guessing
/// a country.
class _FlagGlyph extends StatelessWidget {
  final String currency;
  const _FlagGlyph({required this.currency});

  @override
  Widget build(BuildContext context) {
    if (currency != 'INR') {
      return Icon(Icons.public, color: Colors.white, size: context.w(14));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.r(2)),
      child: SizedBox(
        width: context.w(16),
        height: context.w(11),
        child: Column(
          children: [
            Expanded(child: Container(color: const Color(0xFFFF9933))),
            Expanded(child: Container(color: Colors.white)),
            Expanded(child: Container(color: const Color(0xFF138808))),
          ],
        ),
      ),
    );
  }
}
