import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';

import '../../../Dashboard/Section/data/traveller_api_service.dart';

/// One guest picked off the "Saved Guests" list when the sheet is closed via
/// "DONE" — just the fields [AkHotelPriceConfirmScreen]'s guest form actually
/// collects (name + title); [isChild] steers which paxType slot it can fill.
class AkHotelGuestPick {
  final String title;
  final String firstName;
  final String lastName;
  final bool isChild;

  const AkHotelGuestPick({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.isChild,
  });
}

/// "Add Other Guest" bottom sheet: lets the traveller add a new guest to
/// their saved-guest book ([TravellerApiService.addTraveller] — the same
/// backend the Dashboard's "My Travellers" screen uses) and tick which
/// already-saved guests to bring into this booking. Reads/writes real data
/// only — there is no local-only fabricated list.
///
/// "Edit Guest Info" only updates the row locally (there is no update
/// endpoint on [TravellerApiService] to persist it against).
class AkHotelAddGuestSheet extends StatefulWidget {
  const AkHotelAddGuestSheet({super.key});

  static Future<List<AkHotelGuestPick>?> show(BuildContext context) {
    return showModalBottomSheet<List<AkHotelGuestPick>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AkHotelAddGuestSheet(),
    );
  }

  @override
  State<AkHotelAddGuestSheet> createState() => _AkHotelAddGuestSheetState();
}

class _AkHotelAddGuestSheetState extends State<AkHotelAddGuestSheet> {
  static const _navy = AppColors.black;
  static const _muted = AppColors.subhead;
  static const _border = AppColors.lightsubhead;
  static const _accent = AppColors.OrangeColor;

  bool _loadingSaved = true;
  List<Map<String, dynamic>> _saved = [];
  final Set<int> _selected = {};
  int? _editingIndex;

  String _newTitle = 'Mr';
  final _newFirstName = TextEditingController();
  final _newLastName = TextEditingController();
  bool _newBelow12 = false;
  bool _saving = false;
  String? _saveError;

