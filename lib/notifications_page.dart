import 'package:flutter/material.dart';

import 'data/models/app_notification.dart';
import 'data/repositories/misc_repository.dart';
import 'options_sheet.dart';
import 'production_house_page.dart';
import 'widgets/empty_state.dart';

/// Notifications inbox, opened from the bell icon on the home page.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _acceptBg = Color(0xFFBFF4D6);
  static const Color _acceptText = Color(0xFF1F8A4D);
  static const Color _rejectBg = Color(0xFFFFD9D9);
  static const Color _rejectText = Color(0xFFE53935);
  static const Color _sparkleBg = Color(0xFFE6F0FF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final MiscRepository _repo = MiscRepository();
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchNotifications();
    // Opening the inbox clears the unread badge.
    _repo.markNotificationsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <AppNotification>[];
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: EmptyState(message: 'No notifications yet.'),
                  )
                else
                  for (final n in items) ...[
                    GestureDetector(
                      onTap: n.brand == 'filmfare'
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ProductionHousePage(
                                    name: 'FilmFare',
                                  ),
                                ),
                              )
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: _row(n),
                      ),
                    ),
                    const Divider(
                        color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                  ],
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(AppNotification n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatar(n),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text: n.actorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: n.body),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                n.timeLabel,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
              if (n.hasActions) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _pill(
                      bg: _acceptBg,
                      text: 'Accept',
                      textColor: _acceptText,
                      asset: 'assets/images/true_icon.png',
                      fallbackIcon: Icons.check_circle,
                    ),
                    const SizedBox(width: 10),
                    _pill(
                      bg: _rejectBg,
                      text: 'Reject',
                      textColor: _rejectText,
                      asset: 'assets/images/cancel_icon.png',
                      fallbackIcon: Icons.cancel,
                      iconTint: _rejectText,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (!n.hasActions) ...[
          const SizedBox(width: 8),
          const OptionsMenuButton(),
        ],
      ],
    );
  }

  Widget _avatar(AppNotification n) {
    if (n.brand == 'filmfare') {
      return CircleAvatar(
        radius: 19,
        backgroundColor: const Color(0xFFEDEDED),
        backgroundImage: const AssetImage('assets/images/production_face.png'),
        onBackgroundImageError: (_, __) {},
      );
    }
    if (n.brand == 'sparkle') {
      return Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: _sparkleBg,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            'assets/images/star_icon.png',
            width: 18,
            height: 18,
            color: _blue,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.auto_awesome, color: _blue, size: 18),
          ),
        ),
      );
    }
    final photo = n.photo ?? 'assets/images/profile_pic.png';
    return CircleAvatar(
      radius: 19,
      backgroundColor: const Color(0xFFEDEDED),
      backgroundImage:
          photo.startsWith('http') ? NetworkImage(photo) : AssetImage(photo),
      onBackgroundImageError: (_, __) {},
    );
  }

  Widget _pill({
    required Color bg,
    required String text,
    required Color textColor,
    required String asset,
    required IconData fallbackIcon,
    Color? iconTint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            asset,
            width: 14,
            height: 14,
            color: iconTint,
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, color: iconTint ?? textColor, size: 14),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
