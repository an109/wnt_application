part of 'trisha_cards.dart';

// ---- travel insurance ---------------------------------------------------------------

String _cover(dynamic amount, dynamic currency) {
  final v = amount as num?;
  if (v == null) return '';
  final c = '${currency ?? 'USD'}';
  return '${c == 'INR' ? '₹' : '$c '}${_inr.format(v)}';
}

/// A plan from the quotes — styled like the app's own insurance results
/// (AKInsurance InsPlanCard): insurer logo, coverage, premium, ribbon.
class _InsurancePlanCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _InsurancePlanCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final highlights = (data['highlights'] as List? ?? []).map((e) => '$e').toList();
    final cover = _cover(data['sum_insured'], data['cover_currency']);
    final recommended = data['recommended'] == true;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.fx(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.fx(12)),
            border: Border.all(color: InsTokens.line),
          ),
          child: Stack(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.fx(12), context.fx(12), context.fx(12), context.fx(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    InsProviderLogo(provider: '${data['provider']}', logoUrl: data['logo'] as String?, width: 44, height: 44),
                    SizedBox(width: context.fx(10)),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: recommended ? context.fx(84) : 0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${data['option_number']}. ${data['name']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TrishaStyle.body(context, 13, weight: FontWeight.w600, color: InsTokens.navy, height: 1.25)),
                          Text('${data['provider']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TrishaStyle.body(context, 11, color: InsTokens.subGrey, height: 1.3)),
                          if (cover.isNotEmpty) ...[
                            SizedBox(height: context.fx(4)),
                            Text.rich(TextSpan(children: [
                              TextSpan(text: 'Coverage : ',
                                  style: TrishaStyle.body(context, 11, color: InsTokens.subGrey, height: 1.2)),
                              TextSpan(text: cover,
                                  style: TrishaStyle.body(context, 11, weight: FontWeight.w600, color: InsTokens.navy, height: 1.2)),
                            ])),
                          ],
                        ]),
                      ),
                    ),
                  ]),
                  if (highlights.isNotEmpty) ...[
                    SizedBox(height: context.fx(8)),
                    for (final h in highlights)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.fx(2)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.check_rounded, size: context.fx(13), color: InsTokens.green),
                          SizedBox(width: context.fx(4)),
                          Expanded(
                            child: Text(h, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TrishaStyle.body(context, 11, color: InsTokens.navy, height: 1.3)),
                          ),
                        ]),
                      ),
                  ],
                  SizedBox(height: context.fx(8)),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Flexible(
                      child: Text(onTap != null ? 'View Policy Details' : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TrishaStyle.body(context, 11, weight: FontWeight.w600, color: InsTokens.blue)),
                    ),
                    if (onTap != null) Icon(Icons.chevron_right_rounded, size: context.fx(18), color: InsTokens.blue),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('PREMIUM',
                          style: TrishaStyle.body(context, 10, color: InsTokens.premiumLabel, height: 1.2)
                              .copyWith(letterSpacing: 0.3)),
                      Text(InsTokens.rupees(data['premium'] as num? ?? 0),
                          style: TrishaStyle.body(context, 16, weight: FontWeight.w700, color: InsTokens.blue, height: 1.2)),
                    ]),
                  ]),
                ],
              ),
            ),
            if (recommended)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(2)),
                  decoration: BoxDecoration(
                    gradient: InsTokens.ribbon,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(context.fx(8))),
                  ),
                  child: Text('RECOMMENDED',
                      style: TrishaStyle.body(context, 10, weight: FontWeight.w600, color: Colors.white, height: 1.4)
                          .copyWith(letterSpacing: 0.3)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _InsurancePlanDetailsCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _InsurancePlanDetailsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final benefits = (data['benefits'] as List? ?? []).whereType<Map>().toList();
    final terms = (data['terms'] as List? ?? []).map((e) => '$e').toList();
    final notes = (data['notes'] as List? ?? []).map((e) => '$e').toList();
    final more = (data['more_benefits'] as num?)?.toInt() ?? 0;
    final small = TrishaStyle.body(context, 11, color: InsTokens.subGrey, height: 1.35);
    return Container(
      padding: EdgeInsets.all(context.fx(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: InsTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            InsProviderLogo(provider: '${data['provider']}', logoUrl: data['logo'] as String?, width: 40, height: 40),
            SizedBox(width: context.fx(10)),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${data['name']}',
                    style: TrishaStyle.body(context, 14, weight: FontWeight.w700, color: InsTokens.navy, height: 1.25)),
                Text('${data['provider']}', style: small),
              ]),
            ),
          ]),
          SizedBox(height: context.fx(10)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(8)),
            decoration: BoxDecoration(color: InsTokens.pageBg, borderRadius: BorderRadius.circular(context.fx(8))),
            child: Row(children: [
              Expanded(
                child: Text('Benefit', style: TrishaStyle.body(context, 11, weight: FontWeight.w600, color: InsTokens.navy)),
              ),
              SizedBox(
                width: context.fx(110),
                child: Text('Cover', textAlign: TextAlign.right,
                    style: TrishaStyle.body(context, 11, weight: FontWeight.w600, color: InsTokens.navy)),
              ),
            ]),
          ),
          for (final b in benefits)
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(7)),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: InsTokens.line))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${b['title']}', style: TrishaStyle.body(context, 12, color: InsTokens.navy, height: 1.3)),
                    if ('${b['deductible'] ?? ''}'.isNotEmpty) Text('Deductible ${b['deductible']}', style: small),
                  ]),
                ),
                SizedBox(width: context.fx(8)),
                SizedBox(
                  width: context.fx(110),
                  child: Text('${b['cover'] ?? ''}'.isEmpty ? '—' : '${b['cover']}',
                      textAlign: TextAlign.right,
                      style: TrishaStyle.body(context, 12, weight: FontWeight.w600, color: InsTokens.navy, height: 1.3)),
                ),
              ]),
            ),
          if (more > 0)
            Padding(
              padding: EdgeInsets.only(top: context.fx(6)),
              child: Text('+ $more more benefits in the policy wording', style: small),
            ),
          if (notes.isNotEmpty) ...[
            SizedBox(height: context.fx(8)),
            for (final n in notes) Text('• $n', style: small),
          ],
          if (terms.isNotEmpty) ...[
            SizedBox(height: context.fx(10)),
            for (var i = 0; i < terms.length; i++)
              InkWell(
                onTap: () => _openExternal(terms[i]),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.fx(3)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.picture_as_pdf_rounded, size: context.fx(16), color: InsTokens.blue),
                    SizedBox(width: context.fx(6)),
                    Text(terms.length == 1 ? 'Policy wording' : 'Policy document ${i + 1}',
                        style: TrishaStyle.body(context, 12, weight: FontWeight.w600, color: InsTokens.blue)),
                  ]),
                ),
              ),
          ],
          SizedBox(height: context.fx(10)),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: 'Coverage : ', style: small),
                TextSpan(text: _cover(data['sum_insured'], data['cover_currency']),
                    style: TrishaStyle.body(context, 12, weight: FontWeight.w600, color: InsTokens.navy)),
              ])),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('PREMIUM',
                  style: TrishaStyle.body(context, 10, color: InsTokens.premiumLabel).copyWith(letterSpacing: 0.3)),
              Text(InsTokens.rupees(data['premium'] as num? ?? 0),
                  style: TrishaStyle.body(context, 18, weight: FontWeight.w700, color: InsTokens.blue, height: 1.1)),
            ]),
          ]),
        ],
      ),
    );
  }
}

