import 'package:flutter/material.dart';

import 'data/models/profile.dart';
import 'data/repositories/connection_repository.dart';
import 'home_tab.dart';
import 'user_profile_page.dart';
import 'widgets/empty_state.dart';
import 'widgets/user_connect_card.dart';

/// "My Network" tab — real incoming connection requests + accepted connections,
/// loaded from `public.connections`.
class NetworkView extends StatefulWidget {
  const NetworkView({super.key});

  @override
  State<NetworkView> createState() => _NetworkViewState();
}

class _NetworkViewState extends State<NetworkView> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _checkBg = Color(0xFFB7F0CD);
  static const Color _xBg = Color(0xFFFFD9D9);
  static const Color _green = Color(0xFF1F8A4D);
  static const Color _red = Color(0xFFE53935);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final ConnectionRepository _repo = ConnectionRepository();

  int _tabIndex = 0; // 0 Requests · 1 Connections
  bool _loading = true;
  List<ConnectionEdge> _requests = const [];
  List<ConnectionEdge> _connections = const [];
  List<Profile> _suggestions = const [];
  final Set<String> _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reqs = await _repo.incomingRequests();
      final cons = await _repo.myConnections();
      final sug = await _repo.suggestions();
      if (!mounted) return;
      setState(() {
        _requests = reqs;
        _connections = cons;
        _suggestions = sug;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _accept(ConnectionEdge e) async {
    if (_busy.contains(e.id)) return;
    setState(() => _busy.add(e.id));
    try {
      await _repo.acceptFrom(e.other.id);
      await _load();
      _toast('Connection accepted.');
    } catch (err) {
      _toast('Error: $err');
    } finally {
      if (mounted) setState(() => _busy.remove(e.id));
    }
  }

  Future<void> _reject(ConnectionEdge e) async {
    if (_busy.contains(e.id)) return;
    setState(() => _busy.add(e.id));
    try {
      await _repo.removeWith(e.other.id);
      await _load();
      _toast('Request declined.');
    } catch (err) {
      _toast('Error: $err');
    } finally {
      if (mounted) setState(() => _busy.remove(e.id));
    }
  }

  void _openProfile(Profile p) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => UserProfilePage(profile: p)))
        .then((_) => _load());
  }

  ImageProvider _img(String? url) {
    return (url != null && url.startsWith('http'))
        ? NetworkImage(url)
        : const AssetImage('assets/images/profile_pic.png');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildTabs(),
            _fullBleedDivider(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tabIndex == 0)
              ..._buildRequestsTab()
            else
              ..._buildConnectionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Network',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary),
        ),
        Image.asset(
          'assets/images/bell_icon.png',
          width: 26,
          height: 26,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.notifications_outlined, color: _blue, size: 26),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _tab(0, 'Requests (${_requests.length})'),
        const SizedBox(width: 24),
        _tab(1, 'Connections (${_connections.length})'),
      ],
    );
  }

  Widget _tab(int index, String label) {
    final selected = _tabIndex == index;
    final color = selected ? _textPrimary : _textSecondary;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Requests tab (incoming requests + Suggestions) ───────────────────
  List<Widget> _buildRequestsTab() {
    final out = <Widget>[];
    for (final r in _requests) {
      out.addAll([
        _requestRow(r),
        const SizedBox(height: 14),
        _fullBleedDivider(),
        const SizedBox(height: 14),
      ]);
    }
    if (_suggestions.isNotEmpty) {
      out.addAll([
        _sectionLabel('Suggestions'),
        const SizedBox(height: 12),
        _suggestionsGrid(),
        const SizedBox(height: 12),
      ]);
    }
    if (_requests.isEmpty && _suggestions.isEmpty) {
      out.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: EmptyState(message: 'No connection requests yet.'),
      ));
    }
    return out;
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  // 2-column grid of talent-style connect cards.
  Widget _suggestionsGrid() {
    return Column(
      children: [
        for (int i = 0; i < _suggestions.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: UserConnectCard(
                        profile: _suggestions[i], onChanged: _load),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: i + 1 < _suggestions.length
                        ? UserConnectCard(
                            profile: _suggestions[i + 1], onChanged: _load)
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _requestRow(ConnectionEdge r) {
    final p = r.other;
    final name = p.fullName.isNotEmpty ? p.fullName : 'You2Art User';
    final busy = _busy.contains(r.id);
    return GestureDetector(
      onTap: () => _openProfile(p),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEDEDED),
            backgroundImage: _img(p.avatarUrl),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  (p.category ?? '').isNotEmpty
                      ? p.category!
                      : 'wants to connect',
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            GestureDetector(
              onTap: () => _accept(r),
              behavior: HitTestBehavior.opaque,
              child: _actionCircle(
                  color: _checkBg,
                  child: const Icon(Icons.check, color: _green, size: 18)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _reject(r),
              behavior: HitTestBehavior.opaque,
              child: _actionCircle(
                  color: _xBg,
                  child: const Icon(Icons.close, color: _red, size: 18)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Connections tab ──────────────────────────────────────────────────
  List<Widget> _buildConnectionsTab() {
    if (_connections.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: EmptyState(message: 'You have no connections yet.'),
        ),
      ];
    }
    return [
      _fullBleedDivider(),
      for (final c in _connections) ...[
        _connectionRow(c),
        _fullBleedDivider(),
      ],
    ];
  }

  Widget _connectionRow(ConnectionEdge c) {
    final p = c.other;
    final name = p.fullName.isNotEmpty ? p.fullName : 'You2Art User';
    return GestureDetector(
      onTap: () => _openProfile(p),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFEDEDED),
              backgroundImage: _img(p.avatarUrl),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    (p.category ?? '').isNotEmpty ? p.category! : 'Connected',
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => openDirectChat(context, p),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF), shape: BoxShape.circle),
                child: const Icon(Icons.mail_outline, color: _blue, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCircle({required Color color, required Widget child}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }

  Widget _fullBleedDivider() {
    return SizedBox(
      height: 1,
      child: OverflowBox(
        maxWidth: MediaQuery.sizeOf(context).width,
        child: Container(height: 1, color: const Color(0xFFEFEFEF)),
      ),
    );
  }
}
