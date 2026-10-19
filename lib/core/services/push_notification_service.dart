import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show File, Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../injection_container.dart';
import '../../views/MyBookings/Screen/MyBooking_Screen.dart';
import '../../views/offers/offers_screen.dart';
import '../../views/wallet/wallet/screen/wallet_screen.dart';
import '../constants/urls.dart';
import '../network/dio_client.dart';
import '../utils/storage/shared_preference.dart';

/// Runs in its own isolate when a push arrives while the app is in the
/// background or killed. Notification-type pushes are already shown by the
/// OS, so this only has to bring Firebase up.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Firebase Cloud Messaging setup: permission, the device token (linked to
/// the logged-in user on the backend), the broadcast topic every install
/// listens on, showing pushes while the app is open, and opening the right
/// screen when a push is tapped.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  /// Lets a tapped push open a screen from outside the widget tree.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Topic the admin panel uses for "send to everyone" offers.
  static const String allUsersTopic = 'all_users';

  /// Must match `default_notification_channel_id` in AndroidManifest.xml.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'wandernova_offers',
    'Offers & updates',
    description: 'Deals, offers and travel updates from Wander Nova',
    importance: Importance.high,
  );

  /// Booking outcomes for the person using *this* device. These are raised
  /// locally by the app at the moment it learns the result, never sent from
  /// the server, so they can't reach anyone else's phone.
  static const AndroidNotificationChannel _bookingChannel =
      AndroidNotificationChannel(
    'wandernova_bookings',
    'Your bookings',
    description:
        'Confirmed, pending and failed updates for bookings made on this device',
    importance: Importance.high,
  );

  /// Sign-ins and other account activity. High importance on purpose: this
  /// is the notice that tells someone their account was opened on a device
  /// they may not recognise.
  static const AndroidNotificationChannel _accountChannel =
      AndroidNotificationChannel(
    'wandernova_account',
    'Account activity',
    description: 'Sign-ins and security notices for your Wander Nova account',
    importance: Importance.high,
  );

  /// E-tickets and vouchers written to this device. Quieter than a booking
  /// update — it's a file landing, not news.
  static const AndroidNotificationChannel _downloadChannel =
      AndroidNotificationChannel(
    'wandernova_downloads',
    'Downloads',
    description: 'E-tickets and vouchers saved to this device',
    importance: Importance.defaultImportance,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  String? _token;

  /// Tap data of the push that cold-started the app. The splash replaces
  /// whatever is on top of it, so this waits for [openPendingLaunch].
  Map<String, dynamic>? _pendingLaunch;

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // iOS: let Firebase show the banner itself while the app is open.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          openFromData(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        } catch (_) {}
      },
    );
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.createNotificationChannel(_bookingChannel);
    await android?.createNotificationChannel(_accountChannel);
    await android?.createNotificationChannel(_downloadChannel);

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => openFromData(m.data));

    final initial = await _messaging.getInitialMessage();
    if (initial != null && initial.data.isNotEmpty) _pendingLaunch = initial.data;

    PreferencesManager.onAuthChanged = (loggedIn) {
      if (loggedIn) {
        _register();
      } else {
        _unregister();
      }
    };

    // Fires on a real sign-in only — a silent token refresh does not reach
    // here (see PreferencesManager.saveToken).
    PreferencesManager.onSignedIn = showSignInAlert;

    try {
      await _messaging.subscribeToTopic(allUsersTopic);
      _token = await _messaging.getToken();
      developer.log('FCM token: $_token', name: 'push');
      await _register();
    } catch (e) {
      // No APNs token yet (e.g. the iOS simulator) — pushes simply won't
      // arrive on this device; the app keeps working.
      developer.log('FCM setup incomplete: $e', name: 'push');
    }
    _messaging.onTokenRefresh.listen((token) {
      _token = token;
      _register();
    });
  }

  /// Sends the FCM token to the backend. The app's Dio adds the login token
  /// when there is one, which links this device to the user.
  Future<void> _register() async {
    final token = _token;
    if (token == null) return;
    try {
      await sl<DioClient>().instance.post(
        Urls.deviceRegister,
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (e) {
      developer.log('Device register failed: $e', name: 'push');
    }
  }

  /// On logout: keep broadcast offers, stop that user's targeted ones.
  Future<void> _unregister() async {
    final token = _token;
    if (token == null) return;
    try {
      await sl<DioClient>().instance.post(Urls.deviceUnregister, data: {'token': token});
    } catch (e) {
      developer.log('Device unregister failed: $e', name: 'push');
    }
  }

  /// Called once the splash has handed over to the home screen.
  void openPendingLaunch() {
    final data = _pendingLaunch;
    _pendingLaunch = null;
    if (data != null) openFromData(data);
  }

  /// Opens what the admin chose for "When tapped, open". `type` / `value`
  /// come from the backend's push payload (or a saved offer in the
  /// notification screen).
  Future<void> openFromData(Map<String, dynamic> data) async {
    final type = data['type']?.toString() ?? 'none';
    final value = data['value']?.toString() ?? '';
    final navigator = navigatorKey.currentState;

    switch (type) {
      case 'offers':
        navigator?.push(MaterialPageRoute(builder: (_) => const OffersScreen()));
      case 'deal':
        navigator?.push(
          MaterialPageRoute(builder: (_) => OffersScreen(focusDealId: int.tryParse(value))),
        );
      case 'url':
        final uri = Uri.tryParse(value);
        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      case 'trips':
        navigator?.push(
          MaterialPageRoute(builder: (_) => const MyBookingScreen(showBottomNav: false)),
        );
      case 'wallet':
      case 'benefits':
        // Benefit credit landed, was spent, or a tier moved — all of which
        // the traveller checks in the same place. The server sends 'wallet';
        // 'benefits' is accepted too so a later payload rename needs no app
        // release to keep working.
        navigator?.push(MaterialPageRoute(builder: (_) => const WalletScreen()));
      case 'file':
        // No file-opener package in the app, so hand the saved PDF to the
        // system share sheet — that's how the ticket screen opens it too.
        final file = File(value);
        if (await file.exists()) {
          await Share.shareXFiles([XFile(file.path)]);
        }
      default:
        // 'none': opening the app was the whole point.
        break;
    }
  }

  /// Tells the person their booking landed, is still being confirmed, or
  /// failed. Raised on the device that made the booking, from the result the
  /// app already has in hand — nothing is sent to the server and no other
  /// device ever sees it. Tapping it opens My Trips.
  ///
  /// Never throws: a notification is a courtesy on top of the on-screen
  /// result, so a device that has them switched off must not break checkout.
  Future<void> showBookingUpdate({
    required String title,
    required String body,
    String? reference,
  }) async {
    try {
      await _local.show(
        // Keyed on the booking reference so a later update to the same
        // booking replaces its earlier one instead of stacking.
        id: (reference ?? title).hashCode & 0x7fffffff,
        title: title,
        body: body,
        payload: jsonEncode({'type': 'trips'}),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _bookingChannel.id,
            _bookingChannel.name,
            channelDescription: _bookingChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      developer.log('Booking notification failed: $e', name: 'push');
    }
  }

  /// Tells the person a file finished saving to this device, with the share
  /// sheet a tap away. Local to this device for the same reason as
  /// [showBookingUpdate]. Never throws.
  Future<void> showFileSaved({
    required String title,
    required String body,
    required String filePath,
  }) async {
    try {
      await _local.show(
        id: filePath.hashCode & 0x7fffffff,
        title: title,
        body: body,
        payload: jsonEncode({'type': 'file', 'value': filePath}),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannel.id,
            _downloadChannel.name,
            channelDescription: _downloadChannel.description,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      developer.log('Download notification failed: $e', name: 'push');
    }
  }

  /// Tells the person their account was just signed in to on this device,
  /// and gives them somewhere to go if it wasn't them.
  ///
  /// Raised locally at the moment the session starts, so it never leaves the
  /// device and cannot reach anyone else's phone. Never throws: a sign-in
  /// must not fail because notifications are off.
  Future<void> showSignInAlert() async {
    try {
      final account = _signedInAccount();
      final when = DateFormat('h:mm a, d MMM').format(DateTime.now());
      final body = account.isEmpty
          ? 'Signed in on this device at $when. If this wasn\'t you, secure '
              'your account from Profile.'
          : 'Signed in as $account on this device at $when. If this wasn\'t '
              'you, secure your account from Profile.';

      await _local.show(
        // One id for the channel, so a later sign-in replaces the last notice
        // instead of stacking one per session.
        id: _accountChannel.id.hashCode & 0x7fffffff,
        title: 'New sign-in',
        body: body,
        payload: jsonEncode({'type': 'none'}),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _accountChannel.id,
            _accountChannel.name,
            channelDescription: _accountChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      developer.log('Sign-in notification failed: $e', name: 'push');
    }
  }

  /// Email (or name) of the account that just signed in, when the profile has
  /// already been cached. Several login paths save the token before the user
  /// record, so this is often empty on the first notice — the message reads
  /// correctly without it rather than showing a blank.
  String _signedInAccount() {
    try {
      final data = sl<PreferencesManager>().getUserData();
      if (data == null) return '';
      for (final key in ['email', 'name', 'mobile', 'phone']) {
        final value = (data[key] ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
    } catch (_) {
      // Prefs unavailable — fall back to the account-less wording.
    }
    return '';
  }

  /// Android does not display pushes while the app is in the foreground, so
  /// mirror them as a local notification. iOS shows them via the
  /// presentation options set in [init].
  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      payload: jsonEncode(message.data),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
