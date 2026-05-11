import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SeatOptionEntity extends Equatable {
  final String airlineCode;
  final String flightNumber;
  final String craftType;
  final String origin;
  final String destination;
  final int? availablityType;
  final int? description;
  final String code;
  final String rowNo;
  final String seatNo;
  final int? seatType;
  final int? seatWayType;
  final int? compartment;
  final int? deck;
  final String currency;
  final double price;
  final bool isSelected;

  const SeatOptionEntity({
    required this.airlineCode,
    required this.flightNumber,
    required this.craftType,
    required this.origin,
    required this.destination,
    required this.availablityType,
    required this.description,
    required this.code,
    required this.rowNo,
    required this.seatNo,
    required this.seatType,
    required this.seatWayType,
    required this.compartment,
    required this.deck,
    required this.currency,
    required this.price,
    this.isSelected = false,
  });

  SeatOptionEntity copyWith({bool? isSelected}) {
    return SeatOptionEntity(
      airlineCode: airlineCode,
      flightNumber: flightNumber,
      craftType: craftType,
      origin: origin,
      destination: destination,
      availablityType: availablityType,
      description: description,
      code: code,
      rowNo: rowNo,
      seatNo: seatNo,
      seatType: seatType,
      seatWayType: seatWayType,
      compartment: compartment,
      deck: deck,
      currency: currency,
      price: price,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  String get seatLabel => '$rowNo$seatNo';

  String get displayPrice {
    if (price <= 0) return 'Free';
    return '$currency ${price.toStringAsFixed(2)}';
  }

  bool get isFree => price <= 0;
  bool get isAvailable => availablityType == 1;
  bool get isWindow => seatType == 1;
  bool get isAisle => seatType == 2;
  bool get isMiddle => seatType == 3;

  String get seatTypeLabel {
    if (isWindow) return 'Window';
    if (isAisle) return 'Aisle';
    if (isMiddle) return 'Middle';
    return 'Standard';
  }

  Color get seatColor {
    if (!isAvailable) return Colors.grey.shade300;
    if (isSelected) return Colors.blue;
    if (isFree) return Colors.green.shade600;
    return Colors.grey.shade600;
  }

  Color get seatBgColor {
    if (!isAvailable) return Colors.grey.shade100;
    if (isSelected) return Colors.blue.shade50;
    if (isFree) return Colors.green.shade50;
    return Colors.white;
  }

  IconData get seatIcon {
    if (!isAvailable) return Icons.block;
    if (isWindow) return Icons.window;
    if (isAisle) return Icons.arrow_right_alt;
    return Icons.chair;
  }

  @override
  List<Object?> get props => [
    airlineCode,
    flightNumber,
    craftType,
    origin,
    destination,
    availablityType,
    description,
    code,
    rowNo,
    seatNo,
    seatType,
    seatWayType,
    compartment,
    deck,
    currency,
    price,
    isSelected,
  ];
}