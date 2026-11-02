import 'dart:async';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../data/visa_passport_reader.dart';
import '../utils/visa_camera.dart';
import '../utils/visa_theme.dart';

/// What a scan produced: the photo and the verified data read from it.
class VisaPassportScan {
  final String path;
  final VisaMrz? mrz;
  final VisaPassportFront? front;
  final VisaPassportBack? back;
  const VisaPassportScan(this.path, {this.mrz, this.front, this.back});
}

/// "Scan your passport" / "Now flip to the back page".
/// User captures a photo manually, then OCR extracts the data.
class VisaPassportStep extends StatefulWidget {
  final bool back;
  final ValueChanged<VisaPassportScan> onScanned;

  const VisaPassportStep({super.key, required this.back, required this.onScanned});

  @override
  State<VisaPassportStep> createState() => _VisaPassportStepState();
}

class _VisaPassportStepState extends State<VisaPassportStep> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _camera;
  final TextRecognizer _ocr = TextRecognizer(script: TextRecognitionScript.latin);
  bool _processing = false;
  String _hint = 'Place the page inside the frame';
  String? _error;
  late final AnimationController _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
  late final AnimationController _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didUpdateWidget(covariant VisaPassportStep old) {
    super.didUpdateWidget(old);
    if (old.back != widget.back) {
      _hint = 'Place the page inside the frame';
      _processing = false;
      if (_camera == null) _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    _stop();
    _ocr.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stop();
    } else if (state == AppLifecycleState.resumed && _camera == null && !_processing) {
      _start();
    }
  }

  Future<void> _start() async {
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
        _error = null;
        _hint = 'Place the page inside the frame';
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.toLowerCase().contains('denied');
      setState(() => _error = denied
          ? 'Camera access is off. Allow it in Settings, or upload a photo of the page.'
          : 'Could not open the camera. Upload a photo of the page instead.');
    }
  }

  Future<void> _stop() async {
    final c = _camera;
    _camera = null;
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
    await c.dispose();
  }

  VisaPassportScan? _read(String path, String text) {
    if (widget.back) {
      final back = readPassportBack(text);
      return back.looksValid ? VisaPassportScan(path, back: back) : null;
    }
    final mrz = readPassportMrz(text);
    if (mrz == null) return null;
    return VisaPassportScan(path, mrz: mrz, front: readPassportFront(text, mrz));
  }

  Future<void> _capturePhoto() async {
    final c = _camera;
    if (c == null || _processing) return;
    setState(() {
      _processing = true;
      _hint = 'Focusing…';
    });
    try {
      // Lock focus and exposure before capturing for a sharp image.
      try {
        await c.setFocusMode(FocusMode.auto);
        await c.setExposureMode(ExposureMode.auto);
      } catch (_) {}
      // Give the camera time to auto-focus and stabilise.
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _hint = 'Extracting details…');
      final file = await c.takePicture();
      debugPrint('[PassportScan] Photo saved: ${file.path}');
      await _stop();
      final text = await _ocr.processImage(InputImage.fromFilePath(file.path));
      if (!mounted) return;
      debugPrint('[PassportScan] OCR text:\n${text.text}');
      debugPrint('[PassportScan] OCR blocks: ${text.blocks.length}');
      final scan = _read(file.path, text.text);
      if (scan == null) {
        debugPrint('[PassportScan] MRZ parse failed — no valid MRZ found in OCR output');
        setState(() {
          _processing = false;
          _hint = 'Could not read. Try again';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(widget.back
              ? 'Could not read the back page. Make sure text is clear and fully visible.'
              : 'Could not verify this passport. The two lines at the bottom must be sharp and fully visible.'),
        ));
        _start();
        return;
      }
      _finish(scan);
    } catch (e) {
      debugPrint('[PassportScan] Capture error: $e');
      await _stop();
      if (!mounted) return;
      setState(() {
        _processing = false;
        _hint = 'Something went wrong. Try again';
      });
      _start();
    }
  }

  Future<void> _upload() async {
    await _stop();
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (!mounted) return;
    if (path == null) {
      _start();
      return;
    }
    setState(() {
      _processing = true;
      _hint = 'Extracting details…';
    });
    final text = await _ocr.processImage(InputImage.fromFilePath(path));
    if (!mounted) return;
    final scan = _read(path, text.text);
    if (scan == null) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(widget.back
            ? 'This does not look like the back page of a passport. Try a clearer photo.'
            : 'Could not verify this passport. The two lines at the bottom of the photo page must be sharp and fully visible.'),
      ));
      _start();
      return;
    }
    _finish(scan);
  }

  void _finish(VisaPassportScan scan) {
    if (!mounted) return;
    final expiry = scan.mrz?.expiry;
    if (expiry != null && expiry.isBefore(DateTime.now())) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('This passport has expired. Please renew it before applying.'),
      ));
      _start();
      return;
    }
    widget.onScanned(scan);
  }

  @override
  Widget build(BuildContext context) {
    final live = _camera != null && _camera!.value.isInitialized;
    return Column(
      children: [
        const SizedBox(height: 28),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(colors: [Color(0xFF7B2C8F), Color(0xFFD6336C)]),
          ),
          child: const Icon(Icons.badge, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 10),
        Text(widget.back ? 'Now flip to the back page' : 'Capture your passport',
            style: visaText(14, weight: FontWeight.w600, color: VisaColors.title)),
        const SizedBox(height: 2),
        Text('Align the passport page and tap the capture button', style: visaText(9.5, color: VisaColors.text)),
        const SizedBox(height: 2),
        Text(widget.back ? 'BACK PAGE' : 'FRONT PAGE',
            style: visaText(9.5, weight: FontWeight.w600, color: const Color(0xFF6B21A8))),
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFEDEDED), borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(20),
              child: CustomPaint(
                foregroundPainter: _CornersPainter(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: live
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _camera!.value.previewSize?.height ?? 300,
                                height: _camera!.value.previewSize?.width ?? 400,
                                child: CameraPreview(_camera!),
                              ),
                            ),
                            if (!_processing)
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _scanLineCtrl,
                                  builder: (context, _) => CustomPaint(
                                    painter: _ScanLinePainter(_scanLineCtrl.value),
                                  ),
                                ),
                              ),
                            if (!_processing)
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _pulseCtrl,
                                  builder: (context, _) => Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF6B21A8).withValues(alpha: 0.3 + 0.4 * _pulseCtrl.value),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Center(
                          child: _error != null
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(_error!,
                                      textAlign: TextAlign.center, style: visaText(10, color: VisaColors.text)),
                                )
                              : _processing
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(strokeWidth: 2, color: VisaColors.primary),
                                        const SizedBox(height: 10),
                                        Text('Extracting details…', style: visaText(10, color: VisaColors.text)),
                                      ],
                                    )
                                  : const CircularProgressIndicator(strokeWidth: 2, color: VisaColors.primary),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFFF59E5B), borderRadius: BorderRadius.circular(14)),
          child: Text(_hint.toUpperCase(), style: visaText(10, weight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(height: 20),
        // Capture button
        GestureDetector(
          onTap: (live && !_processing) ? _capturePhoto : null,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: (live && !_processing) ? VisaColors.primary : Colors.grey, width: 4),
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (live && !_processing) ? VisaColors.primary : Colors.grey,
              ),
            ),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _processing ? null : _upload,
          icon: const Icon(Icons.upload_file, size: 16, color: VisaColors.primary),
          label: Text('Upload a photo instead',
              style: visaText(10, weight: FontWeight.w600, color: VisaColors.primary,
                  decoration: TextDecoration.underline)),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6B21A8).withValues(alpha: 0),
          const Color(0xFF6B21A8).withValues(alpha: 0.7),
          const Color(0xFF6B21A8).withValues(alpha: 0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, y - 12, size.width, 24))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => true;
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 22.0, o = -14.0;
    final w = size.width, h = size.height;
    for (final (x, y, dx, dy) in [
      (o, o, 1.0, 1.0),
      (w - o, o, -1.0, 1.0),
      (o, h - o, 1.0, -1.0),
      (w - o, h - o, -1.0, -1.0),
    ]) {
      final path = Path()
        ..moveTo(x, y + dy * l)
        ..quadraticBezierTo(x, y, x + dx * l * 0.4, y)
        ..lineTo(x + dx * l, y);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
