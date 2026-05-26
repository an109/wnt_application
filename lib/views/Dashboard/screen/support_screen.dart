import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../Section/customer_support.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'Most Popular';

  // Track expanded FAQ items
  final Map<int, bool> _expandedItems = {};

  // Animation controller for smooth transitions
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Support & FAQ',
          style: TextStyle(
            color: Colors.black87,
            fontSize: context.responsiveFontSize(20, 18, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: context.scrollPhysics,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(),
            SizedBox(height: context.gapLarge),

            // Main Content
            Padding(
              padding: context.horizontalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FAQ Section
                  _buildFAQSection(),
                  SizedBox(height: context.gapXLarge),

                  // Customer Support Section (Imported)
                  const CustomerSupportSection(),
                  SizedBox(height: context.gapLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      margin: context.horizontalPadding,
      padding: EdgeInsets.all(context.isMobile ? 20 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome..!! How may we help you?',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(24, 20, 18),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (context.isDesktop || context.isTablet) ...[
                  SizedBox(height: context.gapSmall),
                  Text(
                    'Find answers to common questions or contact our support team',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14, 13, 12),
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (context.isDesktop || context.isTablet) ...[
            SizedBox(width: context.gapMedium),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your questions here',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, color: Colors.white, size: 20),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.gapMedium,
                      vertical: context.gapSmall,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: context.shadowOffsetSmall,
          ),
        ],
      ),
      child: context.isMobile
          ? _buildMobileFAQLayout()
          : _buildDesktopFAQLayout(),
    );
  }

  Widget _buildDesktopFAQLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar Categories
        SizedBox(
          width: 250,
          child: _buildCategorySidebar(),
        ),

        // FAQ Content
        Expanded(
          child: Container(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(20, 18, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: context.gapMedium),
                ..._filteredFAQs.asMap().entries.map((entry) {
                  return _buildFAQItem(
                    entry.value['question']!,
                    entry.value['answer']!,
                    entry.key,
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFAQLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Category Scroll
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
            children: _faqData.keys.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: EdgeInsets.only(
                  right: context.gapSmall,
                  top: context.gapSmall,
                  bottom: context.gapSmall,
                ),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                      _expandedItems.clear();
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Colors.blue[50],
                  labelStyle: TextStyle(
                    fontSize: context.responsiveFontSize(13, 12, 11),
                    color: isSelected ? Colors.blue[700] : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Divider(color: Colors.grey[200]),

        // FAQ Content
        Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(20, 18, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: context.gapMedium),
              ..._filteredFAQs.asMap().entries.map((entry) {
                return _buildFAQItem(
                  entry.value['question']!,
                  entry.value['answer']!,
                  entry.key,
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _faqData.keys.map((category) {
          final isSelected = _selectedCategory == category;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _expandedItems.clear();
                });
              },
              borderRadius: BorderRadius.circular(context.borderRadiusSmall),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.gapMedium,
                  vertical: context.gapSmall,
                ),
                margin: EdgeInsets.only(bottom: context.gapXXSmall),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 18,
                      color: isSelected ? Colors.blue[700] : Colors.grey[600],
                    ),
                    SizedBox(width: context.gapMedium),
                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(14, 13, 12),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.blue[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: isSelected ? Colors.blue[700] : Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Most Popular':
        return Icons.star;
      case 'Flight':
        return Icons.flight;
      case 'Payment Options':
        return Icons.payment;
      case 'Visa':
        return Icons.credit_card;
      case 'Holidays':
        return Icons.beach_access;
      case 'Hotels':
        return Icons.hotel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildFAQItem(String question, String answer, int index) {
    final isExpanded = _expandedItems[index] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: context.gapSmall),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
        border: Border.all(
          color: isExpanded ? Colors.blue[200]! : Colors.grey[200]!,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: isExpanded
            ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleExpand(index),
              borderRadius: BorderRadius.circular(context.borderRadiusSmall),
              child: Padding(
                padding: EdgeInsets.all(context.gapMedium),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(15, 14, 13),
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more,
                        color: isExpanded ? Colors.blue[700] : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: EdgeInsets.only(
                left: context.gapMedium,
                right: context.gapMedium,
                bottom: context.gapMedium,
              ),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(14, 13, 12),
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}