/// Nominee, address, PAN and the health declaration. Sent as one
/// `insurance_details` action straight to the booking flow — none of it goes
/// through the chat text or the AI model.
class _InsuranceDetailsForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool active;
  final TrishaCardHandler handler;

  const _InsuranceDetailsForm({required this.data, required this.active, required this.handler});

  @override
  State<_InsuranceDetailsForm> createState() => _InsuranceDetailsFormState();
}

class _InsuranceDetailsFormState extends State<_InsuranceDetailsForm> {
  late final Map<String, dynamic> _prefill =
      (widget.data['prefill'] as Map? ?? {}).cast<String, dynamic>();
  late final _nomineeFirst = TextEditingController(text: '${(_prefill['nominee'] as Map?)?['first_name'] ?? ''}');
  late final _nomineeLast = TextEditingController(text: '${(_prefill['nominee'] as Map?)?['last_name'] ?? ''}');
  late final _line1 = TextEditingController(text: '${_prefill['line1'] ?? ''}');
  late final _line2 = TextEditingController(text: '${_prefill['line2'] ?? ''}');
  late final _city = TextEditingController(text: '${_prefill['city'] ?? ''}');
  late final _pincode = TextEditingController(text: '${_prefill['pincode'] ?? ''}');
  late final _pan = TextEditingController();
  late final _description = TextEditingController();
  late final _since = TextEditingController();
  late String? _relation = (_prefill['nominee'] as Map?)?['relation'] as String?;
  late String? _state = _states.contains(_prefill['state']) ? _prefill['state'] as String : null;
  bool? _hasPed;
  final _conditions = <String>{};

