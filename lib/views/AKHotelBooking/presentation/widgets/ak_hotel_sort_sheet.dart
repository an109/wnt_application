import 'package:flutter/material.dart';
import 'package:wander_nova/newUIWidgets/sheetActionButtons.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';

/// Purely additive, client-side-only sort layered on top of whatever list is
/// already showing (already filtered/searched). Never touches the existing
/// fetch/filter/search pipeline — just reorders its output for display.
/// `null` (no option picked — "Popularity" in the sheet) means "leave the
/// order Content/Rate already returned alone".
enum AkHotelSortOption { priceLowToHigh, priceHighToLow, ratingHighToLow, lowestPriceBestRated }

extension AkHotelSortOptionLabel on AkHotelSortOption {
  String get label {
    switch (this) {
      case AkHotelSortOption.priceLowToHigh:
        return 'Price (Low to High)';
      case AkHotelSortOption.priceHighToLow:
        return 'Price (High to Low)';
      case AkHotelSortOption.ratingHighToLow:
        return 'User Rating (Highest First)';
      case AkHotelSortOption.lowestPriceBestRated:
        return 'Lowest Price & Best Rated';
    }
  }
}

List<HotelUiModel> applyAkHotelSort(List<HotelUiModel> hotels, AkHotelSortOption? option) {
  if (option == null) return hotels;
  final sorted = [...hotels];
  switch (option) {
    case AkHotelSortOption.priceLowToHigh:
      sorted.sort((a, b) => a.numericPrice.compareTo(b.numericPrice));
      break;
    case AkHotelSortOption.priceHighToLow:
      sorted.sort((a, b) => b.numericPrice.compareTo(a.numericPrice));
      break;
    case AkHotelSortOption.ratingHighToLow:
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case AkHotelSortOption.lowestPriceBestRated:
      // A real combination of the two real fields (price, rating) — each
      // star shaves 10% off the "effective" price so a cheap-but-poor hotel
      // doesn't automatically outrank a slightly pricier, much better one.
      double value(HotelUiModel h) => h.numericPrice * (1 - (h.rating.clamp(0, 5) * 0.1));
      sorted.sort((a, b) => value(a).compareTo(value(b)));
      break;
  }
  return sorted;
}

/// Bottom sheet used by both [AkHotelResultsScreen] and
/// [AkHotelViewAllScreen] to pick/clear [AkHotelSortOption] — Figma
/// reference: drag handle, "Sort by" label, one radio-per-row with the
/// control on the trailing edge, Reset/Done at the bottom, and a circular
/// close (✕) button floating just above the sheet's own top edge.
/// Selecting a row is tentative until Done is tapped; Reset clears back to
/// "Popularity" (no sort) without closing the sheet.
Future<void> showAkHotelSortSheet({
  required BuildContext context,
  required AkHotelSortOption? current,
  required ValueChanged<AkHotelSortOption?> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _AkHotelSortSheetContent(current: current, onSelected: onSelected);
    },
  );
}

class _AkHotelSortSheetContent extends StatefulWidget {
  final AkHotelSortOption? current;
  final ValueChanged<AkHotelSortOption?> onSelected;

  const _AkHotelSortSheetContent({required this.current, required this.onSelected});

  @override
  State<_AkHotelSortSheetContent> createState() => _AkHotelSortSheetContentState();
}

class _AkHotelSortSheetContentState extends State<_AkHotelSortSheetContent> {
  late AkHotelSortOption? _pending = widget.current;

  static const _muted = AppColors.subhead;

  void _apply() {
    Navigator.pop(context);
    widget.onSelected(_pending);
  }

  @override
  Widget build(BuildContext context) {
    // Reserves room above the white sheet for the close button so it can
    // sit visually outside/above the card instead of inside its padding.
    const closeButtonSpace = 48.0;

    // No SafeArea here on purpose: the caller asked for the sheet flush
    // against the bottom of the screen, with no reserved gap for the
    // device's bottom inset (home indicator / gesture bar).
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topRight,
      children: [
        Padding(
          padding: EdgeInsets.only(top: context.h(closeButtonSpace)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(context.gapLarge, context.gapMedium, context.gapLarge, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(24))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: context.w(56),
                    height: context.h(5),
                    margin: EdgeInsets.only(bottom: context.gapLarge),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9E0),
                      borderRadius: BorderRadius.circular(context.r(4)),
                    ),
                  ),
                ),
                Text(
                  'Sort by',
                  style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: _muted),
                ),
                SizedBox(height: context.gapMedium),
                // "Popularity" carries no AkHotelSortOption of its own —
                // it *is* the null/no-sort state, i.e. Content/Rate's own
                // order.
                _optionRow(label: 'Popularity', value: null),
                for (final option in AkHotelSortOption.values) _optionRow(label: option.label, value: option),
                SheetActionButtons(
                  onSecondary: () => setState(() => _pending = null),
                  onPrimary: _apply,
                  primaryColor: AppColors.OrangeColor,
                  padding: EdgeInsets.only(top: context.h(8)),
                ),
                SizedBox(height: context.gapLarge),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: context.gapLarge,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: context.w(32),
              height: context.w(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.close_rounded, size: context.w(16), color: AppColors.navy),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionRow({required String label, required AkHotelSortOption? value}) {
    final selected = _pending == value;
    return InkWell(
      onTap: () => setState(() => _pending = value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(14)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ),
            _radioCircle(selected),
          ],
        ),
      ),
    );
  }

  Widget _radioCircle(bool selected) {
    return Container(
      width: context.w(18),
      height: context.w(18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.AppBlue : const Color(0xFFD9D9E0), width: 1),
        color: Colors.white,
      ),
      child: selected
          ? Center(
              child: Container(
                width: context.w(11),
                height: context.w(11),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.AppBlue),
              ),
            )
          : null,
    );
  }
}
