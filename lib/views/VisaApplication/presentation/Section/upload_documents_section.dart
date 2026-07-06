import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../injection_container.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../Document/presentation/bloc/document_bloc.dart';
import '../../../Document/presentation/bloc/document_event.dart';
import '../../../Document/presentation/bloc/document_state.dart';


/// User uploads the required documents, then submits the application.
class UploadDocumentsSection extends StatefulWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final int? applicationId;
  final String? userEmail;

  const UploadDocumentsSection({
    Key? key,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    required this.onBack,
    required this.onSubmit,
    this.applicationId,
    this.userEmail,
  }) : super(key: key);

  @override
  State<UploadDocumentsSection> createState() => _UploadDocumentsSectionState();
}

class _UploadDocumentsSectionState extends State<UploadDocumentsSection>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xff0D47A1);

  // Documents for the visa application. The visa document is optional.
  static const List<_DocSpec> _requiredDocs = [
    _DocSpec('Passport (front & back)', optional: false),
    _DocSpec('Bank Statement', optional: false),
    _DocSpec('Visa Document', optional: true),
  ];

  final Map<String, PlatformFile> _uploaded = {};
  bool _isExpanded = false;
  bool _isUploading = false;

  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late DocumentBloc _documentBloc;

  List<_DocSpec> get _mandatoryDocs =>
      _requiredDocs.where((d) => !d.optional).toList();

  bool get _allUploaded =>
      _mandatoryDocs.every((d) => _uploaded.containsKey(d.name));

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isActive;
    _documentBloc = sl<DocumentBloc>();

    // Listen to bloc state changes
    _documentBloc.stream.listen((state) {
      if (state is DocumentUploadSuccess) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Call the original onSubmit callback
        widget.onSubmit();
      } else if (state is DocumentError) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${state.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

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
    _documentBloc.close();
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

  void _submitDocuments() {
    if (widget.applicationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application ID is required. Please complete previous steps.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Get user email from widget parameter or from PreferencesManager
    String userEmail = widget.userEmail ?? '';
    if (userEmail.isEmpty) {
      final prefs = sl<PreferencesManager>();
      final userData = prefs.getUserData();
      userEmail = userData?['email'] ?? '';
    }

    if (userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User email is required. Please login again.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    // Prepare documents list for API
    final List<Map<String, dynamic>> documents = _uploaded.entries.map((entry) {
      return {
        'file': entry.value,
        'type': entry.key,
      };
    }).toList();

    // Dispatch event to bloc
    _documentBloc.add(UploadDocuments(
      applicationId: widget.applicationId!,
      documents: documents,
      userEmail: userEmail,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
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
              padding: EdgeInsets.all(context.w(12)),
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
                    width: context.w(24),
                    height: context.w(24),
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
                          ? Icon(Icons.check, size: context.iconXSmall, color: Colors.white)
                          : Text(
                        '${widget.stepNumber}',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(8)),
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
                        size: context.iconMedium, color: Colors.grey.shade600),
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
    final mandatoryTotal = _mandatoryDocs.length;
    final mandatoryDone =
        _mandatoryDocs.where((d) => _uploaded.containsKey(d.name)).length;

    return Padding(
      padding: EdgeInsets.all(context.w(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload clear scans (PDF/JPG/PNG) of the documents below.',
            style: TextStyle(fontSize: context.fs(10), color: Colors.grey.shade600),
          ),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(context.r(4)),
                  child: LinearProgressIndicator(
                    value: mandatoryTotal == 0 ? 0 : mandatoryDone / mandatoryTotal,
                    minHeight: context.h(6),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(_navy),
                  ),
                ),
              ),
              SizedBox(width: context.w(8)),
              Text(
                '$mandatoryDone/$mandatoryTotal required',
                style: TextStyle(
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          ..._requiredDocs.map(_buildDocTile),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _navy),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(6))),
                    padding: EdgeInsets.symmetric(vertical: context.h(10)),
                  ),
                  child: Text('BACK',
                      style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w600,
                          color: _navy)),
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: ElevatedButton(
                  onPressed: _allUploaded && !_isUploading ? _submitDocuments : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(6))),
                    padding: EdgeInsets.symmetric(vertical: context.h(10)),
                  ),
                  child: _isUploading
                      ? SizedBox(
                    height: context.h(16),
                    width: context.w(16),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('CONTINUE TO PAYMENT',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PlatformFile? file) {
    final ext = file?.extension?.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') return Icons.image_outlined;
    return Icons.check_circle;
  }

  Widget _buildDocTile(_DocSpec doc) {
    final file = _uploaded[doc.name];
    final isDone = file != null;
    return Container(
      margin: EdgeInsets.only(bottom: context.h(8)),
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(
          color: isDone ? Colors.green.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(34),
            height: context.w(34),
            decoration: BoxDecoration(
              color: isDone ? Colors.green.shade100 : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? _iconFor(file) : Icons.description_outlined,
              size: context.iconSmall,
              color: isDone ? Colors.green.shade700 : Colors.grey.shade500,
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(doc.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.fs(11), fontWeight: FontWeight.w600)),
                    ),
                    if (doc.optional) ...[
                      SizedBox(width: context.w(6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.w(6), vertical: context.h(2)),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(context.r(4)),
                        ),
                        child: Text(
                          'Optional',
                          style: TextStyle(
                              fontSize: context.fs(9),
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade400),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.h(2)),
                Text(
                  isDone ? file.name : (doc.optional ? 'Not uploaded' : 'Required'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: isDone ? Colors.green.shade700 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (isDone && !_isUploading)
            IconButton(
              onPressed: () => setState(() => _uploaded.remove(doc.name)),
              icon: Icon(Icons.close, size: context.iconXSmall, color: Colors.grey.shade500),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: context.w(28), minHeight: context.w(28)),
            ),
          TextButton(
            onPressed: _isUploading ? null : () => _pickFor(doc.name),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: context.w(10)),
              minimumSize: Size(0, context.h(32)),
            ),
            child: Text(
              isDone ? 'Replace' : 'Upload',
              style: TextStyle(
                  fontSize: context.fs(11), fontWeight: FontWeight.w700, color: _navy),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocSpec {
  final String name;
  final bool optional;
  const _DocSpec(this.name, {required this.optional});
}