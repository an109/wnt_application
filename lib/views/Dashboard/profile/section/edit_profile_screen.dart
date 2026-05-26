import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../widgets/profile_dropdown_field.dart';
import '../widgets/profile_phone_field.dart';
import '../widgets/profile_section_title.dart';
import '../widgets/profile_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController addressController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController pinController;
  late TextEditingController phoneController;
  late TextEditingController dobController;

  String title = "Ms";
  String country = "India";
  String gender = "Female";

  @override
  void initState() {
    super.initState();

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
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text =
      "${picked.day}-${picked.month}-${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

      body: SafeArea(
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
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const ProfileSectionTitle(
                      title: "Basic Information",
                    ),

                    SizedBox(height: context.gapLarge),

                    _buildBasicInfoSection(),

                    SizedBox(height: context.gapXLarge),

                    const ProfileSectionTitle(
                      title: "Contact Details",
                    ),


                    SizedBox(height: context.gapLarge),

                    _buildAddressSection(),

                    SizedBox(height: context.gapLarge),

                    ProfilePhoneField(
                      controller: phoneController,
                    ),

                    SizedBox(height: context.gapXLarge),

                    const ProfileSectionTitle(
                      title: "Personal Details",
                    ),

                    SizedBox(height: context.gapLarge),

                    ProfileTextField(
                      label: "DOB (Date of Birth)",
                      hint: "dd-mm-yyyy",
                      controller: dobController,

                      suffixIcon: IconButton(
                        onPressed: _selectDate,
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                        ),
                      ),
                    ),

                    SizedBox(height: context.gapXLarge),

                    CheckboxListTile(
                      value: true,
                      onChanged: (_) {},

                      contentPadding: EdgeInsets.zero,

                      title: Text(
                        "Sign up for Monthly Newsletter, Promotions and Low fare alerts",
                        style: TextStyle(
                          fontSize: context.bodySmall,
                        ),
                      ),
                    ),

                    CheckboxListTile(
                      value: false,
                      onChanged: (_) {},

                      contentPadding: EdgeInsets.zero,

                      title: Text(
                        "Sign up for free SMS alerts",
                        style: TextStyle(
                          fontSize: context.bodySmall,
                        ),
                      ),
                    ),

                    SizedBox(height: context.gapXLarge),

                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: context.gapMedium,
                      runSpacing: context.gapMedium,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                              context.gapLarge,
                              vertical:
                              context.gapMedium,
                            ),
                          ),

                          child: const Text("CANCEL"),
                        ),

                        ElevatedButton(
                          onPressed: () {},

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,

                            padding: EdgeInsets.symmetric(
                              horizontal:
                              context.gapLarge,
                              vertical:
                              context.gapMedium,
                            ),
                          ),

                          child: const Text("SAVE"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
            controller: TextEditingController(
              text: widget.userData?['email'] ?? '',
            ),
            keyboardType: TextInputType.emailAddress,
          ),

          SizedBox(height: context.gapLarge),

          ProfilePhoneField(
            controller: phoneController,
          ),
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
                controller: TextEditingController(
                  text: widget.userData?['email'] ?? '',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),

            SizedBox(width: context.gapMedium),

            Expanded(
              child: ProfilePhoneField(
                controller: phoneController,
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
              items: const [
                "India",
                "USA",
                "Canada",
              ],
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
                items: const [
                  "India",
                  "USA",
                  "Canada",
                ],
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