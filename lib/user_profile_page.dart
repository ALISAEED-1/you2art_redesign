import 'package:flutter/material.dart';

import 'data/models/profile.dart';
import 'data/repositories/connection_repository.dart';
import 'home_tab.dart';

/// Public profile of a REAL user (found via Talent search). Shows live profile
/// data and a connection-state-aware action row (connect / pending / connected).
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.profile});

  final Profile profile;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _idleIcon = Color(0xFF9AA0A6);

  final ConnectionRepository _repo = ConnectionRepository();
  ConnState _state = ConnState.none;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final s = await _repo.stateWith(widget.profile.id);
    if (!mounted) return;
    setState(() {
      _state = s;
      _loading = false;
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirm(String title, String message, String yesLabel) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(message,
            style: const TextStyle(color: _textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(yesLabel,
                style: const TextStyle(color: _blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _toast('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _name =>
      widget.profile.fullName.isNotEmpty ? widget.profile.fullName : 'You2Art User';

  Future<void> _sendRequest() async {
    final ok = await _confirm(
      'Send connection request?',
      'Send a connection request to $_name?',
      'Yes, send',
    );
    if (!ok) return;
    await _run(() async {
      await _repo.sendRequest(widget.profile.id);
      if (mounted) setState(() => _state = ConnState.outgoingPending);
      _toast('Connection request sent.');
    });
  }

  Future<void> _remove({required String verb}) async {
    final ok = await _confirm(
      '$verb?',
      _state == ConnState.connected
          ? 'Remove $_name from your connections?'
          : 'Cancel your connection request to $_name?',
      'Yes',
    );
    if (!ok) return;
    await _run(() async {
      await _repo.removeWith(widget.profile.id);
      if (mounted) setState(() => _state = ConnState.none);
      _toast('$verb done.');
    });
  }

  Future<void> _accept() async {
    await _run(() async {
      await _repo.acceptFrom(widget.profile.id);
      if (mounted) setState(() => _state = ConnState.connected);
      _toast('You are now connected.');
    });
  }

  void _onMessage() {
    if (_state == ConnState.connected) {
      openDirectChat(context, widget.profile);
    } else {
      _toast('Request pending — you can message once it is accepted.');
    }
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 4),
            _buildHero(),
            const SizedBox(height: 20),
            _buildActions(),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFEFEFEF), height: 1, thickness: 1),
            const SizedBox(height: 18),
            _buildAbout(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final avatarUrl = widget.profile.avatarUrl;
    final placeholder = Container(
      width: 90,
      height: 90,
      color: const Color(0xFFEDEDED),
      child: const Icon(Icons.person, size: 42, color: _idleIcon),
    );
    return Column(
      children: [
        ClipOval(
          child: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? Image.network(avatarUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => placeholder)
              : placeholder,
        ),
        const SizedBox(height: 12),
        Text(
          _name,
          style: const TextStyle(
              color: _textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          (widget.profile.category ?? '').isNotEmpty
              ? widget.profile.category!
              : 'Member',
          style: const TextStyle(color: _textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    switch (_state) {
      case ConnState.none:
        return _singleButton(
          label: 'Send Connection Request',
          color: Colors.black,
          onTap: _busy ? null : _sendRequest,
        );
      case ConnState.incomingPending:
        return _twoButtons(
          leftLabel: 'Decline',
          leftColor: Colors.black,
          onLeft: _busy ? null : () => _remove(verb: 'Decline'),
          rightLabel: 'Accept',
          rightColor: _blue,
          onRight: _busy ? null : _accept,
        );
      case ConnState.outgoingPending:
        return _twoButtons(
          leftLabel: 'Remove Connection',
          leftColor: Colors.black,
          onLeft: _busy ? null : () => _remove(verb: 'Cancel request'),
          rightLabel: 'Message',
          rightColor: _blue,
          onRight: _onMessage,
        );
      case ConnState.connected:
        return _twoButtons(
          leftLabel: 'Remove Connection',
          leftColor: Colors.black,
          onLeft: _busy ? null : () => _remove(verb: 'Remove connection'),
          rightLabel: 'Message',
          rightColor: _blue,
          onRight: _onMessage,
        );
    }
  }

  Widget _singleButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Center(
      child: SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: const StadiumBorder(),
          ),
          child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _twoButtons({
    required String leftLabel,
    required Color leftColor,
    required VoidCallback? onLeft,
    required String rightLabel,
    required Color rightColor,
    required VoidCallback? onRight,
  }) {
    Widget btn(String label, Color color, VoidCallback? onTap) => Expanded(
          child: SizedBox(
            height: 40,
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
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          btn(leftLabel, leftColor, onLeft),
          const SizedBox(width: 10),
          btn(rightLabel, rightColor, onRight),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    final p = widget.profile;
    final location = [p.city, p.country]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About',
              style: TextStyle(
                  color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if ((p.category ?? '').isNotEmpty)
            _aboutRow(Icons.badge_outlined, p.category!),
          if (location.isNotEmpty) _aboutRow(Icons.location_on_outlined, location),
          if ((p.bio ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p.bio!.trim(),
                style: const TextStyle(
                    color: _textPrimary, fontSize: 14, height: 1.4)),
          ],
          if ((p.category ?? '').isEmpty &&
              location.isEmpty &&
              (p.bio ?? '').trim().isEmpty)
            const Text('No details added yet.',
                style: TextStyle(color: _textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _idleIcon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: _textPrimary, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
