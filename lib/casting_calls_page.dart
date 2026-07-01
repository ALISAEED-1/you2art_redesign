import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/models/casting_call.dart';
import 'providers/casting_provider.dart';
import 'applications_page.dart';
import 'options_sheet.dart';
import 'casting_apply_page.dart';
import 'casting_call_detail_page.dart';
import 'casting_create_page.dart';
import 'delete_casting_call_sheet.dart';
import 'widgets/empty_state.dart';

/// "Casting Calls" tab — open casting calls, the ones you've applied to, and
/// the ones you've posted. Backed by Supabase via [CastingProvider].
class CastingCallsView extends StatefulWidget {
  const CastingCallsView({super.key});

  @override
  State<CastingCallsView> createState() => _CastingCallsViewState();
}

class _CastingCallsViewState extends State<CastingCallsView> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _shareBg = Color(0xFFD9EBFB);
  static const Color _appliedBg = Color(0xFFBFF4D6);
  static const Color _appliedText = Color(0xFF1F8A4D);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  int _tabIndex = 0; // 0 Casting Calls · 1 Applied · 2 My Casting Call

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CastingProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final casting = context.watch<CastingProvider>();
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => context.read<CastingProvider>().loadAll(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _fullBleedDivider(),
            const SizedBox(height: 14),
            _buildTabs(),
            const SizedBox(height: 8),
            _fullBleedDivider(),
            ..._buildBody(casting),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(CastingProvider casting) {
    if (_tabIndex == 2) {
      return [
        const SizedBox(height: 16),
        _buildCreateButton(),
        const SizedBox(height: 16),
        _fullBleedDivider(),
        ..._listOrState(
          casting.loading,
          casting.mine,
          'You haven\'t posted any casting calls yet.',
          (call) => _buildMyCallCard(call),
        ),
      ];
    }
    final list = _tabIndex == 1 ? casting.applied : casting.all;
    final emptyMsg = _tabIndex == 1
        ? 'You haven\'t applied to any casting calls yet.'
        : 'No casting calls available right now.';
    return _listOrState(casting.loading, list, emptyMsg,
        (call) => _buildCallCard(call));
  }

  List<Widget> _listOrState(
    bool loading,
    List<CastingCall> calls,
    String emptyMessage,
    Widget Function(CastingCall) cardBuilder,
  ) {
    if (loading && calls.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (calls.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: EmptyState(message: emptyMessage),
        ),
      ];
    }
    final out = <Widget>[];
    for (final call in calls) {
      out.add(const SizedBox(height: 16));
      out.add(cardBuilder(call));
      out.add(const SizedBox(height: 16));
      out.add(_fullBleedDivider());
    }
    return out;
  }

  // ── Header ───────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return const Text(
      'Casting Calls',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
      ),
    );
  }

  // ── Tabs ─────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tab(0, 'Casting Calls', 'assets/images/star_icon.png',
              Icons.auto_awesome),
          const SizedBox(width: 28),
          _tab(1, 'Applied', 'assets/images/applied_icon.png',
              Icons.check_circle_outline),
          const SizedBox(width: 28),
          _tab(2, 'My Casting Calls', 'assets/images/star_icon.png',
              Icons.auto_awesome),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _tab(int index, String label, String asset, IconData fallbackIcon) {
    final selected = _tabIndex == index;
    final iconColor = selected ? _blue : _textSecondary;
    final textColor = selected ? _textPrimary : _textSecondary;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: 17,
              height: 17,
              color: iconColor,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Call card (browse / applied) ─────────────────────────────────────
  Widget _buildCallCard(CastingCall call) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEDEDED),
              backgroundImage: _img(call.ownerPhoto),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CastingCallDetailPage(call: call),
                  ),
                ),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.projectTitle,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      call.ownerName,
                      style:
                          const TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: _shareBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/share_icon.png',
                  width: 18,
                  height: 18,
                  color: _blue,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.share, color: _blue, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const OptionsMenuButton(size: 38, iconSize: 20),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Row(
            children: [
              Expanded(child: _stat('Location', call.locationLabel)),
              Expanded(child: _stat('Type', call.typeLabel)),
              Expanded(child: _stat('Shoot', call.shootLabel)),
              Expanded(child: _stat('Budget', call.budgetLabel)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Align(
            alignment: Alignment.centerLeft,
            child: call.isMine
                ? _yourCallLabel()
                : call.appliedByMe
                    ? _appliedPill('Applied')
                    : _applyNowButton(call),
          ),
        ),
      ],
    );
  }

  Widget _yourCallLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Your Casting Call',
        style: TextStyle(
            color: _blue, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── "+ Create Casting Call" button ──────────────────────────────────
  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          final submitted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CastingCreatePage()),
          );
          if (!mounted) return;
          if (submitted == true) {
            setState(() => _tabIndex = 2);
            context.read<CastingProvider>().loadAll();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text(
          'Create Casting Call',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  // ── My casting call card ────────────────────────────────────────────
  Widget _buildMyCallCard(CastingCall call) {
    final published = call.publishedDate != null
        ? 'Published, ${call.publishedDate}'
        : 'Published, ${_relative(call.createdAt)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.projectTitle,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    published,
                    style:
                        const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final confirmed = await showDeleteCastingCallSheet(
                  context,
                  call: {'title': call.projectTitle, 'published': published},
                );
                if (!mounted || confirmed != true) return;
                await context.read<CastingProvider>().deleteCall(call.id);
              },
              behavior: HitTestBehavior.opaque,
              child: _actionCircle(
                bg: const Color(0xFFFFE0E0),
                child: Image.asset(
                  'assets/images/delete_icon.png',
                  width: 18,
                  height: 18,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _actionCircle(
              bg: _shareBg,
              child: Image.asset(
                'assets/images/share_icon.png',
                width: 18,
                height: 18,
                color: _blue,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.share, color: _blue, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            const OptionsMenuButton(size: 38, iconSize: 20),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _stat('Location', call.locationLabel)),
            Expanded(child: _stat('Type', call.typeLabel)),
            Expanded(child: _stat('Shoot', call.shootLabel)),
            Expanded(child: _stat('Budget', call.budgetLabel)),
          ],
        ),
        const SizedBox(height: 14),
        _applicantsFooter(call, published),
      ],
    );
  }

  Widget _actionCircle({required Color bg, Widget? child}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }

  Widget _applicantsFooter(CastingCall call, String published) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Applicants',
                  style: TextStyle(color: _textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  '${call.applicantsCount}',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ApplicationsPage(call: call, published: published),
              ),
            ),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'View Applications',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  'assets/images/arrow_icon.png',
                  width: 16,
                  height: 16,
                  color: _blue,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.arrow_forward, color: _blue, size: 16),
                ),
              ],
            ),
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

  Widget _appliedPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _appliedBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/applied_icon.png',
            width: 16,
            height: 16,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.check_circle, color: _appliedText, size: 14),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _appliedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _applyNowButton(CastingCall call) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CastingApplyPage(call: call)),
          );
          if (!mounted) return;
          context.read<CastingProvider>().loadAll();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: const StadiumBorder(),
        ),
        child: const Text(
          'Apply Now',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _fullBleedDivider() {
    return SizedBox(
      height: 1,
      child: OverflowBox(
        maxWidth: MediaQuery.sizeOf(context).width,
        child: Container(height: 1, color: const Color(0xFFEFEFEF)),
      ),
    );
  }

  ImageProvider _img(String path) =>
      path.startsWith('http') ? NetworkImage(path) : AssetImage(path);

  String _relative(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return 'Just Now';
    if (d.inHours < 24) return '${d.inHours}h Ago';
    if (d.inDays < 7) return '${d.inDays}d Ago';
    return '${(d.inDays / 7).floor()}w Ago';
  }
}
