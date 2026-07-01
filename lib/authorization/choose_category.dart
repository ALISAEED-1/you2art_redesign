import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:you2art_redesign/authorization/complete_profile.dart';

import '../home_page.dart';
import '../providers/profile_provider.dart';

/// "Choose Category" screen — user picks the role/profession they belong to.
///
/// UI only for now. Selection isn't persisted anywhere yet; the Supabase
/// backend hookup happens later.
class ChooseCategoryScreen extends StatefulWidget {
  const ChooseCategoryScreen({super.key});

  @override
  State<ChooseCategoryScreen> createState() => _ChooseCategoryScreenState();
}

class _ChooseCategoryScreenState extends State<ChooseCategoryScreen> {
  // ── Theme colors (kept consistent with the login/verify screens) ──
  static const Color _textPrimary = Color(0xFF000000);
  static const Color _borderColor = Color(0xFFE8E8E8);
  static const Color _accentBlue = Color(0xFF3399FF);
  static const Color _skipBorderColor = Color(0xFFE2E2E2);
  static const Color _skipTextColor = Color(0xFF484C52);

  // Categories laid out as two columns (left, right) to mirror the design.
  static const List<String> _leftColumn = [
    'Production House',
    'Actor',
    'Musician',
    'Choreographer',
    'Cinematographer',
    'Sound Mixing',
    'Producer',
    'Art Director',
    'Makeup Artist',
    'Anchor',
    'Writer',
  ];

  static const List<String> _rightColumn = [
    'Director',
    'Singer',
    'Dancer',
    'Editor',
    'Still Photographer',
    'VFX',
    'Stunt Director',
    'Dubbing Artist',
    'Costume Designer',
    'Standup Comedian',
  ];

  String? _selected;

  Future<void> _saveAndNext() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a category.')),
      );
      return;
    }
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveCategory(_selected!);
    if (!mounted) return;
    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save category.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.06;
    final saving = context.watch<ProfileProvider>().saving;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ───────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, size.height * 0.03, hPad, 0),
              child: Text(
                'Choose Category',
                style: TextStyle(
                  fontSize: size.width * 0.075,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.025),

            // ── Two-column scrollable list of categories ────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: _leftColumn
                            .map((c) => _CategoryTile(
                                  label: c,
                                  selected: _selected == c,
                                  onTap: () => setState(() => _selected = c),
                                  size: size,
                                ))
                            .toList(),
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: Column(
                        children: _rightColumn
                            .map((c) => _CategoryTile(
                                  label: c,
                                  selected: _selected == c,
                                  onTap: () => setState(() => _selected = c),
                                  size: size,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Full-width divider ───────────────────────────────────
            const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),

            // ── Bottom action buttons ───────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                size.height * 0.015,
                hPad,
                size.height * 0.025,
              ),
              child: Row(
                children: [
                  // Skip For Now (outlined)
                  Expanded(
                    child: SizedBox(
                      height: size.height * 0.06,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomePage()),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _skipTextColor,
                          backgroundColor: _skipBorderColor,
                          side: const BorderSide(color: _skipBorderColor, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Skip For Now',
                          style: TextStyle(
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.04),
                  // Save and Next (filled)
                  Expanded(
                    child: SizedBox(
                      height: size.height * 0.06,
                      child: ElevatedButton(
                        onPressed: saving ? null : _saveAndNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.black54,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save and Next',
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
      ),
    );
  }
}

/// A single selectable category row: circular radio indicator + label.
class _CategoryTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Size size;

  const _CategoryTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.size,
  });

  // Shared accent so the selected ring matches the design's blue.
  static const Color _accentBlue = _ChooseCategoryScreenState._accentBlue;
  static const Color _borderColor = _ChooseCategoryScreenState._borderColor;
  static const Color _textPrimary = _ChooseCategoryScreenState._textPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: size.height * 0.005),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.03,
          vertical: size.height * 0.012,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF399AF3) : _borderColor,
            width: selected ? 1.8 : 1.2,
          ),
          color: selected ? const Color(0xFFEAF4FF) : Colors.white,
        ),
        child: Row(
          children: [
            // Custom radio indicator — blue ring only when selected, no inner dot.
            Container(
              width: size.width * 0.045,
              height: size.width * 0.045,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF399AF3) : const Color(0xFF000000),
                  width: selected ? 5.5 : 1.6,
                ),
                color: Colors.white,
              ),
            ),
            SizedBox(width: size.width * 0.02),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: size.width * 0.033,
                  color: _textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
