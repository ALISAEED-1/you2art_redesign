import 'package:flutter/material.dart';

import 'options_sheet.dart';

/// Detail page for a single applicant, opened from the Applications list.
class ApplicationDetailPage extends StatelessWidget {
  const ApplicationDetailPage({
    super.key,
    required this.projectTitle,
    required this.name,
    required this.photo,
    this.appliedAgo = '1 Day Ago',
    this.contactNumber = '+92 332 02522110',
    this.email = 'muhammadali@gmail.com',
    this.age = '23',
    this.height = '5.9 Feet',
    this.experience = '5 Years',
    this.location = 'Islamabad, Pakistan',
    this.note = 'Shoot will be of 30 days at the Centaurus Mall Islamabad.',
  });

  final String projectTitle;
  final String name;
  final String photo;
  final String appliedAgo;
  final String contactNumber;
  final String email;
  final String age;
  final String height;
  final String experience;
  final String location;
  final String note;

  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _summaryBg = Color(0xFFF4F5F7);
  static const Color _shareBg = Color(0xFFD9EBFB);
  static const Color _acceptBg = Color(0xFFBFF4D6);
  static const Color _acceptText = Color(0xFF1F8A4D);
  static const Color _rejectBg = Color(0xFFFFD9D9);
  static const Color _rejectText = Color(0xFFE53935);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _idleIcon = Color(0xFF9AA0A6);

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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Project Title',
                          style: TextStyle(color: _textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          projectTitle,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _authorCard(),
                  const SizedBox(height: 4),
                  _section('Contact Number', _value(contactNumber)),
                  _section('Email', _value(email)),
                  _section('Age', _value(age)),
                  _section('Height', _value(height)),
                  _section('Experience', _value(experience)),
                  _section(
                    'Location',
                    Row(
                      children: [
                        const Text('🇵🇰', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          location,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _section(
                    'Note',
                    Text(
                      note,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  // ── Author card (full-bleed grey band) ───────────────────────────────
  Widget _authorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: _summaryBg,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEDEDED),
            backgroundImage: AssetImage(photo),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                    children: [
                      const TextSpan(text: 'Applied, '),
                      TextSpan(
                        text: appliedAgo,
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }

  Widget _value(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── Bottom action bar ────────────────────────────────────────────────
  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Row(
        children: [
          // Wishlist circle
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _shareBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/wishlist_icon.png',
                width: 18,
                height: 18,
                color: _blue,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.bookmark_outline, color: _blue, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionPill(
              bg: _rejectBg,
              textColor: _rejectText,
              asset: 'assets/images/cancel_icon.png',
              fallbackIcon: Icons.cancel,
              label: 'Reject',
              iconTint: _rejectText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionPill(
              bg: _acceptBg,
              textColor: _acceptText,
              asset: 'assets/images/true_icon.png',
              fallbackIcon: Icons.check_circle,
              label: 'Accept',
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required Color bg,
    required Color textColor,
    required String asset,
    required IconData fallbackIcon,
    required String label,
    Color? iconTint,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textColor,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: 18,
              height: 18,
              color: iconTint,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, color: iconTint ?? textColor, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
