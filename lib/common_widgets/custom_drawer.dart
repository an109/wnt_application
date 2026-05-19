import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../views/login/login.dart';


class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Using your Responsive extension for consistent sizing
    final isMobile = context.isMobile;
    final drawerWidth = context.isDesktop
        ? context.screenWidth * 0.35
        : context.screenWidth * 0.85;

    return Drawer(
      width: drawerWidth,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // ===== HEADER SECTION (MakeMyTrip Style) =====
            // _buildHeader(context),

            // ===== MENU ITEMS =====
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: context.scrollPhysics,
                children: [
                  // _buildSectionDivider(context),
                    SizedBox(height: 28),
                  // My Bookings Section
                  _buildSectionTitle(context, 'MY BOOKINGS'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.receipt_long,
                    title: 'My Bookings',
                    subtitle: 'Flights, Hotels, Trains & more',
                    onTap: () => _navigateTo(context, '/bookings'),
                    showBadge: false,
                  ),

                  _buildSectionDivider(context),

                  // Offers & Rewards Section
                  _buildSectionTitle(context, 'OFFERS & REWARDS'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.local_offer,
                    title: 'Offers',
                    subtitle: 'Exclusive deals & coupons',
                    onTap: () => _navigateTo(context, '/offers'),
                    badgeCount: 3,
                    showBadge: true,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: 'MakeMyTrip Money',
                    subtitle: 'Wallet, Rewards & Cashback',
                    onTap: () => _navigateTo(context, '/wallet'),
                  ),

                  _buildSectionDivider(context),

                  // Support & Settings Section
                  _buildSectionTitle(context, 'SUPPORT'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.support_agent,
                    title: '24x7 Support',
                    subtitle: 'Chat, Call or Email us',
                    onTap: () => _navigateTo(context, '/support'),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    subtitle: 'FAQs & Guides',
                    onTap: () => _navigateTo(context, '/help'),
                  ),

                  _buildSectionDivider(context),

                  // Account Settings
                  _buildSectionTitle(context, 'ACCOUNT'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    subtitle: 'Manage your account',
                    onTap: () => _navigateTo(context, '/profile'),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences & notifications',
                    onTap: () => _navigateTo(context, '/settings'),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out from your account',
                    onTap: () => _showLogoutDialog(context),
                    isDestructive: true,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ===== LOGIN/SIGNUP CTA (Guest Users) =====
            _buildLoginCTA(context),
          ],
        ),
      ),
    );
  }

  // ===== HEADER WITH USER INFO =====
  // Widget _buildHeader(BuildContext context) {
  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.only(
  //       top: context.statusBarHeight + context.gapMedium,
  //       left: context.horizontalPadding.left,
  //       right: context.horizontalPadding.right,
  //       bottom: context.gapMedium,
  //     ),
  //     decoration: const BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [Color(0xFF0054A0), Color(0xFF0077CC)],
  //       ),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // User Avatar & Name Row
  //         Row(
  //           children: [
  //
  //
  //             // User Info
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'Guest User',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: context.titleLarge,
  //                       fontWeight: FontWeight.w700,
  //                       letterSpacing: 0.3,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     'Tap to sign in for exclusive benefits',
  //                     style: TextStyle(
  //                       color: Colors.white.withOpacity(0.9),
  //                       fontSize: context.bodySmall,
  //                       fontWeight: FontWeight.w400,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //
  //             // Chevron Icon
  //             Icon(
  //               Icons.chevron_right,
  //               color: Colors.white.withOpacity(0.9),
  //               size: context.iconMedium,
  //             ),
  //           ],
  //         ),
  //
  //         const SizedBox(height: 16),
  //
  //         // Quick Stats Row (MakeMyTrip Style)
  //         Row(
  //           children: [
  //             _buildQuickStat(context, '0', 'Bookings'),
  //             _buildQuickStat(context, '₹0', 'Wallet'),
  //             _buildQuickStat(context, '0', 'Rewards'),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Quick stat item for header
  Widget _buildQuickStat(BuildContext context, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.gapSmall / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.titleMedium,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: context.labelSmall,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== SECTION DIVIDER WITH TITLE =====
  Widget _buildSectionDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding.left,
        vertical: context.gapSmall,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
        indent: context.isMobile ? 0 : 8,
        endIndent: context.isMobile ? 0 : 8,
      ),
    );
  }

  // Section title (MakeMyTrip uses uppercase, small, grey text)
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.horizontalPadding.left + 8,
        top: context.gapMedium,
        bottom: context.gapSmall / 2,
        right: context.horizontalPadding.right,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: context.labelMedium,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          height: 1.2,
        ),
      ),
    );
  }

  // ===== MENU ITEM BUILDER (MakeMyTrip Style) =====
  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        bool showBadge = false,
        int badgeCount = 0,
        bool isDestructive = false,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.blue.withOpacity(0.08),
        highlightColor: Colors.blue.withOpacity(0.04),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding.left,
            vertical: context.gapSmall / 2,
          ),
          child: Row(
            children: [
              // Icon Container (MakeMyTrip uses blue circle background)
              Container(
                width: context.isMobile ? 40 : 44,
                height: context.isMobile ? 40 : 44,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF0054A0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red : const Color(0xFF0054A0),
                  size: context.isMobile ? 20 : 22,
                ),
              ),

              const SizedBox(width: 14),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive ? Colors.red : Colors.black87,
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: context.bodySmall,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge or Chevron
              if (showBadge && badgeCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.gapSmall / 2,
                    vertical: context.gapSmall / 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.labelSmall,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: context.iconSmall,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== LOGIN/SIGNUP CTA BUTTON =====
  Widget _buildLoginCTA(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding.right),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        color: Colors.grey[50],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginSignupScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7200), // MakeMyTrip Orange
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, context.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
            ),
            elevation: 2,
            shadowColor: Colors.orange.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login_rounded, size: context.iconMedium),
              const SizedBox(width: 10),
              Text(
                'Login / Signup',
                style: TextStyle(
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== NAVIGATION HELPER =====
  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer first
    // Add your routing logic here
    // Example: Navigator.pushNamed(context, route);
  }

  // ===== LOGOUT DIALOG =====
  void _showLogoutDialog(BuildContext context) {
    Navigator.pop(context); // Close drawer
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius),
        ),
        title: Text(
          'Logout',
          style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(fontSize: context.bodyMedium, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(fontSize: context.bodyMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              // Add logout logic here
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout', style: TextStyle(fontSize: context.bodyMedium)),
          ),
        ],
      ),
    );
  }
}