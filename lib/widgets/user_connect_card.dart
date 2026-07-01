import 'package:flutter/material.dart';

import '../data/models/profile.dart';
import '../data/repositories/connection_repository.dart';
import '../home_tab.dart';
import '../user_profile_page.dart';

/// A real-user card in the Talent-card style (avatar + name + category +
/// Connect/mail buttons). Connection-state-aware: Connect → confirm → request;
/// Accept incoming; Message when connected; tap → the user's profile.
class UserConnectCard extends StatefulWidget {
  const UserConnectCard({super.key, required this.profile, this.onChanged});

  final Profile profile;

  /// Called after the connection state changes (so a list can refresh).
  final VoidCallback? onChanged;

  @override
  State<UserConnectCard> createState() => _UserConnectCardState();
}

class _UserConnectCardState extends State<UserConnectCard> {
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _cardBg = Color(0xFFEAF4FF);
  static const Color _msgBtnBg = Color(0xFFDDEBFB);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final ConnectionRepository _repo = ConnectionRepository();
  ConnState _state = ConnState.none;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final s = await _repo.stateWith(widget.profile.id);
    if (mounted) setState(() => _state = s);
  }

  String get _name => widget.profile.fullName.isNotEmpty
      ? widget.profile.fullName
      : 'You2Art User';

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _connect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send connection request?',
            style: TextStyle(
                color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text('Send a connection request to $_name?',
            style: const TextStyle(color: _textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(
                    color: _textSecondary, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, send',
                style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || _busy) return;
    setState(() => _busy = true);
    try {
      await _repo.sendRequest(widget.profile.id);
      if (mounted) setState(() => _state = ConnState.outgoingPending);
      _toast('Connection request sent.');
      widget.onChanged?.call();
    } catch (e) {
      _toast('Could not send request: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repo.acceptFrom(widget.profile.id);
      if (mounted) setState(() => _state = ConnState.connected);
      _toast('You are now connected.');
      widget.onChanged?.call();
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onMessage() {
    if (_state == ConnState.connected) {
      openDirectChat(context, widget.profile);
    } else {
      _toast('Request pending — you can message once it is accepted.');
    }
  }

  void _openProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => UserProfilePage(profile: widget.profile)))
        .then((_) {
      _loadState();
      widget.onChanged?.call();
    });
  }

  Widget _avatar() {
    final url = widget.profile.avatarUrl ?? '';
    Widget fallback() => Container(
          width: 70,
          height: 70,
          color: Colors.white,
          child: const Icon(Icons.person, color: _textSecondary),
        );
    return ClipOval(
      child: url.startsWith('http')
          ? Image.network(url,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback())
          : fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    late final VoidCallback? onTap;
    switch (_state) {
      case ConnState.none:
        label = 'Connect';
        color = Colors.black;
        onTap = _busy ? null : _connect;
        break;
      case ConnState.outgoingPending:
        label = 'Requested';
        color = const Color(0xFF9AA0A6);
        onTap = _openProfile;
        break;
      case ConnState.incomingPending:
        label = 'Accept';
        color = _blue;
        onTap = _busy ? null : _accept;
        break;
      case ConnState.connected:
        label = 'Message';
        color = _blue;
        onTap = _onMessage;
        break;
    }
    return GestureDetector(
      onTap: _openProfile,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _avatar()),
            const SizedBox(height: 10),
            Text(
              _name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              (widget.profile.category ?? '').isNotEmpty
                  ? widget.profile.category!
                  : 'Member',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: const StadiumBorder(),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _onMessage,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _msgBtnBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFD9DDE3), width: 1.4),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/mail_icon.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.mail_outline,
                            size: 16,
                            color: _blue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
