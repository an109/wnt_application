import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/urls.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/storage/shared_preference.dart';
import '../../../injection_container.dart' as di;
import 'visa_form_data.dart';

/// Thrown with a message that can be shown to the user as is.
class VisaSubmitException implements Exception {
  final String message;
  VisaSubmitException(this.message);
  @override
  String toString() => message;
}

class VisaCreatedApplication {
  final int id;
  final String trackId;
  const VisaCreatedApplication(this.id, this.trackId);
}

/// Backend calls of the visa checkout:
/// create → upload passport scans → (Razorpay) → complete-payment.
class VisaSubmitService {
  final Dio _dio = di.sl<DioClient>().instance;
  static final _date = DateFormat('dd/MM/yyyy');
  static final _iso = DateFormat('yyyy-MM-dd');

  String _d(DateTime? d) => d == null ? '' : _date.format(d);
  String _i(DateTime? d) => d == null ? '' : _iso.format(d);

  Future<VisaCreatedApplication> create({
    required String destination,
    required String visaTitle,
    required List<VisaTravellerForm> travellers,
    required VisaTripForm trip,
    required double feePerTravellerInr,
    required double totalInr,
    required Map<String, dynamic> extraDetails,
  }) async {
    final prefs = di.sl<PreferencesManager>();
    final body = {
      'destination': destination,
      'visaType': visaTitle,
      'onwardDate': _d(trip.arrivalDate),
      'returnDate': _d(trip.departureDate),
      'numTravellers': travellers.length,
      'contactEmail': trip.email.trim(),
      'contactPhone': trip.phone.trim(),
      'currency': 'INR',
      'baseFare': feePerTravellerInr.toStringAsFixed(2),
      'tax': '0.00',
      'total': totalInr.toStringAsFixed(2),
      'currentStep': 3,
      'user_email': trip.email.trim(),
      if (prefs.getUserId() != null) 'user_id': prefs.getUserId().toString(),
      'extraDetails': {
        ...extraDetails,
        'arrival_flight': trip.arrivalFlight,
        'arrival_date': _i(trip.arrivalDate),
        'hotel_name': trip.hotel,
        'departure_date': _i(trip.departureDate),
        'departure_flight': trip.departureFlight,
        'location': trip.location,
        'source': 'app',
      },
      'travellersData': [
        for (var i = 0; i < travellers.length; i++)
          {
            'title': travellers[i].title,
            'firstName': travellers[i].firstName.trim(),
            'lastName': travellers[i].lastName.trim(),
            'dob': _d(travellers[i].dob),
            'nationality': travellers[i].passportFrom,
            'passportNo': travellers[i].passportNo.trim(),
            'contactNumber': i == 0 ? trip.phone.trim() : '',
            'emailId': i == 0 ? trip.email.trim() : '',
            'extraDetails': {
              'gender': travellers[i].gender,
              'place_of_birth': travellers[i].placeOfBirth.trim(),
              'passport_country': travellers[i].passportFrom,
              'passport_issue_date': _i(travellers[i].passportIssued),
              'passport_expiry_date': _i(travellers[i].passportExpiry),
              'occupation': travellers[i].occupation.trim(),
              if (travellers[i].employment.isNotEmpty) 'employment': travellers[i].employment,
              if (travellers[i].fatherName.trim().isNotEmpty) 'father_name': travellers[i].fatherName.trim(),
              if (travellers[i].motherName.trim().isNotEmpty) 'mother_name': travellers[i].motherName.trim(),
              if (travellers[i].oldPassportNo.trim().isNotEmpty)
                'old_passport_number': travellers[i].oldPassportNo.trim().toUpperCase(),
              if (travellers[i].passportVerified) 'mrz': [travellers[i].mrzLine1, travellers[i].mrzLine2],
            },
          },
      ],
    };

    try {
      final res = await _dio.post(Urls.visaApplications, data: body);
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      final app = (data['application'] as Map?)?.cast<String, dynamic>();
      if (data['success'] == true && app?['id'] != null) {
        return VisaCreatedApplication(app!['id'] as int, (app['track_id'] ?? '').toString());
      }
      throw VisaSubmitException(_error(data) ?? 'Could not submit the application. Please try again.');
    } on DioException catch (e) {
      throw VisaSubmitException(
        _error(e.response?.data) ?? 'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  /// Uploads each traveller's selfie and passport pages, named like
  /// `traveller1_passport_front.jpg` so the team can tell them apart.
  /// Returns false when it failed; the application itself is already saved,
  /// so the team can collect them later.
  Future<bool> uploadDocuments(int applicationId, String email, List<VisaTravellerForm> travellers) async {
    final files = <MultipartFile>[];
    for (var i = 0; i < travellers.length; i++) {
      final t = travellers[i];
      final docs = {
        'selfie': t.selfiePath,
        'passport_front': t.passportScanPath,
        'passport_back': t.passportBackPath,
      };
      for (final e in docs.entries) {
        final path = e.value;
        if (path == null) continue;
        final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '.jpg';
        files.add(await MultipartFile.fromFile(path, filename: 'traveller${i + 1}_${e.key}$ext'));
      }
    }
    if (files.isEmpty) return true;
    try {
      // The endpoint takes at most 15 files per request.
      for (var start = 0; start < files.length; start += 15) {
        final form = FormData.fromMap({
          'user_email': email,
          'files': files.sublist(start, (start + 15).clamp(0, files.length)),
        });
        final res = await _dio.post('${Urls.visaApplications}$applicationId/documents/', data: form);
        if ((res.data as Map?)?['success'] != true) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Razorpay order for [amountInr]; returns `{order_id, key_id}`.
  Future<Map<String, dynamic>> createRazorpayOrder(double amountInr, int applicationId) async {
    try {
      final res = await _dio.post(Urls.razorpayCreateOrder, data: {
        'amount': double.parse(amountInr.toStringAsFixed(2)),
        'currency': 'INR',
        // complete-payment only accepts orders made for this application.
        'reference_id': 'visa_$applicationId',
        'transaction_type': 'visa',
        if (di.sl<PreferencesManager>().getUserId() != null)
          'user_id': di.sl<PreferencesManager>().getUserId(),
      });
      final data = (res.data as Map).cast<String, dynamic>();
      if (data['order_id'] == null || data['key_id'] == null) {
        throw VisaSubmitException('Could not start the payment. Please try again.');
      }
      return data;
    } on DioException {
      throw VisaSubmitException('Could not start the payment. Please try again.');
    }
  }

  /// Marks the application paid (or submitted, for `free`). Razorpay
  /// payments need the order id and signature; the backend verifies them.
  Future<void> completePayment({
    required int applicationId,
    required String email,
    required String reference,
    required String mode,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    try {
      final res = await _dio.post(Urls.visaCompletePayment(applicationId), data: {
        'user_email': email,
        'payment_reference': reference,
        'payment_mode': mode,
        if (razorpayOrderId != null) 'razorpay_order_id': razorpayOrderId,
        if (razorpaySignature != null) 'razorpay_signature': razorpaySignature,
      });
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      if (data['success'] != true) {
        throw VisaSubmitException(_error(data) ?? 'Could not confirm the application.');
      }
    } on DioException catch (e) {
      throw VisaSubmitException(_error(e.response?.data) ?? 'Could not confirm the application.');
    }
  }

  String? _error(dynamic data) {
    if (data is! Map) return null;
    final e = data['error'] ?? data['message'];
    if (e is String && e.isNotEmpty) return e;
    if (e is Map && e.isNotEmpty) {
      final first = e.values.first;
      return first is List && first.isNotEmpty ? first.first.toString() : first.toString();
    }
    return null;
  }
}
