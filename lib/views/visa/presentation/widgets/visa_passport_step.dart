import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../data/visa_passport_image.dart';
import '../../data/visa_passport_reader.dart';
import '../utils/visa_camera.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';

/// What a scan produced: the photo and the verified data read from it.
class VisaPassportScan {
  final String path;
  final VisaMrz mrz;
  final VisaPassportFront front;
  const VisaPassportScan(this.path, {required this.mrz, required this.front});
}

/// What a scan of the passport's back page produced.
class VisaPassportBackScan {
  final String path;
  final VisaPassportBack back;
  const VisaPassportBackScan(this.path, this.back);
}

enum _Phase { camera, reading, review, failed }

/// Passport step: the traveller photographs the passport's photo page with
/// the shutter button (or picks a photo), the app reads it on the phone and
/// shows the extracted details for confirmation before they fill the form.
///
/// Only the photo page is needed for the application itself: everything it
/// requires is in its machine-readable zone (MRZ) — the two `<<<` lines — and
/// every value is accepted only if the MRZ check digits pass.
///
/// With [back] set the same screen photographs the BACK page of an Indian
/// passport instead and reads the parents' names and the old passport number
/// from it ([onScannedBack]); the front scan cannot supply those.
class VisaPassportStep extends StatefulWidget {
  final ValueChanged<VisaPassportScan>? onScanned;
  final ValueChanged<VisaPassportBackScan>? onScannedBack;
  final bool back;

  const VisaPassportStep({super.key, this.onScanned, this.onScannedBack, this.back = false})
      : assert(back ? onScannedBack != null : onScanned != null);

  @override
  State<VisaPassportStep> createState() => _VisaPassportStepState();
}

class _VisaPassportStepState extends State<VisaPassportStep> with WidgetsBindingObserver {
  static const _frameAspect = 1.42; // ID-3 passport page, 125 × 88 mm

  CameraController? _camera;
  final TextRecognizer _ocr = TextRecognizer(script: TextRecognitionScript.latin);

