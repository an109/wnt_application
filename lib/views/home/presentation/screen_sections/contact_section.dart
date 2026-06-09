import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(20),
        vertical: context.h(40),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Contact Us',
            style: GoogleFonts.inter(
              fontSize: context.fs(24),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: context.h(4)),
          Text(
            'REACH WANDER NOVA',
            style: GoogleFonts.inter(
              fontSize: context.fs(11),
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: context.h(24)),

          // Contact Card
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For legal inquiries, grievances, operational support, or questions about our services, you can contact the Wander Nova corporate headquarters.',
                style: GoogleFonts.inter(
                  fontSize: context.fs(14),
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
              SizedBox(height: context.h(20)),

              // Contact Details
              _buildContactItem(
                context,
                Icons.business,
                'Entity: Wander Nova Pvt. Ltd.',
              ),
              SizedBox(height: context.h(12)),
              _buildContactItem(
                context,
                Icons.location_on,
                'Office No. 114, Al Khaleej Center Near Sharaf DG Metro Station, Bur Dubai',
              ),
              SizedBox(height: context.h(12)),
              GestureDetector(
                onTap: () {
                  // Add email launch functionality if needed
                },
                child: _buildContactItem(
                  context,
                  Icons.email,
                  'Email: contact@thewandernova.com',
                  isLink: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
      BuildContext context,
      IconData icon,
      String text, {
        bool isLink = false,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.green[600],
          size: context.w(16),
        ),
        SizedBox(width: context.w(8)),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: context.fs(14),
              color: isLink ? AppColors.primary : Colors.grey[800],
              fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}