import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../common_widgets/logo.dart';

class MakePaymentScreen extends StatefulWidget {
  const MakePaymentScreen({super.key});

  @override
  State<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends State<MakePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedService;
  final TextEditingController _referenceNoController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(text: 'your@gmail.com');
  String _selectedPaymentMethod = 'ccavenue';
  bool _agreeToTerms = false;
  double _netFare = 0.0;

  final List<String> _services = [
    'Flight Booking',
    'Hotel Booking',
    'Holiday Package',
    'Visa Services',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const WanderNovaLogo(scaleFactor: 0.6),
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: 35,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: context.bodyMedium,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey,
                  ),
                  Text(
                    'Make Payment',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: context.bodyMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(),
                  const SizedBox(height: 20),

                  // Payment Details
                  _buildPaymentDetailsSection(),
                  const SizedBox(height: 16),

                  // Contact Information
                  _buildContactInformationSection(),
                  const SizedBox(height: 16),

                  // Make Payment
                  _buildMakePaymentSection(),
                  const SizedBox(height: 16),

                  // Total and Pay Button
                  _buildTotalAndPayButton(),
                  const SizedBox(height: 20),

                  // Security Features (Mobile)
                  _buildSecurityFeaturesMobile(),
                  const SizedBox(height: 20),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Travel Utility',
            style: TextStyle(
              fontSize: context.fs(22),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Travel Utility is an online payment option available for the convenience of customer to pay additional amount for the service opted. Payment can be made through your Credit / Debit card, Net Banking or Cash Card. We accept Credit / Debit cards of MasterCard and VISA.',
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            child: Column(
              children: [
                // Service Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: InputDecoration(
                    labelText: 'Service *',
                    labelStyle: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey[700],
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: _services.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Text(service),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedService = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a service';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Reference No
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _referenceNoController,
                        decoration: InputDecoration(
                          labelText: 'Reference No',
                          labelStyle: TextStyle(
                            fontSize: context.bodyMedium,
                            color: Colors.grey[700],
                          ),
                          hintText: 'Reference No',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Net Fare
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Net Fare',
                          labelStyle: TextStyle(
                            fontSize: context.bodyMedium,
                            color: Colors.grey[700],
                          ),
                          hintText: '0',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInformationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: context.bodyLarge,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your payment and booking information will be sent here.',
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Country Code Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Image.network(
                      'https://flagcdn.com/w40/in.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 24,
                          height: 24,
                          color: Colors.orange,
                          child: const Icon(Icons.flag, color: Colors.white, size: 16),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone number *',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder:  OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[50],
                    border:  OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder:  OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
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

  Widget _buildMakePaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make payment',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Wallet Option
          _buildPaymentOption(
            'wallet',
            'Wallet',
            'Wallet balance',
            Icons.account_balance_wallet,
          ),

          const SizedBox(height: 12),

          // CCAvenue Option
          _buildPaymentOption(
            'ccavenue',
            'CCAvenue',
            'Cards, Net Banking, Wallet, UPI',
            Icons.payment,
            isCCAvenue: true,
          ),

          const SizedBox(height: 16),

          // CCAvenue Secure Checkout Info
          if (_selectedPaymentMethod == 'ccavenue') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.network(
                        'https://www.ccavenue.com/images/ccavenue-logo.png',
                        height: 30,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text(
                            'CCAvenue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CCAvenue Secure Checkout',
                              style: TextStyle(
                                fontSize: context.bodyMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'You will be redirected to CCAvenue (INR - Cards, Net Banking, Wallet, UPI)',
                              style: TextStyle(
                                fontSize: context.bodySmall,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Accepted payment methods',
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPaymentMethodChip('Credit / Debit Cards'),
                      _buildPaymentMethodChip('Net Banking'),
                      _buildPaymentMethodChip('Wallet'),
                      _buildPaymentMethodChip('UPI'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          '256-bit SSL encrypted • PCI DSS compliant',
                          style: TextStyle(
                            fontSize: context.bodySmall,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Terms and Conditions
          Row(
            children: [
              Checkbox(
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
                activeColor: Colors.blue,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _agreeToTerms = !_agreeToTerms;
                    });
                  },
                  child: Text(
                    'I understand and agree with the rules and restrictions of this fare, the Payment Terms, Cancellation Policy and the Terms & Conditions',
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: Colors.grey[700],
                      height: 1.4,
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

  Widget _buildPaymentOption(
      String value,
      String title,
      String subtitle,
      IconData icon, {
        bool isCCAvenue = false,
      }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isCCAvenue ? Colors.green[50] : Colors.blue[50])
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isCCAvenue ? Colors.green[300]! : Colors.blue[300]!)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? (isCCAvenue ? Colors.green[700] : Colors.blue[700])
                  : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isCCAvenue ? Colors.green[700] : Colors.blue[700])
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: isSelected
                          ? (isCCAvenue ? Colors.green[600] : Colors.blue[600])
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              activeColor: isCCAvenue ? Colors.green : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.labelSmall,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTotalAndPayButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total payable amount',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '₹${_netFare.toStringAsFixed(2)}',
                style:  TextStyle(
                  fontSize: context.fs(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _agreeToTerms ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _agreeToTerms ? Colors.blue[700] : Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'PAY WITH CCAVENUE',
                style: TextStyle(
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeaturesMobile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSecurityFeature(
            Icons.shield_outlined,
            'Secure Payment',
            'We use Secure Server Technology to provide a 100% safe online payment experience. Pay securely through your Debit/Credit Card or Internet Banking',
            Colors.red,
          ),
          const Divider(height: 24),
          _buildSecurityFeature(
            Icons.lock_outline,
            '256 Bit Encryption',
            'Top leading Encryption hardware & software to protect your information.',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeature(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      // Show loading or navigate to payment gateway
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Processing Payment'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Redirecting to CCAvenue...'),
            ],
          ),
        ),
      );

      // Simulate payment processing
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Close loading dialog
        // Navigate to payment success or show error
      });
    }
  }

  @override
  void dispose() {
    _referenceNoController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}