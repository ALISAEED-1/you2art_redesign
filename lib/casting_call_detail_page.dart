import 'package:flutter/material.dart';

import 'data/models/casting_call.dart';
import 'casting_apply_page.dart';

/// Detail page shown when a casting call card is tapped.
class CastingCallDetailPage extends StatelessWidget {
  const CastingCallDetailPage({super.key, required this.call});

  final CastingCall call;

  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _authorCardBg = Color(0xFFF4F5F7);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  ImageProvider _img(String path) =>
      path.startsWith('http') ? NetworkImage(path) : AssetImage(path);

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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Project Title'),
                        const SizedBox(height: 4),
                        Text(
                          call.projectTitle,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _authorCard(),
                      ],
                    ),
                  ),
                  if ((call.shortDescription ?? '').isNotEmpty)
                    _section(
                      'Description',
                      Text(
                        call.shortDescription!,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  _section(
                    'Location',
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: _blue),
                        const SizedBox(width: 8),
                        Text(
                          call.locationFull ?? call.locationLabel,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((call.crewRequired ?? '').isNotEmpty)
                    _section('Crew Required', _value(call.crewRequired!),
                        divider: true),
                  if ((call.shootDetails ?? '').isNotEmpty)
                    _section(
                      'Shoot Details',
                      Text(
                        call.shootDetails!,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  if ((call.budgetFull ?? call.budget ?? '').isNotEmpty)
                    _section('Budget',
                        _value(call.budgetFull ?? call.budget!),
                        divider: true),
                  if ((call.position ?? '').isNotEmpty)
                    _section('Position', _value(call.position!), divider: true),
                  if ((call.age ?? '').isNotEmpty)
                    _section('Age', _value(call.age!)),
                  if ((call.height ?? '').isNotEmpty)
                    _section('Height', _value(call.height!)),
                  if ((call.gender ?? '').isNotEmpty)
                    _section('Gender', _value(call.gender!)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // ── Bottom action ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (call.appliedByMe || call.isMine)
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CastingApplyPage(call: call),
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: call.isMine
                        ? const Color(0xFF8A8F98)
                        : const Color(0xFF1F8A4D),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    call.isMine
                        ? 'Your Casting Call'
                        : call.appliedByMe
                            ? 'Already Applied'
                            : 'Apply Now',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(color: _textSecondary, fontSize: 12),
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

  Widget _authorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _authorCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEDEDED),
            backgroundImage: _img(call.ownerPhoto),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.ownerName,
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
                      const TextSpan(text: 'Published on '),
                      TextSpan(
                        text: call.publishedDate ?? 'recently',
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

  Widget _section(String label, Widget value, {bool divider = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (divider)
          const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(label),
              const SizedBox(height: 4),
              value,
            ],
          ),
        ),
      ],
    );
  }
}
