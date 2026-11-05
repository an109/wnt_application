import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import '../widgets/visa_flag.dart';

/// Countries that require a visa-type selection screen before the main flow.
/// Add country codes here to enable the intermediate screen.
const Set<String> visaTypeSelectionCountries = {'AE'};

/// Intermediate screen shown after [VisaLandingScreen] for countries in
/// [visaTypeSelectionCountries]. The traveller picks a visa type; the rest
/// of the flow proceeds as usual with the chosen type.
class VisaTypeSelectionScreen extends StatefulWidget {
  final VisaPopularDestinationEntity destination;

  const VisaTypeSelectionScreen({super.key, required this.destination});

  static MaterialPageRoute<VisaTypeEntity> route(VisaPopularDestinationEntity destination) =>
      MaterialPageRoute<VisaTypeEntity>(builder: (_) => VisaTypeSelectionScreen(destination: destination));

  @override
  State<VisaTypeSelectionScreen> createState() => _VisaTypeSelectionScreenState();
}

class _VisaTypeSelectionScreenState extends State<VisaTypeSelectionScreen> {
  int? _selectedIndex;

  VisaPopularDestinationEntity get _d => widget.destination;
  List<VisaTypeEntity> get _types => _d.visaTypes;

  void _onSelect(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onContinue() {
    if (_selectedIndex == null) return;
    Navigator.pop(context, _types[_selectedIndex!]);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          SizedBox(height: top),
          _appBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _header(),
                const SizedBox(height: 28),
                Text(
                  'Select Visa Type',
                  style: visaText(15, weight: FontWeight.w700, color: const Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the type of visa that suits your travel needs',
                  style: visaText(12, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                for (int i = 0; i < _types.length; i++) ...[
                  _VisaTypeCard(
                    type: _types[i],
                    destination: _d,
                    selected: _selectedIndex == i,
                    onTap: () => _onSelect(i),
                  ),
                  if (i < _types.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          _bottomButton(bottom),
        ],
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_d.shortName} Visa',
            style: visaText(16, weight: FontWeight.w600, color: const Color(0xFF111827)),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F6FA)],
        ),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          VisaFlag(countryCode: _d.countryCode, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _d.shortName,
                  style: GoogleFonts.goblinOne(
                    fontSize: 20,
                    color: const Color(0xFF111827),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_types.length} visa type${_types.length == 1 ? '' : 's'} available',
                  style: visaText(12, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton(double bottomPadding) {
    final enabled = _selectedIndex != null;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6FA),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: GestureDetector(
        onTap: enabled ? _onContinue : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: enabled
                ? const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFF07A2D)])
                : null,
            color: enabled ? null : const Color(0xFFE5E7EB),
          ),
          child: Text(
            'Continue',
            style: visaText(
              15,
              weight: FontWeight.w700,
              color: enabled ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisaTypeCard extends StatelessWidget {
  final VisaTypeEntity type;
  final VisaPopularDestinationEntity destination;
  final bool selected;
  final VoidCallback onTap;

  const _VisaTypeCard({
    required this.type,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kind = destination.kindOf(type);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? const Color(0xFFFFF4EE) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFFFF6B35) : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    type.title,
                    style: visaText(14, weight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                ),
                _radio(selected),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(Icons.payments_outlined, type.feeLabel),
                const SizedBox(width: 8),
                if (type.processing.isNotEmpty)
                  _chip(Icons.schedule, type.processing),
              ],
            ),
            if (type.stay.isNotEmpty || type.entry.isNotEmpty || type.validity.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFF9FAFB),
                ),
                child: Row(
                  children: [
                    if (type.stay.isNotEmpty)
                      _detail('Max Stay', type.stay),
                    if (type.entry.isNotEmpty) ...[
                      if (type.stay.isNotEmpty) _vertDivider(),
                      _detail('Entry', type.entry),
                    ],
                    if (type.validity.isNotEmpty) ...[
                      if (type.stay.isNotEmpty || type.entry.isNotEmpty) _vertDivider(),
                      _detail('Validity', type.validity),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _kindColor(kind).withOpacity(0.12),
              ),
              child: Text(
                kind.badge,
                style: visaText(10, weight: FontWeight.w700, color: _kindColor(kind)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool on) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? const Color(0xFFFF6B35) : const Color(0xFFD1D5DB),
          width: 2,
        ),
      ),
      child: on
          ? Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF6B35),
          ),
        ),
      )
          : null,
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFF3F4F6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(label, style: visaText(11, weight: FontWeight.w600, color: const Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: visaText(9, weight: FontWeight.w500, color: const Color(0xFF9CA3AF))),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: visaText(11, weight: FontWeight.w600, color: const Color(0xFF111827)),
          ),
        ],
      ),
    );
  }

  Widget _vertDivider() {
    return Container(width: 1, height: 28, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  Color _kindColor(VisaKind kind) => switch (kind) {
    VisaKind.visaFree => const Color(0xFF22C55E),
    VisaKind.onArrival => const Color(0xFF3B82F6),
    VisaKind.eVisa => const Color(0xFFA855F7),
    VisaKind.sticker => const Color(0xFFEAB308),
  };
}
