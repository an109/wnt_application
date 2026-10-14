import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background handler. Must be a top-level (or static) function so
/// the Flutter engine can invoke it in a background isolate.
///
/// Keep this lightweight. Firebase is re-initialized here because background
/// isolates don't share state with the main isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    developer.log(
      'Background message: ${message.messageId}',
      name: 'NotificationService',
    );
  } catch (e) {
    developer.log('Background handler error: $e', name: 'NotificationService');
  }
}

/// Handles Firebase Cloud Messaging + local notification display.
///
/// Safe by design: if Firebase is not configured for the current platform
/// (e.g. iOS has no GoogleService-Info.plist yet), [initialize] simply logs
/// and returns without throwing, so the rest of the app keeps working.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _localReady = false;

  /// Android notification channel used to display foreground messages.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  /// Call this once during app startup (after WidgetsFlutterBinding).
  /// Never throws — failures are logged and swallowed.
  Future<void> initialize() async {
    if (_initialized) return;

    // Local notifications don't need Firebase. Set them up first so in-app
    // notifications (e.g. login/logout) work even if FCM isn't configured yet.
    await _setupLocalNotifications();
    await _requestPermission();

    try {
      await Firebase.initializeApp();
    } catch (e) {
      // No Firebase config for this platform yet (expected on iOS until the
      // GoogleService-Info.plist / APNs setup is done). Local notifications
      // still work; only remote push (FCM) is skipped.
      developer.log(
        'Firebase not configured on this platform, skipping FCM: $e',
        name: 'NotificationService',
      );
      _initialized = true;
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Register with APNs / confirm permission for remote push.
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      developer.log(
        'FCM permission: ${settings.authorizationStatus}',
        name: 'NotificationService',
      );

      // Register background handler for when the app is terminated/backgrounded.
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      // Show a notification when a message arrives while the app is open.
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      // Log the device token. Send this to your backend to target this device.
      final token = await messaging.getToken();
      developer.log('FCM token: $token', name: 'NotificationService');
      messaging.onTokenRefresh.listen((t) {
        developer.log('FCM token refreshed: $t', name: 'NotificationService');
      });

      _initialized = true;
    } catch (e) {
      developer.log(
        'Notification setup error: $e',
        name: 'NotificationService',
      );
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localPlugin.initialize(settings: initSettings);

    // Create the Android channel so foreground notifications are shown.
    if (!kIsWeb && Platform.isAndroid) {
      await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
    _localReady = true;
  }

  /// Requests notification permission without needing Firebase, so local
  /// notifications can be shown even before/without FCM being configured.
  Future<void> _requestPermission() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _localPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _localPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      developer.log('Permission request error: $e', name: 'NotificationService');
    }
  }

  /// Shows a local notification immediately on this device. Safe to call from
  /// anywhere (e.g. after login/logout); never throws.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    try {
      if (!_localReady) await _setupLocalNotifications();
      await _localPlugin.show(
        id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      developer.log('showLocalNotification error: $e', name: 'NotificationService');
    }
  }

  /// Convenience: notification shown right after a successful login.
  Future<void> showLoginNotification({String? name}) {
    final who = (name != null && name.trim().isNotEmpty) ? ', $name' : '';
    return showLocalNotification(
      title: 'Welcome back$who 👋',
      body: 'You have signed in to Wander Nova successfully.',
    );
  }

  /// Convenience: notification shown right after logout.
  Future<void> showLogoutNotification() {
    return showLocalNotification(
      title: 'Signed out',
      body: 'You have been logged out of Wander Nova. See you soon!',
    );
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
