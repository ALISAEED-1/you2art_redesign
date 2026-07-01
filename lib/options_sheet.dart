import 'package:flutter/material.dart';

/// A circular 3-dot button that shows a positioned Share / Hide / Report popup.
///
/// Drop this in wherever a more_vert icon currently appears. Pass [size] and
/// [iconSize] for explicit-sized buttons (most rows), or [containerPadding]
/// for padding-based buttons (AppBar actions, post-card header).
///
/// When [onEdit] is provided, the middle "Hide" item is replaced with a blue
/// "Edit" action (used on the profile pages to jump to Complete Profile).
class OptionsMenuButton extends StatelessWidget {
  const OptionsMenuButton({
    super.key,
    this.size = 32.0,
    this.iconSize = 16.0,
    this.containerPadding,
    this.bgColor = Colors.white,
    this.borderColor = const Color(0xFFD9DDE3),
    this.onEdit,
  });

  final double size;
  final double iconSize;
  final EdgeInsetsGeometry? containerPadding;
  final Color bgColor;
  final Color borderColor;

  /// When set, replaces "Hide" with a blue "Edit" action that calls this.
  final VoidCallback? onEdit;

  static const Color _idleIcon = Color(0xFF9AA0A6);
  static const Color _blue = Color(0xFF2F80ED);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      onSelected: (value) {
        if (value == 1 && onEdit != null) onEdit!();
      },
      itemBuilder: (_) => [
        _item(0, 'assets/images/share_list.png', Icons.share_outlined, 'Share',
            _blue),
        if (onEdit != null)
          _item(1, 'assets/images/edit_icon.png', Icons.edit, 'Edit', _blue,
              imageTint: _blue)
        else
          _item(1, 'assets/images/hide_icon.png',
              Icons.visibility_off_outlined, 'Hide', const Color(0xFF1A1A1A)),
        _item(2, 'assets/images/symbols.png', Icons.flag_outlined, 'Report',
            const Color(0xFFE53935)),
      ],
      child: Container(
        width: containerPadding != null ? null : size,
        height: containerPadding != null ? null : size,
        padding: containerPadding,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Center(
          child: Icon(Icons.more_vert, color: _idleIcon, size: iconSize),
        ),
      ),
    );
  }

  PopupMenuItem<int> _item(
    int value,
    String asset,
    IconData fallback,
    String label,
    Color iconColor, {
    Color? imageTint,
  }) {
    return PopupMenuItem<int>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            asset,
            width: 18,
            height: 18,
            color: imageTint,
            errorBuilder: (_, __, ___) =>
                Icon(fallback, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
