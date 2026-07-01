import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'data/models/post.dart';
import 'data/repositories/dm_repository.dart';
import 'data/repositories/misc_repository.dart';
import 'providers/post_provider.dart';
import 'providers/profile_provider.dart';
import 'widgets/empty_state.dart';
import 'account_page.dart';
import 'casting_calls_page.dart';
import 'chat_page.dart';
import 'create_post_page.dart';
import 'home_tab.dart';
import 'network_page.dart';
import 'notifications_page.dart';
import 'post_card.dart';
import 'search_page.dart';
import 'talent_page.dart';

/// Main home feed shown after the profile is completed.
///
/// UI only for now — posts are static sample data. The Supabase hookup
/// (fetching the feed, posting, reactions) happens later.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _lightBlue = Color(0xFFEAF2FF);
  static const Color _lightOrange = Color(0xFFFFEFE0);
  static const Color _orange = Color(0xFFF2994A);
  static const Color _idleIcon = Color(0xFF9AA0A6);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _border = Color(0xFFECECEC);

  final MiscRepository _miscRepo = MiscRepository();
  int _unreadNotifs = 0;
  RealtimeChannel? _notifChannel;

  final DmRepository _dmRepo = DmRepository();
  int _unreadChats = 0;
  RealtimeChannel? _dmChannel;

  int get _navIndex => HomeTab.index.value;

  @override
  void initState() {
    super.initState();
    // Home is pre-selected to match the design.
    HomeTab.index.value = HomeTab.home;
    HomeTab.index.addListener(_onTabChanged);
    _subscribeNotifications();
    _dmChannel = _dmRepo.subscribeInbox(_onChatChanged, channel: 'home_dm_inbox');
    ChatRefresh.tick.addListener(_onChatChanged);
    _loadUnreadChats();
    // Pull the signed-in user's profile so the greeting / account screens
    // can show real data instead of placeholders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().loadMyProfile();
      context.read<PostProvider>().loadFeed();
      _loadUnread();
    });
  }

  void _onChatChanged() {
    if (mounted) _loadUnreadChats();
  }

  // Total unread direct messages → the Chat tab badge.
  Future<void> _loadUnreadChats() async {
    try {
      final threads = await _dmRepo.fetchThreads();
      final total = threads.fold<int>(0, (sum, t) => sum + t.unread);
      if (mounted) setState(() => _unreadChats = total);
    } catch (_) {}
  }

  // Live-update the bell badge when a new notification lands for me.
  void _subscribeNotifications() {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) return;
    final ch = SupabaseConfig.client.channel('home_notifs');
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) {
            if (mounted) _loadUnread();
          },
        )
        .subscribe();
    _notifChannel = ch;
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    HomeTab.index.removeListener(_onTabChanged);
    ChatRefresh.tick.removeListener(_onChatChanged);
    if (_notifChannel != null) {
      SupabaseConfig.client.removeChannel(_notifChannel!);
    }
    if (_dmChannel != null) _dmRepo.unsubscribe(_dmChannel!);
    super.dispose();
  }

  Future<void> _loadUnread() async {
    final count = await _miscRepo.unreadNotificationCount();
    if (mounted) setState(() => _unreadNotifs = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _navIndex,
        children: [
          const TalentView(),                  // 0 — Talent
          const NetworkView(),                 // 1 — Network
          const ChatView(),                    // 2 — Chat
          _buildHomeFeed(),                    // 3 — Home
          const CastingCallsView(),            // 4 — Casting
          const AccountView(),                 // 5 — Account
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeFeed() {
    final postProvider = context.watch<PostProvider>();
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => context.read<PostProvider>().loadFeed(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildSearchBar(),
            const SizedBox(height: 18),
            _buildComposer(),
            _sectionDivider(),
            ..._buildFeedItems(postProvider),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeedItems(PostProvider provider) {
    if (provider.loading && provider.feed.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (provider.feed.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: EmptyState(
            message: 'No posts yet.\nBe the first to share something!',
          ),
        ),
      ];
    }
    final out = <Widget>[];
    for (final Post post in provider.feed) {
      out.add(PostCard(post: post.toCardMap()));
      out.add(_divider());
    }
    return out;
  }


  // Stretches [child] to the full screen width, breaking out of the
  // ListView's horizontal padding so it spans edge to edge.
  Widget _fullWidth({required double height, required Widget child}) => SizedBox(
        height: height,
        child: OverflowBox(
          maxWidth: MediaQuery.sizeOf(context).width,
          child: child,
        ),
      );

  // Thick, full-bleed band that separates the composer from the feed.
  Widget _sectionDivider() => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        child: _fullWidth(
          height: 7,
          child: Container(height: 7, color: const Color(0xFFEDEDED)),
        ),
      );

  // Thin, light, full-bleed separator used between each post.
  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: _fullWidth(
          height: 0.8,
          child: Container(height: 0.8, color: const Color(0xFFEDEDED)),
        ),
      );

  // ── Header: greeting + notification bell ─────────────────────────────
  Widget _buildHeader() {
    final firstName = context.watch<ProfileProvider>().profile?.firstName;
    final greeting = (firstName != null && firstName.trim().isNotEmpty)
        ? 'Hi ${firstName.trim()}!'
        : 'Hi there!';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
            if (mounted) _loadUnread();
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                'assets/images/bell_icon.png',
                width: 26,
                height: 26,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.notifications_outlined,
                    color: _blue,
                    size: 26),
              ),
              if (_unreadNotifs > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _unreadNotifs > 9 ? '9+' : '$_unreadNotifs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Search bar — opens the full search screen ───────────────────────
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SearchPage()),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 1.4),
        ),
        child: Row(
          children: const [
            Icon(Icons.search, color: _idleIcon, size: 22),
            SizedBox(width: 10),
            Text(
              'Search',
              style: TextStyle(color: _textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ── Composer: avatar + prompt + Photo / Text chips ───────────────────
  Widget _buildComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openCreatePost(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              _avatar(radius: 18),
              const SizedBox(width: 12),
              const Text(
                'Have something to share?',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _composerChip(
              asset: 'assets/images/photos_icon.png',
              fallbackIcon: Icons.image_outlined,
              label: 'Photo',
              boxColor: _lightBlue,
              tint: _blue,
              onTap: () => _openCreatePost(pickImageOnStart: true),
            ),
            const SizedBox(width: 12),
            _composerChip(
              asset: 'assets/images/text_icon.png',
              fallbackIcon: Icons.text_fields,
              label: 'Text',
              boxColor: _lightOrange,
              tint: _orange,
              onTap: () => _openCreatePost(),
            ),
          ],
        ),
      ],
    );
  }

  void _openCreatePost({bool pickImageOnStart = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePostPage(pickImageOnStart: pickImageOnStart),
      ),
    );
  }

  Widget _composerChip({
    required String asset,
    required IconData fallbackIcon,
    required String label,
    required Color boxColor,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: 18,
              height: 18,
              color: tint,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, size: 18, color: tint),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar({required double radius}) {
    final url = context.watch<ProfileProvider>().profile?.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEDEDED),
      backgroundImage: (url != null && url.isNotEmpty)
          ? NetworkImage(url)
          : const AssetImage('assets/images/profile_pic.png') as ImageProvider,
      onBackgroundImageError: (_, __) {},
    );
  }

  // ── Bottom navigation ────────────────────────────────────────────────
  static const List<Map<String, String>> _navItems = [
    {'asset': 'assets/images/group_icon.png', 'label': 'Talent'},
    {'asset': 'assets/images/network_icon.png', 'label': 'Network'},
    {'asset': 'assets/images/massage_icon.png', 'label': 'Chat'},
    {'asset': 'assets/images/home_icon.png', 'label': 'Home'},
    {'asset': 'assets/images/star_icon.png', 'label': 'Casting'},
    {'asset': 'assets/images/profile_icon.png', 'label': 'Account'},
  ];

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < _navItems.length; i++)
                _NavItem(
                  asset: _navItems[i]['asset']!,
                  label: _navItems[i]['label']!,
                  selected: _navIndex == i,
                  badgeCount: i == HomeTab.chat ? _unreadChats : 0,
                  onTap: () => HomeTab.go(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single bottom-nav item. Idle: grey icon only. Selected: animates to a
/// blue pill that expands to reveal the label.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  static const Color _blue = Color(0xFF2F80ED);
  static const Color _lightBlue = Color(0xFFEAF2FF);
  static const Color _idleIcon = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _blue : _idleIcon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 16 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? _lightBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  asset,
                  width: 22,
                  height: 22,
                  color: color,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.circle_outlined, size: 22, color: color),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: _lightBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: _blue,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: _blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
