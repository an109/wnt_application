import '../../domain/entity/AKFareRule_entity.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkFareRuleTripRequestModel extends AkFareRuleTripRequestEntity {
  const AkFareRuleTripRequestModel({
    required super.index,
    required super.amount,
    required super.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'amount': amount,
      'order_id': orderId,
    };
  }
}

class AkFareRuleRequestModel extends AkFareRuleRequestEntity {
  const AkFareRuleRequestModel({
    required super.tui,
    required super.trips,
  });

  factory AkFareRuleRequestModel.fromEntity(AkFareRuleRequestEntity entity) {
    return AkFareRuleRequestModel(
      tui: entity.tui,
      trips: entity.trips
          .map((t) => AkFareRuleTripRequestModel(
                index: t.index,
                amount: t.amount,
                orderId: t.orderId,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tui': tui,
      'trips': trips.map((t) => (t as AkFareRuleTripRequestModel).toJson()).toList(),
    };
  }
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkFareRuleModel extends AkFareRuleEntity {
  const AkFareRuleModel({
    required super.success,
    required super.ruleTexts,
    required super.raw,
  });

  factory AkFareRuleModel.fromJson(Map<String, dynamic> json) {
    return AkFareRuleModel(
      success: json['success'] ?? false,
      ruleTexts: _flattenRules(json),
      raw: json,
    );
  }

  /// The doc doesn't pin down an exact response shape beyond "cancellation
  /// and change-fee slabs". A real observed response nests rules under
  /// `Trips[].Journey[].Segments[].Rules[].Rule[].Info[]` (not top-level),
  /// e.g.:
  /// `{"Trips":[{"Journey":[{"Segments":[{"Rules":[{"Rule":[{"Head":
  /// "Cancellation Fee(Per Pax/ Per Journey)","Info":[{"Description":
  /// "Cancellation","AdultAmount":"Non Refundable"}]}]}]}]}]}]}`
  /// — this walks that real path, plus keeps the original top-level guess
  /// as a fallback in case another Akbar response uses a flatter shape.
  /// Silently skips anything it doesn't recognise rather than throwing.
  static List<String> _flattenRules(Map<String, dynamic> json) {
    final texts = <String>[];

    void flattenRuleGroups(dynamic rulesList) {
      if (rulesList is! List) return;
      for (final ruleGroup in rulesList) {
        if (ruleGroup is! Map<String, dynamic>) continue;

        final remark = ruleGroup['FareRuleRemark'] ?? ruleGroup['FareRuleRemarks'];
        if (remark is String && remark.trim().isNotEmpty) texts.add(remark.trim());

        final ruleText = ruleGroup['FareRuleText'];
        if (ruleText is String && ruleText.trim().isNotEmpty) texts.add(ruleText.trim());

        final subRules = ruleGroup['Rule'];
        if (subRules is! List) continue;
        for (final sub in subRules) {
          if (sub is! Map<String, dynamic>) continue;
          final head = sub['Head']?.toString() ?? '';
          final infoList = sub['Info'];
          if (infoList is! List) continue;
          for (final info in infoList) {
            if (info is! Map<String, dynamic>) continue;
            final desc = info['Description']?.toString() ?? '';
            final adult = info['AdultAmount']?.toString() ?? '';
            final line = [
              if (head.isNotEmpty) head,
              if (desc.isNotEmpty) desc,
              if (adult.isNotEmpty) adult,
            ].join(' — ');
            if (line.isNotEmpty) texts.add(line);
          }
        }
      }
    }

    // Original top-level guess (kept for backward compatibility).
    flattenRuleGroups(json['Rules'] ?? json['FareRules'] ?? json['rules']);

    // Real observed shape: Trips[].Journey[].Segments[].Rules[].
    final tripsList = json['Trips'];
    if (tripsList is List) {
      for (final trip in tripsList) {
        if (trip is! Map<String, dynamic>) continue;
        final journeyList = trip['Journey'];
        if (journeyList is! List) continue;
        for (final journey in journeyList) {
          if (journey is! Map<String, dynamic>) continue;
          final segmentsList = journey['Segments'];
          if (segmentsList is! List) continue;
          for (final segment in segmentsList) {
            if (segment is! Map<String, dynamic>) continue;
            flattenRuleGroups(segment['Rules']);
          }
        }
      }
    }

    return texts;
  }
}
