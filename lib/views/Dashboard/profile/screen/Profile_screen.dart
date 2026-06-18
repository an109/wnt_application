// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:wander_nova/views/Profile/presentation/bloc/profile_bloc.dart';
//
// import '../../../../core/utils/storage/shared_preference.dart';
// import '../../../../injection_container.dart';
// import '../../../Profile/domain/entities/ProfileEntity.dart';
// import '../../../Profile/presentation/bloc/profile_event.dart';
// import '../../../Profile/presentation/bloc/profile_state.dart';
// import '../../Section/add_traveller_popup.dart';
// import '../../../../UI_helper/responsive_layout.dart';
// import '../section/change_password_dialogue.dart';
// import '../section/edit_profile_screen.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   late ProfileBloc _profileBloc;
//   PreferencesManager? _prefsManager;
//
//   Map<String, dynamic>? _userData;
//
//   List<Map<String, dynamic>> _travellers = [];
//
//   bool _isLoading = true;
//   bool _isRefreshing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _profileBloc = sl<ProfileBloc>();
//     _profileBloc.add(const GetProfileEvent());
//     _loadUserData();
//   }
//
//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     _prefsManager = await PreferencesManager.create(prefs);
//
//     final userData = _prefsManager?.getUserData();
//
//     setState(() {
//       if (userData != null) {
//         // Map the stored keys to what ProfileScreen expects
//         _userData = {
//           'name': '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim(),
//           'email': userData['email'] ?? 'Not Available',
//           'phone': userData['phone_number'] ?? 'Not Available',
//           'address': userData['address'] ?? 'Not Available',
//           'travellers': userData['travellers'] ?? [],
//         };
//
//         _travellers = List<Map<String, dynamic>>.from(_userData!['travellers'] ?? []);
//       }
//       _isLoading = false;
//     });
//   }
//
//   Future<void> _saveTravellers() async {
//     if (_prefsManager != null && _userData != null) {
//       _userData!['travellers'] = _travellers;
//       await _prefsManager!.saveUserData(_userData!);
//     }
//   }
//
//   void _showAddTravellerModal() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//         return AddTravellerModal(
//           onTravellerAdded: (traveller) {
//             setState(() {
//               _travellers.add(traveller);
//             });
//
//             _saveTravellers();
//           },
//         );
//       },
//     );
//   }
//
//   //  Maps ProfileEntity to your screen's expected format
//   void _updateUserDataFromEntity(ProfileEntity profile) {
//     setState(() {
//       _userData = {
//         'name': '${profile.firstName} ${profile.lastName}'.trim(),
//         'email': profile.email ?? 'Not Available',
//         'phone': profile.phoneNumber,
//         'address': profile.address,
//         'travellers': _userData?['travellers'] ?? [], // Keep existing travellers
//       };
//       _isLoading = false;
//       _isRefreshing = false;
//     });
//   }
//
// //  Refresh handler for Pull-to-Refresh
//   Future<void> _refreshProfile() async {
//     setState(() => _isRefreshing = true);
//
//     // Listen for the next ProfileLoaded event
//     final completer = Completer<void>();
//     late final StreamSubscription<ProfileState> subscription;
//
//     subscription = _profileBloc.stream.listen((state) {
//       if (state is ProfileLoaded) {
//         _updateUserDataFromEntity(state.profile);
//         completer.complete();
//         subscription.cancel();
//       } else if (state is ProfileError) {
//         _isRefreshing = false;
//         setState(() {});
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(state.message)),
//         );
//         subscription.cancel();
//       }
//     });
//
//     // Dispatch event and wait max 10 seconds
//     _profileBloc.add(const GetProfileEvent());
//     await completer.future.timeout(
//       const Duration(seconds: 10),
//       onTimeout: () {
//         subscription.cancel();
//         setState(() => _isRefreshing = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Refresh timed out')),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.white,
//
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           icon: Icon(
//             Icons.arrow_back_ios_new,
//             size: context.iconSmall,
//             color: Colors.black87,
//           ),
//         ),
//
//         title: Text(
//           "My Profile",
//           style: TextStyle(
//             fontSize: context.titleMedium,
//             fontWeight: FontWeight.w700,
//             color: Colors.black87,
//           ),
//         ),
//       ),
//
//       body: _isLoading && !_isRefreshing
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//         onRefresh: _refreshProfile,
//         color: const Color(0xFF0054A0),
//         backgroundColor: Colors.white,
//         child: SafeArea(
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(), // ✅ Required for pull-to-refresh
//             padding: context.horizontalPadding.copyWith(
//               top: context.gapMedium,
//               bottom: context.gapXLarge,
//             ),
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(
//                   maxWidth: context.isDesktop
//                       ? 900
//                       : context.isTablet
//                       ? 700
//                       : double.infinity,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildProfileHeader(),
//                     SizedBox(height: context.gapLarge),
//                     _buildPersonalInfoCard(),
//                     SizedBox(height: context.gapLarge),
//                     _buildTravellerSection(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // =========================================================
//   // PROFILE HEADER
//   // =========================================================
//
//   Widget _buildProfileHeader() {
//     final name = _userData?['name'] ?? 'Welcome';
//
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.gapLarge),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [
//             Color(0xFF0054A0),
//             Color(0xFF1976D2),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(
//           context.borderRadiusLarge,
//         ),
//       ),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: context.isMobile ? 38 : 48,
//             backgroundColor: Colors.white,
//             child: Text(
//               name.isNotEmpty ? name[0].toUpperCase() : "U",
//               style: TextStyle(
//                 fontSize: context.headlineSmall,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF0054A0),
//               ),
//             ),
//           ),
//
//           SizedBox(height: context.gapMedium),
//
//           Text(
//             name,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: context.titleLarge,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//
//           SizedBox(height: context.gapXXSmall),
//
//           Text(
//             _userData?['email'] ?? 'No email available',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: context.bodyMedium,
//               color: Colors.white.withOpacity(0.9),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // =========================================================
//   // PERSONAL INFO CARD
//   // =========================================================
//
//   Widget _buildPersonalInfoCard() {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.gapLarge),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(
//           context.borderRadiusLarge,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionTitle(
//             title: "Personal Information",
//             icon: Icons.person_outline,
//           ),
//
//           SizedBox(height: context.gapLarge),
//
//           _buildInfoTile(
//             icon: Icons.person_outline,
//             title: "Full Name",
//             value: _userData?['name'] ?? 'Not Available',
//           ),
//
//           SizedBox(height: context.gapMedium),
//
//           _buildInfoTile(
//             icon: Icons.email_outlined,
//             title: "Email Address",
//             value: _userData?['email'] ?? 'Not Available',
//           ),
//
//           SizedBox(height: context.gapMedium),
//
//           _buildInfoTile(
//             icon: Icons.phone_outlined,
//             title: "Phone Number",
//             value: _userData?['phone'] ?? 'Not Available',
//           ),
//
//           SizedBox(height: context.gapMedium),
//
//           _buildInfoTile(
//             icon: Icons.location_on_outlined,
//             title: "Address",
//             value: _userData?['address'] ?? 'Not Available',
//           ),
//
//           SizedBox(height: context.gapLarge),
//
//           Wrap(
//             spacing: context.gapMedium,
//             runSpacing: context.gapMedium,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => EditProfileScreen(
//                         userData: _userData,
//                       ),
//                     ),
//                   );
//                   if (mounted) _refreshProfile();
//                 },
//
//                 icon: Icon(
//                   Icons.edit_outlined,
//                   size: context.iconSmall,
//                 ),
//
//                 label: Text(
//                   "Edit Profile",
//                   style: TextStyle(
//                     fontSize: context.bodyMedium,
//                   ),
//                 ),
//
//                 style: ElevatedButton.styleFrom(
//                   elevation: 0,
//                   backgroundColor: const Color(0xFF0054A0),
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.gapLarge,
//                     vertical: context.gapMedium,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(
//                       context.borderRadiusMedium,
//                     ),
//                   ),
//                 ),
//               ),
//
//               OutlinedButton.icon(
//                 onPressed: () {
//                   showChangePasswordDialog(
//                     context: context,
//                     email: _userData?['email'] ?? '',
//                     onSave: () {
//                       debugPrint("Password Changed");
//                     },
//                   );
//                 },
//
//                 icon: Icon(
//                   Icons.lock_outline,
//                   size: context.iconSmall,
//                 ),
//
//                 label: Text(
//                   "Change Password",
//                   style: TextStyle(
//                     fontSize: context.bodyMedium,
//                   ),
//                 ),
//
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: Colors.black87,
//                   side: BorderSide(
//                     color: Colors.grey.shade300,
//                   ),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.gapLarge,
//                     vertical: context.gapMedium,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(
//                       context.borderRadiusMedium,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // =========================================================
//   // INFO TILE
//   // =========================================================
//
//   Widget _buildInfoTile({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.w(12)),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(
//           context.borderRadiusMedium,
//         ),
//       ),
//
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: EdgeInsets.all(context.gapSmall),
//             decoration: BoxDecoration(
//               color: const Color(0xFF0054A0).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(
//                 context.borderRadiusSmall,
//               ),
//             ),
//             child: Icon(
//               icon,
//               size: context.iconSmall,
//               color: const Color(0xFF0054A0),
//             ),
//           ),
//
//           SizedBox(width: context.gapMedium),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: context.bodySmall,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//
//                 SizedBox(height: context.gapXXSmall),
//
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: context.bodyMedium,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // =========================================================
//   // TRAVELLER SECTION
//   // =========================================================
//
//   Widget _buildTravellerSection() {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.gapLarge),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(
//           context.borderRadiusLarge,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (context.isMobile)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildSectionTitle(
//                   title: "Travellers",
//                   icon: Icons.group_outlined,
//                 ),
//
//                 SizedBox(height: context.gapMedium),
//
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: _showAddTravellerModal,
//
//                     icon: const Icon(Icons.add),
//
//                     label: const Text("Add Traveller"),
//
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF0054A0),
//                       foregroundColor: Colors.white,
//                       padding: EdgeInsets.symmetric(
//                         vertical: context.gapMedium,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(
//                           context.borderRadiusMedium,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           else
//             Row(
//               mainAxisAlignment:
//               MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: _buildSectionTitle(
//                     title: "Travellers",
//                     icon: Icons.group_outlined,
//                   ),
//                 ),
//
//                 ElevatedButton.icon(
//                   onPressed: _showAddTravellerModal,
//
//                   icon: const Icon(Icons.add),
//
//                   label: const Text("Add Traveller"),
//
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF0054A0),
//                     foregroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(
//                       horizontal: context.gapLarge,
//                       vertical: context.gapMedium,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(
//                         context.borderRadiusMedium,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//           SizedBox(height: context.gapLarge),
//
//           TextField(
//             decoration: InputDecoration(
//               hintText: "Search travellers",
//
//               prefixIcon: const Icon(Icons.search),
//
//               filled: true,
//
//               fillColor: Colors.grey.shade100,
//
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(
//                   context.borderRadiusMedium,
//                 ),
//                 borderSide: BorderSide.none,
//               ),
//
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(
//                   context.borderRadiusMedium,
//                 ),
//                 borderSide: BorderSide.none,
//               ),
//
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(
//                   context.borderRadiusMedium,
//                 ),
//                 borderSide: const BorderSide(
//                   color: Color(0xFF0054A0),
//                 ),
//               ),
//             ),
//           ),
//
//           SizedBox(height: context.gapLarge),
//
//           _travellers.isEmpty
//               ? _buildEmptyState()
//               : _buildTravellerList(),
//         ],
//       ),
//     );
//   }
//
//   // =========================================================
//   // EMPTY STATE
//   // =========================================================
//
//   Widget _buildEmptyState() {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         vertical: context.gapXXLarge,
//       ),
//       child: Center(
//         child: Column(
//           children: [
//             Icon(
//               Icons.travel_explore_outlined,
//               size: context.iconXLarge * 1.7,
//               color: Colors.grey.shade300,
//             ),
//
//             SizedBox(height: context.gapMedium),
//
//             Text(
//               "No Travellers Added",
//               style: TextStyle(
//                 fontSize: context.titleMedium,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
//             ),
//
//             SizedBox(height: context.gapXXSmall),
//
//             Text(
//               "Your saved travellers will appear here.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: context.bodyMedium,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // =========================================================
//   // TRAVELLER LIST
//   // =========================================================
//
//   Widget _buildTravellerList() {
//     return ListView.separated(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//
//       itemCount: _travellers.length,
//
//       separatorBuilder: (_, __) {
//         return SizedBox(height: context.gapMedium);
//       },
//
//       itemBuilder: (_, index) {
//         final traveller = _travellers[index];
//
//         final fullName =
//             "${traveller['firstName'] ?? ''} ${traveller['lastName'] ?? ''}";
//
//         return Container(
//           padding: EdgeInsets.all(context.w(12)),
//
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(
//               context.borderRadiusMedium,
//             ),
//           ),
//
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: context.isMobile ? 24 : 30,
//                 backgroundColor:
//                 const Color(0xFF0054A0).withOpacity(0.1),
//
//                 child: Text(
//                   fullName.isNotEmpty
//                       ? fullName[0].toUpperCase()
//                       : "T",
//
//                   style: TextStyle(
//                     color: const Color(0xFF0054A0),
//                     fontWeight: FontWeight.bold,
//                     fontSize: context.bodyLarge,
//                   ),
//                 ),
//               ),
//
//               SizedBox(width: context.gapMedium),
//
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                   CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       fullName,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: context.bodyMedium,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.black87,
//                       ),
//                     ),
//
//                     SizedBox(height: context.gapXXSmall),
//
//                     Text(
//                       "${traveller['nationality'] ?? 'N/A'} • ${traveller['paxType'] ?? 'Adult'}",
//
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//
//                       style: TextStyle(
//                         fontSize: context.bodySmall,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               PopupMenuButton<String>(
//                 icon: const Icon(Icons.more_vert),
//
//                 onSelected: (value) {
//                   if (value == 'delete') {
//                     setState(() {
//                       _travellers.removeAt(index);
//                     });
//
//                     _saveTravellers();
//                   }
//                 },
//
//                 itemBuilder: (_) {
//                   return const [
//                     PopupMenuItem(
//                       value: 'delete',
//                       child: Text('Delete'),
//                     ),
//                   ];
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   // =========================================================
//   // SECTION TITLE
//   // =========================================================
//
//   Widget _buildSectionTitle({
//     required String title,
//     required IconData icon,
//   }) {
//     return Row(
//       children: [
//         Container(
//           padding: EdgeInsets.all(context.gapSmall),
//           decoration: BoxDecoration(
//             color: const Color(0xFF0054A0).withOpacity(0.1),
//             borderRadius: BorderRadius.circular(
//               context.borderRadiusSmall,
//             ),
//           ),
//           child: Icon(
//             icon,
//             color: const Color(0xFF0054A0),
//             size: context.iconSmall,
//           ),
//         ),
//
//         SizedBox(width: context.gapSmall),
//
//         Expanded(
//           child: Text(
//             title,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: context.titleMedium,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/views/Profile/presentation/bloc/profile_bloc.dart';

import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../Profile/domain/entities/ProfileEntity.dart';
import '../../../Profile/presentation/bloc/profile_event.dart';
import '../../../Profile/presentation/bloc/profile_state.dart';
import '../../Section/add_traveller_popup.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../section/change_password_dialogue.dart';
import '../section/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileBloc _profileBloc;
  PreferencesManager? _prefsManager;

  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _travellers = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>();
    _profileBloc.add(const GetProfileEvent());
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _prefsManager = await PreferencesManager.create(prefs);

    final userData = _prefsManager?.getUserData();

    setState(() {
      if (userData != null) {
        _userData = {
          'name': '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim(),
          'email': userData['email'] ?? 'Not Available',
          'phone': userData['phone_number'] ?? 'Not Available',
          'address': userData['address'] ?? 'Not Available',
          'travellers': userData['travellers'] ?? [],
        };
        _travellers = List<Map<String, dynamic>>.from(_userData!['travellers'] ?? []);
      }
      _isLoading = false;
    });
  }

  Future<void> _saveTravellers() async {
    if (_prefsManager != null && _userData != null) {
      _userData!['travellers'] = _travellers;
      await _prefsManager!.saveUserData(_userData!);
    }
  }

  void _showAddTravellerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTravellerModal(
        onTravellerAdded: (traveller) {
          setState(() => _travellers.add(traveller));
          _saveTravellers();
        },
      ),
    );
  }

  void _updateUserDataFromEntity(ProfileEntity profile) {
    setState(() {
      _userData = {
        'name': '${profile.firstName} ${profile.lastName}'.trim(),
        'email': profile.email ?? 'Not Available',
        'phone': profile.phoneNumber,
        'address': profile.address,
        'travellers': _userData?['travellers'] ?? [],
      };
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);
    final completer = Completer<void>();
    late final StreamSubscription<ProfileState> subscription;

    subscription = _profileBloc.stream.listen((state) {
      if (state is ProfileLoaded) {
        _updateUserDataFromEntity(state.profile);
        completer.complete();
        subscription.cancel();
      } else if (state is ProfileError) {
        _isRefreshing = false;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
        subscription.cancel();
      }
    });

    _profileBloc.add(const GetProfileEvent());
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        subscription.cancel();
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refresh timed out')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E2F4E)),
        ),
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            fontSize: context.titleMedium,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2F4E),
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading && !_isRefreshing
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0054A0)))
          : RefreshIndicator(
        onRefresh: _refreshProfile,
        color: const Color(0xFF0054A0),
        backgroundColor: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.gapMedium),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.isDesktop ? 900 : context.isTablet ? 700 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserSummaryCard(),
                    const SizedBox(height: 20),
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 20),
                    _buildTravellerCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // USER SUMMARY CARD (no gradient, simple avatar + name)
  // =========================================================
  Widget _buildUserSummaryCard() {
    final name = _userData?['name'] ?? 'Welcome';
    final email = _userData?['email'] ?? 'No email available';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF0054A0).withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "U",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0054A0),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2F4E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(userData: _userData)),
              ).then((_) => _refreshProfile());
            },
            child: Text(
              "Edit",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0054A0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PERSONAL INFO CARD (list tiles style)
  // =========================================================
  Widget _buildPersonalInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Personal Information",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E2F4E),
              ),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),
          _buildInfoTile(Icons.email_outlined, "Email", _userData?['email'] ?? 'Not Available'),
          _buildDivider(),
          _buildInfoTile(Icons.phone_outlined, "Phone", _userData?['phone'] ?? 'Not Available'),
          _buildDivider(),
          _buildInfoTile(Icons.location_on_outlined, "Address", _userData?['address'] ?? 'Not Available'),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () => showChangePasswordDialog(
                context: context,
                name: _userData?['name'] ?? '',
                email: _userData?['email'] ?? '',
                onSave: () => debugPrint("Password Changed"),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E2F4E),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: Text(
                "Change Password",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF0054A0)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1E2F4E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100, indent: 54);

  // =========================================================
  // TRAVELLER CARD (with search, add button, list)
  // =========================================================
  Widget _buildTravellerCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Travellers",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2F4E),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0054A0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF0054A0)),
                    onPressed: _showAddTravellerModal,
                    tooltip: "Add Traveller",
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search travellers",
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _travellers.isEmpty
              ? _buildEmptyTravellerState()
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _travellers.length,
            separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),
            itemBuilder: (_, index) {
              final traveller = _travellers[index];
              final fullName = "${traveller['firstName'] ?? ''} ${traveller['lastName'] ?? ''}".trim();
              final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : "T";

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0054A0).withOpacity(0.1),
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0054A0),
                    ),
                  ),
                ),
                title: Text(
                  fullName,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  "${traveller['nationality'] ?? 'N/A'} • ${traveller['paxType'] ?? 'Adult'}",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () {
                    setState(() => _travellers.removeAt(index));
                    _saveTravellers();
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyTravellerState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.travel_explore_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "No Travellers Added",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E2F4E)),
            ),
            const SizedBox(height: 4),
            Text(
              "Tap the + button to add a traveller",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}