import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import '../widgets/visa_home_widgets.dart';
import 'visa_landing_screen.dart';

/// Search Visa Destination (Figma 1811:7672).
class VisaSearchScreen extends StatefulWidget {
  final List<VisaPopularDestinationEntity> destinations;
  final bool startWithVoice;

  const VisaSearchScreen({super.key, required this.destinations, this.startWithVoice = false});

  @override
  State<VisaSearchScreen> createState() => _VisaSearchScreenState();
}

class _VisaSearchScreenState extends State<VisaSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _query = _controller.text.trim().toLowerCase()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startWithVoice) {
        _toggleVoice();
      } else {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    bool available = false;
    try {
      available = await _speech.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) setState(() => _listening = false);
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    } catch (_) {}
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice search is unavailable. Please allow microphone access.')),
      );
      return;
    }
    _focus.unfocus();
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(partialResults: true),
      onResult: (r) {
        if (!mounted) return;
        _controller.value = TextEditingValue(
          text: r.recognizedWords,
          selection: TextSelection.collapsed(offset: r.recognizedWords.length),
        );
      },
    );
  }

  void _open(VisaPopularDestinationEntity d) {
    Navigator.push(context, VisaLandingScreen.route(d));
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.destinations;
    final popular = all.where((d) => d.showInPopular && d.cardImage.isNotEmpty).toList();
    final List<VisaPopularDestinationEntity> list;
    if (_query.isEmpty) {
      // Trending: the admin's popular picks first, fastest visas first.
      list = [...popular]..sort((a, b) {
          final pa = a.fastestProcessing?.duration ?? const Duration(days: 999);
          final pb = b.fastestProcessing?.duration ?? const Duration(days: 999);
          return pa.compareTo(pb);
        });
    } else {
      list = all
          .where((d) =>
              d.name.toLowerCase().contains(_query) ||
              d.shortName.toLowerCase().contains(_query) ||
              d.region.toLowerCase().contains(_query))
          .toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 21, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xD6FFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: VisaColors.primary),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SvgPicture.asset(
                          'assets/visa/ic_back.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(VisaColors.text, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        textInputAction: TextInputAction.search,
                        style: visaText(12, weight: FontWeight.w500, color: VisaColors.title),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          hintText: _listening ? 'Listening…' : 'Starting Destination...',
                          hintStyle: visaText(10, weight: FontWeight.w500, color: VisaColors.text),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleVoice,
                      child: Icon(
                        _listening ? Icons.mic : Icons.mic_none,
                        size: 20,
                        color: _listening ? VisaColors.red : VisaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 34, bottom: 24),
                children: [
                  if (_query.isEmpty && popular.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Popular Destination', style: visaText(12, weight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 16),
                    VisaPopularCircles(destinations: popular, onTap: _open),
                    const SizedBox(height: 34),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _query.isEmpty ? 'Trending Search' : '${list.length} result${list.length == 1 ? '' : 's'}',
                      style: visaText(12, weight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No visa destinations found',
                          textAlign: TextAlign.center, style: visaText(12, color: VisaColors.text)),
                    ),
                  for (var i = 0; i < list.length; i++) _row(list[i], last: i == list.length - 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(VisaPopularDestinationEntity d, {required bool last}) {
    final p = d.fastestProcessing;
    return InkWell(
      onTap: () => _open(d),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: VisaColors.stroke, width: 0.2)),
        ),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 28,
                height: 28,
                child: d.cardImage.isEmpty
                    ? Container(color: const Color(0xFFCBD5E1))
                    : CachedNetworkImage(imageUrl: d.cardImage, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.shortName, style: visaText(12, weight: FontWeight.w600)),
                  Text(
                    p == null ? (d.processingTime.isEmpty ? 'On request' : d.processingTime) : 'Visa in ${p.humanized}',
                    style: visaText(8, color: VisaColors.teal),
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
