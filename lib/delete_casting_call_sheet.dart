import 'package:flutter/material.dart';

/// Confirmation bottom-sheet shown before deleting one of the user's own
/// casting calls. Returns `true` when the user confirms the deletion.
Future<bool?> showDeleteCastingCallSheet(
  BuildContext context, {
  required Map<String, String> call,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DeleteCastingCallSheet(call: call),
  );
}

class _DeleteCastingCallSheet extends StatelessWidget {
  const _DeleteCastingCallSheet({required this.call});

  final Map<String, String> call;

  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _summaryBg = Color(0xFFF4F5F7);
  static const Color _cancelBg = Color(0xFFE6E9EE);
  static const Color _deleteBg = Color(0xFFFFD2D2);
  static const Color _deleteText = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ─────────────────────────────────────────
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title + close ───────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Delete Casting Call',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(Icons.close, size: 16, color: _textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Subtitle ────────────────────────────────────────────
          const Text(
            'Are you sure, you want to delete this casting call?',
            style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),

          // ── Summary card ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _summaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call['title'] ?? 'The Next Short Film',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  call['published'] ?? 'Published, 2 Days Ago',
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _stat('Location', call['location'] ?? 'Islamabad')),
                    Expanded(child: _stat('Type', call['type'] ?? 'Short Film')),
                    Expanded(child: _stat('Shoot', call['shoot'] ?? '25 Days')),
                    Expanded(child: _stat('Budget', call['budget'] ?? '\$20K')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Disclaimer ──────────────────────────────────────────
          // Indented by the summary card's inner padding (14) so the line
          // starts under "Location" rather than the card's left edge.
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text(
              'Deleting a casting call is an irreversible action and will '
              'remove all associated information and submissions.',
              style: TextStyle(color: _textSecondary, fontSize: 12, height: 1.45),
            ),
          ),
          SizedBox(height: size.height * 0.025),

          // ── Cancel / Yes, Delete ───────────────────────────────
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
                      backgroundColor: _deleteBg,
                      foregroundColor: _deleteText,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Yes, Delete',
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

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
