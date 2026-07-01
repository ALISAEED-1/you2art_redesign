import 'package:flutter/material.dart';

/// Bottom-sheet style confirmation shown after the profile is created.
///
/// This is the final step before the home page. It mirrors the
/// "Account Created" sheet (green check badge + confirmation copy) but uses a
/// single full-width "Proceed to Home" action.
///
/// [name] personalises the subtitle (e.g. the user's first name). [onProceed]
/// runs when the user taps "Proceed to Home" — wire it to the home route once
/// that screen exists.
Future<void> showProfileCompleteSheet(
  BuildContext context, {
  String? name,
  VoidCallback? onProceed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProfileCompleteSheet(name: name, onProceed: onProceed),
  );
}

class _ProfileCompleteSheet extends StatelessWidget {
  const _ProfileCompleteSheet({this.name, this.onProceed});

  final String? name;
  final VoidCallback? onProceed;

  static const Color _textPrimary = Color(0xFF000000);
  static const Color _textSecondary = Color(0xFF7A7A7A);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.06;

    // Personalised greeting — falls back gracefully when no name is supplied.
    final greetName = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()
        : 'there';

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
            child: Image.asset(
              'assets/images/tick.png',
              width: 250,
              height: 200,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 56),
              ),
            ),
          ),

          // ── Title ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Text(
              'Profile Complete',
              style: TextStyle(
                fontSize: size.width * 0.055,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.012),

          // ── Subtitle (name highlighted) ─────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: size.width * 0.032,
                  color: _textSecondary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Thanks '),
                  TextSpan(
                    text: greetName,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '! for completing your profile.'),
                ],
              ),
            ),
          ),
          SizedBox(height: size.height * 0.025),

          // ── Full-width divider ───────────────────────────────────
          const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),
          SizedBox(height: size.height * 0.025),

          // ── Action button ───────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: SizedBox(
              width: double.infinity,
              height: size.height * 0.06,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onProceed?.call();
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
                  'Proceed to Home',
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
    );
  }
}