  List<String> get _relations => (widget.data['nominee_relations'] as List? ?? []).map((e) => '$e').toList();
  List<String> get _states => (widget.data['states'] as List? ?? []).map((e) => '$e').toList();
  List<Map<String, dynamic>> get _questions => (widget.data['questions'] as List? ?? [])
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      // Tick boxes only; the insurer's free-text row ("any other disease") is
      // the description field below.
      .where((q) => '${q['code']}'.toUpperCase().startsWith('PED') &&
          '${q['selection_type']}'.toLowerCase().replaceAll(' ', '') == 'checkbox')
      .toList();

  @override
  void dispose() {
    for (final c in [_nomineeFirst, _nomineeLast, _line1, _line2, _city, _pincode, _pan, _description, _since]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ready =>
      _nomineeFirst.text.trim().isNotEmpty &&
      _nomineeLast.text.trim().isNotEmpty &&
      _relation != null &&
      _line1.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      _state != null &&
      RegExp(r'^\d{6}$').hasMatch(_pincode.text.trim()) &&
      _hasPed != null &&
      (_hasPed == false || _conditions.isNotEmpty || _description.text.trim().isNotEmpty);

  void _submit() {
    widget.handler.action(
      'insurance_details',
      data: {
        'nominee': {
          'first_name': _nomineeFirst.text.trim(),
          'last_name': _nomineeLast.text.trim(),
          'relation': _relation,
        },
        'address': {
          'line1': _line1.text.trim(),
          'line2': _line2.text.trim(),
          'city': _city.text.trim(),
          'state': _state,
          'pincode': _pincode.text.trim(),
        },
        'pan': _pan.text.trim().toUpperCase(),
        'health': {
          'has_ped': _hasPed,
          'conditions': _conditions.toList(),
          'description': _description.text.trim(),
          'suffering_since': _since.text.trim(),
        },
      },
      // Shown as the customer's bubble: never echo the details themselves.
      label: 'Details added',
    );
  }

  InputDecoration _decoration(BuildContext context, String label) => InputDecoration(
        labelText: label,
        isDense: true,
        labelStyle: TrishaStyle.body(context, 12, color: TrishaStyle.hint),
        contentPadding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(10)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.fx(10))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.fx(10)),
          borderSide: const BorderSide(color: TrishaStyle.cardBorder),
        ),
      );

  Widget _field(BuildContext context, TextEditingController c, String label,
          {TextInputType? keyboard, int? maxLength, TextCapitalization caps = TextCapitalization.words}) =>
      Padding(
        padding: EdgeInsets.only(bottom: context.fx(8)),
        child: TextField(
          controller: c,
          enabled: widget.active,
          keyboardType: keyboard,
          maxLength: maxLength,
          textCapitalization: caps,
          onChanged: (_) => setState(() {}),
          style: TrishaStyle.body(context, 13, height: 1.2),
          decoration: _decoration(context, label).copyWith(counterText: ''),
        ),
      );

  Widget _dropdown(BuildContext context, String label, String? value, List<String> items, ValueChanged<String?> onChanged) =>
      Padding(
        padding: EdgeInsets.only(bottom: context.fx(8)),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: _decoration(context, label),
          style: TrishaStyle.body(context, 13, height: 1.2),
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
          onChanged: widget.active ? (v) => setState(() => onChanged(v)) : null,
        ),
      );

  Widget _section(BuildContext context, String title) => Padding(
        padding: EdgeInsets.only(top: context.fx(6), bottom: context.fx(8)),
        child: Text(title, style: TrishaStyle.body(context, 13, weight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(context, 'Nominee'),
          Row(children: [
            Expanded(child: _field(context, _nomineeFirst, 'First name')),
            SizedBox(width: context.fx(8)),
            Expanded(child: _field(context, _nomineeLast, 'Last name')),
          ]),
          _dropdown(context, 'Relation', _relation, _relations, (v) => _relation = v),
          _section(context, 'Your address'),
          _field(context, _line1, 'Address line 1'),
          _field(context, _line2, 'Address line 2 (optional)'),
          Row(children: [
            Expanded(child: _field(context, _city, 'City')),
            SizedBox(width: context.fx(8)),
            Expanded(child: _field(context, _pincode, 'Pincode', keyboard: TextInputType.number, maxLength: 6)),
          ]),
          _dropdown(context, 'State', _state, _states, (v) => _state = v),
          _field(context, _pan, 'PAN (optional)', maxLength: 10, caps: TextCapitalization.characters),
          _section(context, 'Health declaration'),
          Text('Does any traveller have a pre-existing disease?', style: TrishaStyle.body(context, 12, height: 1.35)),
          Row(children: [
            for (final yes in [false, true])
              Padding(
                padding: EdgeInsets.only(right: context.fx(8), top: context.fx(6)),
                child: ChoiceChip(
                  label: Text(yes ? 'Yes' : 'No'),
                  selected: _hasPed == yes,
                  onSelected: widget.active ? (_) => setState(() => _hasPed = yes) : null,
                  selectedColor: const Color(0xFFDBEAFE),
                  labelStyle: TrishaStyle.body(context, 12, height: 1.1),
                ),
              ),
          ]),
          if (_hasPed == true) ...[
            SizedBox(height: context.fx(6)),
            for (final q in questions)
              CheckboxListTile(
                value: _conditions.contains('${q['code']}'),
                onChanged: widget.active
                    ? (on) => setState(() => on == true ? _conditions.add('${q['code']}') : _conditions.remove('${q['code']}'))
                    : null,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: TrishaStyle.brandBlue,
                title: Text('${q['title']}', style: TrishaStyle.body(context, 12, height: 1.25)),
              ),
            _field(context, _description, questions.isEmpty ? 'Which condition?' : 'Anything else (optional)',
                caps: TextCapitalization.sentences),
            _field(context, _since, 'Since when? (e.g. 2019)', keyboard: TextInputType.number, maxLength: 4),
          ],
          SizedBox(height: context.fx(6)),
          Text('These details go straight to the insurer.', style: TrishaStyle.body(context, 10, color: TrishaStyle.hint)),
          SizedBox(height: context.fx(10)),
          _PrimaryButton(label: 'Continue', onTap: widget.active && _ready ? _submit : null),
        ],
      ),
    );
  }
}

