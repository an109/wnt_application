import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SpecialServiceEntity extends Equatable {
  final String origin;
  final String destination;
  final String? departureTime;
  final String airlineCode;
  final String flightNumber;
  final String code;
  final int? serviceType;
  final String text;
  final int? wayType;
  final String currency;
  final double price;
  final bool isSelected;

  const SpecialServiceEntity({
    required this.origin,
    required this.destination,
    this.departureTime,
    required this.airlineCode,
    required this.flightNumber,
    required this.code,
    this.serviceType,
    required this.text,
    this.wayType,
    required this.currency,
    required this.price,
    this.isSelected = false,
  });

  SpecialServiceEntity copyWith({bool? isSelected}) {
    return SpecialServiceEntity(
      origin: origin,
      destination: destination,
      departureTime: departureTime,
      airlineCode: airlineCode,
      flightNumber: flightNumber,
      code: code,
      serviceType: serviceType,
      text: text,
      wayType: wayType,
      currency: currency,
      price: price,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  String get displayTitle {
    final titles = {
      'BOF1': 'Bag Out First - 1 Bag',
      'BOF2': 'Bag Out First - 2 Bags',
      'MEET': 'Meet & Assist',
      'WCHR': 'Wheelchair Request',
      'UMNR': 'Unaccompanied Minor',
      'PETC': 'Pet in Cabin',
      'EXST': 'Extra Seat',
      'DEAF': 'Deaf Passenger Assistance',
      'BLND': 'Blind Passenger Assistance',
    };
    return titles[code] ?? text;
  }

  String get displaySubtitle {
    final subtitles = {
      'BOF1': 'Priority baggage delivery for 1 bag',
      'BOF2': 'Priority baggage delivery for 2 bags',
      'MEET': 'Personal assistance at airport',
      'WCHR': 'Wheelchair assistance throughout journey',
      'UMNR': 'Special care for unaccompanied minors',
      'PETC': 'Travel with your pet in cabin',
      'EXST': 'Reserve an additional seat',
      'DEAF': 'Assistance for hearing-impaired passengers',
      'BLND': 'Guidance for visually-impaired passengers',
    };
    return subtitles[code] ?? 'Additional service for your journey';
  }

  String get displayPrice {
    if (price <= 0) return 'Free';
    return '$currency ${price.toStringAsFixed(2)}';
  }

  bool get isFree => price <= 0;
  bool get isPriority => code.startsWith('BOF');
  bool get isAssistance =>
      code == 'WCHR' || code == 'DEAF' || code == 'BLND' || code == 'MEET';

  IconData get serviceIcon {
    if (isPriority) return Icons.priority_high;
    if (isAssistance) return Icons.accessibility_new;
    if (code == 'PETC') return Icons.pets;
    if (code == 'UMNR') return Icons.child_care;
    return Icons.star_outline;
  }

  Color get iconColor {
    if (isPriority) return Colors.orange.shade600;
    if (isAssistance) return Colors.blue.shade600;
    if (code == 'PETC') return Colors.purple.shade600;
    return Colors.green.shade600;
  }

  Color get iconBgColor {
    if (isPriority) return Colors.orange.shade50;
    if (isAssistance) return Colors.blue.shade50;
    if (code == 'PETC') return Colors.purple.shade50;
    return Colors.green.shade50;
  }

  @override
  List<Object?> get props => [
    origin,
    destination,
    departureTime,
    airlineCode,
    flightNumber,
    code,
    serviceType,
    text,
    wayType,
    currency,
    price,
    isSelected,
  ];
}