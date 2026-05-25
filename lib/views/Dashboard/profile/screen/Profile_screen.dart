import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/storage/shared_preference.dart';
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
  PreferencesManager? _prefsManager;

  Map<String, dynamic>? _userData;

  List<Map<String, dynamic>> _travellers = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    _prefsManager = await PreferencesManager.create(prefs);

    final userData = _prefsManager?.getUserData();

    setState(() {
      _userData = userData;

      _travellers =
          (userData?['travellers'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
              [];

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
      builder: (_) {
        return AddTravellerModal(
          onTravellerAdded: (traveller) {
            setState(() {
              _travellers.add(traveller);
            });

            _saveTravellers();
          },
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
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: context.iconSmall,
            color: Colors.black87,
          ),
        ),

        title: Text(
          "My Profile",
          style: TextStyle(
            fontSize: context.titleMedium,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: SingleChildScrollView(
          physics: context.scrollPhysics,
          padding: context.horizontalPadding.copyWith(
            top: context.gapMedium,
            bottom: context.gapXLarge,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.isDesktop
                    ? 900
                    : context.isTablet
                    ? 700
                    : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),

                  SizedBox(height: context.gapLarge),

                  _buildPersonalInfoCard(),

                  SizedBox(height: context.gapLarge),

                  _buildTravellerSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PROFILE HEADER
  // =========================================================

  Widget _buildProfileHeader() {
    final name = _userData?['name'] ?? 'Welcome';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.gapLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0054A0),
            Color(0xFF1976D2),
          ],
        ),
        borderRadius: BorderRadius.circular(
          context.borderRadiusLarge,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: context.isMobile ? 38 : 48,
            backgroundColor: Colors.white,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "U",
              style: TextStyle(
                fontSize: context.headlineSmall,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0054A0),
              ),
            ),
          ),

          SizedBox(height: context.gapMedium),

          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: context.gapXXSmall),

          Text(
            _userData?['email'] ?? 'No email available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PERSONAL INFO CARD
  // =========================================================

  Widget _buildPersonalInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.gapLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.borderRadiusLarge,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: "Personal Information",
            icon: Icons.person_outline,
          ),

          SizedBox(height: context.gapLarge),

          _buildInfoTile(
            icon: Icons.person_outline,
            title: "Full Name",
            value: _userData?['name'] ?? 'Not Available',
          ),

          SizedBox(height: context.gapMedium),

          _buildInfoTile(
            icon: Icons.email_outlined,
            title: "Email Address",
            value: _userData?['email'] ?? 'Not Available',
          ),

          SizedBox(height: context.gapMedium),

          _buildInfoTile(
            icon: Icons.phone_outlined,
            title: "Phone Number",
            value: _userData?['phone'] ?? 'Not Available',
          ),

          SizedBox(height: context.gapMedium),

          _buildInfoTile(
            icon: Icons.location_on_outlined,
            title: "Address",
            value: _userData?['address'] ?? 'Not Available',
          ),

          SizedBox(height: context.gapLarge),

          Wrap(
            spacing: context.gapMedium,
            runSpacing: context.gapMedium,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        userData: _userData,
                      ),
                    ),
                  );
                },

                icon: Icon(
                  Icons.edit_outlined,
                  size: context.iconSmall,
                ),

                label: Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF0054A0),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.gapLarge,
                    vertical: context.gapMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.borderRadiusMedium,
                    ),
                  ),
                ),
              ),

              OutlinedButton.icon(
                onPressed: () {
                  showChangePasswordDialog(
                    context: context,
                    email: _userData?['email'] ?? '',
                    onSave: () {
                      debugPrint("Password Changed");
                    },
                  );
                },

                icon: Icon(
                  Icons.lock_outline,
                  size: context.iconSmall,
                ),

                label: Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                  ),
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.gapLarge,
                    vertical: context.gapMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.borderRadiusMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFO TILE
  // =========================================================

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          context.borderRadiusMedium,
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(context.gapSmall),
            decoration: BoxDecoration(
              color: const Color(0xFF0054A0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                context.borderRadiusSmall,
              ),
            ),
            child: Icon(
              icon,
              size: context.iconSmall,
              color: const Color(0xFF0054A0),
            ),
          ),

          SizedBox(width: context.gapMedium),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.grey.shade600,
                  ),
                ),

                SizedBox(height: context.gapXXSmall),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TRAVELLER SECTION
  // =========================================================

  Widget _buildTravellerSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.gapLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.borderRadiusLarge,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context.isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                  title: "Travellers",
                  icon: Icons.group_outlined,
                ),

                SizedBox(height: context.gapMedium),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddTravellerModal,

                    icon: const Icon(Icons.add),

                    label: const Text("Add Traveller"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0054A0),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: context.gapMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.borderRadiusMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildSectionTitle(
                    title: "Travellers",
                    icon: Icons.group_outlined,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: _showAddTravellerModal,

                  icon: const Icon(Icons.add),

                  label: const Text("Add Traveller"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0054A0),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.gapLarge,
                      vertical: context.gapMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.borderRadiusMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          SizedBox(height: context.gapLarge),

          TextField(
            decoration: InputDecoration(
              hintText: "Search travellers",

              prefixIcon: const Icon(Icons.search),

              filled: true,

              fillColor: Colors.grey.shade100,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
                borderSide: const BorderSide(
                  color: Color(0xFF0054A0),
                ),
              ),
            ),
          ),

          SizedBox(height: context.gapLarge),

          _travellers.isEmpty
              ? _buildEmptyState()
              : _buildTravellerList(),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.gapXXLarge,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.travel_explore_outlined,
              size: context.iconXLarge * 1.7,
              color: Colors.grey.shade300,
            ),

            SizedBox(height: context.gapMedium),

            Text(
              "No Travellers Added",
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: context.gapXXSmall),

            Text(
              "Your saved travellers will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TRAVELLER LIST
  // =========================================================

  Widget _buildTravellerList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      itemCount: _travellers.length,

      separatorBuilder: (_, __) {
        return SizedBox(height: context.gapMedium);
      },

      itemBuilder: (_, index) {
        final traveller = _travellers[index];

        final fullName =
            "${traveller['firstName'] ?? ''} ${traveller['lastName'] ?? ''}";

        return Container(
          padding: EdgeInsets.all(context.gapMedium),

          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(
              context.borderRadiusMedium,
            ),
          ),

          child: Row(
            children: [
              CircleAvatar(
                radius: context.isMobile ? 24 : 30,
                backgroundColor:
                const Color(0xFF0054A0).withOpacity(0.1),

                child: Text(
                  fullName.isNotEmpty
                      ? fullName[0].toUpperCase()
                      : "T",

                  style: TextStyle(
                    color: const Color(0xFF0054A0),
                    fontWeight: FontWeight.bold,
                    fontSize: context.bodyLarge,
                  ),
                ),
              ),

              SizedBox(width: context.gapMedium),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: context.gapXXSmall),

                    Text(
                      "${traveller['nationality'] ?? 'N/A'} • ${traveller['paxType'] ?? 'Adult'}",

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),

                onSelected: (value) {
                  if (value == 'delete') {
                    setState(() {
                      _travellers.removeAt(index);
                    });

                    _saveTravellers();
                  }
                },

                itemBuilder: (_) {
                  return const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ];
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.gapSmall),
          decoration: BoxDecoration(
            color: const Color(0xFF0054A0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              context.borderRadiusSmall,
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0054A0),
            size: context.iconSmall,
          ),
        ),

        SizedBox(width: context.gapSmall),

        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}