/// Departure ("Starting From") cities for the holiday search.
///
/// The DIY backend exposes no origins endpoint — `/destinations/` is the
/// "Travelling to" list only — so the origin list ships with the app. The
/// slug format is the one the API expects for `?origin=`: the city name in
/// kebab case followed by the ISO country code, e.g. `new-delhi-in`.
class DiyOrigin {
  final String slug;
  final String name;
  final String state;
  final double lat;
  final double lng;

  const DiyOrigin({
    required this.slug,
    required this.name,
    required this.state,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'state': state,
    'lat': lat,
    'lng': lng,
  };

  /// Slugs earlier builds shipped that the backend does not know. A search
  /// saved on one of those builds is read back under the backend's slug, or
  /// the price call would answer "We do not fly from bengaluru-in".
  static const Map<String, String> _renamed = {
    'bengaluru-in': 'bangalore-in',
    'kochi-in': 'cochin-in',
    'bhubaneswar-in': 'bhubaneshwar-in',
  };

  static DiyOrigin? fromJson(dynamic json) {
    if (json is! Map) return null;
    final raw = json['slug']?.toString() ?? '';
    final slug = _renamed[raw] ?? raw;
    if (slug.isEmpty) return null;
    return DiyOrigin(
      slug: slug,
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DiyOrigins {
  const DiyOrigins._();

  static const DiyOrigin newDelhi = DiyOrigin(
    slug: 'new-delhi-in',
    name: 'New Delhi',
    state: 'Delhi',
    lat: 28.6139,
    lng: 77.2090,
  );

  /// The origin the form opens on when the user has no saved search — the
  /// same city the API samples use, so the first Search always returns
  /// results instead of an empty screen.
  static const DiyOrigin defaultOrigin = newDelhi;

  static const List<DiyOrigin> all = [
    newDelhi,
    DiyOrigin(
      slug: 'mumbai-in',
      name: 'Mumbai',
      state: 'Maharashtra',
      lat: 19.0760,
      lng: 72.8777,
    ),
    DiyOrigin(
      slug: 'bangalore-in',
      name: 'Bengaluru',
      state: 'Karnataka',
      lat: 12.9716,
      lng: 77.5946,
    ),
    DiyOrigin(
      slug: 'hyderabad-in',
      name: 'Hyderabad',
      state: 'Telangana',
      lat: 17.3850,
      lng: 78.4867,
    ),
    DiyOrigin(
      slug: 'chennai-in',
      name: 'Chennai',
      state: 'Tamil Nadu',
      lat: 13.0827,
      lng: 80.2707,
    ),
    DiyOrigin(
      slug: 'kolkata-in',
      name: 'Kolkata',
      state: 'West Bengal',
      lat: 22.5726,
      lng: 88.3639,
    ),
    DiyOrigin(
      slug: 'pune-in',
      name: 'Pune',
      state: 'Maharashtra',
      lat: 18.5204,
      lng: 73.8567,
    ),
    DiyOrigin(
      slug: 'ahmedabad-in',
      name: 'Ahmedabad',
      state: 'Gujarat',
      lat: 23.0225,
      lng: 72.5714,
    ),
    DiyOrigin(
      slug: 'jaipur-in',
      name: 'Jaipur',
      state: 'Rajasthan',
      lat: 26.9124,
      lng: 75.7873,
    ),
    DiyOrigin(
      slug: 'lucknow-in',
      name: 'Lucknow',
      state: 'Uttar Pradesh',
      lat: 26.8467,
      lng: 80.9462,
    ),
    DiyOrigin(
      slug: 'chandigarh-in',
      name: 'Chandigarh',
      state: 'Chandigarh',
      lat: 30.7333,
      lng: 76.7794,
    ),
    DiyOrigin(
      slug: 'cochin-in',
      name: 'Kochi',
      state: 'Kerala',
      lat: 9.9312,
      lng: 76.2673,
    ),
    DiyOrigin(
      slug: 'goa-in',
      name: 'Goa',
      state: 'Goa',
      lat: 15.2993,
      lng: 74.1240,
    ),
    DiyOrigin(
      slug: 'indore-in',
      name: 'Indore',
      state: 'Madhya Pradesh',
      lat: 22.7196,
      lng: 75.8577,
    ),
    DiyOrigin(
      slug: 'guwahati-in',
      name: 'Guwahati',
      state: 'Assam',
      lat: 26.1445,
      lng: 91.7362,
    ),
    DiyOrigin(
      slug: 'bhubaneshwar-in',
      name: 'Bhubaneswar',
      state: 'Odisha',
      lat: 20.2961,
      lng: 85.8245,
    ),
    DiyOrigin(
      slug: 'varanasi-in',
      name: 'Varanasi',
      state: 'Uttar Pradesh',
      lat: 25.3176,
      lng: 82.9739,
    ),
    DiyOrigin(
      slug: 'amritsar-in',
      name: 'Amritsar',
      state: 'Punjab',
      lat: 31.6340,
      lng: 74.8723,
    ),
    DiyOrigin(
      slug: 'nagpur-in',
      name: 'Nagpur',
      state: 'Maharashtra',
      lat: 21.1458,
      lng: 79.0882,
    ),
    DiyOrigin(
      slug: 'coimbatore-in',
      name: 'Coimbatore',
      state: 'Tamil Nadu',
      lat: 11.0168,
      lng: 76.9558,
    ),
  ];

  static List<DiyOrigin> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (o) =>
              o.name.toLowerCase().contains(q) ||
              o.state.toLowerCase().contains(q),
        )
        .toList();
  }

  static DiyOrigin? bySlug(String slug) {
    for (final o in all) {
      if (o.slug == slug) return o;
    }
    return null;
  }

  /// Nearest listed origin to a coordinate, for "Use current location".
  /// Plain squared-degree distance is enough to pick between cities that are
  /// hundreds of kilometres apart.
  static DiyOrigin nearest(double lat, double lng) {
    DiyOrigin best = all.first;
    double bestDist = double.infinity;
    for (final o in all) {
      final dLat = o.lat - lat;
      final dLng = o.lng - lng;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestDist) {
        bestDist = d;
        best = o;
      }
    }
    return best;
  }
}
