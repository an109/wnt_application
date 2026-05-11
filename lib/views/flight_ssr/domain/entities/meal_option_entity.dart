import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class MealOptionEntity extends Equatable {
  final String airlineCode;
  final String flightNumber;
  final int wayType;
  final String code;
  final int description;
  final String airlineDescription;
  final int quantity;
  final String currency;
  final double price;
  final String origin;
  final String destination;
  final bool isSelected;

  const MealOptionEntity({
    required this.airlineCode,
    required this.flightNumber,
    required this.wayType,
    required this.code,
    required this.description,
    required this.airlineDescription,
    required this.quantity,
    required this.currency,
    required this.price,
    required this.origin,
    required this.destination,
    this.isSelected = false,
  });

  MealOptionEntity copyWith({bool? isSelected}) {
    return MealOptionEntity(
      airlineCode: airlineCode,
      flightNumber: flightNumber,
      wayType: wayType,
      code: code,
      description: description,
      airlineDescription: airlineDescription,
      quantity: quantity,
      currency: currency,
      price: price,
      origin: origin,
      destination: destination,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  String get displayTitle {
    if (code == 'NoMeal') return 'No Meal';
    if (airlineDescription.isNotEmpty) return airlineDescription;
    return _formatMealCode(code);
  }

  String get displaySubtitle {
    if (code == 'NoMeal') return 'Skip meal service for this flight';
    if (quantity > 0) return 'Quantity: $quantity';
    return 'Special meal option';
  }

  String get displayPrice {
    if (price <= 0) return 'Free';
    return '$currency ${price.toStringAsFixed(2)}';
  }

  bool get isFree => price <= 0;
  bool get isNoMeal => code == 'NoMeal';
  bool get isVegetarian =>
      code.contains('VGML') ||
          code.contains('VLML') ||
          code.contains('DBML') ||
          airlineDescription.toLowerCase().contains('vegetarian');

  IconData get mealIcon {
    if (isNoMeal) return Icons.no_meals;
    if (isVegetarian) return Icons.eco;
    return Icons.restaurant;
  }

  Color get iconColor {
    if (isNoMeal) return Colors.grey.shade600;
    if (isVegetarian) return Colors.green.shade600;
    return Colors.orange.shade600;
  }

  Color get iconBgColor {
    if (isNoMeal) return Colors.grey.shade100;
    if (isVegetarian) return Colors.green.shade50;
    return Colors.orange.shade50;
  }

  static String _formatMealCode(String code) {
    final meals = {
      'DBML': 'Diabetic Meal',
      'VGML': 'Vegetarian Vegan Meal',
      'VLML': 'Vegetarian Lacto-Ovo Meal',
      'HNML': 'Hindu Meal',
      'KSML': 'Kosher Meal',
      'MOML': 'Muslim Meal',
      'SFML': 'Seafood Meal',
      'CHML': 'Child Meal',
      'BBML': 'Baby Meal',
      'FPML': 'Fruit Platter',
      'LFML': 'Low Fat Meal',
      'LSML': 'Low Salt Meal',
      'NLML': 'Non-Lactose Meal',
      'RVML': 'Raw Vegetarian Meal',
    };
    return meals[code] ?? code.replaceAllMapped(
      RegExp(r'([A-Z][a-z]+)'),
          (m) => ' ${m[0]}',
    ).trim();
  }

  @override
  List<Object?> get props => [
    airlineCode,
    flightNumber,
    wayType,
    code,
    description,
    airlineDescription,
    quantity,
    currency,
    price,
    origin,
    destination,
    isSelected,
  ];
}