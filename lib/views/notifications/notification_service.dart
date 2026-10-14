import 'package:dio/dio.dart';

import '../../core/constants/urls.dart';
import '../../core/network/dio_client.dart';
import '../../injection_container.dart';

/// One item of the notification screen: a wallet alert from
/// `GET /api/wallet/notifications/` or an offer the admin pushed, from
/// `GET /api/notifications/`.
class AppNotification {
  final int id;
  final String type; // 'transaction' | 'low_balance' | 'offer'
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic> metadata;
  final DateTime? created;

  /// Offers only: banner image and what tapping it opens (same `type` /
  /// `value` the push carried).
  final String? imageUrl;
  final String linkType;
  final String linkValue;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.metadata,
    required this.created,
    this.imageUrl,
    this.linkType = 'none',
    this.linkValue = '',
  });

  bool get isOffer => type == 'offer';

  factory AppNotification.fromOffer(Map<String, dynamic> json) => AppNotification(
    id: (json['id'] as num?)?.toInt() ?? 0,
    type: 'offer',
    title: (json['title'] ?? '').toString(),
    message: (json['body'] ?? '').toString(),
    // Offers carry no per-user read state; they are never shown as unread.
    isRead: true,
    metadata: const {},
    created: DateTime.tryParse((json['sent_at'] ?? '').toString())?.toLocal(),
    imageUrl: (json['image_url'] ?? '').toString().isEmpty ? null : json['image_url'].toString(),
    linkType: (json['link_type'] ?? 'none').toString(),
    linkValue: (json['link_value'] ?? '').toString(),
  );

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
/// transaction / low-balance alerts and pushed offers). Uses the app's
/// authenticated Dio.
class NotificationService {
  NotificationService({Dio? dio}) : _dio = dio ?? sl<DioClient>().instance;

  final Dio _dio;

  /// Wallet alerts and pushed offers, newest first. Either source may fail
  /// on its own (wallet alerts need a login) — the feed only fails when
  /// both do.
  Future<NotificationFeed> fetch({int limit = 100}) async {
    final results = await Future.wait([
      _walletFeed(limit).then<NotificationFeed?>((f) => f).catchError((_) => null),
      offers().then<List<AppNotification>?>((o) => o).catchError((_) => null),
    ]);
    final wallet = results[0] as NotificationFeed?;
    final offerItems = results[1] as List<AppNotification>?;
    if (wallet == null && offerItems == null) {
      throw Exception('Notifications unavailable');
    }
    final items = [...?wallet?.items, ...?offerItems]
      ..sort((a, b) {
        final at = a.created, bt = b.created;
        if (at == null || bt == null) return at == null ? 1 : -1;
        return bt.compareTo(at);
      });
    return NotificationFeed(items: items, unreadCount: wallet?.unreadCount ?? 0);
  }

  Future<NotificationFeed> _walletFeed(int limit) async {
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

  /// Offers already pushed to this user (or to everyone).
  Future<List<AppNotification>> offers() async {
    final res = await _dio.get(Urls.pushNotifications);
    final data = res.data is Map ? res.data as Map : const {};
    return [
      for (final n in (data['items'] as List? ?? const []))
        if (n is Map) AppNotification.fromOffer(Map<String, dynamic>.from(n)),
    ];
  }

  /// Unread count only (for the drawer badge) — wallet alerts only, since
  /// offers have no read state.
  Future<int> unreadCount() async => (await _walletFeed(1)).unreadCount;

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
