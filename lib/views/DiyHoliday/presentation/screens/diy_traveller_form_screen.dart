import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../Dashboard/Section/data/traveller_api_service.dart';
import '../../data/diy_traveller.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_review_sheets.dart';

/// "Add New Traveller" — the Figma traveller form.
///
/// The DIY API has no traveller endpoint of its own, so this reuses the app's
/// existing saved-travellers service (`Urls.travellers`): "Select From List"
/// reads the customer's saved people, and a traveller typed here is offered
/// back to that list so the next booking can pick them.
///
/// Returns the completed [DiyTraveller] to the review screen, or null on
/// cancel. Saving to the address book is best-effort — a failure there never
/// blocks the booking, it just means the traveller is not remembered.
class DiyTravellerFormScreen extends StatefulWidget {
  /// Seeded when editing an existing row rather than adding one.
  final DiyTraveller? initial;

  /// Shown as the chip strip across the top: "Adult 1", "Adult 2", "Child 1".
  final List<String> partyLabels;

  /// Which of [partyLabels] this form is filling.
  final int index;

  /// What each chip shows once that traveller is filled in — "Anjli Singh
  /// 21y" — or empty for one still to add.
  final List<String> partyNames;

  const DiyTravellerFormScreen({
    super.key,
    this.initial,
    this.partyLabels = const [],
    this.index = 0,
    this.partyNames = const [],
  });

  @override
  State<DiyTravellerFormScreen> createState() => _DiyTravellerFormScreenState();
}

