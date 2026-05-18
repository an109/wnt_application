import '../../domain/entities/Popular_destination_entity.dart';

class DestinationModel extends DestinationEntity {
  final int id;
  final int reseller;
  final String name;
  final String price;
  final String priceCurrency;
  final String imageUrl;
  final String country;
  final String state;
  final String city;
  final String type;
  final bool isFeatured;
  final bool showInHolidaysTrending;
  final String domesticRegion;
  final String originalPrice;
  final String originalPriceCurrency;
  final List<String> whereToGoMonths;
  final String tagline;
  final String description;
  final String longDescription;
  // final List<PackageModel>? packages;
  final int order;
  final bool isActive;
  final DateTime created;
  final DateTime updated;
  final String img;

  DestinationModel({
    required this.id,
    required this.reseller,
    required this.name,
    required this.price,
    required this.priceCurrency,
    required this.imageUrl,
    required this.country,
    required this.state,
    required this.city,
    required this.type,
    required this.isFeatured,
    required this.showInHolidaysTrending,
    required this.domesticRegion,
    required this.originalPrice,
    required this.originalPriceCurrency,
    required this.whereToGoMonths,
    required this.tagline,
    required this.description,
    required this.longDescription,
    List<PackageModel>? packages,
    required this.order,
    required this.isActive,
    required this.created,
    required this.updated,
    required this.img,
  }) : super(
    id: id,
    reseller: reseller,
    name: name,
    price: price,
    priceCurrency: priceCurrency,
    imageUrl: imageUrl,
    country: country,
    state: state,
    city: city,
    type: type,
    isFeatured: isFeatured,
    showInHolidaysTrending: showInHolidaysTrending,
    domesticRegion: domesticRegion,
    originalPrice: originalPrice,
    originalPriceCurrency: originalPriceCurrency,
    whereToGoMonths: whereToGoMonths,
    tagline: tagline,
    description: description,
    longDescription: longDescription,
    packages: packages?.map((pkg) => PackageEntity(
      id: pkg.id,
      title: pkg.title,
      imageUrl: pkg.imageUrl,
      slug: pkg.slug,
      nights: pkg.nights,
      days: pkg.days,
      packagePrice: pkg.packagePrice,
      originalPrice: pkg.originalPrice,
      accommodationTiers: pkg.accommodationTiers
          .map((tier) => AccommodationTierEntity(
        name: tier.name,
        tier: tier.tier,
        stars: tier.stars,
      ))
          .toList(),
    )).toList(),
    order: order,
    isActive: isActive,
    created: created,
    updated: updated,
    img: img,
  );

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      id: json['id'] ?? 0,
      reseller: json['reseller'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      priceCurrency: json['price_currency'] ?? '',
      imageUrl: json['image_url'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      type: json['type'] ?? '',
      isFeatured: json['is_featured'] ?? false,
      showInHolidaysTrending: json['show_in_holidays_trending'] ?? false,
      domesticRegion: json['domestic_region'] ?? '',
      originalPrice: json['original_price'] ?? '',
      originalPriceCurrency: json['original_price_currency'] ?? '',
      whereToGoMonths: json['where_to_go_months'] != null
          ? List<String>.from(json['where_to_go_months'])
          : [],
      tagline: json['tagline'] ?? '',
      description: json['description'] ?? '',
      longDescription: json['long_description'] ?? '',
      packages: json['packages'] != null
          ? (json['packages'] as List)
          .map((pkg) => PackageModel.fromJson(pkg))
          .toList()
          : null,
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? false,
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
      img: json['img'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reseller': reseller,
      'name': name,
      'price': price,
      'price_currency': priceCurrency,
      'image_url': imageUrl,
      'country': country,
      'state': state,
      'city': city,
      'type': type,
      'is_featured': isFeatured,
      'show_in_holidays_trending': showInHolidaysTrending,
      'domestic_region': domesticRegion,
      'original_price': originalPrice,
      'original_price_currency': originalPriceCurrency,
      'where_to_go_months': whereToGoMonths,
      'tagline': tagline,
      'description': description,
      'long_description': longDescription,
      'packages': packages?.map((pkg) => pkg.toString()).toList(),
      'order': order,
      'is_active': isActive,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'img': img,
    };
  }
}

class PackageModel {
  final int id;
  final int destination;
  final String title;
  final String imageUrl;
  final String slug;
  final int nights;
  final int days;
  final int countries;
  final int cities;
  final List<dynamic> locations;
  final String country;
  final String state;
  final String city;
  final String itinerary;
  final String itineraryText;
  final String tags;
  final String inclusions;
  final String highlights;
  final List<AccommodationTierModel> accommodationTiers;
  final String packagePrice;
  final String? originalPrice;
  final String offerText;
  final bool isWanderNovaChoice;
  final bool showInHolidaysTopPicks;
  final List<String> holidayThemes;
  final String inclusionsDetail;
  final String exclusions;
  final String whatsappNumber;
  final Map<String, dynamic> cancellationPolicy;
  final List<ItineraryDayModel> itineraryDays;
  final int order;
  final bool isActive;
  final DateTime created;
  final DateTime updated;

