import 'package:flutter/material.dart';
import '../views/login/login.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header with Blue Background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 50.0,
                left: 20.0,
                right: 20.0,
                bottom: 20.0,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0054A0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore amazing travel deals',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Divider(height: 1, indent: 65),

                  _buildDrawerItem(
                    icon: Icons.receipt_long,
                    title: 'My Bookings',
                    subtitle: 'All your trip bookings',
                    onTap: () {},
                    showBadge: false,
                    // badgeCount: 2,
                  ),
                  const Divider(height: 1, indent: 65),

                  _buildDrawerItem(
                    icon: Icons.local_offer,
                    title: 'Offers',
                    subtitle: 'Coupons & discounts',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 65),

                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet,
                    title: 'Make Payment',
                    subtitle: 'Rewards & balance',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 65),

                  _buildDrawerItem(
                    icon: Icons.support_agent,
                    title: 'Support',
                    subtitle: '24x7 customer care',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 65),

                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Login/Signup Button at Bottom
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF7200),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginSignupScreen(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.login, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Login / Signup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build drawer items
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: Icon(icon,  color: Color(0xFF0054A0), size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: showBadge
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$badgeCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      hoverColor: Colors.blue.withOpacity(0.05),
    );
  }
}