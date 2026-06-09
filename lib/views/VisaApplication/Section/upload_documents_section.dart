// upload_documents_section.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Step 4 of the visa application — expands automatically after payment.
/// User uploads the required documents, then submits the application.
class UploadDocumentsSection extends StatefulWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const UploadDocumentsSection({
    Key? key,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    required this.onBack,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<UploadDocumentsSection> createState() => _UploadDocumentsSectionState();
}

class _UploadDocumentsSectionState extends State<UploadDocumentsSection>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xff0D47A1);

  // Required documents for the visa application.
  static const List<String> _requiredDocs = [
    'Passport (front & back)',
    'Passport-size Photograph',
  ];

  final Map<String, PlatformFile> _uploaded = {};
  bool _isExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  bool get _allUploaded =>
      _requiredDocs.every((d) => _uploaded.containsKey(d));

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isActive;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (_isExpanded) _animationController.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant UploadDocumentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto expand when this step becomes active, collapse when it isn't.
    if (widget.isActive != oldWidget.isActive) {
      _isExpanded = widget.isActive;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _pickFor(String doc) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _uploaded[doc] = result.files.first);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick file: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (widget.isCompleted || widget.isActive) _toggleExpand();
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? const Color(0xffE3F2FD)
                    : widget.isCompleted
                    ? Colors.green.shade50
                    : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.isCompleted
                          ? Colors.green
                          : widget.isActive
                          ? _navy
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Text(
                              '${widget.stepNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Upload Documents',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(Icons.keyboard_arrow_down,
                        size: 20, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _heightAnimation,
            axisAlignment: -1.0,
            child: ClipRect(child: _buildBody()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload clear scans (PDF/JPG/PNG) of the documents below.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ..._requiredDocs.map(_buildDocTile),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _navy),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('BACK',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _navy)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _allUploaded ? widget.onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('SUBMIT APPLICATION',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
          if (!_allUploaded) ...[
            const SizedBox(height: 8),
            Text(
              'Please upload all required documents to submit.',
              style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocTile(String doc) {
    final file = _uploaded[doc];
    final isDone = file != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDone ? Colors.green.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.description_outlined,
            size: 20,
            color: isDone ? Colors.green : Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
                Text(
                  isDone ? file.name : 'Required',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDone ? Colors.green.shade700 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _pickFor(doc),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              isDone ? 'Replace' : 'Upload',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _navy),
            ),
          ),
        ],
      ),
    );
  }
}
