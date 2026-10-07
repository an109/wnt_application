import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../Dashboard/profile/widgets/account_kit.dart';
import 'notification_service.dart';

/// Notifications — Figma "Notification" / "Notification empty". Shows the
/// user's notification feed from the backend grouped by day; the switch in
/// the top bar turns those alerts on or off.
class NotificationsScreen extends StatefulWidget {
  /// Injectable for tests; defaults to the app's authenticated client.
  final NotificationService? service;

  const NotificationsScreen({super.key, this.service});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _service = widget.service ?? NotificationService();

  List<AppNotification>? _items;
  bool _failed = false;
  bool _alertsOn = true;
  bool _savingToggle = false;

  @override
  void initState() {
    super.initState();
    _load();
    _service.alertsEnabled().then((on) {
      if (mounted) setState(() => _alertsOn = on);
    }).catchError((_) {});
  }

  Future<void> _load() async {
    try {
      final feed = await _service.fetch();
      if (!mounted) return;
      setState(() {
        _items = feed.items;
        _failed = false;
      });
      // Seen now — clears the drawer badge. Unread items keep their
      // highlight until the next visit.
      if (feed.unreadCount > 0) _service.markAllRead().catchError((_) {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggleAlerts(bool on) async {
    final previous = _alertsOn;
    setState(() {
      _alertsOn = on;
      _savingToggle = true;
    });
    try {
      await _service.setAlertsEnabled(on);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(on ? 'Notifications turned on' : 'Notifications turned off')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _alertsOn = previous);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Couldn’t update notification settings')));
    } finally {
      if (mounted) setState(() => _savingToggle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(8), context.fx(12), context.fx(8)),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Expanded(child: AccountTopBar(title: 'Notifications')),
          Semantics(
            label: 'Notifications on or off',
            child: Switch(
              value: _alertsOn,
              onChanged: _savingToggle ? null : _toggleAlerts,
              activeTrackColor: AppColors.AppBlue,
              activeThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD5DAE1),
              inactiveThumbColor: Colors.white,
              trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_failed && _items == null) {
      return _Message(
        icon: Icons.wifi_off_rounded,
        title: 'Couldn’t load notifications',
        body: 'Check your connection and try again.',
        action: AccountPrimaryButton(
          label: 'Try again',
          onPressed: () {
            setState(() => _failed = false);
            _load();
          },
        ),
      );
    }
    final items = _items;
    if (items == null) {
      return const AppLoadingView(message: 'Loading notifications…');
    }

    final groups = _groupByDay(items);
    return RefreshIndicator(
      color: AppColors.AppBlue,
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: context.fx(120)),
                const _EmptyState(),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(12), context.fx(16), context.fx(32)),
              children: [
                for (final g in groups) ...[
                  Padding(
                    padding: EdgeInsets.only(top: context.fx(16), bottom: context.fx(12)),
                    child: Text(
                      g.label,
                      style: TextStyle(fontSize: context.ffs(12), color: kAccountMuted),
                    ),
                  ),
                  for (final n in g.items) ...[
                    _NotificationCard(item: n),
                    SizedBox(height: context.fx(16)),
                  ],
                ],
              ],
            ),
    );
  }

  List<({String label, List<AppNotification> items})> _groupByDay(List<AppNotification> items) {
    final today = DateUtils.dateOnly(DateTime.now());
    String labelFor(DateTime? d) {
      if (d == null) return 'Earlier';
      final day = DateUtils.dateOnly(d);
      if (day == today) return 'Today';
      if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return DateFormat('d MMM yyyy').format(day);
    }

    final out = <({String label, List<AppNotification> items})>[];
    for (final n in items) {
      final label = labelFor(n.created);
      if (out.isEmpty || out.last.label != label) {
        out.add((label: label, items: [n]));
      } else {
        out.last.items.add(n);
      }
    }
    return out;
  }
}

String _timeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return DateFormat('d MMM').format(t);
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;

  const _NotificationCard({required this.item});

  /// Icon from the notification type / what it's about.
  IconData get _icon {
    final m = item.metadata;
    final what = '${m['booking_type'] ?? ''} ${item.title}'.toLowerCase();
    if (item.type == 'low_balance') return Icons.notifications_active_rounded;
    if (what.contains('flight')) return Icons.flight_rounded;
    if (what.contains('hotel')) return Icons.hotel_rounded;
    if (what.contains('holiday')) return Icons.beach_access_rounded;
    if (what.contains('visa')) return Icons.badge_rounded;
    if (what.contains('transport') || what.contains('cab')) return Icons.local_taxi_rounded;
    return Icons.account_balance_wallet_rounded;
  }

