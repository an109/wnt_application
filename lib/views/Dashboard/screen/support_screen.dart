import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../core/resources/app_colours.dart';
import '../Section/customer_support.dart';

/// Palette lifted from the Customer Support design.
const _kInk = Color(0xFF0F1010);
const _kSubtle = Color(0xFF6E6E73);
const _kBlue = Color(0xFF00A1E4);
const _kCardBg = Color(0xFFF9F9FA);
const _kCardStroke = Color(0xFFEDEDF0);
const _kChipSelectedBg = Color(0xFFF0FBFF);

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _selectedCategory = 'Most Popular';

  // Track expanded FAQ items
  final Map<int, bool> _expandedItems = {};

  // FAQ Data
  final Map<String, List<Map<String, String>>> _faqData = {
    'Most Popular': [
      {
        'question': 'How do I book a holiday package?',
        'answer': 'To book a holiday package, navigate to the Holidays section, browse available packages, select your preferred package, choose travel dates, number of travelers, and proceed to checkout. You can customize your package before final booking.',
      },
      {
        'question': 'What is included in a holiday package?',
        'answer': 'Our holiday packages typically include accommodation, flights (if selected), transfers, and specified activities. Each package clearly lists what\'s included. Some packages may also include meals, sightseeing tours, and travel insurance.',
      },
      {
        'question': 'Can I customise my holiday package?',
        'answer': 'Yes! You can customize your holiday package by adding or removing services, upgrading accommodations, extending your stay, or adding extra activities. Contact our support team or use the customization options during booking.',
      },
    ],
    'Flight': [
      {
        'question': 'How do I book a flight?',
        'answer': 'Go to the Flights section, enter your departure and destination cities, select travel dates, choose number of passengers, and search. Select your preferred flight from the results and proceed with passenger details and payment.',
      },
      {
        'question': 'Can I cancel my flight booking?',
        'answer': 'Flight cancellation policies vary by airline and fare type. You can check the cancellation policy before booking. To cancel, go to My Bookings, select your flight, and follow the cancellation process. Refunds are processed as per airline policy.',
      },
      {
        'question': 'How do I check-in online?',
        'answer': 'Online check-in is available 24-48 hours before departure for most airlines. Visit the airline\'s website or app with your booking reference and last name to check in and download your boarding pass.',
      },
    ],
    'Payment Options': [
      {
        'question': 'What payment methods are accepted?',
        'answer': 'We accept Credit Cards (Visa, MasterCard, American Express), Debit Cards, Net Banking, UPI, Wallets (Paytm, PhonePe, Google Pay), and EMI options. All payments are secured with SSL encryption.',
      },
      {
        'question': 'Is my payment information secure?',
        'answer': 'Yes, we use industry-standard SSL encryption and PCI-DSS compliant payment gateways. We never store your complete card details on our servers. All transactions are processed through secure payment partners.',
      },
      {
        'question': 'Can I pay in installments?',
        'answer': 'Yes, we offer EMI options on select credit cards and through our partner financing services. The EMI option will be shown at checkout if available for your booking amount.',
      },
    ],
    'Visa': [
      {
        'question': 'Do I need a visa for my destination?',
        'answer': 'Visa requirements depend on your nationality and destination country. You can check visa requirements in the Visa section by entering your destination and passport details. We recommend checking at least 4-6 weeks before travel.',
      },
      {
        'question': 'Can you help with visa application?',
        'answer': 'Yes, we offer visa assistance services. Our team can guide you through the application process, document requirements, and submission. Some destinations also offer e-visa facilities which we can help you apply for.',
      },
    ],
    'Holidays': [
      {
        'question': 'What is the cancellation policy for holiday packages?',
        'answer': 'Cancellation charges vary based on how many days before departure you cancel. Typically: 30+ days = 10% charge, 15-29 days = 25% charge, 7-14 days = 50% charge, <7 days = 100% charge. Check specific package terms for exact details.',
      },
      {
        'question': 'When will I get my holiday booking confirmation?',
        'answer': 'You will receive an instant booking confirmation email and SMS with your booking reference number upon successful payment. Detailed vouchers with hotel confirmations, flight tickets, and itinerary are sent within 24-48 hours.',
      },
      {
        'question': 'Can I change my travel dates?',
        'answer': 'Date changes are subject to availability and may incur additional charges. Contact our support team at least 7 days before travel to request date changes. Some promotional packages may not allow date changes.',
      },
    ],
    'Hotels': [
      {
        'question': 'How do I book a hotel?',
        'answer': 'Navigate to the Hotels section, enter your destination, check-in and check-out dates, and number of guests. Browse available hotels, select your preferred room type, and complete the booking with guest details and payment.',
      },
      {
        'question': 'What is the check-in and check-out time?',
        'answer': 'Standard check-in time is 2:00 PM and check-out time is 11:00 AM for most hotels. Early check-in and late check-out are subject to availability and may incur additional charges.',
      },
    ],
  };

  List<Map<String, String>> get _filteredFAQs {
    return _faqData[_selectedCategory] ?? [];
  }

  void _toggleExpand(int index) {
    setState(() {
      _expandedItems[index] = !(_expandedItems[index] ?? false);
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _expandedItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleSpacing: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/NewIcons/arrowBack.png',
            width: context.w(18),
            height: context.h(18),
            color: AppColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Customer Support',
          style: TextStyle(
            color: _kInk,
            fontSize: context.fs(19),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: context.scrollPhysics,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.isMobile ? double.infinity : 700,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(16),
                  context.w(20),
                  context.w(16),
                  context.w(32),
                ),
                // padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomerSupportSection(),
                    SizedBox(height: context.w(36)),
                    _buildFAQSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAQ',
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
        SizedBox(height: context.w(14)),
        _buildCategoryFilter(),
        SizedBox(height: context.w(16)),
        ..._filteredFAQs.asMap().entries.map((entry) {
          return _buildFAQItem(
            entry.value['question']!,
            entry.value['answer']!,
            entry.key,
          );
        }),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = _faqData.keys.toList();

    // Narrow screens scroll the categories, wider ones can wrap them.
    if (context.isMobile) {
      return SizedBox(
        height: context.w(28),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
          itemBuilder: (_, index) => _buildCategoryChip(categories[index]),
        ),
      );
    }

    return Wrap(
      spacing: context.w(8),
      runSpacing: context.w(8),
      children: categories.map(_buildCategoryChip).toList(),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectCategory(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.w(4),
        ),
        decoration: BoxDecoration(
          color: isSelected ? _kBlue : _kCardBg,
          borderRadius: BorderRadius.circular(context.w(4)),
          border: Border.all(color: isSelected ? _kBlue : _kCardStroke),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            category,
            style: TextStyle(
              fontSize: context.fs(11),
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : _kSubtle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, int index) {
    final isExpanded = _expandedItems[index] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: context.w(12)),
      decoration: BoxDecoration(
        color: Color(0xFFE5E7EB).withAlpha(24),
        borderRadius: BorderRadius.circular(context.w(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            offset: const Offset(2, 0),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleExpand(index),
              borderRadius: BorderRadius.circular(context.w(16)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: _kInk,
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(12)),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      turns: isExpanded ? 0 : 0.5,
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: context.w(18),
                        color: _kInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: context.w(16),
                right: context.w(16),
                bottom: context.w(18),
              ),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w400,
                  color: _kSubtle,
                  height: 1.25,
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
