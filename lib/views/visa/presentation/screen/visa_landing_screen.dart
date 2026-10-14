import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../../data/visa_draft_store.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import '../widgets/visa_flag.dart';
import 'visa_application_form_screen.dart';
import 'visa_apply_flow_screen.dart';
import 'visa_cost_info_screen.dart';
import 'visa_info_screen.dart';

/// Destination landing (Figma "Free visa card 1" / "Free visa card 2").
class VisaLandingScreen extends StatefulWidget {
  /// Checkout returns here after a successful submit.
  static const routeName = 'visa_landing';

  final VisaPopularDestinationEntity destination;
  const VisaLandingScreen({super.key, required this.destination});

  static Route<void> route(VisaPopularDestinationEntity destination) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (_) => VisaLandingScreen(destination: destination),
      );

  @override
  State<VisaLandingScreen> createState() => _VisaLandingScreenState();
}

class _VisaLandingScreenState extends State<VisaLandingScreen> {
  Map<String, dynamic>? _draft;

  VisaPopularDestinationEntity get _d => widget.destination;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await VisaDraftStore.load(_d.id);
    if (mounted) setState(() => _draft = draft);
  }

  Future<void> _start({bool resume = false}) async {
    if (_d.visaTypes.isEmpty) {
      _openInfo();
      return;
    }
    final primary = _d.primaryType!;
    if (!resume && !_d.usesEntryFormFlow(primary)) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VisaApplyFlowScreen(destination: _d, visaType: primary)),
      );
      return;
    }
    if (!resume) await VisaDraftStore.clear(_d.id);
    if (!mounted) return;
    final draftTitle = resume ? (_draft?['visaTitle']) : null;
    final type = _d.visaTypes.where((t) => t.title == draftTitle).firstOrNull ?? _d.primaryType!;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisaApplicationFormScreen(
          destination: _d,
          visaType: type,
          draft: resume ? _draft : null,
        ),
      ),
    );
    _loadDraft();
  }

  /// Visa-free / on-arrival visas get the entry-form page (Thailand TDAC
  /// design); every other visa gets the cost-visa page (Indonesia design).
  Future<void> _openInfo() async {
    final type = _d.primaryType;
    final entryForm = type != null && _d.usesEntryFormFlow(type);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => entryForm ? VisaInfoScreen(destination: _d) : VisaCostInfoScreen(destination: _d),
      ),
    );
    _loadDraft();
  }

  @override
  Widget build(BuildContext context) {
    final type = _d.primaryType;
    final processing = type?.parsedProcessing ?? _d.fastestProcessing;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _background(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.35, -1),
                end: Alignment(0.35, 1),
                colors: [Color(0x3D000000), Color(0x3D000000), Color(0x3DFFFFFF)],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          Positioned(
            top: top + 24,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: Colors.white.withOpacity(0.7), width: 0.8),
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SvgPicture.asset('assets/visa/ic_back.svg', width: 22, height: 22),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 115,
            left: 16,
            right: 16,
            child: Column(
              children: [
                VisaFlag(countryCode: _d.countryCode, size: 101),
                const SizedBox(height: 12),
                Text(
                  '${_d.shortName} Visa',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.goblinOne(fontSize: 24, color: VisaColors.red, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  processing == null ? 'made simple' : 'guaranteed in ${processing.humanized}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.goblinOne(fontSize: 20, color: Colors.white, letterSpacing: 1),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 339,
            left: 0,
            right: 0,
            child: Center(child: _draft == null ? _startBubble() : _resumeActions()),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _openInfo,
                child: Container(
                  width: 149,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('VIEW MORE INFO', style: visaText(12, weight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    const fallback = Image(image: AssetImage('assets/visa/free_visa_bg.jpg'), fit: BoxFit.cover);
    final url = _d.heroImage;
    if (url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }

  Widget _startBubble() {
    return GestureDetector(
      onTap: _start,
      child: SizedBox(
        width: 143,
        height: 143,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/visa/free_visa_start_btn.gif', width: 143, height: 143, fit: BoxFit.cover),
            SvgPicture.asset('assets/visa/free_visa_start_ring.svg', width: 88, height: 88),
            SizedBox(
              width: 90,
              child: Text(
                'START NOW',
                textAlign: TextAlign.center,
                style: visaText(16, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumeActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 93),
        GestureDetector(
          onTap: () => _start(resume: true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0x8A80DAFF), Color(0x8AFFFFFF)],
              ),
            ),
            child: Text('RESUME APPLICATION', style: visaText(12, weight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 11),
        GestureDetector(
          onTap: _start,
          child: Column(
            children: [
              Text('START NEW', style: visaText(12, weight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 2),
              Container(width: 74, height: 1, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }
}
