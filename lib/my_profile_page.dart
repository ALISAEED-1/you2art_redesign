import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'authorization/complete_profile.dart';
import 'data/models/post.dart';
import 'data/models/profile_media.dart';
import 'data/repositories/media_repository.dart';
import 'data/repositories/post_repository.dart';
import 'options_sheet.dart';
import 'post_card.dart';
import 'providers/profile_provider.dart';
import 'widgets/empty_state.dart';
import 'widgets/media_carousel.dart';

/// "My Profile" — the current user's public-facing profile. Opens from the
/// Account page's "View Profile" link.
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _green = Color(0xFFB7F0CD);
  static const Color _lightBlue = Color(0xFFD9EBFB);
  static const Color _border = Color(0xFFECECEC);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _idleIcon = Color(0xFF9AA0A6);

  int _tabIndex = 0; // 0 Activity · 1 About · 2 My Work

  // Photo carousel state for the My Work tab.
  final PageController _photoCtrl = PageController(viewportFraction: 0.88);
  int _photoIndex = 0;

  final PostRepository _postRepo = PostRepository();
  late Future<List<Post>> _postsFuture;

  final MediaRepository _mediaRepo = MediaRepository();
  late Future<List<ProfileMedia>> _mediaFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postRepo.fetchMyPosts();
    _mediaFuture = _mediaRepo.fetchMyMedia();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadMyProfile();
    });
  }

  @override
  void dispose() {
    _photoCtrl.dispose();
    super.dispose();
  }

  void _openEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const CompleteProfileScreen(isEditing: true)),
    );
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OptionsMenuButton(
              containerPadding: const EdgeInsets.all(6),
              iconSize: 18,
              borderColor: const Color(0xFFECECEC),
              onEdit: _openEditProfile,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 4),
                _buildHero(),
                const SizedBox(height: 20),
                _buildStats(),
                const SizedBox(height: 22),
                const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                const SizedBox(height: 14),
                _buildTabs(),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                if (_tabIndex == 0) ..._buildActivity(),
                if (_tabIndex == 1) ..._buildAbout(),
                if (_tabIndex == 2) ..._buildMyWorkLive(),
                const SizedBox(height: 96),
              ],
            ),
            // ── Floating edit button ─────────────────────────────────
            Positioned(
              right: 20,
              bottom: 20,
              child: GestureDetector(
                onTap: _openEditProfile,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/edit_icon.png',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero: avatar + name + role ───────────────────────────────────────
  Widget _buildHero() {
    final profile = context.watch<ProfileProvider>().profile;
    final name =
        (profile?.fullName.isNotEmpty ?? false) ? profile!.fullName : 'Your Name';
    final role = (profile?.category?.trim().isNotEmpty ?? false)
        ? profile!.category!
        : 'Add your role';
    final avatarUrl = profile?.avatarUrl;
    final placeholder = Container(
      width: 90,
      height: 90,
      color: const Color(0xFFEDEDED),
      child: const Icon(Icons.person, size: 42, color: _idleIcon),
    );
    return Column(
      children: [
        Stack(
          children: [
            // Photo + thin grey ring (ring sits directly on the edge).
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD9DDE3),
                  width: 1.4,
                ),
              ),
              child: ClipOval(
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? Image.network(
                        avatarUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => placeholder,
                      )
                    : Image.asset(
                        'assets/images/profile_pic.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => placeholder,
                      ),
              ),
            ),
            // Verified blue tick.
            Positioned(
              right: 2,
              bottom: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: _blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          role,
          style: const TextStyle(color: _textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ── Stats: Connects + posts (equal width) ───────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Row(
        children: [
          Expanded(
            child: _statPill(
              badgeColor: _green,
              asset: 'assets/images/fluent-group.png',
              fallbackIcon: Icons.connect_without_contact,
              iconColor: const Color(0xFF1F8A4D),
              label: 'Connects',
              value: '124.7K',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statPill(
              badgeColor: _lightBlue,
              asset: 'assets/images/post_icon.png',
              fallbackIcon: Icons.dynamic_feed,
              iconColor: _blue,
              label: 'posts',
              value: '252',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill({
    required Color badgeColor,
    required String asset,
    required IconData fallbackIcon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                asset,
                width: 18,
                height: 18,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, color: iconColor, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs ─────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tab(0, 'Activity', 'assets/images/activity_icon.png',
              Icons.grid_view_rounded),
          const SizedBox(width: 24),
          _tab(1, 'About', 'assets/images/about.png', Icons.person_outline),
          const SizedBox(width: 24),
          _tab(2, 'My Work', 'assets/images/work_icon.png', Icons.work_outline),
        ],
      ),
    );
  }

  Widget _tab(int index, String label, String asset, IconData fallbackIcon) {
    final selected = _tabIndex == index;
    final textColor = selected ? _textPrimary : _textSecondary;
    final iconColor = selected ? _blue : _textSecondary;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Image.asset(
              asset,
              width: 16,
              height: 16,
              color: iconColor,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── About tab ────────────────────────────────────────────────────────
  List<Widget> _buildAbout() {
    final profile = context.watch<ProfileProvider>().profile;
    final bio = (profile?.bio?.trim().isNotEmpty ?? false)
        ? profile!.bio!
        : 'No bio added yet.';
    final location = [profile?.city, profile?.country]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .join(', ');
    return [
      const SizedBox(height: 6),
      _aboutSection(
        label: 'Bio',
        child: Text(
          bio,
          style: const TextStyle(color: _textPrimary, fontSize: 13, height: 1.45),
        ),
      ),
      _aboutSection(
        label: 'Personal Website',
        child: const Text(
          'www.be.net/WajahatUIUX',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      _aboutSection(
        label: 'Experience',
        child: const Text(
          '5+ Years',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      _aboutSection(
        label: 'Location',
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: _blue),
            const SizedBox(width: 8),
            Text(
              location.isNotEmpty ? location : 'Not set',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // Header for a My Work section: "Photos (N)" + Last Updated + edit / add.
  Widget _workHeader(String title, {required bool hasItems}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            if (hasItems) ...[
              const SizedBox(height: 2),
              const Text('Last Updated, Just Now',
                  style: TextStyle(color: _textSecondary, fontSize: 11)),
            ],
          ],
        ),
        Row(
          children: [
            if (hasItems) ...[
              GestureDetector(
                onTap: _openEditProfile,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                      color: Color(0xFFEBF3FF), shape: BoxShape.circle),
                  child: Image.asset(
                    'assets/images/edit_icon.png',
                    width: 16,
                    height: 16,
                    color: _blue,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.edit_outlined, size: 16, color: _blue),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: _openEditProfile,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(hasItems ? 7 : 9),
                decoration: const BoxDecoration(
                    color: Color(0xFFE6FDF9), shape: BoxShape.circle),
                child: Icon(Icons.add,
                    size: hasItems ? 18 : 22, color: const Color(0xFF2DD4BF)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── My Work tab (live from profile_media) ────────────────────────────
  List<Widget> _buildMyWorkLive() {
    return [
      FutureBuilder<List<ProfileMedia>>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final media = snapshot.data ?? const <ProfileMedia>[];
          final videos = media.where((m) => m.isVideo).toList();
          final photos = media.where((m) => !m.isVideo).toList();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _workHeader('Videos (${videos.length})',
                    hasItems: videos.isNotEmpty),
                const SizedBox(height: 12),
                if (videos.isEmpty)
                  const Text('No videos to show',
                      style: TextStyle(color: _textSecondary, fontSize: 13))
                else
                  MediaCarousel(items: videos),
                const SizedBox(height: 22),
                if (videos.isNotEmpty || photos.isNotEmpty)
                  const Divider(
                      color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                const SizedBox(height: 18),
                _workHeader('Photos (${photos.length})',
                    hasItems: photos.isNotEmpty),
                const SizedBox(height: 12),
                if (photos.isEmpty)
                  const Text('No photos to show',
                      style: TextStyle(color: _textSecondary, fontSize: 13))
                else
                  MediaCarousel(items: photos),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    ];
  }

  // ignore: unused_element
  Widget _liveVideoCard(ProfileMedia v) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: const BoxDecoration(
              color: Color(0xFFEDEDED),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
                child: Icon(Icons.play_circle_fill,
                    color: Colors.black54, size: 44)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.title ?? 'Video',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                if ((v.link ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(v.link!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF60A5FA), fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _livePhotoCard(ProfileMedia p) {
    final url = p.url ?? '';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: url.isNotEmpty
                ? Image.network(url,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: const Color(0xFFEDEDED),
                        child: const Icon(Icons.image,
                            color: _idleIcon, size: 40)))
                : Container(
                    height: 180,
                    color: const Color(0xFFEDEDED),
                    child: const Icon(Icons.image, color: _idleIcon, size: 40)),
          ),
          if ((p.title ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(p.title!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  // ── My Work tab (legacy sample — no longer used) ─────────────────────
  // ignore: unused_element
  List<Widget> _buildMyWork() {
    return [
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _sectionHeader(title: 'Videos (1)', subtitle: 'Last Updated, Just Now'),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _videoCard(
          asset: 'assets/images/video_1.png',
          title: "SPECIAL REPORT: What's the Trouble in Gilgit-Baltistan?",
          link: 'https://youtu.be/JKzRWuB4OfE',
          current: 1,
          total: 1,
        ),
      ),
      const SizedBox(height: 22),
      const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _sectionHeader(title: 'Photos (${_photos.length})', subtitle: 'Last Updated, 2 days ago'),
      ),
      const SizedBox(height: 12),
      _photoCarousel(),
      const SizedBox(height: 16),
    ];
  }

  static const List<Map<String, String>> _photos = [
    {
      'asset': 'assets/images/photo_1.jpg',
      'title': 'Short Film on Teen Age Side Hustles',
      'link': 'https://drive.google.com/u/1/d1c',
    },
    {
      'asset': 'assets/images/photo_2.jpg',
      'title': 'Behind the Scenes — Production Day 2',
      'link': 'https://drive.google.com/u/1/d2c',
    },
  ];

  Widget _photoCarousel() {
    return SizedBox(
      height: 340,
      child: PageView.builder(
        controller: _photoCtrl,
        itemCount: _photos.length,
        onPageChanged: (i) => setState(() => _photoIndex = i),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _photoCard(
            asset: _photos[i]['asset']!,
            title: _photos[i]['title']!,
            link: _photos[i]['link']!,
            current: i + 1,
            total: _photos.length,
          ),
        ),
      ),
    );
  }

  void _gotoPhoto(int delta) {
    final next = _photoIndex + delta;
    if (next < 0 || next >= _photos.length) return;
    _photoCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Widget _sectionHeader({required String title, required String subtitle}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFEBF3FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.edit_outlined, size: 20, color: _blue),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFE6FDF9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, size: 20, color: Color(0xFF2DD4BF)),
        ),
      ],
    );
  }

  Widget _videoCard({
    required String asset,
    required String title,
    required String link,
    required int current,
    required int total,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  asset,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFEDEDED),
                    child: const Icon(Icons.image, size: 40, color: _idleIcon),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.black87, size: 28),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Colors.black45,
                  child: const Text(
                    'YouTube',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _mediaCardFooter(
              title: title, link: link, current: current, total: total),
        ],
      ),
    );
  }

  Widget _photoCard({
    required String asset,
    required String title,
    required String link,
    required int current,
    required int total,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              asset,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                width: double.infinity,
                color: const Color(0xFFEDEDED),
                child: const Icon(Icons.image, size: 40, color: _idleIcon),
              ),
            ),
          ),
          _mediaCardFooter(
              title: title,
              link: link,
              current: current,
              total: total,
              isPhoto: true),
        ],
      ),
    );
  }

  Widget _mediaCardFooter({
    required String title,
    required String link,
    required int current,
    required int total,
    bool isPhoto = false,
  }) {
    final canBack = isPhoto && current > 1;
    final canForward = isPhoto && current < total;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            link,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sliderArrow(
                forward: false,
                enabled: canBack,
                onTap: canBack ? () => _gotoPhoto(-1) : null,
              ),
              Text(
                '$current of $total',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _sliderArrow(
                forward: true,
                enabled: canForward,
                onTap: canForward ? () => _gotoPhoto(1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sliderArrow({
    required bool forward,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    final color = enabled ? _blue : _textSecondary;
    final arrow = Image.asset(
      'assets/images/arrow_icon.png',
      width: 14,
      height: 14,
      color: color,
      errorBuilder: (_, __, ___) => Icon(
        forward ? Icons.arrow_forward : Icons.arrow_back,
        size: 14,
        color: color,
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6E9EE), width: 1.2),
          shape: BoxShape.circle,
        ),
        child: forward
            ? arrow
            : Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(3.14159),
                child: arrow,
              ),
      ),
    );
  }

  Widget _aboutSection({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  // ── Activity feed ────────────────────────────────────────────────────
  List<Widget> _buildActivity() {
    return [
      FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final posts = snapshot.data ?? const <Post>[];
          if (posts.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(message: 'No posts yet.'),
            );
          }
          return Column(
            children: [
              for (final p in posts) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PostCard(post: p.toCardMap()),
                ),
                const SizedBox(height: 16),
                const Divider(
                    color: Color(0xFFEFEFEF), thickness: 1, height: 1),
              ],
            ],
          );
        },
      ),
    ];
  }
}
