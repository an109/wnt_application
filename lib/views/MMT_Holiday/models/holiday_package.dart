class HolidayPackage {
  final String id;
  final String title;
  final String location;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final int? discount;
  final double rating;
  final int duration; // in days
  final int maxPeople;
  final List<String> highlights;
  final String description;

  HolidayPackage({
    required this.id,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.discount,
    required this.rating,
    required this.duration,
    required this.maxPeople,
    required this.highlights,
    required this.description,
  });

  factory HolidayPackage.fromJson(Map<String, dynamic> json) {
    return HolidayPackage(
      id: json['id'],
      title: json['title'],
      location: json['location'],
      imageUrl: json['imageUrl'],
      price: json['price'].toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      discount: json['discount'],
      rating: json['rating'].toDouble(),
      duration: json['duration'],
      maxPeople: json['maxPeople'],
      highlights: List<String>.from(json['highlights']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'imageUrl': imageUrl,
      'price': price,
      'originalPrice': originalPrice,
      'discount': discount,
      'rating': rating,
      'duration': duration,
      'maxPeople': maxPeople,
      'highlights': highlights,
      'description': description,
    };
  }
}