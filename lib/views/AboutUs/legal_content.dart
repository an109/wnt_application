import 'package:flutter/material.dart';

// Terms & Privacy copy for the app, taken from the website's India pages
// (wandernova-front: TermsOfServices.jsx / Privacypolicy.jsx → IndiaContent)
// so both channels say the same thing. Update both together.

/// One highlighted row inside a section (icon + optional bold label + text).
class LegalItem {
  final IconData icon;
  final String? label;
  final String text;

  const LegalItem(this.icon, this.text, {this.label});
}

/// Where a section's trailing link goes.
enum LegalLink { terms, privacy }

class LegalSection {
  final String title;
  final List<String> paragraphs;
  final String? quote;
  final String? itemsHeading;
  final List<LegalItem> items;
  final String? note;
  final LegalLink? link;

  const LegalSection({
    required this.title,
    this.paragraphs = const [],
    this.quote,
    this.itemsHeading,
    this.items = const [],
    this.note,
    this.link,
  });
}

class LegalDocument {
  final String title;
  final String summary;
  final List<LegalSection> sections;

  const LegalDocument({required this.title, required this.summary, required this.sections});

  /// Reading time at ~200 words per minute, never less than 1.
  int get readMinutes {
    final buffer = StringBuffer(summary);
    for (final s in sections) {
      buffer
        ..write(' ${s.paragraphs.join(' ')}')
        ..write(' ${s.quote ?? ''} ${s.note ?? ''}');
      for (final i in s.items) {
        buffer.write(' ${i.label ?? ''} ${i.text}');
      }
    }
    final words = buffer.toString().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (words / 200).ceil().clamp(1, 99);
  }
}

