/// Aggregate guest review score for an Akbar hotel: [rating] out of 5, averaged
/// over [count] guest ratings. `(0, 0)` means the API supplied none.
typedef AkHotelReviewSummary = ({double rating, int count});

/// This backend isn't consistent about where the guest review lives: some
/// responses carry a single `userReview: {rating, count}` object, others (the
/// Hotel Detail Content endpoint for some providers) a `reviews` list of
/// `{provider, rating, count}` rows, one per review source. This reads either
/// shape, and only ever reports what the API sent — nothing is defaulted to a
/// made-up score.
///
/// With several sources in a `reviews` list the counts are summed and the
/// rating is the count-weighted average, so a source with 1 rating doesn't
/// outweigh one with 500. Rows with no positive rating are ignored.
AkHotelReviewSummary parseAkHotelReview(Map<String, dynamic> hotel) {
  final userReview = hotel['userReview'];
  if (userReview is Map) {
    final rating = _num(userReview['rating']) ?? 0.0;
    final count = _num(userReview['count'])?.toInt() ?? 0;
    if (rating > 0 && count > 0) return (rating: rating, count: count);
  }

  final reviews = hotel['reviews'];
  if (reviews is List) {
    double weighted = 0;
    int total = 0;
    for (final r in reviews.whereType<Map>()) {
      final rating = _num(r['rating']) ?? 0.0;
      final count = _num(r['count'])?.toInt() ?? 0;
      if (rating <= 0 || count <= 0) continue;
      weighted += rating * count;
      total += count;
    }
    if (total > 0) return (rating: weighted / total, count: total);
  }

  return (rating: 0.0, count: 0);
}

double? _num(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}