  /// "Travel • PNR: AF-924L"-style footer from whatever the metadata carries.
  String? get _footer {
    final m = item.metadata;
    final parts = <String>[];
    final kind = (m['booking_type'] ?? m['category'] ?? '').toString();
    if (kind.isNotEmpty) parts.add(kind[0].toUpperCase() + kind.substring(1));
    for (final key in ['pnr', 'booking_ref', 'reference', 'booking_reference']) {
      final v = (m[key] ?? '').toString();
      if (v.isNotEmpty) {
        parts.add('${key == 'pnr' ? 'PNR' : 'Ref'}: $v');
        break;
      }
    }
    final amount = num.tryParse((m['amount'] ?? '').toString());
    if (amount != null && parts.length < 2) {
      parts.add(CurrencyConverter.format(amount.toDouble(), 'INR'));
    }
    return parts.isEmpty ? null : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final footer = _footer;
    return Container(
      padding: EdgeInsets.all(context.fx(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: item.isRead ? null : Border.all(color: const Color(0xFFCDE8FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.fx(46),
            height: context.fx(46),
            decoration: BoxDecoration(
              color: const Color(0xFFDDEFFC),
              borderRadius: BorderRadius.circular(context.fx(8)),
            ),
            child: Icon(_icon, size: context.fx(22), color: AppColors.AppBlue),
          ),
          SizedBox(width: context.fx(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: context.ffs(14),
                          fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w600,
                          color: kAccountInk,
                        ),
                      ),
                    ),
                    SizedBox(width: context.fx(8)),
                    Icon(Icons.schedule_rounded, size: context.fx(13), color: kAccountMuted),
                    SizedBox(width: context.fx(3)),
                    Text(
                      _timeAgo(item.created),
                      style: TextStyle(fontSize: context.ffs(12), color: kAccountMuted),
                    ),
                  ],
                ),
                SizedBox(height: context.fx(4)),
                Text(
                  item.message,
                  style: TextStyle(fontSize: context.ffs(11.5), color: kAccountMuted, height: 1.35),
                ),
                if (footer != null) ...[
                  SizedBox(height: context.fx(6)),
                  Row(
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: context.fx(12), color: kAccountMuted),
                      SizedBox(width: context.fx(4)),
                      Flexible(
                        child: Text(
                          footer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: context.ffs(10.5), color: kAccountMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "No new notifications" — globe, bell and clouds in a soft blue glow.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final size = context.fx(200);
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size * 0.8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFFE3F2FD), Colors.white.withValues(alpha: 0)],
                  ),
                ),
              ),
              Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5DB4F5), Color(0xFF2F6FE0)],
                  ),
                ),
                child: Icon(Icons.public_rounded, size: size * 0.36, color: const Color(0x8C8EE59B)),
              ),
              Positioned(
                top: size * 0.08,
                child: Icon(Icons.location_on_rounded, size: size * 0.16, color: const Color(0xFFE5484D)),
              ),
              Positioned(
                top: size * 0.1,
                right: size * 0.16,
                child: Transform.rotate(
                  angle: 0.5,
                  child: Icon(Icons.flight_rounded, size: size * 0.11, color: const Color(0xFF3D7BE0)),
                ),
              ),
              Positioned(
                bottom: size * 0.08,
                left: size * 0.2,
                child: Icon(Icons.cloud_rounded, size: size * 0.24, color: Colors.white),
              ),
              Positioned(
                bottom: size * 0.06,
                right: size * 0.22,
                child: Icon(Icons.cloud_rounded, size: size * 0.2, color: Colors.white),
              ),
            ],
          ),
        ),
        SizedBox(height: context.fx(8)),
        Text(
          'No new notifications',
          style: TextStyle(fontSize: context.ffs(16), fontWeight: FontWeight.w600, color: kAccountInk),
        ),
        SizedBox(height: context.fx(6)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.fx(56)),
          child: Text(
            'You’re all caught up! Check back later for travel updates, offers and booking alerts.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: context.ffs(12), color: kAccountMuted, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const _Message({required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.fx(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.fx(40), color: kAccountMuted),
            SizedBox(height: context.fx(12)),
            Text(title, style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600)),
            SizedBox(height: context.fx(6)),
            Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: context.ffs(12), color: kAccountMuted)),
            if (action != null) ...[SizedBox(height: context.fx(16)), action!],
          ],
        ),
      ),
    );
  }
}
