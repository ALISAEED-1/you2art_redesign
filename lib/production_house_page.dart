import 'package:flutter/material.dart';

import 'options_sheet.dart';
import 'post_card.dart';

/// Public profile for a Production House.
/// Only shows a Follow button — no connection or message actions.
class ProductionHousePage extends StatefulWidget {
  const ProductionHousePage({
    super.key,
    this.name = 'FilmFare',
    this.photo = 'assets/images/production_face.png',
  });

  final String name;
  final String photo;

  @override
  State<ProductionHousePage> createState() => _ProductionHousePageState();
}

class _ProductionHousePageState extends State<ProductionHousePage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _green = Color(0xFFB7F0CD);
  static const Color _lightBlue = Color(0xFFD9EBFB);
  static const Color _border = Color(0xFFECECEC);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _idleIcon = Color(0xFF9AA0A6);

  int _tabIndex = 0; // 0 Activity · 1 About
  bool _isFollowing = false;

  static const Map<String, dynamic> _activityPost = {
    'name': 'FilmFare',
    'photo': 'assets/images/production_face.png',
    'time': '2 Days Ago',
    'body':
        'Guys! We have an announcement. We are going to launch Cast for our new upcoming short film soon.',
    'tags': '#Poster #Click #Nature',
    'image': 'assets/images/production_post.png',
    'likes': '141.2K',
    'comments': '14K',
    'shares': '14K',
  };

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
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: OptionsMenuButton(
              containerPadding: EdgeInsets.all(6),
              iconSize: 18,
              borderColor: Color(0xFFECECEC),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 4),
            _buildHero(),
            const SizedBox(height: 20),
            _buildStats(),
            const SizedBox(height: 16),
            _buildFollowButton(),
            const SizedBox(height: 24),
            _fullBleedDivider(),
            const SizedBox(height: 14),
            _buildTabs(),
            const SizedBox(height: 8),
            _fullBleedDivider(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PostCard(post: _activityPost),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Hero: avatar + name + type ───────────────────────────────────────
  Widget _buildHero() {
    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            widget.photo,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 90,
              height: 90,
              color: const Color(0xFFEDEDED),
              child: const Icon(Icons.business, size: 42, color: _idleIcon),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.name,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Production House',
          style: TextStyle(color: _textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ── Stats: Followers + Posts ─────────────────────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Row(
        children: [
          Expanded(
            child: _statPill(
              badgeColor: _green,
              asset: 'assets/images/fluent-group.png',
              fallbackIcon: Icons.people,
              iconColor: const Color(0xFF1F8A4D),
              label: 'Followers',
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
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
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
                  style:
                      const TextStyle(color: _textSecondary, fontSize: 11),
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

  // ── Follow button (toggles Following state) ──────────────────────────
  Widget _buildFollowButton() {
    if (!_isFollowing) {
      return Center(
        child: SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: () => setState(() => _isFollowing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 36),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Follow',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    // After following: Unfollow + Message side by side.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () => setState(() => _isFollowing = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: const StadiumBorder(),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Unfollow',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs: Activity / About ───────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tab(0, 'Activity', 'assets/images/activity_icon.png',
              Icons.grid_view_rounded),
          const SizedBox(width: 24),
          _tab(1, 'About', 'assets/images/about.png', Icons.info_outline),
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
