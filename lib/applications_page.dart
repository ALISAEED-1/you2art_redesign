import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/models/casting_application.dart';
import 'data/models/casting_call.dart';
import 'data/repositories/casting_repository.dart';
import 'providers/casting_provider.dart';
import 'application_detail_page.dart';
import 'options_sheet.dart';
import 'delete_casting_call_sheet.dart';
import 'widgets/empty_state.dart';

/// Applications list for one of the user's own casting calls.
class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({
    super.key,
    required this.call,
    required this.published,
  });

  final CastingCall call;
  final String published;

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _summaryBg = Color(0xFFF4F5F7);
  static const Color _shareBg = Color(0xFFD9EBFB);
  static const Color _acceptBg = Color(0xFFBFF4D6);
  static const Color _acceptText = Color(0xFF1F8A4D);
  static const Color _rejectBg = Color(0xFFFFD9D9);
  static const Color _rejectText = Color(0xFFE53935);
  static const Color _deleteBg = Color(0xFFFFD2D2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final CastingRepository _repo = CastingRepository();

  int _tabIndex = 0; // 0 Received · 1 Rejected · 2 Wishlist
  bool _loading = true;
  List<CastingApplication> _apps = const [];

  static const List<String> _statusForTab = ['received', 'rejected', 'wishlist'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final apps = await _repo.fetchApplications(
        widget.call.id,
        status: _statusForTab[_tabIndex],
      );
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(CastingApplication a, String status) async {
    await _repo.setApplicationStatus(a.id, status);
    if (!mounted) return;
    _load();
  }

  ImageProvider _img(String path) =>
      path.startsWith('http') ? NetworkImage(path) : AssetImage(path);

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
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
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Applications',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${call.applicantsCount} Applicants',
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _summaryCard(),
                  const SizedBox(height: 18),
                  const Divider(
                      color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTabs(),
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                      color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_apps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: EmptyState(message: 'No applications here yet.'),
                    )
                  else
                    for (final a in _apps) ...[
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _applicantRow(a),
                      ),
                      const SizedBox(height: 14),
                      const Divider(
                          color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                    ],
                ],
              ),
            ),
            // ── Pinned bottom: Delete This Call ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirmed = await showDeleteCastingCallSheet(
                      context,
                      call: {
                        'title': call.projectTitle,
                        'published': widget.published,
                      },
                    );
                    if (!context.mounted) return;
                    if (confirmed == true) {
                      await context
                          .read<CastingProvider>()
                          .deleteCall(call.id);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deleteBg,
                    foregroundColor: _rejectText,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Delete This Call',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary card (full-bleed grey band) ──────────────────────────────
  Widget _summaryCard() {
    final call = widget.call;
    return Container(
      width: double.infinity,
      color: _summaryBg,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
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
            widget.published,
            style: const TextStyle(color: _textSecondary, fontSize: 12),
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
        ],
      ),
    );
  }

  // ── Tabs ─────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Row(
      children: [
        _tab(0, 'Received', 'assets/images/file_icon.png',
            Icons.description_outlined),
        const SizedBox(width: 18),
        _tab(1, 'Rejected', 'assets/images/cancel_icon.png',
            Icons.cancel_outlined),
        const SizedBox(width: 18),
        _tab(2, 'Wishlist', 'assets/images/wishlist_icon.png',
            Icons.bookmark_outline),
      ],
    );
  }

  Widget _tab(int index, String label, String asset, IconData fallbackIcon) {
    final selected = _tabIndex == index;
    final iconColor = selected ? _blue : _textSecondary;
    final textColor = selected ? _textPrimary : _textSecondary;
    return GestureDetector(
      onTap: () {
        setState(() => _tabIndex = index);
        _load();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: 18,
              height: 18,
              color: iconColor,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 8),
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

  // ── Applicant row ────────────────────────────────────────────────────
  Widget _applicantRow(CastingApplication a) {
    final showActions = _tabIndex == 0 || _tabIndex == 2;
    final wishlistAsset = _tabIndex == 2
        ? 'assets/images/wishlist_2.png'
        : 'assets/images/wishlist_icon.png';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ApplicationDetailPage(
            projectTitle: widget.call.projectTitle,
            name: a.name,
            photo: a.photo,
            appliedAgo: 'Recently',
            age: a.age ?? '—',
            height: a.height ?? '—',
            experience: a.experience ?? '—',
            contactNumber: a.phone ?? '—',
            email: a.email ?? '—',
            note: a.note ?? '—',
          ),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEDEDED),
                backgroundImage: _img(a.photo),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Applied recently',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (showActions) ...[
                GestureDetector(
                  onTap: () => _setStatus(
                      a, _tabIndex == 2 ? 'received' : 'wishlist'),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: _shareBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        wishlistAsset,
                        width: 16,
                        height: 16,
                        color: _blue,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.bookmark_outline,
                          color: _blue,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const OptionsMenuButton(),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _stat('Age', a.age ?? '—')),
                    Expanded(child: _stat('Height', a.height ?? '—')),
                    Expanded(child: _stat('Gender', a.gender ?? '—')),
                    Expanded(child: _stat('Experience', a.experience ?? '—')),
                  ],
                ),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _setStatus(a, 'accepted'),
                        child: _actionPill(
                          bg: _acceptBg,
                          textColor: _acceptText,
                          asset: 'assets/images/true_icon.png',
                          fallbackIcon: Icons.check_circle,
                          label: 'Accept',
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _setStatus(a, 'rejected'),
                        child: _actionPill(
                          bg: _rejectBg,
                          textColor: _rejectText,
                          asset: 'assets/images/cancel_icon.png',
                          fallbackIcon: Icons.cancel,
                          label: 'Reject',
                          iconTint: _rejectText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required Color bg,
    required Color textColor,
    required String asset,
    required IconData fallbackIcon,
    required String label,
    Color? iconTint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            asset,
            width: 16,
            height: 16,
            color: iconTint,
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, color: iconTint ?? textColor, size: 16),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
}
