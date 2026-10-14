import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../utils/visa_camera.dart';
import '../utils/visa_theme.dart';

enum _Phase { idle, starting, align, blink, capturing, done }

/// "Take a selfie" step (Figma "Before Start p…" x3). The camera captures by
/// itself once one real face is centred, looking straight and has blinked
/// (a basic liveness check); gallery photos must also show one clear face.
class VisaSelfieStep extends StatefulWidget {
  final String? initialPath;
  final ValueChanged<String> onConfirmed;

  const VisaSelfieStep({super.key, this.initialPath, required this.onConfirmed});

  @override
  State<VisaSelfieStep> createState() => _VisaSelfieStepState();
}

class _VisaSelfieStepState extends State<VisaSelfieStep> with WidgetsBindingObserver {
  CameraController? _camera;
  final FaceDetector _detector = visaFaceDetector();
  _Phase _phase = _Phase.idle;
  bool _processing = false;
  bool _eyesClosedSeen = false;
  String _hint = '';
  String? _path;
  bool _reviewing = false;
  Timer? _blinkTimeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _path = widget.initialPath;
    _reviewing = _path != null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blinkTimeout?.cancel();
    _stopCamera();
    _detector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _camera != null) {
      _stopCamera();
      if (mounted) setState(() => _phase = _Phase.idle);
    }
  }

  Future<void> _stopCamera() async {
    final c = _camera;
    _camera = null;
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
    await c.dispose();
  }

  Future<void> _startCamera() async {
    setState(() {
      _phase = _Phase.starting;
      _hint = 'Starting camera…';
    });
    try {
      final c = await openVisaCamera(CameraLensDirection.front, preset: ResolutionPreset.medium);
      if (!mounted) {
        await c.dispose();
        return;
      }
      _camera = c;
      setState(() {
        _phase = _Phase.align;
        _hint = 'Place your face inside the circle';
      });
      await c.startImageStream(_onFrame);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.idle);
      final denied = e.code.contains('Denied') || e.code.contains('denied');
      _snack(denied
          ? 'Camera access is off. Allow it in Settings, or choose a photo from the gallery.'
          : 'Could not open the camera. Choose a photo from the gallery instead.');
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    final camera = _camera;
    if (_processing || camera == null || _phase == _Phase.capturing) return;
    final input = visaInputImage(image, camera.description);
    if (input == null) return;
    _processing = true;
    try {
      final faces = await _detector.processImage(input);
      if (!mounted || _camera == null) return;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      if (_phase == _Phase.align) {
        final problem = visaSelfieProblem(faces, size);
        if (problem != null) {
          _setHint(problem);
        } else {
          _eyesClosedSeen = false;
          setState(() {
            _phase = _Phase.blink;
            _hint = 'Now blink once';
          });
          _blinkTimeout?.cancel();
          _blinkTimeout = Timer(const Duration(seconds: 8), () {
            if (mounted && _phase == _Phase.blink) {
              setState(() {
                _phase = _Phase.align;
                _hint = 'Blink not seen. Look at the camera and try again';
              });
            }
          });
        }
      } else if (_phase == _Phase.blink) {
        if (faces.length != 1) {
          setState(() {
            _phase = _Phase.align;
            _hint = 'Keep only your face in the circle';
          });
          return;
        }
        final f = faces.first;
        final l = f.leftEyeOpenProbability ?? 1, r = f.rightEyeOpenProbability ?? 1;
        if (l < 0.25 && r < 0.25) _eyesClosedSeen = true;
        if (_eyesClosedSeen && l > 0.6 && r > 0.6) {
          _blinkTimeout?.cancel();
          await _capture();
        }
      }
    } catch (_) {
      // A dropped frame; the next one is tried.
    } finally {
      _processing = false;
    }
  }

  void _setHint(String hint) {
    if (hint != _hint) setState(() => _hint = hint);
  }

  Future<void> _capture() async {
    final c = _camera;
    if (c == null) return;
    setState(() {
      _phase = _Phase.capturing;
      _hint = 'Hold still…';
    });
    try {
      await c.stopImageStream();
      final file = await c.takePicture();
      final problem = await _checkFile(file.path, accurate: false);
      await _stopCamera();
      if (!mounted) return;
      if (problem != null) {
        setState(() => _phase = _Phase.idle);
        _snack(problem);
        return;
      }
      _accept(file.path);
    } catch (_) {
      await _stopCamera();
      if (!mounted) return;
      setState(() => _phase = _Phase.idle);
      _snack('Could not take the photo. Please try again.');
    }
  }

  Future<String?> _checkFile(String path, {required bool accurate}) async {
    final detector = visaFaceDetector(accurate: accurate);
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(path));
      final size = await _imageSize(path);
      if (size == null) return 'Could not read this photo. Try another one.';
      return visaSelfieProblem(faces, size);
    } finally {
      detector.close();
    }
  }

  Future<Size?> _imageSize(String path) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = Size(descriptor.width.toDouble(), descriptor.height.toDouble());
      descriptor.dispose();
      buffer.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickGallery() async {
    await _stopCamera();
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null || !mounted) {
      if (mounted) setState(() => _phase = _Phase.idle);
      return;
    }
    setState(() {
      _phase = _Phase.capturing;
      _hint = 'Checking photo…';
    });
    final problem = await _checkFile(path, accurate: true);
    if (!mounted) return;
    if (problem != null) {
      setState(() => _phase = _Phase.idle);
      _snack(problem);
      return;
    }
    _accept(path);
  }

  void _accept(String path) {
    setState(() {
      _path = path;
      _phase = _Phase.done;
    });
    // Show "Perfect · Uploaded" briefly, then the review screen.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _phase == _Phase.done) setState(() => _reviewing = true);
    });
  }

  void _retake() {
    setState(() {
      _path = null;
      _reviewing = false;
      _phase = _Phase.idle;
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewing && _path != null) return _review();
    final size = MediaQuery.of(context).size.width * 0.68;
    final live = _camera != null && _camera!.value.isInitialized;
    final ringColor = switch (_phase) {
      _Phase.blink || _Phase.capturing => VisaColors.green,
      _Phase.done => VisaColors.primaryLight,
      _ => const Color(0xFFE5E7EB),
    };

    return Column(
      children: [
        const SizedBox(height: 32),
        Text('Take a selfie', style: visaText(14, weight: FontWeight.w600, color: VisaColors.title)),
        const SizedBox(height: 2),
        Text('Required by all government', style: visaText(9.5, color: VisaColors.text)),
        const SizedBox(height: 24),
        SizedBox(
          width: size,
          height: size + 22,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3F4F6),
                  border: Border.all(color: ringColor, width: 6),
                ),
                child: ClipOval(child: _circleContent(live)),
              ),
              if (_phase == _Phase.idle)
                Positioned(
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _startCamera,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: VisaColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.photo_camera, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              if (_phase == _Phase.done)
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(color: VisaColors.green, borderRadius: BorderRadius.circular(10)),
                    child: Text('Perfect', style: visaText(9, weight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_phase != _Phase.idle && _phase != _Phase.done)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_hint,
                textAlign: TextAlign.center,
                style: visaText(12, weight: FontWeight.w600, color: VisaColors.title)),
          ),
        const Spacer(),
        if (_phase == _Phase.done)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_done, size: 18, color: VisaColors.green),
              const SizedBox(width: 6),
              Text('Uploaded', style: visaText(11, weight: FontWeight.w600, color: VisaColors.green)),
            ],
          )
        else if (_phase == _Phase.idle || _phase == _Phase.align)
          TextButton.icon(
            onPressed: _pickGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 16, color: VisaColors.primary),
            label: Text('Choose gallery',
                style: visaText(10, weight: FontWeight.w600, color: VisaColors.primary,
                    decoration: TextDecoration.underline)),
          ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _circleContent(bool live) {
    if (_path != null) return Image.file(File(_path!), fit: BoxFit.cover);
    if (!live) return const SizedBox.expand();
    final preview = _camera!.value.previewSize;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        // previewSize is landscape; the preview is shown portrait.
        width: preview?.height ?? 300,
        height: preview?.width ?? 400,
        child: CameraPreview(_camera!),
      ),
    );
  }

  Widget _review() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 13, color: VisaColors.green),
              const SizedBox(width: 4),
              Text('Image will be edited to fit government requirements',
                  style: visaText(9, color: VisaColors.green)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(File(_path!), fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          const SizedBox(height: 24),
          VisaPrimaryButton(label: 'Confirm selfie', onPressed: () => widget.onConfirmed(_path!)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: _retake,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: VisaColors.cta),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('RETAKE SELFIE', style: visaText(12, weight: FontWeight.w700, color: VisaColors.cta)),
            ),
          ),
        ],
      ),
    );
  }
}
