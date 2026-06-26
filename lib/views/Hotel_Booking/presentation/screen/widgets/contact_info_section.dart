import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class ContactInfoSection extends StatefulWidget {
  final String userEmail;

  const ContactInfoSection({
    super.key,
    required this.userEmail,
  });

  @override
  State<ContactInfoSection> createState() => ContactInfoSectionState();
}

class ContactInfoSectionState extends State<ContactInfoSection> {
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  String get phone => _phoneController.text.trim();
  String get email => _emailController.text.trim();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emailController = TextEditingController(text: widget.userEmail);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: context.fs(20),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: context.h(12)),
            Container(
              padding: EdgeInsets.all(context.w(12)),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.grey[600], size: context.w(18)),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Text(
                      'Your booking and hotel information will be sent here.',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.h(16)),

            // Phone Number Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Number *',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: context.h(8)),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.w(12),
                          vertical: context.h(14)
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(context.r(8)),
                          bottomLeft: Radius.circular(context.r(8)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.network(
                            'https://flagcdn.com/w40/in.png',
                            width: context.w(24),
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.flag, size: 24),
                          ),
                          SizedBox(width: context.w(8)),
                          Text(
                            '+91',
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, size: context.w(16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: context.w(12),
                              vertical: context.h(14)
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(context.r(8)),
                              bottomRight: Radius.circular(context.r(8)),
                            ),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(context.r(8)),
                              bottomRight: Radius.circular(context.r(8)),
                            ),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(context.r(8)),
                              bottomRight: Radius.circular(context.r(8)),
                            ),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: context.h(16)),

            // Email Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Address *',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: context.h(8)),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: context.w(12),
                        vertical: context.h(14)
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.r(8)),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.r(8)),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.r(8)),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}