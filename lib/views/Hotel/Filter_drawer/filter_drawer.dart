import 'dart:ui';
import 'package:flutter/material.dart';

class HotelFilterDrawer extends StatefulWidget {
  const HotelFilterDrawer({super.key});

  @override
  State<HotelFilterDrawer> createState() => _HotelFilterDrawerState();
}

class _HotelFilterDrawerState extends State<HotelFilterDrawer> {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _header(),


            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: const Text(
        "Filters",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

}