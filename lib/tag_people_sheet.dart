import 'package:flutter/material.dart';

import 'data/models/profile.dart';
import 'data/repositories/profile_repository.dart';

/// Bottom-sheet for tagging real people in a post.
///
/// Returns the list of tagged user IDs when "Tag" is pressed, or `null` if the
/// user cancels / dismisses. [initiallySelected] is a list of user IDs.
Future<List<String>?> showTagPeopleSheet(
  BuildContext context, {
  List<String> initiallySelected = const [],
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TagPeopleSheet(initiallySelected: initiallySelected),
  );
}

class _TagPeopleSheet extends StatefulWidget {
  const _TagPeopleSheet({required this.initiallySelected});

  final List<String> initiallySelected;

  @override
  State<_TagPeopleSheet> createState() => _TagPeopleSheetState();
}

class _TagPeopleSheetState extends State<_TagPeopleSheet> {
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _border = Color(0xFFECECEC);
  static const Color _cancelBg = Color(0xFFE5E5E5);
  static const Color _cancelText = Color(0xFF484C52);

  final ProfileRepository _repo = ProfileRepository();
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selected; // user ids
  String _query = '';
  List<Profile> _people = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected.toSet();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.fetchPeople();
      if (mounted) {
        setState(() {
          _people = p;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _nameOf(Profile p) =>
      p.fullName.isNotEmpty ? p.fullName : 'You2Art User';

  List<Profile> get _filtered {
    if (_query.isEmpty) return _people;
    return _people
        .where((p) => _nameOf(p).toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
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
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tag People (${_selected.length})',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: const Color(0xFFDDDDDD), width: 1.2),
                        ),
                        child: const Icon(Icons.close,
                            color: _textPrimary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border, width: 1.4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: _textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          cursorColor: Colors.black,
                          style: const TextStyle(
                              color: _textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search',
                            hintStyle:
                                TextStyle(color: _textSecondary, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? const Center(
                            child: Text('No people found.',
                                style: TextStyle(
                                    color: _textSecondary, fontSize: 14)),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFF0F0F0)),
                            itemBuilder: (_, i) {
                              final p = _filtered[i];
                              return _personRow(p, _selected.contains(p.id));
                            },
                          ),
              ),
              const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: size.height * 0.06,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _cancelBg,
                              foregroundColor: _cancelText,
                              side: const BorderSide(color: _cancelBg, width: 1.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: size.height * 0.06,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(_selected.toList()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Tag',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _personRow(Profile p, bool isSelected) {
    final url = p.avatarUrl ?? '';
    return InkWell(
      onTap: () => setState(() {
        if (isSelected) {
          _selected.remove(p.id);
        } else {
          _selected.add(p.id);
        }
      }),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEDEDED),
              backgroundImage: url.startsWith('http')
                  ? NetworkImage(url)
                  : const AssetImage('assets/images/profile_pic.png')
                      as ImageProvider,
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameOf(p),
                    style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (p.category ?? '').isNotEmpty ? p.category! : 'You2Art member',
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            _RadioDot(selected: isSelected),
          ],
        ),
      ),
    );
  }
}

/// Custom radio indicator — filled blue ring with white centre when selected,
/// empty grey ring when not.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? const Color(0xFF2F80ED) : Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFF2F80ED) : const Color(0xFFD0D0D0),
          width: 1.6,
        ),
      ),
      child: selected
          ? const Center(child: Icon(Icons.check, color: Colors.white, size: 14))
          : null,
    );
  }
}