  PackageModel({
    required this.id,
    required this.destination,
    required this.title,
    required this.imageUrl,
    required this.slug,
    required this.nights,
    required this.days,
    required this.countries,
    required this.cities,
    required this.locations,
    required this.country,
    required this.state,
    required this.city,
    required this.itinerary,
    required this.itineraryText,
    required this.tags,
    required this.inclusions,
    required this.highlights,
    required this.accommodationTiers,
    required this.packagePrice,
    this.originalPrice,
    required this.offerText,
    required this.isWanderNovaChoice,
    required this.showInHolidaysTopPicks,
    required this.holidayThemes,
    required this.inclusionsDetail,
    required this.exclusions,
    required this.whatsappNumber,
    required this.cancellationPolicy,
    required this.itineraryDays,
    required this.order,
    required this.isActive,
    required this.created,
    required this.updated,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'] ?? 0,
      destination: json['destination'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      slug: json['slug'] ?? '',
      nights: json['nights'] ?? 0,
      days: json['days'] ?? 0,
      countries: json['countries'] ?? 0,
      cities: json['cities'] ?? 0,
      locations: json['locations'] ?? [],
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      itinerary: json['itinerary'] ?? '',
      itineraryText: json['itinerary_text'] ?? '',
      tags: json['tags'] ?? '',
      inclusions: json['inclusions'] ?? '',
      highlights: json['highlights'] ?? '',
      accommodationTiers: json['accommodation_tiers'] != null
          ? (json['accommodation_tiers'] as List)
          .map((tier) => AccommodationTierModel.fromJson(tier))
          .toList()
          : [],
      packagePrice: json['package_price'] ?? '',
      originalPrice: json['original_price'],
      offerText: json['offer_text'] ?? '',
      isWanderNovaChoice: json['is_wander_nova_choice'] ?? false,
      showInHolidaysTopPicks: json['show_in_holidays_top_picks'] ?? false,
      holidayThemes: json['holiday_themes'] != null
          ? List<String>.from(json['holiday_themes'])
          : [],
      inclusionsDetail: json['inclusions_detail'] ?? '',
      exclusions: json['exclusions'] ?? '',
      whatsappNumber: json['whatsapp_number'] ?? '',
      cancellationPolicy: json['cancellation_policy'] ?? {},
      itineraryDays: json['itinerary_days'] != null
          ? (json['itinerary_days'] as List)
          .map((day) => ItineraryDayModel.fromJson(day))
          .toList()
          : [],
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? false,
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination,
      'title': title,
      'image_url': imageUrl,
      'slug': slug,
      'nights': nights,
      'days': days,
      'countries': countries,
      'cities': cities,
      'locations': locations,
      'country': country,
      'state': state,
      'city': city,
      'itinerary': itinerary,
      'itinerary_text': itineraryText,
      'tags': tags,
      'inclusions': inclusions,
      'highlights': highlights,
      'accommodation_tiers': accommodationTiers.map((tier) => tier.toJson()).toList(),
      'package_price': packagePrice,
      'original_price': originalPrice,
      'offer_text': offerText,
      'is_wander_nova_choice': isWanderNovaChoice,
      'show_in_holidays_top_picks': showInHolidaysTopPicks,
      'holiday_themes': holidayThemes,
      'inclusions_detail': inclusionsDetail,
      'exclusions': exclusions,
      'whatsapp_number': whatsappNumber,
      'cancellation_policy': cancellationPolicy,
      'itinerary_days': itineraryDays.map((day) => day.toJson()).toList(),
      'order': order,
      'is_active': isActive,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }
}

class AccommodationTierModel {
  final String name;
  final String tier;
  final int stars;
  final int nights;
  final String location;

  AccommodationTierModel({
    required this.name,
    required this.tier,
    required this.stars,
    required this.nights,
    required this.location,
  });

  factory AccommodationTierModel.fromJson(Map<String, dynamic> json) {
    return AccommodationTierModel(
      name: json['name'] ?? '',
      tier: json['tier'] ?? '',
      stars: json['stars'] ?? 0,
      nights: json['nights'] ?? 0,
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tier': tier,
      'stars': stars,
      'nights': nights,
      'location': location,
    };
  }
}

class ItineraryDayModel {
  final int id;
  final int package;
  final int dayNumber;
  final String title;
  final List<ActivityModel> activities;
  final String? imageUrl;
  final List<String> imageUrls;
  final String details;
  final int order;

  ItineraryDayModel({
    required this.id,
    required this.package,
    required this.dayNumber,
    required this.title,
    required this.activities,
    this.imageUrl,
    required this.imageUrls,
    required this.details,
    required this.order,
  });

  factory ItineraryDayModel.fromJson(Map<String, dynamic> json) {
    return ItineraryDayModel(
      id: json['id'] ?? 0,
      package: json['package'] ?? 0,
      dayNumber: json['day_number'] ?? 0,
      title: json['title'] ?? '',
      activities: json['activities'] != null
          ? (json['activities'] as List)
          .map((act) => ActivityModel.fromJson(act))
          .toList()
          : [],
      imageUrl: json['image_url'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      details: json['details'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package': package,
      'day_number': dayNumber,
      'title': title,
      'activities': activities.map((act) => act.toJson()).toList(),
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'details': details,
      'order': order,
    };
  }
}

class ActivityModel {
  final String icon;
  final String text;
  final String time;

  ActivityModel({
    required this.icon,
    required this.text,
    required this.time,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      icon: json['icon'] ?? '',
      text: json['text'] ?? '',
      time: json['time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'text': text,
      'time': time,
    };
  }
}