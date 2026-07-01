import 'dart:async';

import 'package:flutter/material.dart';

import 'data/models/profile.dart';
import 'data/models/talent.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/talent_repository.dart';
import 'production_house_page.dart';
import 'talent_profile_page.dart';
import 'widgets/empty_state.dart';
import 'widgets/user_connect_card.dart';

/// Talent feed — a 2-column grid of people you can connect with, loaded from
/// the `talents` table in Supabase.
///
/// Rendered as a [Scaffold]-less body so [HomePage] can swap it into its
/// IndexedStack without nesting scaffolds.
class TalentView extends StatefulWidget {
  const TalentView({super.key});

  @override
  State<TalentView> createState() => _TalentViewState();
}

class _TalentViewState extends State<TalentView> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _cardBg = Color(0xFFEAF4FF);
  static const Color _msgBtnBg = Color(0xFFDDEBFB);
  static const Color _border = Color(0xFFECECEC);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _idleIcon = Color(0xFF9AA0A6);

  final TalentRepository _repo = TalentRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  late Future<List<Talent>> _future;

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _searching = false;
  List<Profile> _results = const [];

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchTalents();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _repo.fetchTalents());

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    setState(() => _query = q);
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await _profileRepo.searchProfiles(q);
        if (!mounted || _query != q) return;
        setState(() {
          _results = res;
          _searching = false;
        });
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  // Real-user search results, shown in place of the talent grid while typing.
  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          EmptyState(message: 'No people found.'),
        ],
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          for (int i = 0; i < _results.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: UserConnectCard(profile:_results[i])),
                    const SizedBox(width: 14),
                    Expanded(
                      child: i + 1 < _results.length
                          ? UserConnectCard(profile:_results[i + 1])
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Talent',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                Image.asset(
                  'assets/images/bell_icon.png',
                  width: 26,
                  height: 26,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.notifications_outlined,
                    color: _blue,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Search bar (inline real-user search) ──────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 1.4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: _idleIcon, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      cursorColor: _blue,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Search people by name',
                        hintStyle:
                            TextStyle(color: _textSecondary, fontSize: 15),
                      ),
                      style: const TextStyle(
                          color: _textPrimary, fontSize: 15),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(Icons.close,
                          color: _idleIcon, size: 20),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Divider ───────────────────────────────────────────────
          const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),

          // ── Talent grid (2 columns) — or search results while typing ──
          Expanded(
            child: _query.isNotEmpty
                ? _buildSearchResults()
                : FutureBuilder<List<Talent>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final talents = snapshot.data ?? const <Talent>[];
                if (snapshot.hasError || talents.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(
                      children: const [
                        SizedBox(height: 60),
                        EmptyState(message: 'No talent to show yet.'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      children: [
                        for (int i = 0; i < talents.length; i += 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _cellFor(talents[i])),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: i + 1 < talents.length
                                        ? _cellFor(talents[i + 1])
                                        : const SizedBox(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cellFor(Talent t) {
    if (t.isProduction) {
      return _ProductionCard(
        name: t.name,
        role: t.role ?? '',
        photo: t.photo ?? '',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductionHousePage(name: t.name),
          ),
        ),
      );
    }
    return _TalentCard(talent: t);
  }
}

/// Network image when [photo] is a URL, otherwise a bundled asset.
Widget _circleImage(String? photo, double size, IconData fallback) {
  final p = photo ?? '';
  Widget err() => Container(
        width: size,
        height: size,
        color: Colors.white,
        child: Icon(fallback, color: const Color(0xFF8A8F98)),
      );
  return ClipOval(
    child: p.startsWith('http')
        ? Image.network(p,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => err())
        : Image.asset(p,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => err()),
  );
}

class _TalentCard extends StatelessWidget {
  const _TalentCard({required this.talent});

  final Talent talent;

  static const Color _cardBg = _TalentViewState._cardBg;
  static const Color _msgBtnBg = _TalentViewState._msgBtnBg;
  static const Color _textPrimary = _TalentViewState._textPrimary;
  static const Color _textSecondary = _TalentViewState._textSecondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TalentProfilePage(
            name: talent.name,
            role: talent.role ?? '',
            photo: talent.photo ?? 'assets/images/profile_pic.png',
          ),
        ),
      ),
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
            Center(child: _circleImage(talent.photo, 70, Icons.person)),
            const SizedBox(height: 10),
            Text(
              talent.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              talent.role ?? '',
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _msgBtnBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD9DDE3),
                        width: 1.4,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/mail_icon.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.mail_outline,
                          size: 16,
                          color: _TalentViewState._blue,
                        ),
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

class _ProductionCard extends StatefulWidget {
  const _ProductionCard({
    required this.name,
    required this.role,
    required this.photo,
    required this.onTap,
  });

  final String name;
  final String role;
  final String photo;
  final VoidCallback onTap;

  @override
  State<_ProductionCard> createState() => _ProductionCardState();
}

class _ProductionCardState extends State<_ProductionCard> {
  static const Color _cardBg = _TalentViewState._cardBg;
  static const Color _textPrimary = _TalentViewState._textPrimary;
  static const Color _textSecondary = _TalentViewState._textSecondary;

  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
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
            Center(child: _circleImage(widget.photo, 70, Icons.business)),
            const SizedBox(height: 10),
            Text(
              widget.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.role,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => setState(() => _isFollowing = !_isFollowing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.white : Colors.black,
                  foregroundColor: _isFollowing ? Colors.black : Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: const StadiumBorder(),
                  side: _isFollowing
                      ? const BorderSide(color: Color(0xFFCCCCCC), width: 1.2)
                      : BorderSide.none,
                ),
                child: Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
