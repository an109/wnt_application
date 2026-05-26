import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData? icon;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    this.icon,
    required this.imageUrl,
  });
}