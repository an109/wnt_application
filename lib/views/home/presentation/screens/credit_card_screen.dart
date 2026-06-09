// lib/views/credit_card/presentation/screen/credit_card_screen.dart
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/custom_bottom_nav.dart';
import 'package:wander_nova/common_widgets/custom_drawer.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../common_widgets/new_bottom_nav.dart';

class CreditCardScreen extends StatelessWidget {
  const CreditCardScreen({super.key});

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
            child: Image.asset("assets/images/wander_logo.png", height: context.hp(4.5)),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, size: 80, color: Colors.grey[400]),
            SizedBox(height: context.hp(2)),
            Text(
              'WanderNova Credit Card',
              style: TextStyle(
                fontSize: context.isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              'Earn rewards on every booking',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NewBottomNav(currentIndex: 2),
    );
  }
}