import 'package:flutter/material.dart';

import 'choose_category.dart';

/// Bottom-sheet style confirmation shown after a successful OTP verification.
///
/// Mirrors the "Account Created" card in the design: a green check badge,
/// confirmation copy, and two actions — Skip For Now / Create Profile.
Future<void> showAccountCreatedSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AccountCreatedSheet(),

  );
}

class _AccountCreatedSheet extends StatelessWidget {
  const _AccountCreatedSheet();

  static const Color _textPrimary = Color(0xFF000000);
  static const Color _textSecondary = Color(0xFF7A7A7A);
  static const Color _borderColor = Color(0xFFE8E8E8);
  static const Color _green = Color(0xFF2ECC71);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.06;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: size.height * 0.015,
        bottom: size.height * 0.035 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Close button ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFDDDDDD), width: 1.2),
                  ),
                  child: const Icon(Icons.close, color: _textSecondary, size: 18),
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.01),

          // ── Green check badge ───────────────────────────────────
          Center(
            child: Image.asset("assets/images/tick.png", width: 250, height: 200),
          ),

          // ── Title ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Text(
              'Account Created',
              style: TextStyle(
                fontSize: size.width * 0.055,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.012),

          // ── Subtitle ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Text(
              'Congratulations! Your account has been created.\n'
              'Start exploring talent and post casting calls.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width * 0.032,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.035),

          // ── Full-width divider ───────────────────────────────────
          const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),
          SizedBox(height: size.height * 0.025),

          // ── Action buttons ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: size.height * 0.06,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xffE2E2E2),
                        side: const BorderSide(color: _borderColor, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Skip For Now',
                        style: TextStyle(
                          color: const Color(0xff484C52),
                          fontSize: size.width * 0.038,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.04),
                Expanded(
                  child: SizedBox(
                    height: size.height * 0.06,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChooseCategoryScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Create Profile',
                        style: TextStyle(
                          fontSize: size.width * 0.038,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