const LegalDocument kTermsOfService = LegalDocument(
  title: 'Terms & Services',
  summary:
      'Wander Nova is a travel intermediary: your booking is a contract with the airline, '
      'hotel or operator you choose. Prices are shown in INR and include GST on our fees, '
      'and changes, cancellations and refunds follow the supplier\'s rules.',
  sections: [
    LegalSection(
      title: 'Legal Intermediary Status & Relationship Framework',
      paragraphs: [
        'Wander Nova India Private Limited ("Company," "We," "Us," or "Wander Nova") operates '
            'strictly as an IATA-certified travel intermediary and an online marketplace platform '
            'facilitator under Section 79 of the Information Technology Act 2000. The platform serves '
            'to connect intending travelers ("User," "You," or "Client") with the ultimate third-party '
            'service providers of travel inventory, including but not limited to commercial airlines, '
            'hotel properties, alternative accommodation hosts, bus operators, car rental firms, and '
            'the Indian Railways (IRCTC).',
      ],
      quote:
          'The definitive contract for service delivery and utilization is always exclusively '
          'executed between the User and the respective underlying service provider.',
      note:
          'Wander Nova does not own, manage, operate, or control any aircraft, hotel properties, '
          'buses, surface cabs, or rail coaches, and cannot be held liable for any deficiency, delay, '
          'route alteration, overbooking, or modification in the services of the ultimate supplier.',
    ),
    LegalSection(
      title: 'Core Pricing Architecture & Statutory Tax Inclusions',
      paragraphs: [
        'All prices, tariffs, and room or seat rates displayed across the Indian web domain '
            '(thewandernova.com) or localized mobile applications are presented in Indian Rupees (INR). '
            'Fares are highly dynamic, adjusting in real time based on direct inventory supply metrics. '
            'Unless explicitly noted otherwise during the final checkout session, all listed prices are '
            'comprehensive of the base fare, carrier-imposed surcharges, and statutory government levies.',
        'Per the mandate of domestic tax structures, all platform-level Service Charges, Rescheduling '
            'Charges, Convenience Fees, and Cancellation processing fees levied by Wander Nova are strictly '
            'inclusive of the applicable statutory Goods and Services Tax (GST). Optional incidentals, '
            'including in-room hotel dining, minibar utilization, telephone tolls, and localized resort '
            'entrance destination fees, are explicitly excluded from the platform booking rate and must be '
            'settled by the traveler directly with the supplier.',
      ],
    ),
    LegalSection(
      title: 'Domestic & International Flight Reservations',
      items: [
        LegalItem(
          Icons.child_care_rounded,
          label: 'Age Classifications & Criteria',
          'To qualify for infant ticketing pricing tiers, the child traveler must be strictly under '
              '24 months of age throughout the entire itinerary, covering both the onward leg and the '
              'return journey. If an infant reaches or exceeds 24 months of age on the return date, the '
              'User must make a separate booking under standard child fare guidelines. Children between '
              '2 and 12 years must be booked under the child category. All minors and infants must be '
              'accompanied on all flight segments by an adult traveler who is at least 18 years old.',
        ),
        LegalItem(
          Icons.luggage_outlined,
          label: 'Baggage Limitations',
          'Baggage allowances on any given fare are determined solely by the airline. Certain highly '
              'discounted fares are "hand baggage only" or "lite fares," which do not include free checked '
              'baggage. The User is required to purchase checked baggage weight separately.',
        ),
        LegalItem(
          Icons.flight_rounded,
          label: 'Code-Share Agreements',
          'When a marketing airline sells tickets on a route operated by a partner airline, the platform '
              'discloses the arrangement during checkout by labeling the segment "Operated by," provided '
              'the ticketing carrier has accurately synchronized this data with our system.',
        ),
      ],
    ),
    LegalSection(
      title: 'Accommodations & Hotel Booking Compliance',
      items: [
        LegalItem(
          Icons.badge_outlined,
          label: 'Check-In Thresholds',
          'The primary guest must be at least 18 years of age at check-in. The primary traveler and all '
              'accompanying guests must present valid government-issued photo identity and address proofs '
              '(such as a passport, driving license, or voter identification card) at the property.',
        ),
        LegalItem(
          Icons.do_not_disturb_on_outlined,
          label: 'Admission Sovereignty & Restrictions',
          'Accommodation properties retain an absolute right of admission. Under municipal rules, house '
              'policies, or regional regulations, check-in may be denied to local city residents, unmarried '
              'couples, or unrelated individuals traveling together. Wander Nova has no control over such '
              'rejections, and no refunds apply if check-in is denied for these reasons.',
        ),
        LegalItem(
          Icons.celebration_outlined,
          label: 'Festive Surcharges',
          'Properties may levy mandatory meal surcharges during festive intervals, such as Christmas Eve or '
              'New Year\'s Eve. These must be paid directly at the hotel front desk.',
        ),
      ],
    ),
    LegalSection(
      title: 'Surface Transportation Systems (Bus & Cabs)',
      items: [
        LegalItem(
          Icons.directions_bus_outlined,
          label: 'Bus Segment Framework',
          'Wander Nova provides a search and reservation platform for independent bus operators and does '
              'not maintain a fleet or employ transit staff. Amenities, routes, seats, and timings are managed '
              'by the bus provider. Arrive at the boarding point at least 30 minutes before departure with your '
              'ticket and a valid government ID. Tickets are non-transferable, and a regular seat fare is '
              'required for any child above 5 years of age.',
        ),
        LegalItem(
          Icons.local_taxi_outlined,
          label: 'Cab Segment Framework',
          'The platform facilitates Outstation Cabs (All India Tourist Permit), Intracity Rentals, and Airport '
              'Drops. The quote covers only the primary distance and time. Tolls, state border taxes, parking, '
              'and overnight driver allowances are excluded and payable to the driver in cash. Pricing is '
              'calculated "garage-to-garage." Users must not coerce drivers into violating traffic laws or '
              'overloading the luggage boot.',
        ),
      ],
    ),
    LegalSection(
      title: 'Railway Ticketing (IRCTC Integration)',
      paragraphs: [
        'All train ticket reservations made on the platform are subject to the master Terms & Conditions '
            'issued by the Indian Railways and the Indian Railway Catering and Tourism Corporation (IRCTC). '
            'During booking, the platform redirects users to enter their verified IRCTC credentials. Users can '
            'book a maximum of 6 seats/berths per transaction; berth allocation is handled by Indian Railways, '
            'with no platform-level guarantee for specific preferences.',
        'The train booking interface is unavailable daily between 2345 hours and 0030 hours due to essential '
            'IRCTC server downtime. Fully waitlisted e-tickets that fail to confirm are automatically canceled '
            'by the Railways after final chart preparation, and the fare is reversed to the original payment '
            'account, minus the non-refundable platform service fee.',
      ],
    ),
    LegalSection(
      title: 'Changes, Cancellations, No-Shows & Refunds',
      items: [
        LegalItem(
          Icons.link_off_rounded,
          label: 'Single PNR Multi-Segment Rule',
          'If a user does not board the onward segment of a multi-city or international journey issued '
              'under a single PNR, the airline automatically cancels all remaining legs, including return '
              'sectors. The Company cannot override this carrier protocol.',
        ),
        LegalItem(
          Icons.mail_outline_rounded,
          label: 'Offline Disconnection Protocol',
          'If you cancel or modify a ticket directly with the airline, you must notify Wander Nova by email '
              'to start refund tracking. Carriers do not alert agencies of direct changes, so we cannot process '
              'reversals without your written notification.',
        ),
        LegalItem(
          Icons.currency_rupee_rounded,
          label: 'Refund Deductions & Reversals',
          'Approved refunds go back to the original payment source. Convenience fees are non-refundable. For '
              'partially utilized tickets, any promotional discount or promo code value applied at checkout is '
              'deducted from the final refund.',
        ),
      ],
    ),
    LegalSection(
      title: 'Governing Law & Court Jurisdiction',
      paragraphs: [
        'These Terms and Conditions, along with all transactions executed within India, are governed by and '
            'construed in accordance with the laws of the Republic of India. Any legal dispute, claim, or '
            'consumer complaint arising from the use of this platform must be filed exclusively in the '
            'competent courts holding territorial jurisdiction over the registered operating office of the '
            'Company in India.',
      ],
      link: LegalLink.privacy,
    ),
  ],
);

