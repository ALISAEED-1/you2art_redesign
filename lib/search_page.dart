import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/models/profile.dart';
import 'data/repositories/profile_repository.dart';
import 'post_card.dart';
import 'production_house_page.dart';
import 'providers/post_provider.dart';
import 'user_profile_page.dart';
import 'widgets/empty_state.dart';

/// Full-screen search experience.
///
/// Opens when the user taps the search bar on the home page. Shows recent
/// searches — a mix of keyword searches (with a clock icon) and people
/// (with an avatar and "Connection" subtitle). Each entry can be dismissed.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _lightBlue = Color(0xFFEAF2FF);
  static const Color _border = Color(0xFFECECEC);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final ProfileRepository _profileRepo = ProfileRepository();

  Timer? _debounce;
  String _query = '';
  bool _searchingPeople = false;
  List<Profile> _people = const [];

  // Two entry kinds: a keyword (clock icon) or a person (avatar + subtitle).
  late final List<_RecentSearch> _recent = [
    const _RecentSearch.keyword('Don 3 Auditions'),
    const _RecentSearch.keyword('Ranveer Singh'),
    const _RecentSearch.person(
      'Muhammad Ali Nizami',
      'assets/images/ali_nizami (1).png',
    ),
    const _RecentSearch.person(
      'Yasir Hafeez',
      'assets/images/ali_nizami (2).png',
    ),
    const _RecentSearch.productionHouse(
      'FilmFare',
      'assets/images/production_face.png',
    ),
  ];

  bool get _hasQuery => _query.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field once the page is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
    _searchController.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final q = _searchController.text.trim();
    setState(() => _query = q);
    if (q.isEmpty) {
      setState(() {
        _people = const [];
        _searchingPeople = false;
      });
      return;
    }
    setState(() => _searchingPeople = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await _profileRepo.searchProfiles(q);
        if (!mounted || _searchController.text.trim() != q) return;
        setState(() {
          _people = res;
          _searchingPeople = false;
        });
      } catch (_) {
        if (mounted) setState(() => _searchingPeople = false);
      }
    });
  }

  void _useRecent(_RecentSearch entry) {
    if (entry.isProductionHouse) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductionHousePage(name: entry.title)),
      );
      return;
    }
    _searchController.text = entry.title;
    _searchController.selection =
        TextSelection.collapsed(offset: entry.title.length);
    _searchFocus.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search field ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
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
                    const Icon(Icons.search, color: _textSecondary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        cursorColor: Colors.black,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: _textSecondary,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            Expanded(child: _hasQuery ? _buildResults() : _buildRecent()),
          ],
        ),
      ),
    );
  }

  // Recent-search list with header.
  Widget _buildRecent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // See-All flow not built yet.
                },
                behavior: HitTestBehavior.opaque,
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _recent.length,
            itemBuilder: (_, i) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _recentRow(_recent[i]),
                ),
                const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Real search results — people (from profiles) + posts (from the feed).
  Widget _buildResults() {
    final q = _query.toLowerCase();
    final feed = context.watch<PostProvider>().feed;
    final posts = feed.where((p) {
      final hay = [p.authorName ?? '', p.body ?? '', p.tags ?? '']
          .join(' ')
          .toLowerCase();
      return hay.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        if (_people.isNotEmpty) ...[
          _sectionLabel('People'),
          ..._people.map(_personResult),
          const SizedBox(height: 10),
        ] else if (_searchingPeople)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (posts.isNotEmpty) ...[
          _sectionLabel('Posts'),
          for (final p in posts) ...[
            PostCard(post: p.toCardMap()),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _fullBleedDivider(),
            ),
          ],
        ],
        if (!_searchingPeople && _people.isEmpty && posts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: EmptyState(message: 'No results for "$_query".'),
          ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
            color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _personResult(Profile p) {
    final name = p.fullName.isNotEmpty ? p.fullName : 'You2Art User';
    final url = p.avatarUrl ?? '';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UserProfilePage(profile: p)),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEDEDED),
              backgroundImage: url.startsWith('http')
                  ? NetworkImage(url)
                  : const AssetImage('assets/images/profile_pic.png')
                      as ImageProvider,
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    (p.category ?? '').isNotEmpty
                        ? p.category!
                        : 'You2Art member',
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _fullBleedDivider() => SizedBox(
        height: 1,
        child: OverflowBox(
          maxWidth: MediaQuery.sizeOf(context).width,
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      );

  Widget _recentRow(_RecentSearch entry) {
    return GestureDetector(
      onTap: () => _useRecent(entry),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Leading icon: avatar for person/production house, clock for keyword.
            if (entry.isPerson || entry.isProductionHouse)
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEDEDED),
                backgroundImage: AssetImage(entry.avatar!),
                onBackgroundImageError: (_, __) {},
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: _blue, size: 20),
              ),
            const SizedBox(width: 12),

            // Title + subtitle.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.isPerson) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Connection',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ] else if (entry.isProductionHouse) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Production House',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing remove button.
            GestureDetector(
              onTap: () => setState(() => _recent.remove(entry)),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 1.2),
                ),
                child: const Icon(Icons.close, size: 14, color: _textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single recent-search entry: keyword, person, or production house.
class _RecentSearch {
  const _RecentSearch.keyword(this.title)
      : isPerson = false,
        isProductionHouse = false,
        avatar = null;

  const _RecentSearch.person(this.title, this.avatar)
      : isPerson = true,
        isProductionHouse = false;

  const _RecentSearch.productionHouse(this.title, this.avatar)
      : isPerson = false,
        isProductionHouse = true;

  final String title;
  final bool isPerson;
  final bool isProductionHouse;
  final String? avatar;
}