class _DiyTravellerFormScreenState extends State<DiyTravellerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();

  DateTime? _dob;
  String _gender = '';
  bool _saving = false;

  List<DiyTraveller> _saved = const [];
  bool _loadingSaved = true;

  static const List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    if (t != null) {
      _firstName.text = t.firstName;
      _lastName.text = t.lastName;
      _phone.text = t.phone;
      _gender = t.gender;
      _dob = DateTime.tryParse(t.dob);
    }
    _loadSaved();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final email = sl<PreferencesManager>()
          .getUserData()?['email']
          ?.toString();
      if (email == null || email.isEmpty) {
        setState(() => _loadingSaved = false);
        return;
      }
      final res = await sl<TravellerApiService>().getTravellers(email);
      final data = res.data;
      final rows = data is List
          ? data
          : (data is Map && data['travellers'] is List
                ? data['travellers'] as List
                : const []);
      if (!mounted) return;
      setState(() {
        _saved = rows
            .whereType<Map>()
            .map((r) => DiyTraveller.fromJson(Map<String, dynamic>.from(r)))
            .where((t) => t.isComplete)
            .toList();
        _loadingSaved = false;
      });
    } catch (_) {
      // The saved list is a convenience — the form works without it.
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  void _applySaved(DiyTraveller t) {
    setState(() {
      _firstName.text = t.firstName;
      _lastName.text = t.lastName;
      _phone.text = t.phone;
      _gender = t.gender;
      _dob = DateTime.tryParse(t.dob);
    });
  }

  Future<void> _pickDob() async {
    final picked = await showDiyDobPicker(context, initial: _dob);
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickGender() async {
    final picked = await showDiySelectSheet(
      context,
      options: _genders,
      selected: _gender,
    );
    if (picked != null) setState(() => _gender = picked);
  }

  Future<void> _openSaved() async {
    final picked = await showDiySavedTravellers(context, _saved);
    if (picked != null) _applySaved(picked);
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final label = widget.index < widget.partyLabels.length
        ? widget.partyLabels[widget.index]
        : 'Adult';

    // Children are priced and booked on age, so their date of birth is a must.
    if (label.toLowerCase().startsWith('child') && _dob == null) {
      diySnack(context, 'Add the child\'s date of birth', isError: true);
      return;
    }

    final traveller = DiyTraveller(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      gender: _gender,
      dob: _dob == null ? '' : _ymd(_dob!),
      paxType: label.toLowerCase().startsWith('child') ? 'Child' : 'Adult',
    );

    setState(() => _saving = true);
    // Remember the traveller for next time. Best-effort by design: the
    // booking must not fail because the address book did.
    try {
      final email = sl<PreferencesManager>()
          .getUserData()?['email']
          ?.toString();
      if (email != null && email.isNotEmpty) {
        await sl<TravellerApiService>().addTraveller({
          'paxType': traveller.paxType,
          'title': traveller.title,
          'firstName': traveller.firstName,
          'lastName': traveller.lastName,
          'dob': traveller.dob,
          'gender': traveller.gender,
          'user_email': email,
        });
      }
    } on DioException catch (_) {
      // ignored — see above
    } catch (_) {
      // ignored — see above
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(traveller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.close, color: DiyTokens.navy, size: context.w(21)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(
          widget.initial == null ? 'Add New Traveller' : 'Edit Traveller',
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.w700,
            color: DiyTokens.navy,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.w(16),
            context.h(14),
            context.w(16),
            context.h(24),
          ),
          children: [
            _selectFromList(),
            SizedBox(height: context.h(14)),
            if (widget.partyLabels.isNotEmpty) _partyChips(),
            SizedBox(height: context.h(18)),
            Text(
              'Mandatory Information',
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w700,
                color: DiyTokens.navy,
              ),
            ),
            SizedBox(height: context.h(12)),
            _field(
              label: 'FIRST NAME',
              controller: _firstName,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter the first name'
                  : null,
            ),
            SizedBox(height: context.h(12)),
            _field(
              label: 'LAST NAME',
              controller: _lastName,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter the last name'
                  : null,
            ),
            SizedBox(height: context.h(12)),
            _phoneField(),
            SizedBox(height: context.h(12)),
            _dobField(),
            SizedBox(height: context.h(12)),
            _genderField(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(8),
          context.w(16),
          context.h(12),
        ),
        child: SizedBox(
          height: context.h(48),
          child: ElevatedButton(
            onPressed: _saving ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: DiyTokens.orange,
              disabledBackgroundColor: DiyTokens.orange.withOpacity(0.5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
            ),
            child: _saving
                ? SizedBox(
                    width: context.w(18),
                    height: context.w(18),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'CONFIRM DETAILS',
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// "Select From List" — opens the Saved Traveller List sheet.
  Widget _selectFromList() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: _loadingSaved ? null : _openSaved,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(10),
            vertical: context.h(6),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: DiyTokens.blue),
            borderRadius: BorderRadius.circular(context.r(6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select From List',
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w500,
                  color: DiyTokens.blue,
                ),
              ),
              SizedBox(width: context.w(6)),
              _loadingSaved
                  ? SizedBox(
                      width: context.w(12),
                      height: context.w(12),
                      child: const CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: context.w(17),
                      color: DiyTokens.blue,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// The party across the top: a filled traveller shows their name and age
  /// with a tick, the one being filled is outlined in blue, and the rest are
  /// dashed placeholders.
  Widget _partyChips() {
    return SizedBox(
      height: context.h(56),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.only(top: context.h(6)),
        itemCount: widget.partyLabels.length,
        separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
        itemBuilder: (context, i) {
          final selected = i == widget.index;
          final name = i < widget.partyNames.length ? widget.partyNames[i] : '';
          final filled = name.isNotEmpty;
          final chip = Container(
            width: filled ? null : context.w(56),
            constraints: BoxConstraints(minWidth: context.w(56)),
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            decoration: BoxDecoration(
              color: selected || filled
                  ? const Color(0xFFEFF7FD)
                  : Colors.white,
              border: selected || filled
                  ? Border.all(
                      color: selected
                          ? DiyTokens.blue
                          : const Color(0xFFBFD7EA),
                    )
                  : null,
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: filled
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: filled
                  ? [
                      Text(
                        name,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: context.fs(9.5),
                          height: 1.3,
                          color: DiyTokens.navy,
                        ),
                      ),
                    ]
                  : [
                      Icon(
                        selected
                            ? Icons.person_rounded
                            : Icons.person_outline_rounded,
                        size: context.w(15),
                        color: DiyTokens.blue,
                      ),
                      SizedBox(height: context.h(3)),
                      Text(
                        widget.partyLabels[i],
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: context.fs(9.5),
                          color: DiyTokens.blue,
                        ),
                      ),
                    ],
            ),
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (!selected && !filled)
                CustomPaint(
                  foregroundPainter: _DashedBorder(
                    color: const Color(0xFF7FB8E6),
                    radius: context.r(6),
                  ),
                  child: chip,
                )
              else
                chip,
              if (filled)
                Positioned(
                  top: -context.h(6),
                  right: -context.w(5),
                  child: Container(
                    padding: EdgeInsets.all(context.w(2)),
                    decoration: const BoxDecoration(
                      color: DiyTokens.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: context.w(9),
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Floating-label bordered box, matching the Figma inputs.
  Widget _field({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: TextStyle(fontSize: context.fs(14), color: DiyTokens.navy),
      decoration: _decoration(label),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: context.fs(10),
        color: DiyTokens.labelGrey,
        letterSpacing: 0.4,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(14),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(8)),
        borderSide: const BorderSide(color: DiyTokens.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(8)),
        borderSide: const BorderSide(color: DiyTokens.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(8)),
        borderSide: const BorderSide(color: DiyTokens.blue),
      ),
    );
  }

  Widget _phoneField() {
    return Row(
      children: [
        Container(
          height: context.h(52),
          padding: EdgeInsets.symmetric(horizontal: context.w(10)),
          decoration: BoxDecoration(
            border: Border.all(color: DiyTokens.line),
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: Row(
            children: [
              Text('🇮🇳', style: TextStyle(fontSize: context.fs(15))),
              SizedBox(width: context.w(5)),
              Text(
                '+91',
                style: TextStyle(
                  fontSize: context.fs(13.5),
                  color: DiyTokens.navy,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: _field(
            label: 'MOBILE NUMBER',
            controller: _phone,
            keyboardType: TextInputType.phone,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return null; // only the lead contact is required
              return s.length == 10 ? null : 'Enter a 10-digit number';
            },
          ),
        ),
      ],
    );
  }

  Widget _dobField() {
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(context.r(8)),
      child: InputDecorator(
        decoration: _decoration('DATE OF BIRTH').copyWith(
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.w(20),
            color: DiyTokens.blue,
          ),
        ),
        child: Text(
          _dob == null
              ? 'Select'
              : '${_dob!.day.toString().padLeft(2, '0')}/'
                    '${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}',
          style: TextStyle(
            fontSize: context.fs(14),
            color: _dob == null ? DiyTokens.labelGrey : DiyTokens.navy,
          ),
        ),
      ),
    );
  }

  Widget _genderField() {
    return FormField<String>(
      initialValue: _gender,
      validator: (_) => _gender.isEmpty ? 'Select a gender' : null,
      builder: (state) => InkWell(
        onTap: () async {
          await _pickGender();
          state.didChange(_gender);
        },
        borderRadius: BorderRadius.circular(context.r(8)),
        child: InputDecorator(
          decoration: _decoration('GENDER').copyWith(
            errorText: state.errorText,
            suffixIcon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: context.w(20),
              color: DiyTokens.blue,
            ),
          ),
          child: Text(
            _gender.isEmpty ? 'Select' : _gender,
            style: TextStyle(
              fontSize: context.fs(14),
              color: _gender.isEmpty ? DiyTokens.labelGrey : DiyTokens.navy,
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded dashed outline — the Figma's not-yet-added traveller chips.
class _DashedBorder extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorder({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) =>
      old.color != color || old.radius != radius;
}