  String _editTitle = 'Mr';
  final _editFirstName = TextEditingController();
  final _editLastName = TextEditingController();
  bool _editBelow12 = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _newFirstName.dispose();
    _newLastName.dispose();
    _editFirstName.dispose();
    _editLastName.dispose();
    super.dispose();
  }

  Future<String?> _currentEmail() async {
    final prefs = sl<PreferencesManager>();
    final stored = prefs.getUserData()?['email'] as String?;
    return (stored != null && stored.isNotEmpty) ? stored : null;
  }

  /// Accepts a plain array, or common wrapper shapes like
  /// {"travellers": [...]}, {"results": [...]}, {"data": [...]} — same
  /// tolerant parsing the Dashboard's traveller list uses.
  List<Map<String, dynamic>> _parseTravellers(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map) {
      final list = data['travellers'] ?? data['results'] ?? data['data'];
      if (list is List) {
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return const [];
  }

  Future<void> _loadSaved() async {
    setState(() => _loadingSaved = true);
    final email = await _currentEmail();
    if (email == null) {
      if (mounted) setState(() => _loadingSaved = false);
      return;
    }
    try {
      final response = await sl<TravellerApiService>().getTravellers(email);
      final travellers = _parseTravellers(response.data);
      if (mounted) setState(() { _saved = travellers; _loadingSaved = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  String _fullName(Map<String, dynamic> t) {
    final first = (t['firstName'] as String?)?.trim() ?? '';
    final last = (t['lastName'] as String?)?.trim() ?? '';
    return [first, last].where((s) => s.isNotEmpty).join(' ');
  }

  Future<void> _saveGuest() async {
    final first = _newFirstName.text.trim();
    final last = _newLastName.text.trim();
    if (first.isEmpty || last.isEmpty) {
      setState(() => _saveError = 'First and last name are required.');
      return;
    }
    setState(() { _saving = true; _saveError = null; });

    final email = await _currentEmail();
    final payload = <String, dynamic>{
      'paxType': _newBelow12 ? 'Child' : 'Adult',
      'title': _newTitle,
      'firstName': first,
      'lastName': last,
      if (email != null) 'user_email': email,
    };

    try {
      final response = await sl<TravellerApiService>().addTraveller(payload);
      final data = response.data;
      final traveller = (data is Map && data['traveller'] is Map)
          ? Map<String, dynamic>.from(data['traveller'] as Map)
          : payload;
      if (!mounted) return;
      setState(() {
        _saved = [..._saved, traveller];
        _selected.add(_saved.length - 1);
        _newFirstName.clear();
        _newLastName.clear();
        _newBelow12 = false;
        _newTitle = 'Mr';
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _saving = false; _saveError = 'Could not save this guest. Please try again.'; });
    }
  }

  void _startEdit(int index) {
    final t = _saved[index];
    _editTitle = (t['title'] as String?) ?? 'Mr';
    _editFirstName.text = (t['firstName'] as String?) ?? '';
    _editLastName.text = (t['lastName'] as String?) ?? '';
    _editBelow12 = (t['paxType'] as String?) == 'Child';
    setState(() => _editingIndex = index);
  }

  void _applyEdit() {
    final i = _editingIndex;
    if (i == null) return;
    final first = _editFirstName.text.trim();
    final last = _editLastName.text.trim();
    if (first.isEmpty || last.isEmpty) return;
    setState(() {
      _saved[i] = {
        ..._saved[i],
        'title': _editTitle,
        'firstName': first,
        'lastName': last,
        'paxType': _editBelow12 ? 'Child' : 'Adult',
      };
      _editingIndex = null;
    });
  }

  void _done() {
    final picks = [
      for (final i in _selected)
        AkHotelGuestPick(
          title: (_saved[i]['title'] as String?) ?? 'Mr',
          firstName: (_saved[i]['firstName'] as String?)?.trim() ?? '',
          lastName: (_saved[i]['lastName'] as String?)?.trim() ?? '',
          isChild: (_saved[i]['paxType'] as String?) == 'Child',
        ),
    ];
    Navigator.pop(context, picks);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.h(26)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: context.screenHeight * 0.86),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20))),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: context.h(10)),
                  Container(
                    width: context.w(44),
                    height: context.h(4),
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(context.r(4)),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: context.scrollPhysics,
                      padding: EdgeInsets.fromLTRB(context.w(18), context.h(16), context.w(18), context.h(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Guest',
                            style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.w800, color: _navy),
                          ),
                          SizedBox(height: context.h(8)),
                          Text(
                            "Name should be as per official govt. ID & travelers below 18 years of age cannot travel alone.",
                            style: TextStyle(fontSize: context.fs(12.5), color: _muted, height: 1.4),
                          ),
                          SizedBox(height: context.h(18)),
                          _newGuestForm(context),
                          SizedBox(height: context.h(24)),
                          _savedGuestsCard(context),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(context.w(18), 0, context.w(18), context.h(16)),
                    child: SizedBox(
                      width: double.infinity,
                      height: context.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _done,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                        ),
                        child: Text(
                          'DONE',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: context.fs(14), letterSpacing: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -context.h(4),
            right: context.w(16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: context.w(34),
                height: context.w(34),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Icon(Icons.close_rounded, size: context.w(18), color: _navy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _newGuestForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: context.w(78), child: _titleDropdown(context, _newTitle, (v) => setState(() => _newTitle = v ?? _newTitle))),
            SizedBox(width: context.w(8)),
            Expanded(child: _nameField(context, 'First Name', _newFirstName)),
            SizedBox(width: context.w(8)),
            Expanded(child: _nameField(context, 'Last Name', _newLastName)),
          ],
        ),
        SizedBox(height: context.h(12)),
        InkWell(
          onTap: () => setState(() => _newBelow12 = !_newBelow12),
          child: Row(
            children: [
              _checkbox(_newBelow12, (v) => setState(() => _newBelow12 = v)),
              SizedBox(width: context.w(8)),
              Text('Below 12 year of age', style: TextStyle(fontSize: context.fs(13), color: _navy)),
            ],
          ),
        ),
        if (_saveError != null) ...[
          SizedBox(height: context.h(8)),
          Text(_saveError!, style: TextStyle(fontSize: context.fs(11.5), color: Colors.red.shade400)),
        ],
        SizedBox(height: context.h(16)),
        SizedBox(
          width: double.infinity,
          height: context.buttonHeight,
          child: OutlinedButton(
            onPressed: _saving ? null : _saveGuest,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _accent, width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
            ),
            child: _saving
                ? SizedBox(width: context.w(18), height: context.w(18), child: const CircularProgressIndicator(strokeWidth: 2, color: _accent))
                : Text('SAVE GUEST', style: TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: context.fs(13.5), letterSpacing: 0.4)),
          ),
        ),
      ],
    );
  }

  Widget _savedGuestsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved Guests', style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: _navy)),
          SizedBox(height: context.h(12)),
          if (_editingIndex != null) ...[
            _editGuestPanel(context),
            SizedBox(height: context.h(14)),
            Divider(color: _border, height: 1),
            SizedBox(height: context.h(10)),
          ],
          if (_loadingSaved)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(12)),
              child: Row(
                children: [
                  SizedBox(width: context.w(16), height: context.w(16), child: const CircularProgressIndicator(strokeWidth: 2, color: _accent)),
                  SizedBox(width: context.w(10)),
                  Text('Loading saved guests…', style: TextStyle(fontSize: context.fs(12), color: _muted)),
                ],
              ),
            )
          else if (_saved.isEmpty)
            Text('No saved guests yet — add one above.', style: TextStyle(fontSize: context.fs(12.5), color: _muted))
          else
            for (var i = 0; i < _saved.length; i++) ...[
              _savedGuestRow(context, i),
              if (i != _saved.length - 1) Divider(color: _border, height: context.h(20)),
            ],
        ],
      ),
    );
  }

  Widget _savedGuestRow(BuildContext context, int index) {
    final t = _saved[index];
    final isChild = (t['paxType'] as String?) == 'Child';
    return Row(
      children: [
        _checkbox(_selected.contains(index), (v) {
          setState(() {
            if (v) {
              _selected.add(index);
            } else {
              _selected.remove(index);
            }
          });
        }),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fullName(t).isEmpty ? 'Guest' : _fullName(t),
                style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w700, color: _navy),
              ),
              if (isChild) ...[
                SizedBox(height: context.h(2)),
                Text('Below 12 year of age', style: TextStyle(fontSize: context.fs(10.5), color: _muted)),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => _startEdit(index),
          icon: Icon(Icons.edit_outlined, size: context.w(18), color: AppColors.AppBlue),
        ),
      ],
    );
  }

  Widget _editGuestPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Edit Guest Info', style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w700, color: _muted)),
            ),
            InkWell(
              onTap: () => setState(() => _editingIndex = null),
              child: Icon(Icons.close_rounded, size: context.w(18), color: _muted),
            ),
          ],
        ),
        SizedBox(height: context.h(10)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: context.w(78), child: _titleDropdown(context, _editTitle, (v) => setState(() => _editTitle = v ?? _editTitle))),
            SizedBox(width: context.w(8)),
            Expanded(child: _nameField(context, 'First Name', _editFirstName)),
            SizedBox(width: context.w(8)),
            Expanded(child: _nameField(context, 'Last Name', _editLastName)),
          ],
        ),
        SizedBox(height: context.h(12)),
        InkWell(
          onTap: () => setState(() => _editBelow12 = !_editBelow12),
          child: Row(
            children: [
              _checkbox(_editBelow12, (v) => setState(() => _editBelow12 = v)),
              SizedBox(width: context.w(8)),
              Text('Below 12 year of age', style: TextStyle(fontSize: context.fs(13), color: _navy)),
            ],
          ),
        ),
        SizedBox(height: context.h(14)),
        SizedBox(
          width: double.infinity,
          height: context.buttonHeight,
          child: OutlinedButton(
            onPressed: _applyEdit,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _accent, width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
            ),
            child: Text('UPDATE', style: TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: context.fs(13.5), letterSpacing: 0.4)),
          ),
        ),
      ],
    );
  }

  Widget _checkbox(bool value, ValueChanged<bool> onChanged) {
    return Checkbox(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      activeColor: _accent,
      side: const BorderSide(color: _border),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  InputDecoration _decoration(BuildContext context, String label) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.r(10)),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(14)),
      labelStyle: TextStyle(color: _muted, fontSize: context.fs(12.5)),
      floatingLabelStyle: const TextStyle(color: _accent),
      border: border(_border),
      enabledBorder: border(_border),
      focusedBorder: border(_accent),
    );
  }

  Widget _nameField(BuildContext context, String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(fontSize: context.fs(13.5), color: _navy, fontWeight: FontWeight.w600),
      decoration: _decoration(context, label),
    );
  }

  Widget _titleDropdown(BuildContext context, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: TextStyle(fontSize: context.fs(13.5), color: _navy, fontWeight: FontWeight.w600),
      decoration: _decoration(context, 'Title'),
      items: const ['Mr', 'Mrs', 'Ms', 'Mstr', 'Miss']
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
