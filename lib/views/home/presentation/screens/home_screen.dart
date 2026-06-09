// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
// import 'package:wander_nova/common_widgets/custom_drawer.dart';
// import 'package:wander_nova/core/resources/app_colours.dart';
// import '../../../../common_widgets/logo.dart';
// import '../../../../injection_container.dart';
// import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
// import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_event.dart';
// import '../../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
// import '../../../Holidays/presentation/screen/holidays_screen.dart';
// import '../../../Hotel/screen/hotel_screen.dart';
// import '../../../MMT_Holiday/screen/holiday_screen.dart';
// import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
// import '../../../MainApi/presentation/bloc/general_settings_event.dart';
// import '../../../Transport/screen/transport_screen.dart';
// import '../../../footer/presentation/widget/footer_banner_widget.dart';
// import '../../../travel_stories/presentation/screen/travel_stories.dart';
// import '../../../visa/presentation/screen/visa_screen.dart';
// import '../screen_sections/about_company_section.dart';
// import '../screen_sections/contact_section.dart';
// import '../screen_sections/faq/FAQ_section.dart';
// import '../../../flight_popularDestination/presentation/screen/popular_destination.dart';
// import '../../../trending_route/presentation/screen/trending_routes.dart';
// import '../screen_sections/service_info_section.dart';
// import '../screen_sections/why_choose_us/why_choose_us.dart';
// import '../../flight/flight_screen.dart';
// import 'package:animated_text_kit/animated_text_kit.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _printInitialDimensions();
//   }
//
//   void _printInitialDimensions() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final size = MediaQuery.of(context).size;
//       debugPrint('Initial Width: ${size.width}, Height: ${size.height}');
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     debugPrint('Screen Updated - Width: ${size.width}, Height: ${size.height}');
//
//     return Scaffold(
//       drawer: const CustomDrawer(),
//       appBar: AppBar(
//         title: WanderNovaLogo(
//           scaleFactor: context.isMobile ? 0.6 : (context.isTablet ? 0.8 : 1.0),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           Padding(
//             padding: EdgeInsets.all(context.w(16)),
//             child: Image.asset(
//               "assets/images/wander_logo.png",
//               height: context.h(36),
//               width: context.h(36),
//               fit: BoxFit.contain,
//             ),
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: () async {
//           final generalBloc = context.read<GeneralSettingsBloc>();
//           final dealsBloc = context.read<ExclusiveDealsBloc>();
//
//           generalBloc.add(const LoadFaqList(domain: 'thewandernova.com'));
//           generalBloc.add(
//             const LoadGeneralSettings(domain: 'thewandernova.com'),
//           );
//           dealsBloc.add(const LoadExclusiveDeals());
//
//           await Future.wait([
//             Future.delayed(const Duration(milliseconds: 500)),
//           ]);
//         },
//         color: const Color(0xff005B7F),
//         backgroundColor: Colors.white,
//         child: Container(
//           color: const Color(0xFFF8F9FA),
//           child: CustomScrollView(
//             physics: context.scrollPhysics,
//             slivers: [
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(horizontal: context.w(16)),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(height: context.h(20)),
//                       _buildQuickBookingSection(context),
//                       SizedBox(height: context.h(24)),
//                       _buildAdditionalServicesRow(context),
//                       SizedBox(height: context.h(16)),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SliverToBoxAdapter(
//                 child: BlocProvider<ExclusiveDealsBloc>(
//                   create: (context) => sl<ExclusiveDealsBloc>(),
//                   child: const TransportExclusiveDealsSection(),
//                 ),
//               ),
//
//               const SliverToBoxAdapter(child: TrendingPackages()),
//               const SliverToBoxAdapter(child: PopularDestinations()),
//               const SliverToBoxAdapter(child: TravelStoriesSection()),
//
//               SliverToBoxAdapter(
//                 child: BlocProvider(
//                   create: (_) =>
//                   sl<GeneralSettingsBloc>()
//                     ..add(const LoadFaqList(domain: 'thewandernova.com')),
//                   child: const FAQSection(),
//                 ),
//               ),
//
//               const SliverToBoxAdapter(child: WhyChooseUs()),
//
//               SliverToBoxAdapter(
//                 child: BlocProvider(
//                   create: (_) => sl<GeneralSettingsBloc>()
//                     ..add(
//                       const LoadGeneralSettings(domain: 'thewandernova.com'),
//                     ),
//                   child: const AboutCompanySection(),
//                 ),
//               ),
//
//               SliverToBoxAdapter(
//                 child: BlocProvider(
//                   create: (_) => sl<GeneralSettingsBloc>()
//                     ..add(
//                       const LoadGeneralSettings(domain: 'thewandernova.com'),
//                     ),
//                   child: const ServicesInfoSection(),
//                 ),
//               ),
//
//               const SliverToBoxAdapter(child: ContactSection()),
//               SliverToBoxAdapter(child: SizedBox(height: context.h(40))),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ================= QUICK BOOKING SECTION (2x2 Grid) =================
//   Widget _buildQuickBookingSection(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: _buildQuickBookingCard(
//                 context,
//                 title: 'Flights',
//                 subtitle: 'Book now',
//                 backgroundColor: const Color(0xFFE8E4F9),
//                 imageUrl: 'assets/images/airplane.png',
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const FlightScreen()),
//                 ),
//               ),
//             ),
//             SizedBox(width: context.w(12)),
//             Expanded(
//               child: _buildQuickBookingCard(
//                 context,
//                 title: 'Hotels',
//                 subtitle: 'Find stays',
//                 backgroundColor: const Color(0xFFFCE8E0),
//                 imageUrl: 'assets/images/hotel.png',
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: context.h(12)),
//         Row(
//           children: [
//             Expanded(
//               child: _buildQuickBookingCard(
//                 context,
//                 title: 'Holidays',
//                 subtitle: 'Packages',
//                 backgroundColor: const Color(0xFFE0F2F1),
//                 imageUrl: 'assets/images/beach_hut.png',
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const HolidaysScreen()),
//                 ),
//               ),
//             ),
//             SizedBox(width: context.w(12)),
//             Expanded(
//               child: _buildQuickBookingCard(
//                 context,
//                 title: 'Visa',
//                 subtitle: 'Apply now',
//                 backgroundColor: const Color(0xFFE3F2FD),
//                 imageUrl: 'assets/images/passbook.png',
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const VisaScreen()),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildQuickBookingCard(
//       BuildContext context, {
//         required String title,
//         required String subtitle,
//         required Color backgroundColor,
//         required String imageUrl,
//         required VoidCallback onTap,
//       }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: context.isMobile ? context.h(160) : context.h(180),
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(context.r(16)),
//         ),
//         child: Stack(
//           children: [
//             Positioned(
//               top: context.h(16),
//               left: context.w(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: GoogleFonts.poppins(
//                       fontSize: context.fs(22),
//                       fontWeight: FontWeight.w800,
//                       color: _getTitleColor(backgroundColor),
//                       letterSpacing: context.letterSpacingTight,
//                     ),
//                   ),
//                   SizedBox(height: context.h(4)),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontSize: context.fs(13),
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black54,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Positioned(
//               right: context.w(4),
//               top: context.h(66),
//               child: Image.asset(
//                 imageUrl,
//                 height: context.isMobile ? context.h(110) : context.h(130),
//                 width: context.isMobile ? context.w(120) : context.w(140),
//                 fit: BoxFit.contain,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Color _getTitleColor(Color bgColor) {
//     if (bgColor == const Color(0xFFE8E4F9)) return const Color(0xFF5B3CC4);
//     if (bgColor == const Color(0xFFFCE8E0)) return const Color(0xFFD35400);
//     if (bgColor == const Color(0xFFE0F2F1)) return const Color(0xFF00796B);
//     if (bgColor == const Color(0xFFE3F2FD)) return const Color(0xFF1565C0);
//     return Colors.black87;
//   }
//
//   // ================= ADDITIONAL SERVICES ROW =================
//   Widget _buildAdditionalServicesRow(BuildContext context) {
//     final services = [
//       {
//         'icon': Icons.local_taxi_outlined,
//         'label': 'Cabs',
//         'onTap': () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const TransportBookingScreen(),
//           ),
//         ),
//       },
//       {
//         'icon': Icons.home_outlined,
//         'label': 'Home Stays',
//         'onTap': () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const HotelBookingScreen(),
//           ),
//         ),
//       },
//       {
//         'icon': Icons.people_outline,
//         'label': 'Activities',
//         'onTap': () => _showComingSoon(context, 'Activities'),
//       },
//       {
//         'icon': Icons.access_time_outlined,
//         'label': 'Hourly Stay',
//         'onTap': () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const HotelBookingScreen(),
//           ),
//         ),
//       },
//     ];
//
//     return Row(
//       children: services.asMap().entries.map((entry) {
//         final index = entry.key;
//         final service = entry.value;
//         return Expanded(
//           child: Padding(
//             padding: EdgeInsets.only(
//               left: index == 0 ? 0 : context.w(4),
//               right: index == services.length - 1 ? 0 : context.w(4),
//             ),
//             child: _buildServiceIconItem(
//               context,
//               icon: service['icon'] as IconData,
//               label: service['label'] as String,
//               onTap: service['onTap'] as VoidCallback,
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   Widget _buildServiceIconItem(
//       BuildContext context, {
//         required IconData icon,
//         required String label,
//         required VoidCallback onTap,
//       }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(context.r(10)),
//       onTap: onTap,
//       child: Container(
//         height: context.h(80),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(context.r(10)),
//           border: Border.all(color: Colors.grey.shade200),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.06),
//               blurRadius: context.h(12),
//               offset: Offset(0, context.h(6)),
//             ),
//             BoxShadow(
//               color: Colors.white.withOpacity(0.8),
//               blurRadius: context.h(4),
//               offset: const Offset(-2, -2),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Stack(
//               alignment: Alignment.center,
//               children: [
//                 Transform.translate(
//                   offset: const Offset(3, 4),
//                   child: Icon(
//                     icon,
//                     size: context.w(30),
//                     color: Colors.black.withOpacity(.12),
//                   ),
//                 ),
//                 ShaderMask(
//                   shaderCallback: (bounds) => const LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [Color(0xFF666666), Color(0xFF1A1A1A)],
//                   ).createShader(bounds),
//                   child: Icon(icon, size: context.w(30), color: Colors.white),
//                 ),
//                 Transform.translate(
//                   offset: const Offset(-1, -1),
//                   child: Icon(
//                     icon,
//                     size: context.w(28),
//                     color: Colors.white.withOpacity(.15),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: context.h(12)),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: context.w(4)),
//               child: Text(
//                 label,
//                 textAlign: TextAlign.center,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: GoogleFonts.poppins(
//                   fontSize: context.fs(11),
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showComingSoon(BuildContext context, String feature) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('$feature coming soon!')),
//     );
//   }
//
//   Widget _buildAnimatedCloud(BuildContext context, {int delay = 0}) {
//     return TweenAnimationBuilder(
//       tween: Tween<double>(begin: 0, end: 1),
//       duration: const Duration(milliseconds: 1500),
//       curve: Curves.easeOut,
//       builder: (context, double value, child) {
//         return Transform.translate(
//           offset: Offset(-10 * (1 - value), 0),
//           child: Opacity(
//             opacity: value * 0.3,
//             child: Icon(
//               Icons.cloud_rounded,
//               color: Colors.white,
//               size: context.isMobile ? context.w(60) : context.w(80),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildAnimatedPlane(BuildContext context) {
//     return TweenAnimationBuilder(
//       tween: Tween<double>(begin: 0, end: 1),
//       duration: const Duration(milliseconds: 2000),
//       curve: Curves.easeInOut,
//       builder: (context, double value, child) {
//         return Transform.translate(
//           offset: Offset(0, -5 * sin(value * 3.14159 * 2)),
//           child: Transform.rotate(
//             angle: sin(value * 3.14159 * 2) * 0.1,
//             child: Opacity(
//               opacity: 0.4,
//               child: Icon(
//                 Icons.flight_rounded,
//                 color: Colors.white,
//                 size: context.isMobile ? context.w(40) : context.w(50),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildMainServicesGrid(BuildContext context) {
//     final services = [
//       ServiceItem(
//         assetIcon: 'assets/icons/flight.png',
//         label: 'Flights',
//         color: const Color(0xFF4A90E2),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const FlightScreen()),
//         ),
//       ),
//       ServiceItem(
//         assetIcon: 'assets/icons/hotel.png',
//         label: 'Hotels',
//         color: const Color(0xFF50C878),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
//         ),
//       ),
//       ServiceItem(
//         assetIcon: 'assets/icons/visa.png',
//         label: 'Visa',
//         color: const Color(0xFF8E44AD),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const VisaScreen()),
//         ),
//       ),
//       ServiceItem(
//         assetIcon: 'assets/icons/holiday.png',
//         label: 'Holidays',
//         color: const Color(0xFFFF6B6B),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const HolidaysScreen()),
//         ),
//       ),
//     ];
//
//     return Column(
//       children: [
//         GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           padding: EdgeInsets.zero,
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 4,
//             childAspectRatio: context.isMobile
//                 ? 0.75
//                 : (context.isTablet ? 0.8 : 0.85),
//             crossAxisSpacing: context.w(5.6),
//             mainAxisSpacing: context.h(8),
//           ),
//           itemCount: services.length,
//           itemBuilder: (context, index) {
//             return _buildMainServiceIcon(context, services[index]);
//           },
//         ),
//         SizedBox(height: context.h(12)),
//       ],
//     );
//   }
//
//   Widget _buildMainServiceIcon(BuildContext context, ServiceItem service) {
//     return TweenAnimationBuilder(
//       tween: Tween<double>(begin: 0, end: 1),
//       duration: const Duration(milliseconds: 300),
//       builder: (context, double value, child) {
//         return Transform.translate(
//           offset: Offset(0, -2 * value),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: service.onTap,
//               borderRadius: BorderRadius.circular(context.r(context.isMobile ? 16 : 18)),
//               splashColor: service.color.withOpacity(0.15),
//               highlightColor: service.color.withOpacity(0.08),
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   vertical: context.h(16),
//                   horizontal: context.w(8),
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(context.r(context.isMobile ? 16 : 18)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.08),
//                       blurRadius: context.h(14),
//                       offset: Offset(0, context.h(6)),
//                     ),
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.04),
//                       blurRadius: context.h(4),
//                       offset: Offset(0, context.h(2)),
//                     ),
//                   ],
//                   border: Border.all(
//                     color: Colors.grey.withOpacity(0.12),
//                     width: 1.2,
//                   ),
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       Colors.white,
//                       Colors.grey.shade50.withOpacity(0.8),
//                     ],
//                   ),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Stack(
//                       clipBehavior: Clip.none,
//                       children: [
//                         Positioned(
//                           left: context.w(3),
//                           top: context.h(3),
//                           child: Icon(
//                             service.icon ?? Icons.circle,
//                             color: service.color.withOpacity(0.2),
//                             size: context.w(context.iconXLarge),
//                           ),
//                         ),
//                         Positioned(
//                           left: context.w(1),
//                           top: context.h(2),
//                           child: Icon(
//                             service.icon ?? Icons.circle,
//                             color: service.color.withOpacity(0.15),
//                             size: context.w(context.iconXLarge),
//                           ),
//                         ),
//                         if (service.assetIcon != null)
//                           Image.asset(
//                             service.assetIcon!,
//                             height: context.w(context.iconXLarge + 14),
//                             width: context.w(context.iconXLarge + 14),
//                             fit: BoxFit.contain,
//                           )
//                         else
//                           ShaderMask(
//                             shaderCallback: (bounds) => LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [
//                                 service.iconColor,
//                                 service.iconColor.withOpacity(0.7),
//                               ],
//                             ).createShader(bounds),
//                             child: Icon(
//                               service.icon ?? Icons.circle,
//                               color: Colors.white,
//                               size: context.w(context.iconXLarge),
//                             ),
//                           ),
//                         Positioned(
//                           left: context.w(-2),
//                           top: context.h(-2),
//                           child: Icon(
//                             service.icon ?? Icons.circle,
//                             color: Colors.white.withOpacity(0.15),
//                             size: context.w(context.iconXLarge - 2),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: context.h(context.gapSmall)),
//                     Text(
//                       service.label,
//                       textAlign: TextAlign.center,
//                       style: GoogleFonts.robotoFlex(
//                         fontSize: context.fs(context.titleSmall),
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black,
//                         height: 1.2,
//                         letterSpacing: context.letterSpacingTight,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildAdditionalServicesGrid(BuildContext context) {
//     final services = [
//       ServiceItem(
//         icon: Icons.local_taxi_outlined,
//         label: 'Airport Cabs',
//         color: const Color(0xFF1E3C72),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const TransportBookingScreen()),
//         ),
//       ),
//       ServiceItem(
//         icon: Icons.home_work_outlined,
//         label: 'Villas & Homestays',
//         color: const Color(0xFF1E3C72),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
//         ),
//       ),
//       ServiceItem(
//         icon: Icons.emoji_events_outlined,
//         label: 'Tours & Attractions',
//         color: const Color(0xFF1E3C72),
//         badge: 'NEW',
//         onTap: () => _showComingSoon(context, 'Tours & Attractions'),
//       ),
//       ServiceItem(
//         icon: Icons.access_time_outlined,
//         label: 'Hourly Stays',
//         color: const Color(0xFF1E3C72),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
//         ),
//       ),
//     ];
//
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       padding: EdgeInsets.zero,
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         childAspectRatio: context.isMobile ? 0.85 : (context.isTablet ? 0.9 : 1.0),
//         crossAxisSpacing: context.w(7.5),
//         mainAxisSpacing: context.h(16),
//       ),
//       itemCount: services.length,
//       itemBuilder: (context, index) {
//         return _buildServiceIcon(context, services[index]);
//       },
//     );
//   }
//
//   Widget _buildServiceIcon(BuildContext context, ServiceItem service) {
//     return StatefulBuilder(
//       builder: (context, setState) {
//         return TweenAnimationBuilder(
//           tween: Tween<double>(begin: 0, end: 1),
//           duration: const Duration(milliseconds: 300),
//           builder: (context, double value, child) {
//             return Transform.scale(
//               scale: 1 - (value * 0.02),
//               child: Transform.translate(
//                 offset: Offset(0, -2 * value),
//                 child: Material(
//                   color: Colors.transparent,
//                   child: InkWell(
//                     onTap: () {
//                       service.onTap();
//                     },
//                     onTapDown: (_) {
//                       setState(() {});
//                     },
//                     onTapUp: (_) {
//                       Future.delayed(const Duration(milliseconds: 100), () {
//                         setState(() {});
//                       });
//                     },
//                     borderRadius: BorderRadius.circular(context.r(context.isMobile ? 16 : 18)),
//                     splashColor: service.color.withOpacity(0.15),
//                     highlightColor: service.color.withOpacity(0.08),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       curve: Curves.easeOutCubic,
//                       padding: EdgeInsets.all(context.w(context.gapSmall)),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(context.r(context.isMobile ? 16 : 18)),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: context.h(12),
//                             offset: Offset(0, context.h(6)),
//                           ),
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.04),
//                             blurRadius: context.h(4),
//                             offset: Offset(0, context.h(2)),
//                           ),
//                         ],
//                         border: Border.all(
//                           color: Colors.grey.withOpacity(0.12),
//                           width: 1.2,
//                         ),
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [
//                             Colors.white,
//                             Colors.grey.shade50.withOpacity(0.8),
//                           ],
//                         ),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Stack(
//                             clipBehavior: Clip.none,
//                             children: [
//                               Positioned(
//                                 left: context.w(3),
//                                 top: context.h(4),
//                                 child: Icon(
//                                   service.icon ?? Icons.circle,
//                                   color: service.color.withOpacity(0.2),
//                                   size: context.w(context.iconXLarge),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: context.w(1),
//                                 top: context.h(2),
//                                 child: Icon(
//                                   service.icon ?? Icons.circle,
//                                   color: service.color.withOpacity(0.15),
//                                   size: context.w(context.iconXLarge),
//                                 ),
//                               ),
//                               ShaderMask(
//                                 shaderCallback: (bounds) => LinearGradient(
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                   colors: [
//                                     service.color,
//                                     service.color.withOpacity(0.7),
//                                   ],
//                                 ).createShader(bounds),
//                                 child: Icon(
//                                   service.icon ?? Icons.circle,
//                                   color: Colors.white,
//                                   size: context.w(context.iconXLarge),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: context.w(-2),
//                                 top: context.h(-2),
//                                 child: Icon(
//                                   service.icon ?? Icons.circle,
//                                   color: Colors.white.withOpacity(0.15),
//                                   size: context.w(context.iconXLarge - 2),
//                                 ),
//                               ),
//                               if (service.badge != null)
//                                 Positioned(
//                                   right: context.w(-8),
//                                   top: context.h(-8),
//                                   child: TweenAnimationBuilder(
//                                     tween: Tween<double>(begin: 0, end: 1),
//                                     duration: const Duration(milliseconds: 400),
//                                     curve: Curves.elasticOut,
//                                     builder: (context, double scale, child) {
//                                       return Transform.scale(
//                                         scale: scale,
//                                         child: Container(
//                                           padding: EdgeInsets.symmetric(
//                                             horizontal: context.w(6),
//                                             vertical: context.h(3),
//                                           ),
//                                           decoration: BoxDecoration(
//                                             gradient: const LinearGradient(
//                                               colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
//                                               begin: Alignment.topLeft,
//                                               end: Alignment.bottomRight,
//                                             ),
//                                             borderRadius: BorderRadius.circular(context.r(10)),
//                                             boxShadow: [
//                                               BoxShadow(
//                                                 color: Colors.red.withOpacity(0.4),
//                                                 blurRadius: context.h(6),
//                                                 offset: Offset(0, context.h(2)),
//                                               ),
//                                             ],
//                                             border: Border.all(
//                                               color: Colors.white.withOpacity(0.5),
//                                               width: 1.5,
//                                             ),
//                                           ),
//                                           child: Text(
//                                             service.badge!,
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: context.fs(context.caption),
//                                               fontWeight: FontWeight.bold,
//                                               height: 1,
//                                             ),
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                             ],
//                           ),
//                           SizedBox(height: context.h(context.gapXSmall)),
//                           Flexible(
//                             child: Text(
//                               service.label,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: context.fs(context.labelMedium),
//                                 fontWeight: FontWeight.w800,
//                                 color: Colors.black87,
//                                 height: 1.3,
//                                 letterSpacing: context.letterSpacingTight,
//                                 shadows: [
//                                   Shadow(
//                                     color: Colors.black.withOpacity(0.05),
//                                     blurRadius: context.h(2),
//                                     offset: Offset(0, context.h(1)),
//                                   ),
//                                 ],
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
//
// class ServiceItem {
//   final IconData? icon;
//   final String? assetIcon;
//   final String label;
//   final Color color;
//   final Color? backgroundColor;
//   final String? badge;
//   final VoidCallback onTap;
//
//   Color get iconColor => color;
//
//   ServiceItem({
//     this.icon,
//     this.assetIcon,
//     required this.label,
//     required this.color,
//     this.backgroundColor,
//     this.badge,
//     required this.onTap,
//   });
// }





import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/custom_drawer.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../injection_container.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_event.dart';
import '../../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../../Holidays/presentation/screen/holidays_screen.dart';
import '../../../Hotel/screen/hotel_screen.dart';
import '../../../MMT_Holiday/screen/holiday_screen.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../Transport/screen/transport_screen.dart';
import '../../../footer/presentation/widget/footer_banner_widget.dart';
import '../../../travel_stories/presentation/screen/travel_stories.dart';
import '../../../visa/presentation/screen/visa_screen.dart';
import '../screen_sections/about_company_section.dart';
import '../screen_sections/contact_section.dart';
import '../screen_sections/faq/FAQ_section.dart';
import '../../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../../trending_route/presentation/screen/trending_routes.dart';
import '../screen_sections/service_info_section.dart';
import '../screen_sections/why_choose_us/why_choose_us.dart';
import '../../flight/flight_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _printInitialDimensions();
  }

  void _printInitialDimensions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      print('Initial Width: ${size.width}, Height: ${size.height}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    print(' Screen Updated - Width: ${size.width}, Height: ${size.height}');
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
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: context.hp(4.5),
              width: context.hp(4.5),
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final generalBloc = context.read<GeneralSettingsBloc>();
          final dealsBloc = context.read<ExclusiveDealsBloc>();

          generalBloc.add(const LoadFaqList(domain: 'thewandernova.com'));
          generalBloc.add(
            const LoadGeneralSettings(domain: 'thewandernova.com'),
          );
          dealsBloc.add(const LoadExclusiveDeals());

          // If PopularDestinations has a GlobalKey or you're using context
          await Future.wait([
            Future.delayed(const Duration(milliseconds: 500)),
          ]);
        },
        color: const Color(0xff005B7F),
        backgroundColor: Colors.white,
        child: Container(
          color: const Color(0xFFF8F9FA),
          child: CustomScrollView(
            physics: context.scrollPhysics,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.wp(3.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //  BOLDER & LARGER TITLE
                      SizedBox(height: context.hp(2)),

                      // ================= HERO CARD =================
                      _buildHeroCard(
                        context,
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15),

                      SizedBox(height: context.hp(3)),

                      // Main Services (Top Row - 4 items)
                      _buildMainServicesGrid(context),

                      SizedBox(height: context.hp(0.7)),

                      //  BOLDER & LARGER SUBTITLE
                      Text(
                        'More Services',
                        style: TextStyle(
                          fontSize: context.titleLarge, // Use responsive font
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: context.letterSpacingTight,
                        ),
                      ),
                      SizedBox(height: context.hp(2)),

                      _buildAdditionalServicesGrid(context),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ===== EXISTING SECTIONS =====
              SliverToBoxAdapter(
                child: BlocProvider<ExclusiveDealsBloc>(
                  create: (context) => sl<ExclusiveDealsBloc>(),
                  child: const TransportExclusiveDealsSection(),
                ),
              ),

              const SliverToBoxAdapter(child: PopularDestinations()),
              const SliverToBoxAdapter(child: TrendingPackages()),
              const SliverToBoxAdapter(child: TravelStoriesSection()),
              SliverToBoxAdapter(
                child: BlocProvider(
                  create: (_) =>
                  sl<GeneralSettingsBloc>()
                    ..add(const LoadFaqList(domain: 'thewandernova.com')),
                  child: const FAQSection(),
                ),
              ),

              const SliverToBoxAdapter(child: WhyChooseUs()),

              SliverToBoxAdapter(
                child: BlocProvider(
                  create: (_) => sl<GeneralSettingsBloc>()
                    ..add(
                      const LoadGeneralSettings(domain: 'thewandernova.com'),
                    ),
                  child: const AboutCompanySection(),
                ),
              ),

              SliverToBoxAdapter(
                child: BlocProvider(
                  create: (_) => sl<GeneralSettingsBloc>()
                    ..add(
                      const LoadGeneralSettings(domain: 'thewandernova.com'),
                    ),
                  child: const ServicesInfoSection(),
                ),
              ),

              // SliverToBoxAdapter(
              //   child: FooterBannerWidget(
              //     domain: 'thewandernova.com',
              //     height: context.hp(18),
              //   ),
              // ),
              const SliverToBoxAdapter(child: ContactSection()),

              SliverToBoxAdapter(child: SizedBox(height: context.hp(5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.wp(5)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3C72), // Dark Blue
            Color(0xFF2A5298), // Medium Blue
            Color(0xFF7E8BA3), // Light Blue Grey
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Animated Background Elements
          Positioned(top: -20, right: -20, child: _buildAnimatedCloud(context)),
          Positioned(
            bottom: 40,
            left: -30,
            child: _buildAnimatedCloud(context, delay: 500),
          ),
          Positioned(top: 100, right: 50, child: _buildAnimatedPlane(context)),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Discover Your Next\nJourney ✈️",
                style: TextStyle(
                  fontSize: context.titleLarge * 1.3,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.hp(1.5)),
              Text(
                "Flights, hotels and more — all in one place.",
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.4,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.hp(1)),

              // Search Bar with Animation
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(50),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.2),
              //         blurRadius: 15,
              //         offset: const Offset(0, 5),
              //       ),
              //     ],
              //   ),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: TextField(
              //           decoration: InputDecoration(
              //             hintText: "Search destinations or deals",
              //             hintStyle: TextStyle(
              //               color: Colors.grey.shade400,
              //               fontSize: context.bodyMedium,
              //             ),
              //             border: InputBorder.none,
              //             contentPadding: EdgeInsets.symmetric(
              //               horizontal: context.wp(5),
              //               vertical: context.hp(2),
              //             ),
              //             prefixIcon: Icon(
              //               Icons.search_rounded,
              //               color: const Color(0xFF2A5298),
              //               size: context.iconMedium,
              //             ),
              //           ),
              //           style: TextStyle(
              //             fontSize: context.bodyMedium,
              //             color: Colors.black87,
              //           ),
              //         ),
              //       ),
              //       Container(
              //         margin: EdgeInsets.only(right: 4),
              //         decoration: const BoxDecoration(
              //           gradient: LinearGradient(
              //             colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              //           ),
              //           shape: BoxShape.circle,
              //           boxShadow: [
              //             BoxShadow(
              //               color: Color(0xFF1E3C72),
              //               blurRadius: 10,
              //               offset: Offset(0, 4),
              //             ),
              //           ],
              //         ),
              //         child: Material(
              //           color: Colors.transparent,
              //           child: InkWell(
              //             onTap: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (_) => const FlightScreen(),
              //                 ),
              //               );
              //             },
              //             borderRadius: BorderRadius.circular(50),
              //             child: Padding(
              //               padding: EdgeInsets.all(context.wp(2.5)),
              //               child: Icon(
              //                 Icons.arrow_forward_ios_rounded,
              //                 color: Colors.white,
              //                 size: context.iconSmall,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0),

              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(50),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedTextKit(
                      repeatForever: true,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          "Book now and save big",
                          speed: const Duration(milliseconds: 70),
                          textStyle: GoogleFonts.aBeeZee(
                            color: AppColors.lightBg,
                            fontSize: context.bodyLarge,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    // SizedBox(width: context.wp(1)),
                    // const Icon(
                    //   Icons.arrow_forward_rounded,
                    //   color: Colors.white,
                    //   size: 18,
                    // ),
                  ],
                ),
              ),
              SizedBox(height: context.hp(1)),

              // Animated Destination Chips
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroActionItem(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onTap,
      ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: context.hp(0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: context.iconMedium,
              ),
              SizedBox(height: context.hp(0.5)),
              Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.bodySmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCloud(BuildContext context, {int delay = 0}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(-10 * (1 - value), 0),
          child: Opacity(
            opacity: value * 0.3,
            child: Icon(
              Icons.cloud_rounded,
              color: Colors.white,
              size: context.isMobile ? 60 : 80,
            ),
          ),
        );
      },
    );
  }


  Widget _buildAnimatedPlane(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -5 * sin(value * 3.14159 * 2)),
          child: Transform.rotate(
            angle: sin(value * 3.14159 * 2) * 0.1,
            child: Opacity(
              opacity: 0.4,
              child: Icon(
                Icons.flight_rounded,
                color: Colors.white,
                size: context.isMobile ? 40 : 50,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainServicesGrid(BuildContext context) {
    final services = [
      ServiceItem(
        assetIcon: 'assets/icons/flight.png',
        // icon: Icons.flight_takeoff,
        label: 'Flights',
        color: const Color(0xFF4A90E2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FlightScreen()),
        ),
      ),
      ServiceItem(
        assetIcon: 'assets/icons/hotel.png',

        label: 'Hotels',
        color: const Color(0xFF50C878),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        ),
      ),
      ServiceItem(
        // icon: Icons.assignment_turned_in,
        assetIcon: 'assets/icons/visa.png',
        label: 'Visa',
        color: const Color(0xFF8E44AD),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VisaScreen()),
        ),
      ),
      ServiceItem(
        // icon: Icons.beach_access,
        assetIcon: 'assets/icons/holiday.png',
        label: 'Holidays',
        color: const Color(0xFFFF6B6B),
        onTap: () => Navigator.push(
          context,
          // MaterialPageRoute(builder: (_) => const NewHolidayScreen()),
          MaterialPageRoute(builder: (_) => const HolidaysScreen()),
        ),
      ),
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: context.isMobile
                ? 0.75
                : (context.isTablet ? 0.8 : 0.85),
            crossAxisSpacing: context.wp(1.5),
            mainAxisSpacing: context.hp(1),
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            // Use the MAIN service icon builder with larger Google Fonts text
            return _buildMainServiceIcon(context, services[index]);
          },
        ),
        SizedBox(height: context.hp(1.5)),
      ],
    );
  }

  Widget _buildMainServiceIcon(BuildContext context, ServiceItem service) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -2 * value),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: service.onTap,
              borderRadius: BorderRadius.circular(context.isMobile ? 16 : 18),
              splashColor: service.color.withOpacity(0.15),
              highlightColor: service.color.withOpacity(0.08),
              child: Container(
                // Changed from AnimatedContainer to Container
                padding: EdgeInsets.symmetric(
                  vertical: context.hp(2.2),
                  horizontal: context.gapSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    context.isMobile ? 16 : 18,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.12),
                    width: 1.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Use min instead of max
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 3,
                          top: 3,
                          child: Icon(
                            service.icon,
                            color: service.color.withOpacity(0.2),
                            size: context.iconXLarge,
                          ),
                        ),
                        Positioned(
                          left: 1,
                          top: 2,
                          child: Icon(
                            service.icon,
                            color: service.color.withOpacity(0.15),
                            size: context.iconXLarge,
                          ),
                        ),
                        service.assetIcon != null
                            ? Image.asset(
                          service.assetIcon!,
                          height: context.iconXLarge + 14,
                          width: context.iconXLarge + 14,
                          fit: BoxFit.contain,
                        )
                            : ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              service.iconColor,
                              service.iconColor.withOpacity(0.7),
                            ],
                          ).createShader(bounds),
                          child: Icon(
                            service.icon,
                            color: Colors.white,
                            size: context.iconXLarge,
                          ),
                        ),
                        Positioned(
                          left: -2,
                          top: -2,
                          child: Icon(
                            service.icon,
                            color: Colors.white.withOpacity(0.15),
                            size: context.iconXLarge - 2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.gapSmall),
                    // REMOVED Expanded widget from here
                    Text(
                      service.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoFlex(
                        fontSize: context.titleSmall,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.2,
                        letterSpacing: -0.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== ADDITIONAL SERVICES GRID =====
  Widget _buildAdditionalServicesGrid(BuildContext context) {
    final services = [
      ServiceItem(
        icon: Icons.local_taxi_outlined,
        label: 'Airport Cabs',
        color: const Color(0xFF1E3C72),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransportBookingScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.home_work_outlined,
        label: 'Villas & Homestays',
        color: const Color(0xFF1E3C72),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.emoji_events_outlined,
        label: 'Tours & Attractions',
        color: const Color(0xFF1E3C72),
        badge: 'NEW',
        onTap: () => _showComingSoon(context, 'Tours & Attractions'),
      ),
      ServiceItem(
        icon: Icons.access_time_outlined,
        label: 'Hourly Stays',
        color: const Color(0xFF1E3C72),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: context.isMobile
            ? 0.85
            : (context.isTablet ? 0.9 : 1.0),
        crossAxisSpacing: context.wp(2),
        mainAxisSpacing: context.hp(2),
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceIcon(context, services[index]);
      },
    );
  }

  Widget _buildServiceIcon(BuildContext context, ServiceItem service) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: 1 - (value * 0.02), // Subtle scale on animation
              child: Transform.translate(
                offset: Offset(0, -2 * value),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Add haptic feedback (optional)
                      // HapticFeedback.lightImpact();
                      service.onTap();
                    },
                    onTapDown: (_) {
                      setState(() {});
                    },
                    onTapUp: (_) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        setState(() {});
                      });
                    },
                    borderRadius: BorderRadius.circular(
                      context.isMobile ? 16 : 18,
                    ),
                    splashColor: service.color.withOpacity(0.15),
                    highlightColor: service.color.withOpacity(0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.all(context.gapSmall),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          context.isMobile ? 16 : 18,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.12),
                          width: 1.2,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey.shade50.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 3,
                                top: 4,
                                child: Icon(
                                  service.icon,
                                  color: service.color.withOpacity(0.2),
                                  size: context.iconXLarge,
                                ),
                              ),
                              Positioned(
                                left: 1,
                                top: 2,
                                child: Icon(
                                  service.icon,
                                  color: service.color.withOpacity(0.15),
                                  size: context.iconXLarge,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    service.color,
                                    service.color.withOpacity(0.7),
                                  ],
                                ).createShader(bounds),
                                child: Icon(
                                  service.icon,
                                  color: Colors.white,
                                  size: context.iconXLarge,
                                ),
                              ),
                              Positioned(
                                left: -2,
                                top: -2,
                                child: Icon(
                                  service.icon,
                                  color: Colors.white.withOpacity(0.15),
                                  size: context.iconXLarge - 2,
                                ),
                              ),
                              if (service.badge != null)
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.elasticOut,
                                    builder: (context, double scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFE74C3C),
                                                Color(0xFFC0392B),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(
                                                  0.4,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            service.badge!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: context.caption,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: context.gapXSmall),
                          Flexible(
                            child: Text(
                              service.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: context.labelMedium,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                height: 1.3,
                                letterSpacing: context.letterSpacingTight,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon!')));
  }
}

class ServiceItem {
  final IconData? icon;
  final String? assetIcon;
  final String label;
  final Color color;
  final Color? backgroundColor;
  final String? badge;
  final VoidCallback onTap;

  Color get iconColor => color ?? Colors.blue;

  ServiceItem({
    this.icon,
    this.assetIcon,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.badge,
    required this.onTap,
  });
}
