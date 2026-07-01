import 'package:flutter/material.dart';

/// Confirmation bottom-sheet for logging out. Returns `true` when the user
/// taps "Yes, Logout".
Future<bool?> showLogoutSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LogoutSheet(),
  );
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _cancelBg = Color(0xFFE6E9EE);
  static const Color _logoutBg = Color(0xFFFFD2D2);
  static const Color _logoutText = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ─────────────────────────────────────────
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header: title + close ───────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Logout?',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(Icons.close, size: 18, color: _textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Logging out will end your current session and require you to '
            'sign in again the next time you access the app.',
            style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 22),

          // ── Buttons ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cancelBg,
                      foregroundColor: _textPrimary,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _logoutBg,
                      foregroundColor: _logoutText,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Yes, Logout',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
