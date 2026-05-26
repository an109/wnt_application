import 'package:flutter/material.dart';
import '../models/holiday_package.dart';
import '../models/category.dart';

class DummyData {
  static List<Category> get categories => [
    Category(
      id: '1',
      name: 'Beach',
      icon: Icons.beach_access,
      imageUrl: 'https://picsum.photos/seed/beach/200',
    ),
    Category(
      id: '2',
      name: 'Mountain',
      icon: Icons.landscape,
      imageUrl: 'https://picsum.photos/seed/mountain/200',
    ),
    Category(
      id: '3',
      name: 'City',
      icon: Icons.location_city,
      imageUrl: 'https://picsum.photos/seed/city/200',
    ),
    Category(
      id: '4',
      name: 'Adventure',
      icon: Icons.hiking,
      imageUrl: 'https://picsum.photos/seed/adventure/200',
    ),
    Category(
      id: '5',
      name: 'Cultural',
      icon: Icons.account_balance,
      imageUrl: 'https://picsum.photos/seed/cultural/200',
    ),
  ];

  static List<HolidayPackage> get packages => [
    HolidayPackage(
      id: '1',
      title: 'Goa Beach Retreat',
      location: 'Goa, India',
      imageUrl: 'https://picsum.photos/seed/goa/400/300',
      price: 15999,
      originalPrice: 19999,
      discount: 20,
      rating: 4.5,
      duration: 4,
      maxPeople: 4,
      highlights: ['Beach Access', 'Water Sports', 'Nightlife'],
      description: 'Experience the vibrant beaches and nightlife of Goa.',
    ),
    HolidayPackage(
      id: '2',
      title: 'Kashmir Valley Tour',
      location: 'Kashmir, India',
      imageUrl: 'https://picsum.photos/seed/kashmir/400/300',
      price: 24999,
      rating: 4.8,
      duration: 6,
      maxPeople: 6,
      highlights: ['Dal Lake', 'Gulmarg', 'Local Cuisine'],
      description: 'Discover the paradise on earth with stunning valleys.',
    ),
    HolidayPackage(
      id: '3',
      title: 'Kerala Backwaters',
      location: 'Kerala, India',
      imageUrl: 'https://picsum.photos/seed/kerala/400/300',
      price: 18999,
      originalPrice: 22999,
      discount: 17,
      rating: 4.6,
      duration: 5,
      maxPeople: 4,
      highlights: ['Houseboat Stay', 'Ayurveda', 'Spice Plantation'],
      description: 'Cruise through serene backwaters of God\'s Own Country.',
    ),
    HolidayPackage(
      id: '4',
      title: 'Rajasthan Heritage',
      location: 'Rajasthan, India',
      imageUrl: 'https://picsum.photos/seed/rajasthan/400/300',
      price: 21999,
      rating: 4.7,
      duration: 7,
      maxPeople: 6,
      highlights: ['Palace Tours', 'Camel Safari', 'Cultural Shows'],
      description: 'Explore the royal heritage and vibrant culture.',
    ),
    HolidayPackage(
      id: '5',
      title: 'Andaman Islands',
      location: 'Andaman, India',
      imageUrl: 'https://picsum.photos/seed/andaman/400/300',
      price: 29999,
      originalPrice: 34999,
      discount: 14,
      rating: 4.9,
      duration: 5,
      maxPeople: 4,
      highlights: ['Scuba Diving', 'White Sand Beaches', 'Marine Life'],
      description: 'Tropical paradise with crystal clear waters.',
    ),
    HolidayPackage(
      id: '6',
      title: 'Himachal Adventure',
      location: 'Himachal Pradesh, India',
      imageUrl: 'https://picsum.photos/seed/himachal/400/300',
      price: 16999,
      rating: 4.4,
      duration: 5,
      maxPeople: 6,
      highlights: ['Trekking', 'Paragliding', 'Mountain Views'],
      description: 'Adventure awaits in the lap of the Himalayas.',
    ),
  ];

  static List<String> get heroImages => [
    'https://picsum.photos/seed/hero1/800/400',
    'https://picsum.photos/seed/hero2/800/400',
    'https://picsum.photos/seed/hero3/800/400',
  ];
}
