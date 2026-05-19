// lib/views/my_trips/presentation/screen/my_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/custom_bottom_nav.dart';
import 'package:wander_nova/common_widgets/custom_drawer.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../common_widgets/new_bottom_nav.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: WanderNovaLogo(
          scaleFactor: context.isMobile ? 0.6 : (context.isTablet ? 0.8 : 1.0),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.wp(2)),
            child: Image.asset("assets/images/wander_nova_logo.jpg", height: context.hp(4.5)),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.luggage, size: 80, color: Colors.grey[400]),
            SizedBox(height: context.hp(2)),
            Text(
              'No trips yet',
              style: TextStyle(
                fontSize: context.isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              'Book your first trip to see it here',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NewBottomNav(currentIndex: 1),
    );
  }
}