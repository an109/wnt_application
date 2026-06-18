import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/Profile/presentation/bloc/profile_bloc.dart';
import 'package:wander_nova/views/Profile/presentation/bloc/profile_event.dart';

import '../../../Profile/domain/entities/ProfileEntity.dart';
import '../../../Profile/presentation/bloc/profile_state.dart';
import '../widgets/profile_dropdown_field.dart';
import '../widgets/profile_phone_field.dart';
import '../widgets/profile_section_title.dart';
import '../widgets/profile_text_field.dart';

import '../../../../injection_container.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late ProfileBloc _profileBloc;

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController addressController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController pinController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  late TextEditingController emailController; // Added for clean disposal

  bool newsletterSubscribed = true;
  bool smsAlertsEnabled = false;

  String title = "Ms";
  String country = "India";
  String gender = "Female";
  String? _emailError;
  String? _phoneError;

  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() => _emailError = null);
      return;
    }

    final isValid = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
    ).hasMatch(value.trim());

    setState(() {
      _emailError = isValid ? null : 'Enter a valid email address';
    });
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      setState(() => _phoneError = null);
      return;
    }

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    setState(() {
      if (!RegExp(r'^\d+$').hasMatch(value)) {
        _phoneError = 'Only numbers are allowed';
      } else if (digits.length < 10) {
        _phoneError = 'Minimum 10 digits required';
      } else if (digits.length > 15) {
        _phoneError = 'Maximum 15 digits allowed';
      } else {
        _phoneError = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize BLoC and fetch profile
    _profileBloc = sl<ProfileBloc>();
    _profileBloc.add(const GetProfileEvent());

    firstNameController = TextEditingController(
      text: widget.userData?['name'] ?? '',
    );
    lastNameController = TextEditingController();
    addressController = TextEditingController(
      text: widget.userData?['address'] ?? '',
    );
    cityController = TextEditingController();
    stateController = TextEditingController();
    pinController = TextEditingController();
    phoneController = TextEditingController(
      text: widget.userData?['phone'] ?? '',
    );
    dobController = TextEditingController();
    emailController = TextEditingController(
      text: widget.userData?['email'] ?? '',
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pinController.dispose();
    phoneController.dispose();
    dobController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // Maps API response to UI state
  void _populateProfile(ProfileEntity profile) {
    setState(() {
      title = profile.title.isEmpty ? "Ms" : profile.title;
      firstNameController.text = profile.firstName;
      lastNameController.text = profile.lastName;
      emailController.text = profile.email ?? '';
      phoneController.text = profile.phoneNumber;
      dobController.text = profile.dob ?? '';
      addressController.text = profile.address;
      cityController.text = profile.city;
      stateController.text = profile.state;
      country = profile.country.isEmpty ? "India" : profile.country;
      pinController.text = profile.pinCode;
      newsletterSubscribed = profile.newsletter;
      smsAlertsEnabled = profile.smsAlerts;
    });
  }

  // Constructs entity and dispatches PATCH request
  void _saveProfile() {
    _validateEmail(emailController.text);
    _validatePhone(phoneController.text);

    if (_emailError != null || _phoneError != null) {
      return;
    }
    final profile = ProfileEntity(
      id: _profileBloc.currentProfile?.id ?? 0,
      title: title,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim().isNotEmpty
          ? emailController.text.trim()
          : null,
      phoneCode:
          '+91', // Adjust if your ProfilePhoneField exposes the selected code
      phoneNumber: phoneController.text.trim(),
      dob: dobController.text.trim().isNotEmpty
          ? dobController.text.trim()
          : null,
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      country: country,
      pinCode: pinController.text.trim(),
      platform: _profileBloc.currentProfile?.platform ?? 'web',
      newsletter: newsletterSubscribed,
      smsAlerts: smsAlertsEnabled,
      created: _profileBloc.currentProfile?.created ?? DateTime.now(),
      updated: DateTime.now(),
    );
    _profileBloc.add(PatchProfileEvent(profile));
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text = "${picked.year}-${picked.month}-${picked.day}";
      // dobController.text = "${picked.day}-${picked.month}-${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      bloc: _profileBloc,
      listener: (context, state) {
        if (state is ProfileLoaded) {
          _populateProfile(state.profile);
        } else if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            "Edit Profile",
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
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
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          bloc: _profileBloc,
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final isUpdating = state is ProfileUpdateLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: context.horizontalPadding.copyWith(
                  top: context.gapLarge,
                  bottom: context.gapXLarge,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: context.isDesktop
                          ? 1000
                          : context.isTablet
                          ? 800
                          : double.infinity,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(context.gapLarge),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          context.borderRadiusLarge,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ProfileSectionTitle(title: "Basic Information"),
                          SizedBox(height: context.gapLarge),
                          _buildBasicInfoSection(),
                          SizedBox(height: context.gapXLarge),
                          const ProfileSectionTitle(title: "Contact Details"),
                          SizedBox(height: context.gapLarge),
                          _buildAddressSection(),
                          SizedBox(height: context.gapLarge),
                          ProfilePhoneField(
                            controller: phoneController,
                            errorText: _phoneError,
                            onChanged: _validatePhone,
                          ),
                          SizedBox(height: context.gapXLarge),
                          const ProfileSectionTitle(title: "Personal Details"),
                          SizedBox(height: context.gapLarge),
                          ProfileTextField(
                            label: "DOB (Date of Birth)",
                            hint: "dd-mm-yyyy",
                            controller: dobController,
                            suffixIcon: IconButton(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_month_outlined),
                            ),
                          ),
                          SizedBox(height: context.gapXLarge),
                          CheckboxListTile(
                            value: newsletterSubscribed,
                            onChanged: isUpdating
                                ? null
                                : (value) {
                                    setState(() {
                                      newsletterSubscribed = value ?? false;
                                    });
                                  },
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              "Sign up for Monthly Newsletter, Promotions and Low fare alerts",
                              style: TextStyle(fontSize: context.bodySmall),
                            ),
                          ),
                          CheckboxListTile(
                            value: smsAlertsEnabled,
                            onChanged: isUpdating
                                ? null
                                : (value) {
                                    setState(() {
                                      smsAlertsEnabled = value ?? false;
                                    });
                                  },
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              "Sign up for free SMS alerts",
                              style: TextStyle(fontSize: context.bodySmall),
                            ),
                          ),
                          SizedBox(height: context.gapXLarge),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: context.gapMedium,
                            runSpacing: context.gapMedium,
                            children: [
                              OutlinedButton(
                                onPressed: isUpdating
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.gapLarge,
                                    vertical: context.gapMedium,
                                  ),
                                ),
                                child: const Text("CANCEL"),
                              ),
                              ElevatedButton(
                                onPressed: isUpdating ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.gapLarge,
                                    vertical: context.gapMedium,
                                  ),
                                ),
                                child: isUpdating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text("SAVE"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    if (context.isMobile) {
      return Column(
        children: [
          ProfileDropdownField(
            label: "Title",
            value: title,
            items: const ["Mr", "Mrs", "Ms"],
            onChanged: (value) {
              setState(() {
                title = value!;
              });
            },
          ),
          SizedBox(height: context.gapLarge),
          ProfileTextField(
            label: "First Name",
            hint: "First Name",
            controller: firstNameController,
          ),
          SizedBox(height: context.gapLarge),
          ProfileTextField(
            label: "Last Name",
            hint: "Last Name",
            controller: lastNameController,
          ),
          SizedBox(height: context.gapLarge),
          ProfileTextField(
            label: "Email",
            hint: "Email",
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: _validateEmail,
          ),
          SizedBox(height: context.gapMedium),
          // ProfilePhoneField(controller: phoneController),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: ProfileDropdownField(
                label: "Title",
                value: title,
                items: const ["Mr", "Mrs", "Ms"],
                onChanged: (value) {
                  setState(() {
                    title = value!;
                  });
                },
              ),
            ),
            SizedBox(width: context.gapMedium),
            Expanded(
              flex: 2,
              child: ProfileTextField(
                label: "First Name",
                hint: "First Name",
                controller: firstNameController,
              ),
            ),
            SizedBox(width: context.gapMedium),
            Expanded(
              flex: 2,
              child: ProfileTextField(
                label: "Last Name",
                hint: "Last Name",
                controller: lastNameController,
              ),
            ),
          ],
        ),
        SizedBox(height: context.gapLarge),
        Row(
          children: [
            Expanded(
              child: ProfileTextField(
                label: "Email",
                hint: "Email",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            SizedBox(width: context.gapMedium),
            Expanded(
              child: ProfilePhoneField(
                controller: phoneController,
                errorText: _phoneError,
                onChanged: _validatePhone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      children: [
        ProfileTextField(
          label: "Address",
          hint: "Address",
          controller: addressController,
        ),
        SizedBox(height: context.gapLarge),
        context.isMobile
            ? Column(
                children: [
                  ProfileTextField(
                    label: "City",
                    hint: "City",
                    controller: cityController,
                  ),
                  SizedBox(height: context.gapLarge),
                  ProfileTextField(
                    label: "State",
                    hint: "State",
                    controller: stateController,
                  ),
                  SizedBox(height: context.gapLarge),
                  ProfileDropdownField(
                    label: "Country",
                    value: country,
                    items: const ["India", "USA", "Canada"],
                    onChanged: (value) {
                      setState(() {
                        country = value!;
                      });
                    },
                  ),
                  SizedBox(height: context.gapLarge),
                  ProfileTextField(
                    label: "Pin Code",
                    hint: "Pin Code",
                    controller: pinController,
                    keyboardType: TextInputType.number,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: ProfileTextField(
                      label: "City",
                      hint: "City",
                      controller: cityController,
                    ),
                  ),
                  SizedBox(width: context.gapMedium),
                  Expanded(
                    child: ProfileTextField(
                      label: "State",
                      hint: "State",
                      controller: stateController,
                    ),
                  ),
                  SizedBox(width: context.gapMedium),
                  Expanded(
                    child: ProfileDropdownField(
                      label: "Country",
                      value: country,
                      items: const ["India", "USA", "Canada"],
                      onChanged: (value) {
                        setState(() {
                          country = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: context.gapMedium),
                  Expanded(
                    child: ProfileTextField(
                      label: "Pin Code",
                      hint: "Pin Code",
                      controller: pinController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
      ],
    );
  }
}
