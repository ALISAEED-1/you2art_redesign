
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/repositories/post_repository.dart';

/// Custom "Share this post" bottom sheet. Each action records the share (which
/// notifies the post owner) and then performs the external share.
Future<void> showSharePostSheet(
  BuildContext context, {
  required String? postId,
  required String shareText,
  required String shareLink,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _SharePostSheet(postId: postId, shareText: shareText, shareLink: shareLink),
  );
}

class _SharePostSheet extends StatelessWidget {
  const _SharePostSheet({
    required this.postId,
    required this.shareText,
    required this.shareLink,
  });

  final String? postId;
  final String shareText;
  final String shareLink;

  static const Color _blue = Color(0xFF2F80ED);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  Future<void> _record() async {
    if (postId == null) return;
    try {
      await PostRepository().recordShare(postId!);
    } catch (_) {}
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _osShare() async {
    try {
      await Share.share(shareText);
    } catch (_) {}
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    String done = 'Post shared.',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    await _record();
    await action();
    nav.pop();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Share',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Share this post with your friends and family',
                style: TextStyle(color: _textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _appTile(
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  icon: Icons.chat_rounded,
                  onTap: () => _run(
                      context,
                      () => _launch(
                          'https://wa.me/?text=${Uri.encodeComponent(shareText)}')),
                ),
                _appTile(
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  icon: Icons.camera_alt_rounded,
                  onTap: () => _run(context, _osShare),
                ),
                _appTile(
                  label: 'Messenger',
                  color: const Color(0xFF7B5CFF),
                  icon: Icons.messenger_outline_rounded,
                  onTap: () => _run(context, _osShare),
                ),
                _appTile(
                  label: 'Telegram',
                  color: const Color(0xFF229ED9),
                  icon: Icons.send_rounded,
                  onTap: () => _run(
                      context,
                      () => _launch(
                          'https://t.me/share/url?url=${Uri.encodeComponent(shareLink)}&text=${Uri.encodeComponent(shareText)}')),
                ),
                _appTile(
                  label: 'More',
                  color: const Color(0xFFEDEDED),
                  icon: Icons.more_horiz_rounded,
                  iconColor: _textSecondary,
                  onTap: () => _run(context, _osShare),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEDEDED)),
            _listRow(
              icon: Icons.link_rounded,
              iconBg: const Color(0xFFEAF2FF),
              iconColor: _blue,
              title: 'Copy link',
              subtitle: 'Get a link to share anywhere',
              onTap: () => _run(
                context,
                () async =>
                    Clipboard.setData(ClipboardData(text: shareLink)),
                done: 'Link copied.',
              ),
            ),
            _listRow(
              icon: Icons.near_me_rounded,
              iconBg: const Color(0xFFFFF0E0),
              iconColor: const Color(0xFFF2994A),
              title: 'Nearby Share',
              subtitle: 'Share with devices nearby',
              onTap: () => _run(context, _osShare),
            ),
            _listRow(
              icon: Icons.more_horiz_rounded,
              iconBg: const Color(0xFFEDEDED),
              iconColor: _textSecondary,
              title: 'More options',
              subtitle: 'See more ways to share',
              onTap: () => _run(context, _osShare),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF2FF),
                  foregroundColor: _blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appTile({
    required String label,
    required Color color,
    required IconData icon,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: _textPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _listRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textSecondary),
          ],
        ),
      ),
    );
  }
}
