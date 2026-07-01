import 'package:flutter/material.dart';

/// Shared empty-state: the `no_data` illustration above a short message.
///
/// Used wherever a list/feed has nothing to show.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.padding = const EdgeInsets.symmetric(vertical: 40),
    this.imageSize = 160,
  });

  final String message;
  final EdgeInsetsGeometry padding;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/no_data.png',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.inbox_outlined,
              size: 72,
              color: Color(0xFFB9C0C9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A8F98),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