class _InsuranceReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool active;
  final TrishaCardHandler handler;

  const _InsuranceReviewCard({required this.data, required this.active, required this.handler});

  @override
  Widget build(BuildContext context) {
    final travellers = (data['travellers'] as List? ?? []).map((e) => '$e').toList();
    final countries = (data['countries'] as List? ?? []).map((e) => '$e').join(', ');
    Widget line(String label, String value) => Padding(
          padding: EdgeInsets.only(bottom: context.fx(6)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: context.fx(84),
              child: Text(label, style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.35)),
            ),
            Expanded(child: Text(value, style: TrishaStyle.body(context, 12, height: 1.35))),
          ]),
        );
    final end = data['end_date'];
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${data['plan']}', style: TrishaStyle.body(context, 14, weight: FontWeight.w700, height: 1.25)),
          Text('${data['provider']} · ${data['policy_type']}',
              style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.3)),
          const Divider(color: TrishaStyle.cardBorder),
          line('Trip', countries),
          line('Dates', end == null ? 'From ${_date(data['start_date'])}' : '${_date(data['start_date'])} – ${_date(end)}'),
          line('Travellers', travellers.join(', ')),
          line('Nominee', '${data['nominee']}'),
          line('Health', '${data['health']}'),
          line('Sum insured', _cover(data['sum_insured'], data['cover_currency'])),
          const Divider(color: TrishaStyle.cardBorder),
          Row(children: [
            Text('Total premium', style: TrishaStyle.body(context, 13, weight: FontWeight.w600)),
            const Spacer(),
            Text(_money(data['premium']), style: TrishaStyle.body(context, 18, weight: FontWeight.w700, height: 1)),
          ]),
          SizedBox(height: context.fx(12)),
          _PrimaryButton(
            label: 'Confirm & pay',
            onTap: active ? () => handler.action('confirm_booking', label: 'Confirm & pay') : null,
          ),
        ],
      ),
    );
  }
}

class _InsuranceConfirmedCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _InsuranceConfirmedCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final number = data['policy_number'] ?? data['transaction_id'];
    final end = data['end_date'];
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.verified_user_rounded, color: Colors.green.shade600, size: context.fx(22)),
            SizedBox(width: context.fx(8)),
            Text("You're insured", style: TrishaStyle.body(context, 14, weight: FontWeight.w700)),
          ]),
          SizedBox(height: context.fx(10)),
          Text(data['policy_number'] != null ? 'Policy number' : 'Booking reference',
              style: TrishaStyle.body(context, 11, color: TrishaStyle.hint)),
          SelectableText('${number ?? '-'}',
              style: TrishaStyle.body(context, 20, weight: FontWeight.w700, height: 1.2).copyWith(letterSpacing: 1.2)),
          SizedBox(height: context.fx(10)),
          Text('${data['plan']} · ${data['provider']}', style: TrishaStyle.body(context, 13, weight: FontWeight.w600)),
          Text(
            '${(data['countries'] as List? ?? []).join(', ')} · '
            '${end == null ? 'from ${_date(data['start_date'])}' : '${_date(data['start_date'])} – ${_date(end)}'} · '
            '${data['travellers']} traveller${data['travellers'] == 1 ? '' : 's'}',
            style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.35),
          ),
          SizedBox(height: context.fx(6)),
          Text('Paid ${_money(data['amount_paid'])}', style: TrishaStyle.body(context, 11, color: TrishaStyle.hint)),
        ],
      ),
    );
  }
}
