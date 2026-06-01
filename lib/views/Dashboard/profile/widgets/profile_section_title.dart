import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';


class ProfileSectionTitle extends StatelessWidget {
  final String title;

  const ProfileSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: context.titleMedium,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }
}