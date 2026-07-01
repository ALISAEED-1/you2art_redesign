import 'package:flutter/material.dart';

/// One key on the dial pad: the value emitted on tap + an optional caption
/// (the small "ABC" letters under the digit).
class _KeySpec {
  final String value;
  final String? letters;
  const _KeySpec(this.value, [this.letters]);
}

/// Polished iOS-style numeric keypad shared by the Login and Verify screens.
///
/// Emits the tapped value via [onKeyTap]: digits '0'–'9', '+*#' for the
/// bottom-left key, and 'back' for backspace. (Plain-ASCII tokens are used so
/// the value comparisons never depend on emoji/glyph encoding.)
class DialKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  const DialKeypad({super.key, required this.onKeyTap});

  static const Color _bg = Color(0xFFD7D9DE);
  static const Color _keyBg = Colors.white;
  static const Color _digitColor = Color(0xFF1C1C1E);
  static const Color _letterColor = Color(0xFF8A8A8E);

  static const List<List<_KeySpec>> _rows = [
    [_KeySpec('1'), _KeySpec('2', 'ABC'), _KeySpec('3', 'DEF')],
    [_KeySpec('4', 'GHI'), _KeySpec('5', 'JKL'), _KeySpec('6', 'MNO')],
    [_KeySpec('7', 'PQRS'), _KeySpec('8', 'TUV'), _KeySpec('9', 'WXYZ')],
    [_KeySpec('+*#'), _KeySpec('0'), _KeySpec('back')],
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyHeight = size.height * 0.065;

    return Container(
      width: double.infinity,
      color: _bg,
      padding: EdgeInsets.fromLTRB(5, 8, 5, bottomInset > 0 ? bottomInset : 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _rows.map((row) {
          return Row(
            children: row.map((spec) {
              final isSpecial = spec.value == '+*#' || spec.value == 'back';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Material(
                    color: isSpecial ? Colors.transparent : _keyBg,
                    borderRadius: BorderRadius.circular(7),
                    elevation: isSpecial ? 0 : 1,
                    shadowColor: Colors.black.withValues(alpha: 0.35),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(7),
                      splashColor: Colors.black12,
                      highlightColor: Colors.black.withValues(alpha: 0.06),
                      onTap: () => onKeyTap(spec.value),
                      child: SizedBox(
                        height: keyHeight,
                        child: Center(child: _content(spec, size)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _content(_KeySpec spec, Size size) {
    if (spec.value == 'back') {
      return Icon(
        Icons.backspace_outlined,
        color: _digitColor,
        size: size.width * 0.06,
      );
    }
    if (spec.value == '+*#') {
      return Text(
        '+ * #',
        style: TextStyle(
          fontSize: size.width * 0.05,
          fontWeight: FontWeight.w500,
          color: _digitColor,
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          spec.value,
          style: TextStyle(
            fontSize: size.width * 0.072,
            fontWeight: FontWeight.w400,
            color: _digitColor,
            height: 1.0,
          ),
        ),
        if (spec.letters != null)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              spec.letters!,
              style: TextStyle(
                fontSize: size.width * 0.022,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: _letterColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// A thin blinking text cursor used inside the phone field and OTP boxes.
class BlinkingCursor extends StatefulWidget {
  final Color color;
  final double height;
  const BlinkingCursor({super.key, this.color = Colors.black, this.height = 18});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        margin: const EdgeInsets.only(left: 2),
        width: 1.5,
        height: widget.height,
        color: widget.color,
      ),
    );
  }
}
