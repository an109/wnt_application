import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';

/// "Upload Image" — Figma `Holiday Uploadimage (camera)`.
///
/// The DIY API has no image-recognition endpoint, so the photo is not sent
/// anywhere. Once one is chosen the screen falls back to the live
/// destination list (**API 1 — GET /destinations/**) so the user still
/// leaves with a destination selected. Wire the picked [File] to a
/// visual-search endpoint here once the backend exposes one.
class DiyImageSearchScreen extends StatefulWidget {
  const DiyImageSearchScreen({super.key});

  @override
  State<DiyImageSearchScreen> createState() => _DiyImageSearchScreenState();
}

class _DiyImageSearchScreenState extends State<DiyImageSearchScreen> {
  File? _picked;
  bool _picking = false;
  Future<List<DiyDestination>>? _destinations;

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null || !mounted) return;
      setState(() {
        _picked = File(path);
        _destinations = sl<DiyHolidayApi>().getDestinations();
      });
    } catch (e) {
      if (mounted) diySnack(context, 'Could not open that image.', isError: true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: diyAppBar(context, title: 'Upload Image'),
      body: Column(
        children: [
          const Divider(height: 1, color: DiyTokens.line),
          Expanded(
            child: _picked == null ? _emptyState() : _matchState(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(10),
              context.w(16),
              context.h(16) + MediaQuery.of(context).padding.bottom,
            ),
            child: DiyPrimaryButton(
              label: _picked == null ? 'UPLOAD IMAGE' : 'CHOOSE ANOTHER IMAGE',
              icon: Icons.file_upload_outlined,
              busy: _picking,
              onPressed: _pickImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(24),
        vertical: context.h(30),
      ),
      child: Column(
        children: [
          _collage(),
          SizedBox(height: context.h(24)),
          Text(
            'Love the view? Find the place!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
          SizedBox(height: context.h(6)),
          Text(
            'Upload a photo and uncover your next travel destination.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.fs(12),
              color: DiyTokens.subGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// The three tilted photo cards from the Figma frame, drawn from the app's
  /// own artwork so the screen needs no new assets.
  Widget _collage() {
    Widget tile(String asset, double angle, double size) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: context.w(16),
                offset: Offset(0, context.h(6)),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
      );
    }

    return SizedBox(
      height: context.h(210),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: tile('assets/images/beach_hut.png', 0, context.w(110)),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: tile('assets/images/TransHeroImage.png', -0.7, context.w(96)),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: tile('assets/images/dashboard_bg.jpg', 0.7, context.w(96)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: context.w(58),
              height: context.h(96),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(10)),
                border: Border.all(color: DiyTokens.navy, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: context.w(12),
                  ),
                ],
              ),
              child: Icon(
                Icons.image_outlined,
                color: DiyTokens.blue,
                size: context.w(22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(context.w(16)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(context.r(12)),
                child: Image.file(
                  _picked!,
                  width: context.w(78),
                  height: context.w(78),
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: context.w(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We could not identify this place automatically.',
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color: DiyTokens.navy,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      'Pick the destination you had in mind and we will show '
                      'its packages.',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: DiyTokens.line),
        Expanded(
          child: FutureBuilder<List<DiyDestination>>(
            future: _destinations,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const DiyLoading(message: 'Loading destinations…');
              }
              if (snapshot.hasError) {
                return DiyErrorView(message: snapshot.error.toString());
              }
              final list = snapshot.data ?? const <DiyDestination>[];
              return ListView.separated(
                padding: EdgeInsets.symmetric(vertical: context.h(6)),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: DiyTokens.line),
                itemBuilder: (context, i) {
                  final d = list[i];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: DiyTokens.blue,
                      size: context.w(20),
                    ),
                    title: Text(
                      d.name,
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: DiyTokens.navy,
                      ),
                    ),
                    subtitle: Text(
                      '${d.packageCount} Packages · ${d.kindLabel}',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(d),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
