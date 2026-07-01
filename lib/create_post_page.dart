import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'providers/post_provider.dart';
import 'providers/profile_provider.dart';
import 'tag_people_sheet.dart';

/// "New Post" composer screen.
///
/// Opens from the home composer:
///   • Tapping the placeholder text → text-only flow ([pickImageOnStart] = false)
///   • Tapping the Photo chip       → image flow, opens the custom picker on entry
///                                    ([pickImageOnStart] = true)
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key, this.pickImageOnStart = false});

  final bool pickImageOnStart;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _lightBlue = Color(0xFFEAF2FF);
  static const Color _orange = Color(0xFFF2994A);
  static const Color _lightOrange = Color(0xFFFFEFE0);
  static const Color _discardBg = Color(0xFFFFE4E4);
  static const Color _discardText = Color(0xFFE53935);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final _controller = TextEditingController();
  final _picker = ImagePicker();

  File? _pickedImage; // photo chosen from the device gallery
  List<String> _taggedPeople = const [];

  @override
  void initState() {
    super.initState();
    if (widget.pickImageOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openTagPeople() async {
    final result = await showTagPeopleSheet(
      context,
      initiallySelected: _taggedPeople,
    );
    if (!mounted || result == null) return;
    setState(() => _taggedPeople = result);
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (!mounted || picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _onPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something or add a photo.')),
      );
      return;
    }

    final provider = context.read<PostProvider>();
    final ok = await provider.createPost(
      body: text.isEmpty ? null : text,
      image: _pickedImage,
      taggedUserIds: _taggedPeople,
    );
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).maybePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not publish your post.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorRow(),
                  const SizedBox(height: 18),
                  _buildTextField(),
                ],
              ),
            ),
            if (_pickedImage != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: _buildImagePreview(),
                ),
              )
            else
              const Spacer(),
            _buildAttachmentRow(),
            const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  // ── Author row ───────────────────────────────────────────────────────
  Widget _buildAuthorRow() {
    final profile = context.watch<ProfileProvider>().profile;
    final name =
        (profile?.fullName.isNotEmpty ?? false) ? profile!.fullName : 'You';
    final avatarUrl = profile?.avatarUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFEDEDED),
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? NetworkImage(avatarUrl)
              : const AssetImage('assets/images/profile_pic.png')
                  as ImageProvider,
          onBackgroundImageError: (_, __) {},
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'New Post',
              style: TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  // ── Body text field ──────────────────────────────────────────────────
  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      cursorColor: Colors.black,
      minLines: 2,
      maxLines: _pickedImage != null ? 4 : null,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 15,
        height: 1.5,
      ),
      decoration: const InputDecoration(
        hintText: "What's on your mind?",
        hintStyle: TextStyle(color: _textSecondary, fontSize: 15),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // ── Image preview (with remove button) ───────────────────────────────
  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          _pickedImage!,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image, size: 48, color: Colors.grey),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _pickedImage = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  // ── Photo / Tag People chips ─────────────────────────────────────────
  Widget _buildAttachmentRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          _attachmentChip(
            asset: 'assets/images/photos_icon.png',
            fallbackIcon: Icons.image_outlined,
            label: 'Photo',
            tint: _blue,
            background: _lightBlue,
            onTap: _pickImage,
          ),
          const SizedBox(width: 12),
          _attachmentChip(
            asset: 'assets/images/tag_icon.png',
            fallbackIcon: Icons.person_add_alt_1_outlined,
            label: _taggedPeople.isEmpty
                ? 'Tag People'
                : 'Tag People (${_taggedPeople.length})',
            tint: _orange,
            background: _lightOrange,
            onTap: _openTagPeople,
          ),
        ],
      ),
    );
  }

  Widget _attachmentChip({
    required String? asset,
    required IconData fallbackIcon,
    required String label,
    required Color tint,
    required Color background,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (asset != null)
              Image.asset(
                asset,
                width: 18,
                height: 18,
                color: tint,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, size: 18, color: tint),
              )
            else
              Icon(fallbackIcon, size: 18, color: tint),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Discard / Post Now action bar ────────────────────────────────────
  Widget _buildActionBar() {
    final posting = context.watch<PostProvider>().posting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed:
                    posting ? null : () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _discardBg,
                  foregroundColor: _discardText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'Discard',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: posting ? null : _onPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.black54,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: posting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Post Now',
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
