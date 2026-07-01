import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/profile_media.dart';

/// Swipeable media carousel. Every item left-aligns to the content width (its
/// left edge sits at the section margin, no peek of the previous item); when
/// there are more items the next one peeks and bleeds to the right screen edge.
/// The last item ends exactly at the content edge (where the header + button
/// ends) with no peek. Title + tappable link + "X of N" pager sit below.
class MediaCarousel extends StatefulWidget {
  const MediaCarousel({super.key, required this.items});

  final List<ProfileMedia> items;

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  final ScrollController _scroll = ScrollController();
  int _index = 0;
  double _itemExtent = 0; // content width + gap (one snap step)

  static const Color _blue = Color(0xFF2F80ED);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _idleIcon = Color(0xFF9AA0A6);
  static const double _gap = 16.0;
  static const double _height = 200.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _itemExtent <= 0) return;
    final i = (_scroll.offset / _itemExtent)
        .round()
        .clamp(0, widget.items.length - 1);
    if (i != _index) setState(() => _index = i);
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.items.length - 1);
    if (!_scroll.hasClients || _itemExtent <= 0) return;
    _scroll.animateTo(
      next * _itemExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  // ── YouTube helpers ──────────────────────────────────────────────────
  String? _youtubeId(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first.isNotEmpty) {
        return uri.pathSegments.first;
      }
    }
    if (host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
      final seg = uri.pathSegments;
      if (seg.length >= 2 && (seg[0] == 'shorts' || seg[0] == 'embed')) {
        return seg[1];
      }
    }
    return null;
  }

  String? _thumbFor(ProfileMedia m) {
    if (m.isVideo) {
      final id = _youtubeId(m.link);
      return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    return (m.url ?? '').isEmpty ? null : m.url;
  }

  Future<void> _openLink(String raw) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      // No app can handle the link — nothing else to do.
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    if (total == 0) return const SizedBox.shrink();
    final current = widget.items[_index.clamp(0, total - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image strip ───────────────────────────────────────────────
        if (total == 1)
          // Single item: fill the content width, no scroller.
          SizedBox(height: _height, child: _imageCard(widget.items.first))
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth; // content width
              final screenW = MediaQuery.sizeOf(context).width;
              // How far the strip extends past the right content edge so the
              // peeking next item reaches the screen edge.
              final rightPad = ((screenW - available) / 2).clamp(0.0, 64.0);
              final bleed = available + rightPad + _gap;
              _itemExtent = available + _gap;
              return SizedBox(
                height: _height,
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: bleed,
                  child: SizedBox(
                    width: bleed,
                    height: _height,
                    child: ListView(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: _SnapPhysics(itemExtent: _itemExtent),
                      children: [
                        for (final m in widget.items)
                          Padding(
                            padding: const EdgeInsets.only(right: _gap),
                            child: SizedBox(
                                width: available, child: _imageCard(m)),
                          ),
                        // Trailing spacer so the last item can scroll fully
                        // left (ends exactly at the content edge, no peek).
                        SizedBox(width: rightPad),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        // ── Title + link + pager (content width) ──────────────────────
        Text(
          current.title ?? (current.isVideo ? 'Video' : 'Photo'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if ((current.link ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _openLink(current.link!),
            child: Text(
              current.link!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2F80ED),
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF2F80ED),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _arrow(forward: false, enabled: _index > 0),
            Text(
              '${_index + 1} of $total',
              style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            _arrow(forward: true, enabled: _index < total - 1),
          ],
        ),
      ],
    );
  }

  Widget _imageCard(ProfileMedia m) {
    final thumb = _thumbFor(m);
    Widget inner;
    if (thumb != null) {
      final img = Image.network(
        thumb,
        width: double.infinity,
        height: _height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(video: m.isVideo),
      );
      inner = m.isVideo
          ? Stack(
              fit: StackFit.expand,
              children: [
                img,
                const Center(
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 54),
                ),
              ],
            )
          : img;
    } else {
      inner = _fallback(video: m.isVideo);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: inner);
  }

  Widget _fallback({bool video = false}) {
    return Container(
      width: double.infinity,
      height: _height,
      color: const Color(0xFFEDEDED),
      child: Center(
        child: Icon(video ? Icons.play_circle_fill : Icons.image,
            color: _idleIcon, size: 44),
      ),
    );
  }

  Widget _arrow({required bool forward, required bool enabled}) {
    final color = enabled ? _blue : _textSecondary;
    final arrow = Image.asset(
      'assets/images/arrow_icon.png',
      width: 14,
      height: 14,
      color: color,
      errorBuilder: (_, __, ___) => Icon(
          forward ? Icons.arrow_forward : Icons.arrow_back,
          size: 14,
          color: color),
    );
    return GestureDetector(
      onTap: enabled ? () => _go(forward ? 1 : -1) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6E9EE), width: 1.2),
          shape: BoxShape.circle,
        ),
        child: forward
            ? arrow
            : Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: arrow,
              ),
      ),
    );
  }
}

/// Page-like snap physics that snaps to multiples of [itemExtent] (one media
/// card + gap), so each item lands left-aligned at the content edge.
class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  double _snapTarget(ScrollMetrics position, double velocity) {
    final tol = toleranceFor(position);
    double item = position.pixels / itemExtent;
    if (velocity < -tol.velocity) {
      item = item.floorToDouble();
    } else if (velocity > tol.velocity) {
      item = item.ceilToDouble();
    } else {
      item = item.roundToDouble();
    }
    return (item * itemExtent)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tol = toleranceFor(position);
    final target = _snapTarget(position, velocity);
    if ((target - position.pixels).abs() < tol.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity,
        tolerance: tol);
  }

  @override
  bool get allowImplicitScrolling => false;
}
