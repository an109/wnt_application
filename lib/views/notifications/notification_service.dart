import 'package:dio/dio.dart';

import '../../core/constants/urls.dart';
import '../../core/network/dio_client.dart';
import '../../injection_container.dart';

/// One item of `GET /api/wallet/notifications/`.
class AppNotification {
  final int id;
  final String type; // 'transaction' | 'low_balance'
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic> metadata;
  final DateTime? created;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.metadata,
    required this.created,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: (json['id'] as num?)?.toInt() ?? 0,
    type: (json['type'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    message: (json['message'] ?? '').toString(),
    isRead: json['is_read'] == true,
    metadata: json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const {},
    created: DateTime.tryParse((json['created'] ?? '').toString())?.toLocal(),
  );
}

class NotificationFeed {
  final List<AppNotification> items;
  final int unreadCount;

  const NotificationFeed({required this.items, required this.unreadCount});
}

/// Thin client for the backend's user notification endpoints (wallet
/// transaction and low-balance alerts). Uses the app's authenticated Dio.
class NotificationService {
  NotificationService({Dio? dio}) : _dio = dio ?? sl<DioClient>().instance;

  final Dio _dio;

  Future<NotificationFeed> fetch({int limit = 100}) async {
    final res = await _dio.get(
      Urls.walletNotifications,
      queryParameters: {'limit': limit},
    );
    final data = res.data is Map ? res.data as Map : const {};
    return NotificationFeed(
      items: [
        for (final n in (data['notifications'] as List? ?? const []))
          if (n is Map) AppNotification.fromJson(Map<String, dynamic>.from(n)),
      ],
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Unread count only (for the drawer badge).
  Future<int> unreadCount() async => (await fetch(limit: 1)).unreadCount;

  Future<void> markAllRead() =>
      _dio.post(Urls.walletNotificationsMarkRead, data: {'all': true});

  /// Notifications are "on" when either alert type is enabled.
  Future<bool> alertsEnabled() async {
    final res = await _dio.get(Urls.walletNotificationPreferences);
    final prefs = res.data is Map ? (res.data as Map)['preferences'] : null;
    if (prefs is! Map) return true;
    return prefs['notify_transactions'] == true || prefs['notify_low_balance'] == true;
  }

  Future<void> setAlertsEnabled(bool enabled) => _dio.put(
    Urls.walletNotificationPreferences,
    data: {'notify_transactions': enabled, 'notify_low_balance': enabled},
  );
}
