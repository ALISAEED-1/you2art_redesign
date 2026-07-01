import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'authorization/login.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'about_us_sheet.dart';
import 'logout_sheet.dart';
import 'my_profile_page.dart';
import 'privacy_policy_sheet.dart';
import 'support_page.dart';
import 'terms_and_conditions_sheet.dart';
import 'transaction_history_page.dart';

/// "My Account" tab — profile summary + settings links.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _red = Color(0xFFE53935);
  static const Color _summaryBg = Color(0xFFF4F5F7);
  static const Color _menuIcon = Color(0xFFB9C0C9);
  static const Color _textPrimary = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'My Account',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _profileCard(context),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
          _menuItem(
            asset: 'assets/images/verify.png',
            fallback: Icons.verified_user_outlined,
            label: 'Verify Account',
            onTap: () {},
          ),
          _menuItem(
            asset: 'assets/images/transaction.png',
            fallback: Icons.swap_horiz,
            label: 'Transaction History',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransactionHistoryPage(),
              ),
            ),
          ),
          _menuItem(
            asset: 'assets/images/support.png',
            fallback: Icons.support_agent,
            label: 'Support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SupportPage()),
            ),
          ),
          _menuItem(
            icon: Icons.info_outline,
            label: 'About us',
            onTap: () => showAboutUsSheet(context),
          ),
          _menuItem(
            asset: 'assets/images/terms.png',
            fallback: Icons.description_outlined,
            label: 'Terms & Conditions',
            onTap: () => showTermsAndConditionsSheet(context),
          ),
          _menuItem(
            icon: Icons.shield_outlined,
            label: 'Privacy Policy',
            onTap: () => showPrivacyPolicySheet(context),
          ),
          _menuItem(
            asset: 'assets/images/logout.png',
            fallback: Icons.logout,
            label: 'Logout',
            destructive: true,
            onTap: () async {
              final confirmed = await showLogoutSheet(context);
              if (confirmed != true || !context.mounted) return;
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              context.read<ProfileProvider>().clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Profile summary card (full-bleed grey band) ──────────────────────
  Widget _profileCard(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final name =
        (profile?.fullName.isNotEmpty ?? false) ? profile!.fullName : 'Your Name';
    final avatarUrl = profile?.avatarUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      color: _summaryBg,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEDEDED),
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : const AssetImage('assets/images/profile_pic.png')
                        as ImageProvider,
                onBackgroundImageError: (_, __) {},
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: _summaryBg, width: 2),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Account Verified',
                  style: TextStyle(
                    color: Color(0xFF008F5C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyProfilePage()),
            ),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'View Profile',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                _ArrowIcon(size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu row + full-width bottom divider ─────────────────────────────
  Widget _menuItem({
    String? asset,
    IconData? icon,
    IconData? fallback,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final textColor = destructive ? _red : _textPrimary;
    final iconColor = destructive ? _red : _menuIcon;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                if (asset != null)
                  Image.asset(
                    asset,
                    width: 22,
                    height: 22,
                    color: iconColor,
                    errorBuilder: (_, __, ___) =>
                        Icon(fallback ?? Icons.circle, color: iconColor, size: 22),
                  )
                else
                  Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!destructive) const _ArrowIcon(size: 18),
              ],
            ),
          ),
        ),
        const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
      ],
    );
  }
}

/// Shared arrow icon — uses `arrow_icon.png` (tinted blue) with a Material
/// fallback if the asset ever fails.
class _ArrowIcon extends StatelessWidget {
  const _ArrowIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/arrow_icon.png',
      width: size,
      height: size,
      color: AccountView._blue,
      errorBuilder: (_, __, ___) => Icon(
        Icons.arrow_forward,
        color: AccountView._blue,
        size: size,
      ),
    );
  }
}
