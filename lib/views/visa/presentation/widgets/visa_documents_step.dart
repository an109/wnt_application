import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../../data/visa_form_data.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import 'visa_fields.dart';

/// Documents step of the visa application: the documents the reseller
/// configured for this destination, filtered per traveller by the occupation
/// behind their employment answer. Shown after the traveller details and
/// before payment, as on the website.
class VisaDocumentsStep extends StatefulWidget {
  final VisaPopularDestinationEntity destination;
  final List<VisaTravellerForm> travellers;

  /// Called whenever a file is attached or removed, so a host screen can
  /// save its draft.
  final VoidCallback? onChanged;

  const VisaDocumentsStep({
    super.key,
    required this.destination,
    required this.travellers,
    this.onChanged,
  });

  /// Documents [t] has to provide for [destination].
  static List<VisaRequiredDocument> documentsFor(
    VisaPopularDestinationEntity destination,
    VisaTravellerForm t,
  ) =>
      destination.documentsFor(visaOccupationOf(t));

  /// Message naming the first document still missing, or null when every
  /// required one is attached.
  static String? missing(
    VisaPopularDestinationEntity destination,
    List<VisaTravellerForm> travellers,
  ) {
    for (var i = 0; i < travellers.length; i++) {
      for (final doc in documentsFor(destination, travellers[i])) {
        if (doc.required && !travellers[i].documentPaths.containsKey(doc.key)) {
          final who = travellers.length == 1 ? 'you' : 'traveller ${i + 1}';
          return 'Attach ${doc.label} for $who';
        }
      }
    }
    return null;
  }

  @override
  State<VisaDocumentsStep> createState() => _VisaDocumentsStepState();
}

class _VisaDocumentsStepState extends State<VisaDocumentsStep> {
  VisaPopularDestinationEntity get _d => widget.destination;

  Future<void> _pick(int traveller, VisaRequiredDocument doc) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    final file = (picked?.files.isNotEmpty ?? false) ? picked!.files.first : null;
    final path = file?.path;
    if (file == null || path == null) return;
    // The same limit the upload endpoint enforces, checked here so the
    // traveller finds out before paying rather than after.
    if (file.size > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('${file.name} is larger than 10 MB. Please attach a smaller file.'),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    setState(() => widget.travellers[traveller].documentPaths[doc.key] = path);
    widget.onChanged?.call();
  }

  void _remove(int traveller, VisaRequiredDocument doc) {
    setState(() => widget.travellers[traveller].documentPaths.remove(doc.key));
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('visaDocuments'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Upload your documents',
            style: visaText(13, weight: FontWeight.w600, color: VisaColors.title)),
        const SizedBox(height: 4),
        Text(
          'What ${_d.shortName} asks for depends on each traveller’s employment, so the '
          'list below is already filtered. PDF, JPG, PNG or WEBP, up to 10 MB each.',
          style: visaText(9.5, color: VisaColors.text, height: 1.4),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < widget.travellers.length; i++) _travellerCard(i),
      ],
    );
  }

  Widget _travellerCard(int i) {
    final t = widget.travellers[i];
    final docs = VisaDocumentsStep.documentsFor(_d, t);
    final name = t.firstName.trim();
    return VisaDetailCard(
      icon: Icons.folder_open_outlined,
      iconColor: VisaColors.cta,
      title: widget.travellers.length == 1
          ? 'Your documents'
          : 'Traveller ${i + 1}${name.isEmpty ? '' : ' · $name'}',
      child: Column(
        children: [
          if (t.employment.trim().isNotEmpty || t.occupation.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  t.employment.trim().isNotEmpty ? t.employment.trim() : t.occupation.trim(),
                  style: visaText(9, weight: FontWeight.w600, color: VisaColors.primary),
                ),
              ),
            ),
          if (docs.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('No documents to upload for this traveller.',
                  style: visaText(9.5, color: VisaColors.text)),
            ),
          for (final doc in docs) _row(i, doc),
        ],
      ),
    );
  }

  Widget _row(int traveller, VisaRequiredDocument doc) {
    final path = widget.travellers[traveller].documentPaths[doc.key];
    final attached = path != null;
    final name = attached ? path.split(Platform.pathSeparator).last : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: attached ? VisaColors.greenSoft : Colors.white,
        border: Border.all(color: attached ? VisaColors.green : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(attached ? Icons.check_circle : Icons.insert_drive_file_outlined,
              size: 17, color: attached ? VisaColors.green : const Color(0xFF9BA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.required ? doc.label : '${doc.label} (optional)',
                    style: visaText(10, weight: FontWeight.w600, color: VisaColors.title)),
                if (doc.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(doc.description,
                        style: visaText(8.5, color: VisaColors.text, height: 1.3)),
                  ),
                if (attached)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: visaText(8.5, color: VisaColors.green)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (attached)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFE53935)),
              onPressed: () => _remove(traveller, doc),
            ),
          TextButton(
            onPressed: () => _pick(traveller, doc),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(attached ? 'Replace' : 'Attach',
                style: visaText(9.5, weight: FontWeight.w700, color: VisaColors.cta)),
          ),
        ],
      ),
    );
  }
}