const LegalDocument kPrivacyPolicy = LegalDocument(
  title: 'Privacy Policy',
  summary:
      'Wander Nova Private Limited (hereinafter referred to as "Wander Nova") recognizes the importance '
      'of the privacy of its users and is deeply committed to maintaining the absolute confidentiality of '
      'the information provided by its users as a responsible data controller and data processor.\n'
      'This Privacy Policy outlines our dedicated practices for handling, processing, and securing the '
      'User\'s Personal Information (as defined hereunder) by Wander Nova, its subsidiaries, and its affiliates.',
  sections: [
    LegalSection(
      title: 'Applicability',
      paragraphs: [
        'This Privacy Policy applies to any person ("User") who purchases, intends to purchase, or inquires '
            'about any product(s) or service(s)—including tourism packages, flight bookings, visa services, and '
            'ancillary travel solutions—made available by Wander Nova through any of our customer interface '
            'channels. These include our website, mobile site, mobile applications, and offline channels, '
            'including our corporate offices in Noida, Uttar Pradesh, and global call centers (collectively '
            'referred to herein as "Sales Channels").',
      ],
      itemsHeading: 'For the purpose of this Privacy Policy, wherever the context so requires:',
      items: [
        LegalItem(Icons.person_outline_rounded, label: '"You" or "Your"', 'shall mean the User.'),
        LegalItem(Icons.business_rounded, label: '"We", "Us", or "Our"', 'shall mean Wander Nova.'),
        LegalItem(
          Icons.language_rounded,
          label: '"Website"',
          'means the website(s), mobile site(s), and mobile app(s) owned and operated by Wander Nova.',
        ),
      ],
    ),
    LegalSection(
      title: 'Data Storage and Retention',
      paragraphs: [
        'To enhance your user experience and streamline future transactions, Wander Nova securely stores your '
            'basic information (including but not limited to name, contact details, and basic profile data) on '
            'our secure servers for future references and faster bookings when you choose to "Travel with us."',
      ],
    ),
    LegalSection(
      title: 'Mobile Application Permissions',
      paragraphs: [
        'For Users accessing our services via our mobile application, we require specific, limited system '
            'permissions to ensure seamless and secure service delivery:',
      ],
      items: [
        LegalItem(
          Icons.sms_outlined,
          label: 'SMS/Message Permission',
          'Required solely for sending and automatically verifying One-Time Passwords (OTPs) to secure your '
              'account and validate transactions.',
        ),
        LegalItem(
          Icons.location_on_outlined,
          label: 'Location Services',
          'Required to provide location-based services, such as coordinating cab pickups, local transfers, '
              'and real-time transit solutions.',
        ),
        LegalItem(
          Icons.photo_camera_outlined,
          label: 'Camera Access',
          'Required to securely scan and upload travel documents (like passports), read QR codes for digital '
              'check-ins, and quickly capture payment methods at checkout.',
        ),
        LegalItem(
          Icons.notifications_none_rounded,
          label: 'Notifications',
          'Required to deliver real-time updates, including instant booking confirmations, PNR status '
              'changes, and flight delays.',
        ),
        LegalItem(
          Icons.phone_android_rounded,
          label: 'Device & Technical Information',
          'Required to analyze basic system metadata (such as OS version and device model) to optimize app '
              'stability, prevent digital fraud, and ensure proper interface rendering.',
        ),
      ],
      note:
          'No other device permissions (such as Contacts, Calendar, Photo Galleries, or Microphone) are required '
          'as of now. If any are needed in future, this policy will be updated and you will be asked for consent.',
    ),
    LegalSection(
      title: 'User Consent',
      paragraphs: [
        'By using or accessing the Website or other Sales Channels, the User hereby explicitly agrees to the '
            'terms of this Privacy Policy and the contents contained herein. If you disagree with any part of '
            'this Privacy Policy, please do not use or access our Website or other Sales Channels.',
      ],
    ),
    LegalSection(
      title: 'Third-Party Links and Hyperlinks',
      paragraphs: [
        'This Privacy Policy does not apply to any website(s), mobile sites, or mobile apps operated by third '
            'parties, even if their platforms, products, or services are linked to our Website. The information '
            'and privacy practices of Wander Nova\'s business partners (such as airlines, hospitality providers, '
            'consular authorities, or advertisers) may be materially different from this Privacy Policy. We '
            'strongly recommend that you review the privacy policies of any such third parties you interact with.',
      ],
    ),
    LegalSection(
      title: 'Integral Agreement',
      paragraphs: [
        'This Privacy Policy is an integral part of your User Agreement with Wander Nova. All capitalized terms '
            'used, but not otherwise defined herein, shall have the respective meanings ascribed to them in the '
            'primary User Agreement.',
      ],
      link: LegalLink.terms,
    ),
  ],
);
