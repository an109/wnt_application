import 'package:flutter/material.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../Section/itinery_section.dart';
import '../Section/traveller_detail_section.dart';

class VisaApplicationScreen extends StatefulWidget {
  final String destinationName;
  final String price;
  final String currency;
  final dynamic visaType;
  final Map<String, dynamic>? preFilledData;

  const VisaApplicationScreen({
    Key? key,
    required this.destinationName,
    required this.price,
    required this.currency,
    required this.visaType,
    this.preFilledData,
  }) : super(key: key);

  @override
  State<VisaApplicationScreen> createState() => _VisaApplicationScreenState();
}

class _VisaApplicationScreenState extends State<VisaApplicationScreen> with TickerProviderStateMixin {
  int _currentStep = 1;
  final Map<String, dynamic> _formData = {};
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();

    // Pre-fill data if available
    if (widget.preFilledData != null) {
      _formData.addAll(widget.preFilledData!);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _updateStep(int step) {
    setState(() => _currentStep = step);
  }

  void _saveFormData(Map<String, dynamic> data) {
    setState(() => _formData.addAll(data));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 1024;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 100 : 16,
                      vertical: 16,
                    ),
                    child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPLYING FOR',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.destinationName,
                style:  TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w700, color: Color(0xff0D1B3D)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff00BFA5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '99.8% Visa Approval Rate',
                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Colors.white,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Row(
            children: [
              _buildStepItem(1, 'Itinerary', Icons.flight_takeoff),
              _buildConnector(1),
              _buildStepItem(2, 'Traveller Details', Icons.person_outline),
              _buildConnector(2),
              _buildStepItem(3, 'Make Payment', Icons.payment),
              _buildConnector(3),
              _buildStepItem(4, 'Upload Documents', Icons.upload_file),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepItem(int step, String label, IconData icon) {
    final isCompleted = step < _currentStep;
    final isCurrent = step == _currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted || isCurrent ? const Color(0xff0D47A1) : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text('$step', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              color: isCompleted || isCurrent ? const Color(0xff0D47A1) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(int step) {
    final isCompleted = step < _currentStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isCompleted ? const Color(0xff0D47A1) : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildFormSections()),
        const SizedBox(width: 16),
        Expanded(flex: 1, child: _buildFareSummary()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildFormSections(),
        const SizedBox(height: 12),
        _buildFareSummary(),
      ],
    );
  }

  Widget _buildFormSections() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            ItinerarySection(
              stepNumber: 1,
              isCompleted: _currentStep > 1,
              isActive: _currentStep == 1,
              destination: widget.destinationName,
              visaType: widget.visaType,
              preFilledData: _formData,
              onContinue: () => _updateStep(2),
              onSave: _saveFormData,
            ),
            const SizedBox(height: 12),
            TravellerDetailsSection(
              stepNumber: 2,
              isCompleted: _currentStep > 2,
              isActive: _currentStep == 2,
              preFilledData: _formData,
              onContinue: () => _updateStep(3),
              onBack: () => _updateStep(1),
              onSave: _saveFormData,
            ),
            const SizedBox(height: 12),
            // ReviewPaySection(
            //   stepNumber: 3,
            //   isActive: _currentStep == 3,
            //   amount: widget.price,
            //   currency: widget.currency,
            //   onBack: () => _updateStep(2),
            //   onSubmit: () => _showSuccessDialog(),
            // ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFareSummary() {
    final travellers = _formData['travellers'] ?? 1;
    final basePrice = double.tryParse(widget.price) ?? 0;
    final total = basePrice * travellers;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Fare Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$travellers Traveller${travellers > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 10, color: Color(0xff0D47A1), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Base Fare', basePrice.toStringAsFixed(0)),
          const SizedBox(height: 4),
          _buildPriceRow('Taxes & charges', '0'),
          const Divider(height: 12, color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text('${widget.currency} ${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xffFF6B00))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.add_circle_outline, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
        Text(amount, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text('Application Submitted!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Your ${widget.destinationName} visa application submitted successfully.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}