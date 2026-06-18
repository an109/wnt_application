import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String email;
  final String name;
  final VoidCallback? onSave;

  const ChangePasswordDialog({
    super.key,
    required this.email,
    required this.name,
    this.onSave,
  });

  @override
  State<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPasswordController =
  TextEditingController();

  final TextEditingController _newPasswordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _passwordError;


  void _validatePassword(String value) {
    if (value.isEmpty) {
      setState(() => _passwordError = null);
      return;
    }

    if (value.length < 6) {
      setState(() => _passwordError = 'Minimum 6 characters required');
      return;
    }

    if (value.length > 16) {
      setState(() => _passwordError = 'Maximum 16 characters allowed');
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      setState(() => _passwordError = 'Include at least 1 uppercase letter');
      return;
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      setState(() => _passwordError = 'Include at least 1 lowercase letter');
      return;
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      setState(() => _passwordError = 'Include at least 1 number');
      return;
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      setState(() => _passwordError = 'Include at least 1 special character');
      return;
    }

    setState(() => _passwordError = null);
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);

      if (widget.onSave != null) {
        widget.onSave!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password changed successfully"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? context.wp(5) : context.wp(20),
        vertical: context.hp(5),
      ),
      child: Container(
        width: context.isDesktop
            ? context.wp(30)
            : context.isTablet
            ? context.wp(50)
            : double.infinity,
        padding: EdgeInsets.all(context.gapLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            context.dialogBorderRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Change Password",
                        style: TextStyle(
                          fontSize: context.titleLarge,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Padding(
                        padding: EdgeInsets.all(context.gapXSmall),
                        child: Icon(
                          Icons.close,
                          size: context.iconSmall,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.gapLarge),

                // ================= EMAIL =================

                Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: context.gapXXSmall),

                Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: context.gapLarge),

                // ================= OLD PASSWORD =================

                _buildTextField(
                  context: context,
                  title: "Old Password",
                  hint: "Enter Old Password",
                  controller: _oldPasswordController,
                  obscureText: _obscureOld,
                  toggle: () {
                    setState(() {
                      _obscureOld = !_obscureOld;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter old password";
                    }
                    return null;
                  },
                ),

                SizedBox(height: context.gapMedium),

                // ================= NEW PASSWORD =================

                _buildTextField(
                  context: context,
                  title: "New Password",
                  hint: "Enter New Password",
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  toggle: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter new password";
                    }

                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }

                    return null;
                  },
                ),

                SizedBox(height: context.gapMedium),

                // ================= CONFIRM PASSWORD =================

                _buildTextField(
                  context: context,
                  title: "Confirm Password",
                  hint: "Enter Confirm Password",
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  toggle: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm password";
                    }

                    if (value !=
                        _newPasswordController.text) {
                      return "Passwords do not match";
                    }

                    return null;
                  },
                ),

                SizedBox(height: context.gapLarge),

                // ================= SAVE BUTTON =================

                SizedBox(
                  width: double.infinity,
                  height: context.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.borderRadiusMedium,
                        ),
                      ),
                    ),
                    child: Text(
                      "Save",
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: context.gapSmall),

                // ================= CANCEL =================

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        color: Colors.red.shade600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String title,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.bodySmall,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: context.gapXXSmall),

        SizedBox(
          height: context.formFieldHeight,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter new password";
              }
              if (value.length < 6) {
                return "Password must be at least 6 characters";
              }
              if (value.length > 16) {
                return "Maximum 16 characters allowed";
              }
              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return "Include at least 1 uppercase letter";
              }
              if (!RegExp(r'[a-z]').hasMatch(value)) {
                return "Include at least 1 lowercase letter";
              }
              if (!RegExp(r'[0-9]').hasMatch(value)) {
                return "Include at least 1 number";
              }
              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                return "Include at least 1 special character";
              }
              return null;
            },
            onChanged: _validatePassword,
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',

              hintStyle: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade500,
              ),

              filled: true,
              fillColor: Colors.white,

              contentPadding: EdgeInsets.symmetric(
                horizontal: context.gapMedium,
                vertical: context.gapMedium,
              ),

              suffixIcon: IconButton(
                onPressed: toggle,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: context.iconSmall,
                  color: Colors.grey.shade600,
                ),
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
                borderSide: const BorderSide(
                  color: Color(0xFF0054A0),
                  width: 1.4,
                ),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// =======================================================
// SHOW DIALOG METHOD
// =======================================================

void showChangePasswordDialog({
  required BuildContext context,
  required String email,
  VoidCallback? onSave, required String name,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return ChangePasswordDialog(
        name: name,
        email: email,
        onSave: onSave,
      );
    },
  );
}