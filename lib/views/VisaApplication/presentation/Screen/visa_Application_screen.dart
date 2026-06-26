// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../../UI_helper/responsive_layout.dart';
// import '../../../../UI_helper/currency_converter.dart';
// import '../../../../injection_container.dart';
// import '../../domain/entity/TravellerEntity.dart';
// import '../../domain/entity/visaEntity.dart';
// import '../Section/fare_summary.dart';
// import '../Section/itinery_section.dart';
// import '../Section/payment_section.dart';
// import '../Section/traveller_detail_section.dart';
// import '../Section/upload_documents_section.dart';
// import '../bloc/visaBloc.dart';
// import '../bloc/visaEvent.dart';
// import '../bloc/visaState.dart';
//
//
// class VisaApplicationScreen extends StatefulWidget {
//   final String destinationName;
//   final String price;
//   final String currency;
//   final dynamic visaType;
//   final Map<String, dynamic>? preFilledData;
//
//   const VisaApplicationScreen({
//     Key? key,
//     required this.destinationName,
//     required this.price,
//     required this.currency,
//     required this.visaType,
//     this.preFilledData,
//   }) : super(key: key);
//
//   @override
//   State<VisaApplicationScreen> createState() => _VisaApplicationScreenState();
// }
//
// class _VisaApplicationScreenState extends State<VisaApplicationScreen> with TickerProviderStateMixin {
//   int _currentStep = 1;
//   final Map<String, dynamic> _formData = {};
//   late AnimationController _progressController;
//   late Animation<double> _progressAnimation;
//   String _preferredSymbol = '₹';
//   double _convertedPrice = 0;
//   bool _isCurrencyLoaded = false;
//
//   // Track if API call is in progress during step transition
//   bool _isApiProcessing = false;
//
//   late final VisaApplicationBloc _visaBloc;
//
//   Future<void> _loadConvertedPrice() async {
//     final preferred = CurrencyConverter.getPreferredCurrency();
//     final sourceCurrency = widget.currency.isNotEmpty ? widget.currency : 'USD';
//     final amount = double.tryParse(widget.price) ?? 0;
//
//     final converted = CurrencyConverter.convert(
//       amount: amount,
//       fromCurrency: sourceCurrency,
//       toCurrency: preferred,
//     );
//
//     setState(() {
//       _preferredSymbol = CurrencyConverter.getSymbol(preferred);
//       _convertedPrice = converted;
//       _isCurrencyLoaded = true;
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//
//     _visaBloc = sl<VisaApplicationBloc>();
//
//     // Listen for API success to get the Application ID
//     _visaBloc.stream.listen((state) {
//       if (state is VisaApplicationCreated) {
//         setState(() {
//           _isApiProcessing = false;
//           // Save the created application ID to form data for future reference
//           _formData['applicationId'] = state.application.id;
//           _formData['status'] = state.application.status;
//         });
//
//         // Only move to next step if we are currently waiting for this creation
//         if (_currentStep == 2) {
//           _updateStep(3);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Application created successfully! Proceed to payment.'),
//               backgroundColor: Color(0xff10B981),
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         }
//       } else if (state is VisaApplicationError) {
//         setState(() => _isApiProcessing = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${state.message}'),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     });
//
//     _progressController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
//     );
//     _progressController.forward();
//
//     if (widget.preFilledData != null) {
//       _formData.addAll(widget.preFilledData!);
//     }
//     _loadConvertedPrice();
//   }
//
//   @override
//   void dispose() {
//     _visaBloc.close();
//     _progressController.dispose();
//     super.dispose();
//   }
//
//   void _updateStep(int step) {
//     setState(() => _currentStep = step);
//   }
//
//   void _saveFormData(Map<String, dynamic> data) {
//     setState(() => _formData.addAll(data));
//   }
//
//   /// Helper to create entity and trigger API
//   void _triggerCreateApplication() {
//     setState(() => _isApiProcessing = true);
//
//     String formatDate(DateTime? date) {
//       if (date == null) return '';
//       return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
//     }
//
//     List<Map<String, dynamic>> rawTravellers = [];
//     if (_formData['travellersData'] != null && _formData['travellersData'] is List) {
//       rawTravellers = List<Map<String, dynamic>>.from(_formData['travellersData']);
//     } else if (_formData['firstName'] != null) {
//       rawTravellers.add({
//         "title": _formData['title'] ?? "Mr",
//         "firstName": _formData['firstName'] ?? "",
//         "lastName": _formData['lastName'] ?? "",
//         "dob": _formData['dob'] is DateTime ? formatDate(_formData['dob']) : _formData['dob']?.toString() ?? "",
//         "nationality": _formData['nationality'] ?? "Indian",
//         "passportNo": _formData['passportNo'] ?? "",
//         "contactNumber": _formData['phone'] ?? "",
//         "emailId": _formData['email'] ?? "",
//       });
//     }
//
//     List<TravellerEntity> travellers = rawTravellers.asMap().entries.map((e) {
//       final t = e.value;
//       return TravellerEntity(
//         travellerIndex: e.key,
//         title: t['title']?.toString() ?? 'Mr',
//         firstName: t['firstName']?.toString() ?? '',
//         lastName: t['lastName']?.toString() ?? '',
//         dob: t['dob']?.toString() ?? '',
//         nationality: t['nationality']?.toString() ?? 'Indian',
//         passportNo: t['passportNo']?.toString() ?? '',
//         contactNumber: t['contactNumber']?.toString() ?? t['phone']?.toString() ?? '',
//         emailId: t['emailId']?.toString() ?? t['email']?.toString() ?? '',
//       );
//     }).toList();
//
//     final sourceCurrency = widget.currency.isNotEmpty ? widget.currency : 'USD';
//     final originalBaseFare = double.tryParse(widget.price) ?? 0;
//     final inrBaseFare = CurrencyConverter.convert(
//       amount: originalBaseFare,
//       fromCurrency: sourceCurrency,
//       toCurrency: 'INR',
//     );
//
//     final numTravellers = _formData['travellers'] ?? 1;
//     final totalInr = inrBaseFare * numTravellers;
//
//     final application = VisaApplicationEntity(
//       destination: widget.destinationName,
//       visaType: _formData['visaType'] ?? widget.visaType?.title?.toString() ?? '',
//       onwardDate: formatDate(_formData['onwardDate']),
//       returnDate: formatDate(_formData['returnDate']),
//       numTravellers: numTravellers,
//       contactEmail: _formData['email']?.toString() ?? _formData['contactEmail']?.toString() ?? '',
//       contactPhone: _formData['phone']?.toString() ?? _formData['contactPhone']?.toString() ?? '',
//       currency: 'INR',
//       baseFare: inrBaseFare.toStringAsFixed(2),
//       tax: '0.00',
//       total: totalInr.toStringAsFixed(2),
//       status: 'payment_pending',
//       currentStep: 3,
//       travellers: travellers,
//       documents: [],
//     );
//
//     _visaBloc.add(CreateVisaApplicationEvent(application));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDesktop = context.screenWidth > 1024;
//
//     return Scaffold(
//       backgroundColor: const Color(0xffF8F9FA),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             _buildProgressBar(),
//             Expanded(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isDesktop ? context.w(100) : context.w(16),
//                   vertical: context.h(16),
//                 ),
//                 child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: EdgeInsets.all(context.w(16)),
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'APPLYING FOR',
//             style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600, fontWeight: FontWeight.w600),
//           ),
//           SizedBox(height: context.h(4)),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 widget.destinationName,
//                 style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w700, color: const Color(0xff0D1B3D)),
//               ),
//               SizedBox(width: context.w(8)),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
//                 decoration: BoxDecoration(
//                   color: const Color(0xff00BFA5),
//                   borderRadius: BorderRadius.circular(context.r(4)),
//                 ),
//                 child: Text(
//                   '99.8% Visa Approval Rate',
//                   style: TextStyle(fontSize: context.fs(10), color: Colors.white, fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildProgressBar() {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: context.h(16), horizontal: context.w(16)),
//       color: Colors.white,
//       child: AnimatedBuilder(
//         animation: _progressAnimation,
//         builder: (context, child) {
//           return Row(
//             children: [
//               _buildStepItem(1, 'Itinerary', Icons.flight_takeoff),
//               _buildConnector(1),
//               _buildStepItem(2, 'Traveller Details', Icons.person_outline),
//               _buildConnector(2),
//               _buildStepItem(3, 'Make Payment', Icons.payment),
//               _buildConnector(3),
//               _buildStepItem(4, 'Upload Documents', Icons.upload_file),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildStepItem(int step, String label, IconData icon) {
//     final isCompleted = step < _currentStep;
//     final isCurrent = step == _currentStep;
//
//     return Expanded(
//       child: Column(
//         children: [
//           Container(
//             width: context.w(32),
//             height: context.w(32),
//             decoration: BoxDecoration(
//               color: isCompleted || isCurrent ? const Color(0xff0D47A1) : Colors.grey.shade200,
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: isCompleted
//                   ? Icon(Icons.check, size: context.iconSmall, color: Colors.white)
//                   : Text('$step', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: Colors.white)),
//             ),
//           ),
//           SizedBox(height: context.h(6)),
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: context.fs(11),
//               fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
//               color: isCompleted || isCurrent ? const Color(0xff0D47A1) : Colors.grey.shade500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildConnector(int step) {
//     final isCompleted = step < _currentStep;
//     return Expanded(
//       child: Container(
//         height: context.h(2),
//         margin: EdgeInsets.only(bottom: context.h(24)),
//         color: isCompleted ? const Color(0xff0D47A1) : Colors.grey.shade200,
//       ),
//     );
//   }
//
//   Widget _buildDesktopLayout() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(flex: 3, child: _buildFormSections()),
//         // SizedBox(width: context.w(16)),
//         // Expanded(flex: 1, child: _buildFareSummary()),
//       ],
//     );
//   }
//
//   Widget _buildMobileLayout() {
//     return Column(
//       children: [
//         _buildFormSections(),
//         // SizedBox(height: context.h(12)),
//         // _buildFareSummary(),
//       ],
//     );
//   }
//
//   Widget _buildFormSections() {
//     return Expanded(
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             ItinerarySection(
//               stepNumber: 1,
//               isCompleted: _currentStep > 1,
//               isActive: _currentStep == 1,
//               destination: widget.destinationName,
//               visaType: widget.visaType,
//               preFilledData: _formData,
//               onContinue: () => _updateStep(2),
//               onSave: _saveFormData,
//             ),
//             SizedBox(height: context.h(12)),
//             TravellerDetailsSection(
//               stepNumber: 2,
//               isCompleted: _currentStep > 2,
//               isActive: _currentStep == 2,
//               preFilledData: _formData,
//               isLoading: _isApiProcessing, // Pass loading state
//               onContinue: () {
//                 // Trigger API before moving to payment
//                 _triggerCreateApplication();
//               },
//               onBack: () => _updateStep(1),
//               onSave: _saveFormData,
//             ),
//             SizedBox(height: context.h(12)),
//             PaymentSection(
//               stepNumber: 3,
//               isCompleted: _currentStep > 3,
//               isActive: _currentStep == 3,
//               amountInr: _payableInr,
//               formData: _formData,
//               onBack: () => _updateStep(2),
//               onPaymentSuccess: () {
//                 _updateStep(4);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Payment successful! Please upload your documents.'),
//                     backgroundColor: Color(0xff10B981),
//                     behavior: SnackBarBehavior.floating,
//                   ),
//                 );
//               },
//             ),
//             SizedBox(height: context.h(12)),
//             UploadDocumentsSection(
//               stepNumber: 4,
//               isCompleted: _currentStep > 4,
//               isActive: _currentStep == 4,
//               onBack: () => _updateStep(3),
//               onSubmit: _showSuccessDialog,
//             ),
//             SizedBox(height: context.h(12)),
//             FareSummary(
//               travellers: _formData['travellers'] ?? 1,
//               basePrice: _isCurrencyLoaded ? _convertedPrice : (double.tryParse(widget.price) ?? 0),
//               currencySymbol: _isCurrencyLoaded ? _preferredSymbol : widget.currency,
//               taxesAndCharges: 0, // Pass your actual taxes if available
//             ),
//             SizedBox(height: context.h(14)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Widget _buildFareSummary() {
//   //   final travellers = _formData['travellers'] ?? 1;
//   //   final basePrice = _isCurrencyLoaded ? _convertedPrice : (double.tryParse(widget.price) ?? 0);
//   //   final symbol = _isCurrencyLoaded ? _preferredSymbol : widget.currency;
//   //   final total = basePrice * travellers;
//   //   final formattedTotal = total.toStringAsFixed(total % 1 == 0 ? 0 : 2);
//   //
//   //   return Container(
//   //     padding: EdgeInsets.all(context.w(12)),
//   //     decoration: BoxDecoration(
//   //       color: Colors.white,
//   //       borderRadius: BorderRadius.circular(context.r(8)),
//   //       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.w(8), offset: Offset(0, context.h(2)))],
//   //     ),
//   //     child: Column(
//   //       crossAxisAlignment: CrossAxisAlignment.start,
//   //       children: [
//   //         Row(
//   //           children: [
//   //             Text('Fare Summary', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700)),
//   //             const Spacer(),
//   //             Text('$travellers Traveller${travellers > 1 ? 's' : ''}',
//   //                 style: TextStyle(fontSize: context.fs(10), color: const Color(0xff0D47A1), fontWeight: FontWeight.w600)),
//   //           ],
//   //         ),
//   //         SizedBox(height: context.h(12)),
//   //         _buildPriceRow('Base Fare', '${basePrice.toStringAsFixed(basePrice % 1 == 0 ? 0 : 2)}'),
//   //         SizedBox(height: context.h(4)),
//   //         _buildPriceRow('Taxes & charges', '0'),
//   //         Divider(height: context.h(12), color: Colors.grey),
//   //         Row(
//   //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //           children: [
//   //             Text('Grand Total', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700)),
//   //             Text('$formattedTotal',
//   //                 style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: const Color(0xffFF6B00))),
//   //           ],
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   // Widget _buildPriceRow(String label, String amount) {
//   //   final symbol = _isCurrencyLoaded ? _preferredSymbol : widget.currency;
//   //   return Row(
//   //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //     children: [
//   //       Row(
//   //         children: [
//   //           Icon(Icons.add_circle_outline, size: context.iconXSmall, color: Colors.grey.shade400),
//   //           SizedBox(width: context.w(6)),
//   //           Text(label, style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade700)),
//   //         ],
//   //       ),
//   //       Text('$amount', style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600)),
//   //     ],
//   //   );
//   // }
//
//   double get _payableInr {
//     final travellers = (_formData['travellers'] is int)
//         ? _formData['travellers'] as int
//         : int.tryParse('${_formData['travellers'] ?? 1}') ?? 1;
//     final base = double.tryParse(widget.price) ?? 0;
//     final source = widget.currency.isNotEmpty ? widget.currency : 'USD';
//     final inrBase = CurrencyConverter.convert(
//       amount: base,
//       fromCurrency: source,
//       toCurrency: 'INR',
//     );
//     return inrBase * travellers;
//   }
//
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: EdgeInsets.all(context.w(12)),
//               decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
//               child: Icon(Icons.check, size: context.iconXLarge, color: Colors.white),
//             ),
//             SizedBox(height: context.h(12)),
//             Text('Application Submitted!', style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w700)),
//             SizedBox(height: context.h(8)),
//             Text('Your ${widget.destinationName} visa application submitted successfully.',
//                 textAlign: TextAlign.center, style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600)),
//             SizedBox(height: context.h(16)),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   Navigator.of(context).pop();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xff0D47A1),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
//                   padding: EdgeInsets.symmetric(vertical: context.h(10)),
//                 ),
//                 child: Text('Done', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../UI_helper/responsive_layout.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../injection_container.dart';
import '../../domain/entity/TravellerEntity.dart';
import '../../domain/entity/visaEntity.dart';
import '../Section/fare_summary.dart';
import '../Section/itinery_section.dart';
import '../Section/payment_section.dart';
import '../Section/traveller_detail_section.dart';
import '../Section/upload_documents_section.dart';
import '../bloc/visaBloc.dart';
import '../bloc/visaEvent.dart';
import '../bloc/visaState.dart';


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
  String _preferredSymbol = '₹';
  double _convertedPrice = 0;
  bool _isCurrencyLoaded = false;

  // Track if API call is in progress during step transition
  bool _isApiProcessing = false;

  late final VisaApplicationBloc _visaBloc;

  Future<void> _loadConvertedPrice() async {
    final preferred = CurrencyConverter.getPreferredCurrency();
    final sourceCurrency = widget.currency.isNotEmpty ? widget.currency : 'USD';
    final amount = double.tryParse(widget.price) ?? 0;

    final converted = CurrencyConverter.convert(
      amount: amount,
      fromCurrency: sourceCurrency,
      toCurrency: preferred,
    );

    setState(() {
      _preferredSymbol = CurrencyConverter.getSymbol(preferred);
      _convertedPrice = converted;
      _isCurrencyLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();

    _visaBloc = sl<VisaApplicationBloc>();

    // Listen for API success to get the Application ID
    _visaBloc.stream.listen((state) {
      // if (state is VisaApplicationCreated) {
      //   setState(() {
      //     _isApiProcessing = false;
      //     // Save the created application ID to form data for future reference
      //     _formData['applicationId'] = state.application.id;
      //     _formData['status'] = state.application.status;
      //   });
      //
      //   // Only move to next step if we are currently waiting for this creation
      //   if (_currentStep == 2) {
      //     _updateStep(3);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Application created successfully! Proceed to payment.'),
      //         backgroundColor: Color(0xff10B981),
      //         behavior: SnackBarBehavior.floating,
      //       ),
      //     );
      //   }
      // }
      if (state is VisaApplicationCreated) {
        setState(() {
          _isApiProcessing = false;
          // Save the created application ID to form data for future reference
          _formData['applicationId'] = state.application.id;
          _formData['status'] = state.application.status;
        });

        // Check if payment was successful
        if (state.application.status == 'payment_completed' || state.application.status == 'completed'|| state.application.status == 'processing') {
          // Move to upload documents section
          _updateStep(4);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application created successfully! Please upload your documents.'),
              backgroundColor: Color(0xff10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Payment pending case - show appropriate message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application created with pending payment status.'),
              backgroundColor: Color(0xffF59E0B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      else if (state is VisaApplicationError) {
        setState(() => _isApiProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${state.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();

    if (widget.preFilledData != null) {
      _formData.addAll(widget.preFilledData!);
    }
    _loadConvertedPrice();
  }

  @override
  void dispose() {
    _visaBloc.close();
    _progressController.dispose();
    super.dispose();
  }

  void _updateStep(int step) {
    setState(() => _currentStep = step);
  }

  void _saveFormData(Map<String, dynamic> data) {
    setState(() => _formData.addAll(data));
  }

  /// Helper to create entity and trigger API
  void _triggerCreateApplication({String paymentStatus = 'processing'}) {
    setState(() => _isApiProcessing = true);

    String formatDate(DateTime? date) {
      if (date == null) return '';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    List<Map<String, dynamic>> rawTravellers = [];
    if (_formData['travellersData'] != null && _formData['travellersData'] is List) {
      rawTravellers = List<Map<String, dynamic>>.from(_formData['travellersData']);
    } else if (_formData['firstName'] != null) {
      rawTravellers.add({
        "title": _formData['title'] ?? "Mr",
        "firstName": _formData['firstName'] ?? "",
        "lastName": _formData['lastName'] ?? "",
        "dob": _formData['dob'] is DateTime ? formatDate(_formData['dob']) : _formData['dob']?.toString() ?? "",
        "nationality": _formData['nationality'] ?? "Indian",
        "passportNo": _formData['passportNo'] ?? "",
        "contactNumber": _formData['phone'] ?? "",
        "emailId": _formData['email'] ?? "",
      });
    }

    List<TravellerEntity> travellers = rawTravellers.asMap().entries.map((e) {
      final t = e.value;
      return TravellerEntity(
        travellerIndex: e.key,
        title: t['title']?.toString() ?? 'Mr',
        firstName: t['firstName']?.toString() ?? '',
        lastName: t['lastName']?.toString() ?? '',
        dob: t['dob']?.toString() ?? '',
        nationality: t['nationality']?.toString() ?? 'Indian',
        passportNo: t['passportNo']?.toString() ?? '',
        contactNumber: t['contactNumber']?.toString() ?? t['phone']?.toString() ?? '',
        emailId: t['emailId']?.toString() ?? t['email']?.toString() ?? '',
      );
    }).toList();

    final sourceCurrency = widget.currency.isNotEmpty ? widget.currency : 'USD';
    final originalBaseFare = double.tryParse(widget.price) ?? 0;
    final inrBaseFare = CurrencyConverter.convert(
      amount: originalBaseFare,
      fromCurrency: sourceCurrency,
      toCurrency: 'INR',
    );

    final numTravellers = _formData['travellers'] ?? 1;
    final totalInr = inrBaseFare * numTravellers;

    final application = VisaApplicationEntity(
      destination: widget.destinationName,
      visaType: _formData['visaType'] ?? widget.visaType?.title?.toString() ?? '',
      onwardDate: formatDate(_formData['onwardDate']),
      returnDate: formatDate(_formData['returnDate']),
      numTravellers: numTravellers,
      contactEmail: _formData['email']?.toString() ?? _formData['contactEmail']?.toString() ?? '',
      contactPhone: _formData['phone']?.toString() ?? _formData['contactPhone']?.toString() ?? '',
      currency: '₹',
      baseFare: inrBaseFare.toStringAsFixed(2),
      tax: '0.00',
      total: totalInr.toStringAsFixed(2),
      status: paymentStatus, // Use the passed payment status
      currentStep: 4, // Change to 4 since it's after payment
      travellers: travellers,
      documents: [],
    );

    _visaBloc.add(CreateVisaApplicationEvent(application));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.screenWidth > 1024;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? context.w(100) : context.w(16),
                  vertical: context.h(16),
                ),
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPLYING FOR',
            style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: context.h(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.destinationName,
                style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w700, color: const Color(0xff0D1B3D)),
              ),
              SizedBox(width: context.w(8)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
                decoration: BoxDecoration(
                  color: const Color(0xff00BFA5),
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
                child: Text(
                  '99.8% Visa Approval Rate',
                  style: TextStyle(fontSize: context.fs(10), color: Colors.white, fontWeight: FontWeight.w600),
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
      padding: EdgeInsets.symmetric(vertical: context.h(16), horizontal: context.w(16)),
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
            width: context.w(32),
            height: context.w(32),
            decoration: BoxDecoration(
              color: isCompleted || isCurrent ? const Color(0xff0D47A1) : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check, size: context.iconSmall, color: Colors.white)
                  : Text('$step', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          SizedBox(height: context.h(6)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.fs(11),
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
        height: context.h(2),
        margin: EdgeInsets.only(bottom: context.h(24)),
        color: isCompleted ? const Color(0xff0D47A1) : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildFormSections()),
        // SizedBox(width: context.w(16)),
        // Expanded(flex: 1, child: _buildFareSummary()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildFormSections(),
        // SizedBox(height: context.h(12)),
        // _buildFareSummary(),
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
            SizedBox(height: context.h(12)),
            TravellerDetailsSection(
              stepNumber: 2,
              isCompleted: _currentStep > 2,
              isActive: _currentStep == 2,
              preFilledData: _formData,
              isLoading: _isApiProcessing, // Pass loading state
              onContinue: () {
                // Trigger API before moving to payment
                // _triggerCreateApplication();
                _updateStep(3);
              },
              onBack: () => _updateStep(1),
              onSave: _saveFormData,
            ),
            SizedBox(height: context.h(12)),
            PaymentSection(
              stepNumber: 3,
              isCompleted: _currentStep > 3,
              isActive: _currentStep == 3,
              amountInr: _payableInr,
              formData: _formData,
              onBack: () => _updateStep(2),
              onPaymentSuccess: () {
                _updateStep(4);
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(
                //     content: Text('Payment successful! Please upload your documents.'),
                //     backgroundColor: Color(0xff10B981),
                //     behavior: SnackBarBehavior.floating,
                //   ),
                // );
              },
              onPaymentComplete: () {
                //  Trigger API with payment_completed status
                if (!_isApiProcessing) {
                  _triggerCreateApplication(paymentStatus: 'processing');
                }
              },
            ),
            SizedBox(height: context.h(12)),
            UploadDocumentsSection(
              stepNumber: 4,
              isCompleted: _currentStep > 4,
              isActive: _currentStep == 4,
              onBack: () => _updateStep(3),
              onSubmit: _showSuccessDialog,
            ),
            SizedBox(height: context.h(12)),
            FareSummary(
              travellers: _formData['travellers'] ?? 1,
              basePrice: _isCurrencyLoaded ? _convertedPrice : (double.tryParse(widget.price) ?? 0),
              currencySymbol: _isCurrencyLoaded ? _preferredSymbol : widget.currency,
              taxesAndCharges: 0, // Pass your actual taxes if available
            ),
            SizedBox(height: context.h(14)),
          ],
        ),
      ),
    );
  }

  // Widget _buildFareSummary() {
  //   final travellers = _formData['travellers'] ?? 1;
  //   final basePrice = _isCurrencyLoaded ? _convertedPrice : (double.tryParse(widget.price) ?? 0);
  //   final symbol = _isCurrencyLoaded ? _preferredSymbol : widget.currency;
  //   final total = basePrice * travellers;
  //   final formattedTotal = total.toStringAsFixed(total % 1 == 0 ? 0 : 2);
  //
  //   return Container(
  //     padding: EdgeInsets.all(context.w(12)),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(context.r(8)),
  //       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.w(8), offset: Offset(0, context.h(2)))],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Text('Fare Summary', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700)),
  //             const Spacer(),
  //             Text('$travellers Traveller${travellers > 1 ? 's' : ''}',
  //                 style: TextStyle(fontSize: context.fs(10), color: const Color(0xff0D47A1), fontWeight: FontWeight.w600)),
  //           ],
  //         ),
  //         SizedBox(height: context.h(12)),
  //         _buildPriceRow('Base Fare', '${basePrice.toStringAsFixed(basePrice % 1 == 0 ? 0 : 2)}'),
  //         SizedBox(height: context.h(4)),
  //         _buildPriceRow('Taxes & charges', '0'),
  //         Divider(height: context.h(12), color: Colors.grey),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text('Grand Total', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700)),
  //             Text('$formattedTotal',
  //                 style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: const Color(0xffFF6B00))),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildPriceRow(String label, String amount) {
  //   final symbol = _isCurrencyLoaded ? _preferredSymbol : widget.currency;
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(Icons.add_circle_outline, size: context.iconXSmall, color: Colors.grey.shade400),
  //           SizedBox(width: context.w(6)),
  //           Text(label, style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade700)),
  //         ],
  //       ),
  //       Text('$amount', style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600)),
  //     ],
  //   );
  // }

  double get _payableInr {
    final travellers = (_formData['travellers'] is int)
        ? _formData['travellers'] as int
        : int.tryParse('${_formData['travellers'] ?? 1}') ?? 1;
    final base = double.tryParse(widget.price) ?? 0;
    final source = widget.currency.isNotEmpty ? widget.currency : 'USD';
    final inrBase = CurrencyConverter.convert(
      amount: base,
      fromCurrency: source,
      toCurrency: 'INR',
    );
    return inrBase * travellers;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.w(12)),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: Icon(Icons.check, size: context.iconXLarge, color: Colors.white),
            ),
            SizedBox(height: context.h(12)),
            Text('Application Submitted!', style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w700)),
            SizedBox(height: context.h(8)),
            Text('Your ${widget.destinationName} visa application submitted successfully.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600)),
            SizedBox(height: context.h(16)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
                  padding: EdgeInsets.symmetric(vertical: context.h(10)),
                ),
                child: Text('Done', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}