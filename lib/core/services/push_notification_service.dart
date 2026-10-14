import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../injection_container.dart';
import '../../views/offers/offers_screen.dart';
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
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

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
      default:
        // 'none': opening the app was the whole point.
        break;
    }
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