  _Phase _phase = _Phase.camera;
  String? _cameraError;
  bool _torch = false;
  bool _busy = false;
  String? _photoPath;
  VisaPassportScan? _scan;
  VisaPassportBackScan? _backScan;
  String _failure = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _ocr.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed && _phase == _Phase.camera && _camera == null) {
      _startCamera();
    }
  }

  // ---------------------------------------------------------------- camera

  Future<void> _startCamera() async {
    try {
      final c = await openVisaCamera(CameraLensDirection.back, preset: ResolutionPreset.veryHigh);
      if (!mounted) {
        await c.dispose();
        return;
      }
      try {
        await c.setFocusMode(FocusMode.auto);
        await c.setFlashMode(FlashMode.off);
      } catch (_) {}
      setState(() {
        _camera = c;
        _cameraError = null;
        _torch = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.toLowerCase().contains('denied');
      setState(() => _cameraError = denied
          ? 'Camera access is off. Allow it in Settings, or upload a photo of your passport.'
          : 'The camera could not be opened. Upload a photo of your passport instead.');
    }
  }

  Future<void> _stopCamera() async {
    final c = _camera;
    _camera = null;
    if (c == null) return;
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _toggleTorch() async {
    final c = _camera;
    if (c == null) return;
    try {
      await c.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      setState(() => _torch = !_torch);
    } catch (_) {}
  }

  Future<void> _focusAt(TapUpDetails d, Size size) async {
    final c = _camera;
    if (c == null) return;
    final p = Offset(d.localPosition.dx / size.width, d.localPosition.dy / size.height);
    try {
      await c.setFocusPoint(p);
      await c.setExposurePoint(p);
    } catch (_) {}
  }

  // ---------------------------------------------------------------- capture

  Future<void> _capture() async {
    final c = _camera;
    if (c == null || _busy || c.value.isTakingPicture) return;
    _busy = true;
    try {
      final file = await c.takePicture();
      if (_torch) {
        try {
          await c.setFlashMode(FlashMode.off);
        } catch (_) {}
      }
      await _stopCamera();
      await _read(file.path);
    } catch (_) {
      if (mounted) _showFailure(null, 'The photo could not be taken. Please try again.');
    } finally {
      _busy = false;
    }
  }

  Future<void> _upload() async {
    if (_busy) return;
    _busy = true;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      final path = result?.files.single.path;
      if (path == null) return;
      await _stopCamera();
      await _read(path);
    } finally {
      _busy = false;
    }
  }

  /// Reads the passport from the photo at [path] and moves to review, or to
  /// the failure screen with the reason. Tries the photo as taken, then
  /// prepared copies (upright, cropped, MRZ enlarged, turned) until every
  /// check digit passes; the best partial read is kept otherwise.
  Future<void> _read(String path) async {
    setState(() {
      _photoPath = path;
      _phase = _Phase.reading;
    });
    if (widget.back) return _readBack(path);
    var variants = const <String>[];
    try {
      VisaMrz? best;
      var fullText = '';
      var sawMrz = false;
      // Every pass of the OCR, kept to cross-check the names against the ones
      // printed on the photo page.
      final texts = <String>[];

      Future<void> attempt(String file) async {
        final text = (await _ocr.processImage(InputImage.fromFilePath(file))).text;
        texts.add(text);
        // The whole-photo pass carries the printed fields; keep the fullest.
        if (text.length > fullText.length) fullText = text;
        if (text.replaceAll(' ', '').contains('<<')) sawMrz = true;
        final mrz = readPassportMrz(text);
        if (mrz == null) return;
        // Verified digits first, then a readable name, then a name whose end
        // is not in doubt.
        int score(VisaMrz m) =>
            (m.fullyVerified ? 4 : 0) + (m.surname.isNotEmpty ? 2 : 0) + (m.namesAmbiguous ? 0 : 1);
        if (best == null || score(mrz) > score(best!)) best = mrz;
      }

      // Done when the digits pass and the name matches the printed one;
      // otherwise another, sharper copy of the photo may settle it.
      bool settled() {
        final b = best;
        return b != null &&
            b.fullyVerified &&
            b.surname.isNotEmpty &&
            reconcilePassportNames(b, texts).namesConfirmed;
      }

      await attempt(path);
      if (!settled()) {
        variants = await passportOcrVariants(path);
        for (final v in variants) {
          if (!mounted) return;
          await attempt(v);
          if (settled()) break;
        }
      }
      if (!mounted) return;

      // The check digits do not cover the names: compare them with the
      // printed ones and correct a letter lost or gained in the MRZ.
      final mrz = best == null ? null : reconcilePassportNames(best!, texts);
      if (mrz == null) {
        _showFailure(
          path,
          sawMrz
              ? 'We found the passport but the two lines at the bottom were not sharp enough to read.'
              : 'We could not find a passport photo page in this picture.',
        );
        return;
      }
      if (mrz.expiry.isBefore(DateTime.now())) {
        _showFailure(path, 'This passport expired on ${visaDateFormat.format(mrz.expiry)}. '
            'Please renew it before applying.');
        return;
      }
      setState(() {
        _scan = VisaPassportScan(path, mrz: mrz, front: readPassportFront(fullText, mrz));
        _phase = _Phase.review;
      });
    } catch (e) {
      debugPrint('[Passport] read failed: $e');
      if (mounted) _showFailure(path, 'This photo could not be read. Please try again.');
    } finally {
      deletePassportVariants(variants);
    }
  }

  /// Reads the back page: the parents' names, the old passport number and the
  /// file number. Tries the photo as taken, then upright/cropped/turned copies,
  /// and keeps the read that found the most.
  Future<void> _readBack(String path) async {
    var variants = const <String>[];
    try {
      VisaPassportBack? best;
      var bestScore = -1;

      Future<void> attempt(String file) async {
        final text = (await _ocr.processImage(InputImage.fromFilePath(file))).text;
        final b = readPassportBack(text);
        if (!b.looksValid) return;
        final score = (b.fatherName.isNotEmpty ? 2 : 0) +
            (b.motherName.isNotEmpty ? 2 : 0) +
            (b.fileNumber.isNotEmpty ? 1 : 0) +
            (b.oldPassportNumber.isNotEmpty ? 1 : 0);
        if (score > bestScore) {
          best = b;
          bestScore = score;
        }
      }

      await attempt(path);
      // Both parents found: nothing more to gain from another pass.
      if (bestScore < 4) {
        variants = await passportOcrVariants(path);
        // [0] upright, [1] window, [2] the MRZ band (front page only), then turned.
        for (var i = 0; i < variants.length; i++) {
          if (i == 2) continue;
          if (!mounted) return;
          await attempt(variants[i]);
          if (bestScore >= 4) break;
        }
      }
      if (!mounted) return;

      final b = best;
      if (b == null) {
        _showFailure(
          path,
          'We could not read this page. Photograph the last page of the passport — '
          'the one with the names of your father and mother and your address.',
        );
        return;
      }
      setState(() {
        _backScan = VisaPassportBackScan(path, b);
        _phase = _Phase.review;
      });
    } catch (e) {
      debugPrint('[Passport] back read failed: $e');
      if (mounted) _showFailure(path, 'This photo could not be read. Please try again.');
    } finally {
      deletePassportVariants(variants);
    }
  }

  void _showFailure(String? path, String message) {
    setState(() {
      _photoPath = path;
      _failure = message;
      _phase = _Phase.failed;
    });
  }

  void _retake() {
    setState(() {
      _scan = null;
      _backScan = null;
      _photoPath = null;
      _phase = _Phase.camera;
    });
    _startCamera();
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (_phase) {
        _Phase.camera => _cameraView(),
        _Phase.reading => _readingView(),
        _Phase.review => _reviewView(),
        _Phase.failed => _failedView(),
      },
    );
  }

  Widget _heading(String title, String subtitle) {
    return Column(
      children: [
        Text(title, style: visaText(15, weight: FontWeight.w700, color: VisaColors.title)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center, style: visaText(10, color: VisaColors.text, height: 1.4)),
      ],
    );
  }

  Widget _cameraView() {
    final c = _camera;
    final live = c != null && c.value.isInitialized;
    return Column(
      key: const ValueKey('camera'),
      children: [
        const SizedBox(height: 18),
        widget.back
            ? _heading('Scan the back of your passport',
                'Photograph the last page — the one with your father\'s\nand mother\'s names and your address')
            : _heading('Scan your passport', 'Photograph the photo page — the one with your picture\nand the two lines of <<< at the bottom'),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: const Color(0xFF0B1220),
                child: LayoutBuilder(builder: (context, box) {
                  final size = Size(box.maxWidth, box.maxHeight);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (live)
                        GestureDetector(
                          onTapUp: (d) => _focusAt(d, size),
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: c.value.previewSize?.height ?? 300,
                              height: c.value.previewSize?.width ?? 400,
                              child: CameraPreview(c),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: _cameraError != null
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.no_photography_outlined, color: Colors.white54, size: 36),
                                      const SizedBox(height: 10),
                                      Text(_cameraError!,
                                          textAlign: TextAlign.center,
                                          style: visaText(11, color: Colors.white70, height: 1.4)),
                                    ],
                                  ),
                                )
                              : const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      IgnorePointer(
                          child: CustomPaint(painter: _FramePainter(aspect: _frameAspect, mrzHint: !widget.back))),
                      if (live)
                        Positioned(
                          top: 14,
                          left: 0,
                          right: 0,
                          child: Center(
                              child: _pill(Icons.center_focus_strong,
                                  widget.back ? 'Fit the last page inside the frame' : 'Fit the photo page inside the frame')),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _tips(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _roundAction(Icons.photo_library_outlined, 'Upload', _upload),
              _shutter(enabled: live),
              _roundAction(_torch ? Icons.flash_on : Icons.flash_off, _torch ? 'Light on' : 'Light',
                  live ? _toggleTorch : null),
            ],
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: visaText(10, weight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _tips() {
    Widget tip(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: VisaColors.primary),
            const SizedBox(width: 4),
            Text(text, style: visaText(9.5, weight: FontWeight.w500, color: VisaColors.text)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        tip(Icons.wb_sunny_outlined, 'Good light, no glare'),
        tip(Icons.crop_free, 'All 4 corners visible'),
        tip(Icons.blur_off, 'Hold steady'),
      ],
    );
  }

  Widget _shutter({required bool enabled}) {
    return GestureDetector(
      onTap: enabled ? _capture : null,
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? VisaColors.primary : VisaColors.stroke, width: 3),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? VisaColors.primary : VisaColors.stroke,
          ),
          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _roundAction(IconData icon, String label, VoidCallback? onTap) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? VisaColors.primarySoft : VisaColors.surface,
            ),
            child: Icon(icon, size: 20, color: active ? VisaColors.primary : VisaColors.stroke),
          ),
          const SizedBox(height: 4),
          Text(label, style: visaText(9, weight: FontWeight.w500, color: VisaColors.text)),
        ],
      ),
    );
  }

  Widget _photo({double height = 190}) {
    final path = _photoPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFF0B1220),
        child: path == null
            ? const Icon(Icons.badge_outlined, color: Colors.white38, size: 40)
            : Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
      ),
    );
  }

  Widget _readingView() {
    return Padding(
      key: const ValueKey('reading'),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          Stack(
            children: [
              _photo(height: 220),
              const Positioned.fill(child: _ScanSweep()),
            ],
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: VisaColors.primary),
          ),
          const SizedBox(height: 14),
          _heading('Reading your passport', 'Extracting and verifying your details on this phone…'),
        ],
      ),
    );
  }

  Widget _backReviewView() {
    final scan = _backScan!;
    final b = scan.back;
    final rows = <(String, String)>[
      if (b.fatherName.isNotEmpty) ("Father's name", b.fatherName),
      if (b.motherName.isNotEmpty) ("Mother's name", b.motherName),
      if (b.spouseName.isNotEmpty) ("Spouse's name", b.spouseName),
      if (b.oldPassportNumber.isNotEmpty) ('Old passport number', b.oldPassportNumber),
      if (b.fileNumber.isNotEmpty) ('File number', b.fileNumber),
    ];
    return Column(
      key: const ValueKey('review-back'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            children: [
              _photo(height: 150),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, size: 18, color: Color(0xFFC2410C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Read from the back page — please check the names before continuing',
                        style: visaText(10.5, weight: FontWeight.w600, color: const Color(0xFF9A3412)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          border: i == rows.length - 1
                              ? null
                              : const Border(bottom: BorderSide(color: Color(0xFFF1F2F4))),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 4, child: Text(rows[i].$1, style: visaText(10.5, color: VisaColors.text))),
                            Expanded(
                              flex: 6,
                              child: Text(
                                rows[i].$2,
                                textAlign: TextAlign.right,
                                style: visaText(11.5, weight: FontWeight.w600, color: VisaColors.title),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You can correct any of these on the next screen.',
                style: visaText(9, color: VisaColors.text, height: 1.4),
              ),
            ],
          ),
        ),
        _bottomActions(
          primary: 'Use these details',
          onPrimary: () => widget.onScannedBack!(scan),
          secondary: 'Retake photo',
          onSecondary: _retake,
        ),
      ],
    );
  }

  Widget _reviewView() {
    if (widget.back) return _backReviewView();
    final scan = _scan!;
    final m = scan.mrz;
    final rows = <(String, String)>[
      ('Surname', m.surname),
      ('Given name', m.givenNames.isEmpty ? '—' : m.givenNames),
      ('Passport number', m.passportNumber),
      ('Nationality', m.nationalityName),
      ('Date of birth', visaDateFormat.format(m.dob)),
      ('Gender', m.gender),
      ('Date of expiry', visaDateFormat.format(m.expiry)),
      if (scan.front.issueDate != null) ('Date of issue', visaDateFormat.format(scan.front.issueDate!)),
      if (scan.front.placeOfBirth.isNotEmpty) ('Place of birth', scan.front.placeOfBirth),
    ];
    // A tick means the value is locked to the passport. The check digits
    // cover the number and both dates; the names only count once they match
    // the printed ones.
    final verified = m.fullyVerified
        ? {
            'Passport number', 'Nationality', 'Date of birth', 'Gender', 'Date of expiry',
            if (m.namesConfirmed) ...['Surname', 'Given name'],
          }
        : {'Passport number', 'Date of birth', 'Date of expiry'};
    final namesToCheck = !m.namesConfirmed;

    return Column(
      key: const ValueKey('review'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            children: [
              _photo(height: 150),
              const SizedBox(height: 14),
              Builder(builder: (context) {
                final allGood = m.fullyVerified && !namesToCheck;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: allGood ? VisaColors.greenSoft : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: allGood ? VisaColors.green.withValues(alpha: 0.3) : const Color(0xFFFDBA74),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(allGood ? Icons.verified_user : Icons.fact_check_outlined,
                          size: 18, color: allGood ? VisaColors.green : const Color(0xFFC2410C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          allGood
                              ? 'Passport verified — details match the machine-readable zone and the printed names'
                              : m.fullyVerified
                                  ? 'Passport number and dates verified — please check your name before continuing'
                                  : 'Details read from your passport — please check the names before continuing',
                          style: visaText(10.5,
                              weight: FontWeight.w600,
                              color: allGood ? const Color(0xFF166534) : const Color(0xFF9A3412)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          border: i == rows.length - 1
                              ? null
                              : const Border(bottom: BorderSide(color: Color(0xFFF1F2F4))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(rows[i].$1, style: visaText(10.5, color: VisaColors.text)),
                            ),
                            Expanded(
                              flex: 6,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(
                                      rows[i].$2,
                                      textAlign: TextAlign.right,
                                      style: visaText(11.5, weight: FontWeight.w600, color: VisaColors.title),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    verified.contains(rows[i].$1) ? Icons.check_circle : Icons.edit_note,
                                    size: 14,
                                    color: verified.contains(rows[i].$1) ? VisaColors.green : VisaColors.stroke,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ticked fields are locked to your passport. You can still check the others on the next screen.',
                style: visaText(9, color: VisaColors.text, height: 1.4),
              ),
            ],
          ),
        ),
        _bottomActions(
          primary: 'Use these details',
          onPrimary: () => widget.onScanned!(scan),
          secondary: 'Retake photo',
          onSecondary: _retake,
        ),
      ],
    );
  }

  Widget _failedView() {
    return Column(
      key: const ValueKey('failed'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            children: [
              if (_photoPath != null) ...[_photo(height: 150), const SizedBox(height: 14)],
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, size: 20, color: Color(0xFFB42318)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_failure, style: visaText(11, color: const Color(0xFFB42318), height: 1.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('For a successful scan', style: visaText(12, weight: FontWeight.w700, color: VisaColors.title)),
              const SizedBox(height: 10),
              for (final (icon, text) in widget.back
                  ? const [
                      (Icons.menu_book_outlined, 'Open the passport to its last page, with the names and address'),
                      (Icons.table_restaurant_outlined, 'Lay it flat on a plain, dark surface'),
                      (Icons.wb_sunny_outlined, 'Use even light — avoid glare on the page'),
                      (Icons.text_fields, 'Keep the whole page in the frame and the text sharp'),
                    ]
                  : const [
                      (Icons.menu_book_outlined, 'Open the passport to the page with your photo'),
                      (Icons.table_restaurant_outlined, 'Lay it flat on a plain, dark surface'),
                      (Icons.wb_sunny_outlined, 'Use even light — avoid glare on the plastic'),
                      (Icons.text_fields, 'Keep the two <<< lines at the bottom sharp and fully visible'),
                    ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: VisaColors.primarySoft, borderRadius: BorderRadius.circular(7)),
                        child: Icon(icon, size: 15, color: VisaColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(text, style: visaText(10.5, color: VisaColors.title))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _bottomActions(
          primary: 'Retake photo',
          onPrimary: _retake,
          secondary: 'Upload a different photo',
          onSecondary: _upload,
        ),
      ],
    );
  }

  Widget _bottomActions({
    required String primary,
    required VoidCallback onPrimary,
    required String secondary,
    required VoidCallback onSecondary,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VisaPrimaryButton(label: primary, onPressed: onPrimary),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: VisaColors.cta),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(secondary.toUpperCase(),
                    style: visaText(12, weight: FontWeight.w700, color: VisaColors.cta)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Darkens everything outside a passport-shaped window and marks the MRZ
/// band at its bottom.
class _FramePainter extends CustomPainter {
  final double aspect;

  /// Marks the MRZ band at the bottom of the frame (photo page only).
  final bool mrzHint;
  _FramePainter({required this.aspect, this.mrzHint = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.88;
    final h = w / aspect;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: w, height: h);
    final window = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(window)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // MRZ band hint.
    if (mrzHint) {
      final mrz = Rect.fromLTRB(rect.left + 10, rect.bottom - h * 0.22, rect.right - 10, rect.bottom - 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(mrz, const Radius.circular(6)),
        Paint()
          ..color = VisaColors.primaryLight.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: 'P<IND<<<<<<<<<<<<<<<<  ·  keep these lines sharp',
          style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: mrz.width - 12);
      tp.paint(canvas, Offset(mrz.left + 6, mrz.center.dy - tp.height / 2));
    }

    // Corner brackets.
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 26.0;
    for (final (x, y, dx, dy) in [
      (rect.left, rect.top, 1.0, 1.0),
      (rect.right, rect.top, -1.0, 1.0),
      (rect.left, rect.bottom, 1.0, -1.0),
      (rect.right, rect.bottom, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + dy * l)
          ..lineTo(x, y + dy * 8)
          ..quadraticBezierTo(x, y, x + dx * 8, y)
          ..lineTo(x + dx * l, y),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.aspect != aspect || old.mrzHint != mrzHint;
}

/// Light bar sweeping over the photo while it is being read.
class _ScanSweep extends StatefulWidget {
  const _ScanSweep();

  @override
  State<_ScanSweep> createState() => _ScanSweepState();
}

class _ScanSweepState extends State<_ScanSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Align(
        alignment: Alignment(0, -1 + 2 * _c.value),
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: VisaColors.primaryLight,
            boxShadow: [BoxShadow(color: VisaColors.primaryLight.withValues(alpha: 0.8), blurRadius: 14, spreadRadius: 2)],
          ),
        ),
      ),
    );
  }
}
