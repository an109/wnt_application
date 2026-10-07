import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import '../../../DeleteAccount/presentation/screen/delete_account_screen.dart';
import '../widgets/account_kit.dart';
import 'add_traveller_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/views/Profile/presentation/bloc/profile_bloc.dart';

import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../Profile/domain/entities/ProfileEntity.dart';
import '../../../Profile/presentation/bloc/profile_event.dart';
import '../../../Profile/presentation/bloc/profile_state.dart';
import '../../Section/data/traveller_api_service.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../section/edit_profile_screen.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileBloc _profileBloc;
  PreferencesManager? _prefsManager;

  // Add this to track if we've already loaded from API
  bool _isFirstLoad = true;

  Map<String, dynamic>? _userData;

  List<Map<String, dynamic>> _travellers = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  // Add subscription for BLoC state changes
  StreamSubscription<ProfileState>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>();

    // Listen to BLoC state changes
    _profileSubscription = _profileBloc.stream.listen(_handleProfileState);

    // Load from API when screen opens
    _profileBloc.add(const GetProfileEvent());

    // Still load from SharedPreferences as fallback, but don't show it immediately
    _loadUserDataFromPrefs();

    // Refresh the traveller list from the backend (falls back to whatever
    // was already loaded from prefs if this fails or the user has no email).
    _loadTravellersFromApi();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  // Handle BLoC state changes
  void _handleProfileState(ProfileState state) {
    if (state is ProfileLoaded) {
      // Update UI with API data
      _updateUserDataFromEntity(state.profile);
      _isFirstLoad = false;

      // Also update SharedPreferences with fresh API data
      _saveUserDataToPrefs(state.profile);

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    } else if (state is ProfileError) {
      // Only show error if we don't have cached data
      if (_userData == null) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      } else {
        // If we have cached data, just refresh the UI
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } else if (state is ProfileLoading) {
      // Only show loading on first load
      if (_isFirstLoad) {
        setState(() {
          _isLoading = true;
        });
      }
    }
  }

  // Load from SharedPreferences as fallback
  Future<void> _loadUserDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefsManager = await PreferencesManager.create(prefs);

      final userData = _prefsManager?.getUserData();

      // Only set data if API hasn't loaded yet
      if (_isFirstLoad && userData != null && mounted) {
        setState(() {
          _userData = {
            'name': '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim(),
            'firstName': userData['firstname'] ?? '',
            'lastName': userData['lastname'] ?? '',
            'email': userData['email'] ?? 'Not Available',
            'phone': userData['phone_number'] ?? 'Not Available',
            'address': userData['address'] ?? 'Not Available',
            'travellers': userData['travellers'] ?? [],
          };

          _travellers = List<Map<String, dynamic>>.from(_userData!['travellers'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      // Silent fail - API will be the primary source
    }
  }

  // Save API data to SharedPreferences
  Future<void> _saveUserDataToPrefs(ProfileEntity profile) async {
    try {
      if (_prefsManager == null) {
        final prefs = await SharedPreferences.getInstance();
        _prefsManager = await PreferencesManager.create(prefs);
      }

      if (_prefsManager != null) {
        // Convert ProfileEntity to map format
        final Map<String, dynamic> userData = {
          'firstname': profile.firstName,
          'lastname': profile.lastName,
          'email': profile.email ?? '',
          'phone_number': profile.phoneNumber,
          'address': profile.address,
          'travellers': _travellers, // Keep travellers from current state
        };
        await _prefsManager!.saveUserData(userData);
      }
    } catch (e) {
      // Silent fail - don't block UI
    }
  }

  Future<void> _saveTravellers() async {
    if (_prefsManager != null && _userData != null) {
      _userData!['travellers'] = _travellers;
      await _prefsManager!.saveUserData(_userData!);
    }
  }

  Future<void> _loadTravellersFromApi() async {
    try {
      final prefs = sl<PreferencesManager>();
      final email = prefs.getString('user_email') ??
          prefs.getUserData()?['email'] as String?;
      if (email == null || email.isEmpty) return;

      final response = await sl<TravellerApiService>().getTravellers(email);
      final travellers = _parseTravellersResponse(response.data);
      if (travellers != null && mounted) {
        setState(() => _travellers = travellers);
        await _saveTravellers();
      }
    } catch (_) {
      // Silent fail - keep whatever was already loaded from prefs.
    }
  }

  // Accepts a plain array, or common wrapper shapes like
  // {"travellers": [...]}, {"results": [...]}, {"data": [...]}.
  List<Map<String, dynamic>>? _parseTravellersResponse(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final list = data['travellers'] ?? data['results'] ?? data['data'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return null;
  }

  // Maps ProfileEntity to your screen's expected format
  void _updateUserDataFromEntity(ProfileEntity profile) {
    setState(() {
      _userData = {
        'name': '${profile.firstName} ${profile.lastName}'.trim(),
        'firstName': profile.firstName,
        'lastName': profile.lastName,
        'phoneCode': profile.phoneCode,
        'email': profile.email ?? 'Not Available',
        'phone': profile.phoneNumber,
        'address': profile.address,
        'travellers': _userData?['travellers'] ?? [], // Keep existing travellers
      };
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  // Refresh handler for Pull-to-Refresh
  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);

    // Listen for the next ProfileLoaded event
    final completer = Completer<void>();
    late final StreamSubscription<ProfileState> subscription;

    subscription = _profileBloc.stream.listen((state) {
      if (state is ProfileLoaded) {
        _updateUserDataFromEntity(state.profile);
        // Update SharedPreferences with fresh data
        _saveUserDataToPrefs(state.profile);
        completer.complete();
        subscription.cancel();
      } else if (state is ProfileError) {
        _isRefreshing = false;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
        subscription.cancel();
        completer.completeError(state.message);
      }
    });

    // Dispatch event and wait max 10 seconds
    _profileBloc.add(const GetProfileEvent());
    try {
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
    } catch (e) {
      // Handle error silently
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = EdgeInsets.symmetric(horizontal: context.fx(16));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: gutter.copyWith(top: context.fx(8)),
                child: const AccountTopBar(title: 'Profile'),
              ),
              Expanded(
                child: _isLoading && !_isRefreshing
                    ? const AppLoadingView(message: 'Loading your profile…')
                    : RefreshIndicator(
                        onRefresh: _refreshProfile,
                        color: AppColors.AppBlue,
                        backgroundColor: Colors.white,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: gutter.copyWith(
                            top: context.fx(16),
                            bottom: context.fx(32),
                          ),
                          children: [
                            AccountHeaderCard(
                              name: _userData?['name'] ?? '',
                              phone: _displayValue(_userData?['phone']),
                              email: _displayValue(_userData?['email']),
                            ),
                            SizedBox(height: context.fx(28)),
                            _buildPersonalInfoCard(),
                            SizedBox(height: context.fx(24)),
                            _buildTravellerSection(),
                            SizedBox(height: context.fx(24)),
                            AccountSectionCard(
                              title: 'Delete Account',
                              icon: Icons.delete_rounded,
                              iconColor: const Color(0xFFE5484D),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: context.fx(22),
                                color: kAccountMuted,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DeleteAccountScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// API placeholders ("Not Available") read as empty in the new UI.
  String _displayValue(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text == 'Not Available' ? '' : text;
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(userData: _userData)),
    );
    if (mounted) _refreshProfile();
  }

  // =========================================================
  // PERSONAL INFORMATION
  // =========================================================

  Widget _buildPersonalInfoCard() {
    final gap = SizedBox(height: context.fx(16));
    return AccountSectionCard(
      title: 'Personal Information',
      icon: Icons.person_rounded,
      iconColor: kAccountOrange,
      trailing: Semantics(
        button: true,
        label: 'Edit profile',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openEditProfile,
          child: Icon(Icons.edit_square, size: context.fx(20), color: AppColors.AppBlue),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: context.fx(4)),
          Row(
            children: [
              Expanded(
                child: AccountDisplayField(
                  label: 'First Name',
                  value: (_userData?['firstName'] ?? '').toString().toUpperCase(),
                  icon: Icons.person_rounded,
                ),
              ),
              SizedBox(width: context.fx(12)),
              Expanded(
                child: AccountDisplayField(
                  label: 'Last Name',
                  value: (_userData?['lastName'] ?? '').toString().toUpperCase(),
                  icon: Icons.person_rounded,
                ),
              ),
            ],
          ),
          gap,
          Row(
            children: [
              AccountPhoneCode(code: (_userData?['phoneCode'] ?? '+91').toString()),
              SizedBox(width: context.fx(8)),
              Expanded(
                child: AccountDisplayField(
                  label: 'Phone Number',
                  value: _displayValue(_userData?['phone']),
                ),
              ),
            ],
          ),
          gap,
          AccountDisplayField(
            label: 'EMAIL ADDRESS',
            value: _displayValue(_userData?['email']),
            icon: Icons.mail_rounded,
          ),
          gap,
          AccountDisplayField(
            label: 'PASSWORD',
            value: '••••••••••',
            suffix: Icon(Icons.visibility_off_outlined, size: context.fx(18), color: kAccountMuted),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TRAVELLERS
  // =========================================================

  Future<void> _openAddTraveller() async {
    final traveller = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddTravellerScreen()),
    );
    if (traveller == null || !mounted) return;
    setState(() => _travellers.add(traveller));
    _saveTravellers();
  }

  String _travellerSummary(Map<String, dynamic> t) {
    final parts = <String>[];
    final dob = DateTime.tryParse((t['dob'] ?? '').toString());
    if (dob != null) parts.add('DOB: ${DateFormat('dd MMM yyyy').format(dob)}');
    final gender = (t['gender'] ?? '').toString();
    if (gender.isNotEmpty) parts.add(gender);
    final passport = (t['passportNumber'] ?? '').toString();
    if (passport.isNotEmpty) parts.add('Passport: $passport');
    return parts.join(' | ');
  }

  Widget _buildTravellerSection() {
    return AccountSectionCard(
      title: 'Add Travellers',
      icon: Icons.groups_rounded,
      iconColor: AppColors.AppBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _travellers.length; i++) _travellerRow(i),
          if (_travellers.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: context.fx(12)),
              child: Text(
                'No travellers saved yet. Add the people you travel with to book faster.',
                style: TextStyle(fontSize: context.ffs(11), color: kAccountMuted),
              ),
            ),
          SizedBox(height: context.fx(8)),
          _addTravellerButton(),
        ],
      ),
    );
  }

  Widget _travellerRow(int index) {
    final t = _travellers[index];
    final name = '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim();
    final summary = _travellerSummary(t);
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.fx(10)),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kAccountLine)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Traveller' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.ffs(13),
                    fontWeight: FontWeight.w500,
                    color: kAccountInk,
                  ),
                ),
                if (summary.isNotEmpty)
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.ffs(11), color: kAccountMuted),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Traveller options',
            icon: Icon(Icons.edit_square, size: context.fx(20), color: AppColors.AppBlue),
            onSelected: (value) {
              if (value == 'remove') {
                setState(() => _travellers.removeAt(index));
                _saveTravellers();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addTravellerButton() {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openAddTraveller,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: const Color(0xFFBFE3F7),
            radius: context.fx(12),
          ),
          child: Container(
            height: context.fx(52),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FBFF),
              borderRadius: BorderRadius.circular(context.fx(12)),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_rounded, size: context.fx(20), color: AppColors.AppBlue),
                SizedBox(width: context.fx(8)),
                Text(
                  'Add New Adult',
                  style: TextStyle(
                    fontSize: context.ffs(14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.AppBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.5),
        Radius.circular(radius),
      ));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
