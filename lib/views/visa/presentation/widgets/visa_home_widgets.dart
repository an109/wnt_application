import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import 'visa_flag.dart';

/// One option of a filter dropdown; a null [value] means "any".
class VisaFilterOption<T> {
  final T? value;
  final String label;
  final int count;
  const VisaFilterOption(this.value, this.label, this.count);
}

/// White pill filter of the Visa home hero (Figma 1892:7340).
class VisaFilterChip extends StatelessWidget {
  final String iconAsset;
  final double iconWidth;
  final double iconHeight;
  final String label;
  final String value;
  final bool active;
  final void Function(BuildContext chipContext) onTap;

  const VisaFilterChip({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.onTap,
    this.active = false,
    this.iconWidth = 20,
    this.iconHeight = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (chipContext) => GestureDetector(
        onTap: () => onTap(chipContext),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: active ? VisaColors.primary : Colors.white),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(iconAsset, width: iconWidth, height: iconHeight),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 60.5, maxWidth: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: visaText(8, weight: FontWeight.w600, color: VisaColors.text),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: visaText(12, weight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 5),
                        RotatedBox(
                          quarterTurns: 1,
                          child: SvgPicture.asset(
                            'assets/visa/ic_chevron.svg',
                            width: 3.85,
                            height: 6.51,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown of a filter chip (Figma "Visa type" / "type" / "Docume…").
Future<VisaFilterOption<T>?> showVisaFilterMenu<T>(
  BuildContext chipContext,
  List<VisaFilterOption<T>> options,
  T? selected,
) {
  final box = chipContext.findRenderObject() as RenderBox;
  final overlay = Overlay.of(chipContext).context.findRenderObject() as RenderBox;
  final topLeft = box.localToGlobal(Offset(0, box.size.height + 6), ancestor: overlay);
  return showMenu<VisaFilterOption<T>>(
    context: chipContext,
    color: Colors.white,
    elevation: 6,
    constraints: const BoxConstraints(minWidth: 150, maxWidth: 230),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    position: RelativeRect.fromRect(
      topLeft & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: [
      for (final o in options)
        PopupMenuItem<VisaFilterOption<T>>(
          value: o,
          height: 34,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: o.label,
                  style: visaText(10,
                      weight: o.value == selected ? FontWeight.w600 : FontWeight.w500,
                      color: o.value == selected ? VisaColors.primary : VisaColors.title),
                ),
                TextSpan(text: '  (${o.count})', style: visaText(10, color: VisaColors.text)),
              ],
            ),
          ),
        ),
    ],
  );
}

/// Horizontal row of round destination photos (Figma 1811:7636).
class VisaPopularCircles extends StatelessWidget {
  final List<VisaPopularDestinationEntity> destinations;
  final ValueChanged<VisaPopularDestinationEntity> onTap;

  const VisaPopularCircles({super.key, required this.destinations, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: destinations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (_, i) {
          final d = destinations[i];
          return GestureDetector(
            onTap: () => onTap(d),
            child: SizedBox(
              width: 54,
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 4))],
                    ),
                    child: ClipOval(child: _photo(d.cardImage)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d.shortName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: visaText(12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _photo(String url, {String? fallbackAsset}) {
  if (url.isEmpty) {
    return fallbackAsset != null
        ? Image.asset(fallbackAsset, fit: BoxFit.cover)
        : Container(color: const Color(0xFFCBD5E1));
  }
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (_, __) => Container(color: const Color(0xFFE2E8F0)),
    errorWidget: (_, __, ___) => fallbackAsset != null
        ? Image.asset(fallbackAsset, fit: BoxFit.cover)
        : Container(color: const Color(0xFFCBD5E1)),
  );
}

/// "Even The Toughest Visas. Made Simpler" carousel (Figma 1807:7504).
class VisaToughCarousel extends StatefulWidget {
  final List<VisaPopularDestinationEntity> destinations;
  final ValueChanged<VisaPopularDestinationEntity> onOpen;

  const VisaToughCarousel({super.key, required this.destinations, required this.onOpen});

  @override
  State<VisaToughCarousel> createState() => _VisaToughCarouselState();
}

class _VisaToughCarouselState extends State<VisaToughCarousel> {
  static const _fallbacks = [
    'assets/visa/visa_tough_1.jpg',
    'assets/visa/visa_tough_2.jpg',
    'assets/visa/visa_tough_3.jpg',
  ];
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 224 / 412, initialPage: _initialPage);
    _page = _initialPage;
  }

  int get _initialPage => widget.destinations.length > 1 ? 1 : 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return ClipRect(
      child: SizedBox(
        height: 400,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              height: 244,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.destinations.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _card(widget.destinations[i], _fallbacks[i % _fallbacks.length]),
                ),
              ),
            ),
            // Curved edges that make the strip look like a lens.
            Positioned(
              top: 0,
              left: (width - 770) / 2 + 11.5,
              width: 770,
              height: 135,
              child: IgnorePointer(
                child: SvgPicture.asset('assets/visa/visa_curve_top.svg', width: 770, height: 135),
              ),
            ),
            Positioned(
              top: 352,
              left: (width - 770) / 2,
              width: 770,
              height: 135,
              child: IgnorePointer(
                child: SvgPicture.asset('assets/visa/visa_curve_bottom.svg', width: 770, height: 135),
              ),
            ),
            Positioned(
              top: 85,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Even The Toughest Visas.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.marcellusSc(fontSize: 14, height: 20 / 14, letterSpacing: 2.1),
                  ),
                  Text(
                    'Made Simpler',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.marcellusSc(fontSize: 14, height: 20 / 14, letterSpacing: 2.4),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 368,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: widget.destinations.isEmpty
                      ? null
                      : () => widget.onOpen(widget.destinations[_page]),
                  child: SizedBox(
                    width: 92,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: VisaColors.primary, width: 0.5)),
                          ),
                          child: Text('KNOW MORE',
                              style: visaText(11, weight: FontWeight.w600, color: VisaColors.primary)),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xD6FFFFFF),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: const Color(0x3D000000), width: 2),
                            boxShadow: const [BoxShadow(color: VisaColors.primaryLight, blurRadius: 8.1)],
                          ),
                          child: Transform.rotate(
                            angle: 1.5708,
                            child: SvgPicture.asset('assets/visa/ic_arrow_small.svg', width: 12, height: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(VisaPopularDestinationEntity d, String fallback) {
    final processing = d.fastestProcessing;
    return GestureDetector(
      onTap: () => widget.onOpen(d),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFCBD5E1)),
            _photo(d.cardImage, fallbackAsset: fallback),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ),
              ),
            ),
            Positioned(
              top: 156,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  VisaFlag(countryCode: d.countryCode, size: 24),
                  const SizedBox(height: 6),
                  Text(d.shortName.toUpperCase(),
                      style: visaText(12, weight: FontWeight.w700, color: Colors.white)),
                  Text(
                    processing == null ? 'VISA MADE EASY' : 'VISA IN ${processing.humanized.toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'CaveatBrush',
                      fontSize: 10,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
