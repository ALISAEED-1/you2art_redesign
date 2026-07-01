import 'package:flutter/material.dart';

/// Bottom sheet describing the You2Art mission and offering.
///
/// Opens from the Account page's "About us" row.
Future<void> showAboutUsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AboutUsSheet(),
  );
}

class _AboutUsSheet extends StatelessWidget {
  const _AboutUsSheet();

  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 18),
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header: title + close ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'About us',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
              ),

              // ── Full-bleed divider ──────────────────────────────────
              SizedBox(
                height: 1,
                child: OverflowBox(
                  maxWidth: MediaQuery.sizeOf(context).width,
                  child: Container(height: 1, color: const Color(0xFFEFEFEF)),
                ),
              ),

              // ── Scrollable body ─────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                  children: const [
                    _SectionHeading('Our Vision'),
                    SizedBox(height: 6),
                    _Paragraph(
                      'At You2Art, we believe that art has the power to '
                      'inspire, provoke thought, and foster connections that '
                      'transcend boundaries. Our vision is to create an '
                      'inclusive community where artists of all backgrounds '
                      'and disciplines can showcase their creations, receive '
                      'recognition, and find inspiration in the work of '
                      'others.',
                    ),
                    SizedBox(height: 18),
                    _SectionHeading('Who We Are'),
                    SizedBox(height: 6),
                    _Paragraph(
                      'We are a team of artists, technologists, and dreamers '
                      'who are passionate about nurturing a thriving '
                      'artistic ecosystem. Our diverse backgrounds allow us '
                      'to blend creativity with innovation, ensuring that '
                      'the You2Art app is a place where imagination knows no '
                      'limits.',
                    ),
                    SizedBox(height: 18),
                    _SectionHeading('What We Offer'),
                    SizedBox(height: 6),
                    _Paragraph(
                      'Through the You2Art app, you can explore a diverse '
                      'spectrum of art forms — from mesmerizing paintings '
                      'and captivating photographs to exhilarating '
                      'performances and soul-stirring poetry. Connect with '
                      'like-minded individuals who share your passion, '
                      'engage in conversations that spark creativity, and '
                      'discover hidden gems from emerging talents.',
                    ),
                    SizedBox(height: 18),
                    _SectionHeading('Empowerment Through Connection'),
                    SizedBox(height: 6),
                    _Paragraph(
                      'We believe that art thrives in an environment of '
                      'collaboration and shared experiences. With You2Art, '
                      'you can connect with fellow artists, exchange ideas, '
                      "and support each other's artistic journeys. Whether "
                      "you're a seasoned creator or someone just dipping "
                      'their toes into the world of art, our community '
                      'welcomes you.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _AboutUsSheet._textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _AboutUsSheet._textPrimary,
        fontSize: 13.5,
        height: 1.55,
      ),
    );
  }
}
