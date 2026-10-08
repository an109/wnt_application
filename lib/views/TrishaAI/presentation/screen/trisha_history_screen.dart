import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../injection_container.dart';
import '../../data/data_source/trisha_api_service.dart';
import '../../data/model/trisha_models.dart';
import '../widgets/trisha_messages.dart';
import '../widgets/trisha_style.dart';

/// "Recent chats": the user's past Thrisha chats, newest first. Tapping one
/// pops with its session id so the chat screen can reopen it; swiping left
/// deletes it (on the server too).
class TrishaHistoryScreen extends StatefulWidget {
  final String? currentSessionId;

  const TrishaHistoryScreen({super.key, this.currentSessionId});

  @override
  State<TrishaHistoryScreen> createState() => _TrishaHistoryScreenState();
}

class _TrishaHistoryScreenState extends State<TrishaHistoryScreen> {
  final _api = sl<TrishaApiService>();
  final _scroll = ScrollController();
  final _chats = <TrishaChatSummary>[];
  bool _loading = true;
  bool _more = true;
  String? _error;

  static const _pageSize = 20;
  static const _flowIcons = {
    'flight': Icons.flight_rounded,
    'hotel': Icons.hotel_rounded,
    'holiday': Icons.beach_access_rounded,
    'transfer': Icons.local_taxi_rounded,
    'insurance': Icons.health_and_safety_rounded,
  };

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) _load();
    });
    _load(refresh: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (!refresh && (_loading || !_more)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _api.listChats(before: refresh || _chats.isEmpty ? null : _chats.last.updatedAt, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        if (refresh) _chats.clear();
        _chats.addAll(page);
        _more = page.length == _pageSize;
        _loading = false;
      });
    } on TrishaException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  Future<bool> _confirmDelete(TrishaChatSummary chat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this chat?'),
        content: Text('"${chat.title}" will be removed from your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return false;
    try {
      await _api.deleteChat(chat.sessionId);
      return true;
    } on TrishaException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return false;
    }
  }

  static String _when(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    if (day == today) return DateFormat('h:mm a').format(t);
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(t).inDays < 7) return DateFormat('EEEE').format(t);
    return DateFormat('d MMM').format(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: TrishaStyle.text,
        title: Text('Recent chats', style: TrishaStyle.body(context, 16, weight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(''),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New chat'),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: () => _load(refresh: true), child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (_chats.isEmpty && _loading) return const Center(child: CircularProgressIndicator());
    if (_chats.isEmpty && _error != null) {
      return ListView(children: [
        SizedBox(height: context.fx(120)),
        Padding(
          padding: EdgeInsets.all(context.fx(16)),
          child: TrishaErrorRow(message: _error!, onRetry: () => _load(refresh: true)),
        ),
      ]);
    }
    if (_chats.isEmpty) {
      return ListView(children: [
        SizedBox(height: context.fx(140)),
        Icon(Icons.forum_outlined, size: context.fx(48), color: TrishaStyle.hint),
        SizedBox(height: context.fx(12)),
        Center(
          child: Text('No chats yet. Ask Thrisha anything!',
              style: TrishaStyle.body(context, 13, color: TrishaStyle.hint)),
        ),
      ]);
    }
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: context.fx(8)),
      itemCount: _chats.length + (_more ? 1 : 0),
      separatorBuilder: (_, __) => Divider(height: 1, indent: context.fx(68), color: TrishaStyle.cardBorder),
      itemBuilder: (context, i) {
        if (i == _chats.length) {
          return Padding(
            padding: EdgeInsets.all(context.fx(16)),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final chat = _chats[i];
        final current = chat.sessionId == widget.currentSessionId;
        return Dismissible(
          key: ValueKey(chat.sessionId),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(chat),
          onDismissed: (_) => setState(() => _chats.removeWhere((c) => c.sessionId == chat.sessionId)),
          background: Container(
            color: Colors.red.shade400,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: context.fx(20)),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          child: ListTile(
            onTap: () => Navigator.of(context).pop(chat.sessionId),
            contentPadding: EdgeInsets.symmetric(horizontal: context.fx(16), vertical: context.fx(4)),
            leading: Container(
              width: context.fx(40),
              height: context.fx(40),
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              child: Icon(_flowIcons[chat.flow] ?? Icons.chat_bubble_outline_rounded,
                  size: context.fx(20), color: TrishaStyle.brandBlue),
            ),
            title: Row(children: [
              Expanded(
                child: Text(chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TrishaStyle.body(context, 13, weight: FontWeight.w600, height: 1.3)),
              ),
              SizedBox(width: context.fx(8)),
              Text(current ? 'Open now' : _when(chat.updatedAt),
                  style: TrishaStyle.body(context, 10,
                      color: current ? TrishaStyle.brandBlue : TrishaStyle.hint, height: 1.2)),
            ]),
            subtitle: Text(chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TrishaStyle.body(context, 11, color: TrishaStyle.hint, height: 1.4)),
          ),
        );
      },
    );
  }
}
