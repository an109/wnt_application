import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.flight), label: 'Flights'),
        BottomNavigationBarItem(icon: Icon(Icons.hotel), label: 'Hotels'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Visa'),
        BottomNavigationBarItem(icon: Icon(Icons.card_travel), label: 'Holidays'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Transport'),
      ],
    );
  }
}