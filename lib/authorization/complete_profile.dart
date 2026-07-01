import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/models/profile_media.dart';
import '../data/repositories/media_repository.dart';
import '../home_page.dart';
import '../providers/profile_provider.dart';
import '../widgets/media_carousel.dart';
import 'profile_complete_dialog.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, this.isEditing = false});

  /// When opened via "Edit" (returning user), the bottom buttons become
  /// "Discard Edit" / "Save" and saving pops back instead of onboarding.
  final bool isEditing;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _selectedCountry;
  String? _selectedCity;

  // FIX 4: Country-to-city map so city list filters by selected country
  final Map<String, List<String>> _cityMap = {
    'Pakistan': ['Rawalpindi', 'Islamabad', 'Lahore'],
    'United States': ['New York', 'Los Angeles', 'Chicago'],
    'United Kingdom': ['London', 'Manchester', 'Birmingham'],
  };

  final List<String> _countries = ['Pakistan', 'United States', 'United Kingdom'];

  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;

  final MediaRepository _mediaRepo = MediaRepository();
  List<ProfileMedia> _media = const [];

  // Derived from selected country
  List<String> get _cities =>
      _selectedCountry != null ? (_cityMap[_selectedCountry] ?? []) : [];

  @override
  void initState() {
    super.initState();
    // Pre-fill from the existing profile so this screen doubles as "Edit
    // Profile" (new users just see empty fields).
    final profile = context.read<ProfileProvider>().profile;
    if (profile != null) {
      _firstNameController.text = profile.firstName ?? '';
      _lastNameController.text = profile.lastName ?? '';
      _bioController.text = profile.bio ?? '';
      _selectedCountry = profile.country;
      _selectedCity = profile.city;
    }
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final media = await _mediaRepo.fetchMyMedia();
    if (mounted) setState(() => _media = media);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Validates the form, persists the profile to Supabase, then shows the
  /// "Profile Complete" confirmation sheet — the final step before the home page.
  // ignore: unused_element
  Future<void> _addProfilePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading photo…')),
    );
    try {
      await _mediaRepo.addPhoto(file: File(picked.path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo added to your profile.')),
      );
      _loadMedia();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add photo: $e')),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (!mounted || picked == null) return;
    setState(() => _avatarFile = File(picked.path));
  }

  Future<void> _onCreateProfile() async {
    // FIX 3: null-safe validate() instead of `!`.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<ProfileProvider>();
    final ok = await provider.completeProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      country: _selectedCountry,
      city: _selectedCity,
      bio: _bioController.text.trim(),
    );
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save your profile.')),
      );
      return;
    }

    // Upload the chosen avatar (if any) before moving on.
    if (_avatarFile != null) {
      final uploaded = await provider.uploadAvatar(_avatarFile!);
      if (!mounted) return;
      if (!uploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Could not upload your photo.'),
          ),
        );
      }
    }

    showProfileCompleteSheet(
      context,
      name: _firstNameController.text,
      onProceed: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      },
    );
  }

  /// Edit-mode save: persist changes and pop back to the profile (no onboarding
  /// dialog, no navigation to Home).
  Future<void> _onSaveEdit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<ProfileProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await provider.completeProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      country: _selectedCountry,
      city: _selectedCity,
      bio: _bioController.text.trim(),
    );
    if (!mounted) return;
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save your profile.')),
      );
      return;
    }
    if (_avatarFile != null) {
      final uploaded = await provider.uploadAvatar(_avatarFile!);
      if (!mounted) return;
      if (!uploaded) {
        messenger.showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Could not upload your photo.')),
        );
      }
    }
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileProvider>();
    final saving = profileState.saving;
    final category = profileState.profile?.category ?? 'Actor';
    final videos = _media.where((m) => m.isVideo).toList();
    final photos = _media.where((m) => !m.isVideo).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title + Category ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Complete Profile',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Category: ',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  category,
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      // ── Divider 1 — above Upload Profile ────────────────
                      const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),

                      // ── Upload Profile → Videos ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            const Text(
                              'Upload Profile',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _pickAvatar,
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: _avatarFile != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _avatarFile!,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/upload.png',
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.upload_outlined,
                                            size: 32,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // First Name & Last Name
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('First Name'),
                                      const SizedBox(height: 8),
                                      _buildTextField(
                                        controller: _firstNameController,
                                        hintText: '',
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Last Name'),
                                      const SizedBox(height: 8),
                                      _buildTextField(
                                        controller: _lastNameController,
                                        hintText: '',
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            _buildFieldLabel('Country'),
                            const SizedBox(height: 8),
                            _buildDropdownField(
                              hintText: 'Choose Country',
                              value: _selectedCountry,
                              items: _countries,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a country';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  _selectedCountry = val;
                                  _selectedCity = null;
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            _buildFieldLabel('City'),
                            const SizedBox(height: 8),
                            _buildDropdownField(
                              hintText: 'Choose City',
                              value: _selectedCity,
                              items: _cities,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a city';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  _selectedCity = val;
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            _buildFieldLabel('Short Bio'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _bioController,
                              hintText: '',
                              maxLines: 4,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please write a short bio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            _simpleMediaHeader(
                              'Videos (${videos.length})',
                              onAdd: () => _showAddVideoBottomSheet(context),
                              onEdit: () => _showAddVideoBottomSheet(context),
                              hasItems: videos.isNotEmpty,
                            ),
                            const SizedBox(height: 14),
                            if (videos.isEmpty)
                              const Text(
                                'No videos to show',
                                style: TextStyle(
                                    color: Color(0xFF8A8F98), fontSize: 14),
                              )
                            else
                              MediaCarousel(items: videos),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),

                      // ── Divider 2 — only shown when there's media ────────
                      if (videos.isNotEmpty || photos.isNotEmpty)
                        const Divider(
                            color: Color(0xFFE5E5E5), height: 1, thickness: 1),

                      // ── Photos Section ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 28),
                            _simpleMediaHeader(
                              'Photos (${photos.length})',
                              onAdd: () => _showAddPhotoSheet(context),
                              onEdit: () => _showAddPhotoSheet(context),
                              hasItems: photos.isNotEmpty,
                            ),
                            const SizedBox(height: 14),
                            if (photos.isEmpty)
                              const Text(
                                'No photos to show',
                                style: TextStyle(
                                    color: Color(0xFF8A8F98), fontSize: 14),
                              )
                            else
                              MediaCarousel(items: photos),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Bar + Disclaimer Rules Text Row
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        // FIX 5: ElevatedButton instead of OutlinedButton misuse
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.isEditing) {
                                Navigator.of(context).maybePop();
                              }
                              // Handle Skip action (onboarding)
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5E5E5),
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: Text(
                              widget.isEditing ? 'Discard Edit' : 'Skip For Now',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : (widget.isEditing
                                    ? _onSaveEdit
                                    : _onCreateProfile),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.black54,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              elevation: 0,
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    widget.isEditing ? 'Save' : 'Create Profile',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Terms and Conditions Disclaimer footer text
                  SizedBox(
                    width: double.infinity,
                    child: RichText(
                      textAlign: TextAlign.left,
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        children: [
                          const TextSpan(text: 'by creating an account, you agree with the '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const TextSpan(text: ' of You2Art'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVideoBottomSheet(BuildContext context) {
    final TextEditingController _videoLinkController = TextEditingController();
    final TextEditingController _videoTitleController = TextEditingController();
    // Capture the page's messenger up front so it survives the sheet pop.
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Video',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFFDDDDDD), width: 1.2),
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Paste Link label + field
                const Text(
                  'Paste Link',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _videoLinkController,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'Paste Video Link',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade400, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Video Title label + field
                const Text(
                  'Video Title',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _videoTitleController,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'Enter video title',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade400, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Cancel / Add buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5E5E5),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            final link = _videoLinkController.text.trim();
                            final title = _videoTitleController.text.trim();
                            if (link.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Paste a video link.')),
                              );
                              return;
                            }
                            // Dismiss the keyboard / text-selection overlay
                            // BEFORE the sheet pops, otherwise tearing down a
                            // focused TextField throws _dependents.isEmpty.
                            FocusManager.instance.primaryFocus?.unfocus();
                            try {
                              await _mediaRepo.addVideo(
                                title: title.isEmpty ? 'Video' : title,
                                link: link,
                              );
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              _loadMedia();
                              messenger.showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Video added to your profile.')),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text('Could not add video: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _videoLinkController.dispose();
      _videoTitleController.dispose();
    });
  }

  /// Functional "Add Photo" sheet: pick from gallery OR paste a link, give it a
  /// title, then Upload → saves to profile_media and refreshes the list.
  void _showAddPhotoSheet(BuildContext context) {
    final linkController = TextEditingController();
    final titleController = TextEditingController();
    File? picked;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            Future<void> pick() async {
              final x = await _picker.pickImage(
                  source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
              if (x != null) setSheet(() => picked = File(x.path));
            }

            Future<void> doUpload() async {
              final link = linkController.text.trim();
              final title = titleController.text.trim();
              if (picked == null && link.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pick a photo or paste a link.')),
                );
                return;
              }
              // Dismiss the keyboard / text-selection overlay before the sheet
              // pops, otherwise tearing down a focused TextField throws
              // _dependents.isEmpty (Overlay deactivation assertion).
              FocusManager.instance.primaryFocus?.unfocus();
              setSheet(() => uploading = true);
              try {
                if (picked != null) {
                  await _mediaRepo.addPhoto(
                      file: picked!, title: title.isEmpty ? null : title);
                } else {
                  await _mediaRepo.addPhotoLink(
                      url: link, title: title.isEmpty ? null : title);
                }
                if (!mounted) return;
                Navigator.of(sheetCtx).pop();
                _loadMedia();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo added to your profile.')),
                );
              } catch (e) {
                setSheet(() => uploading = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not add photo: $e')),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add Photo',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () => Navigator.of(sheetCtx).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFDDDDDD), width: 1.2),
                            ),
                            child: const Icon(Icons.close,
                                size: 18, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Upload Photo',
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: pick,
                      child: picked != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(picked!,
                                  width: 70, height: 70, fit: BoxFit.cover),
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFEAF2FF),
                                  shape: BoxShape.circle),
                              child: Image.asset(
                                'assets/images/upload.png',
                                width: 70,
                                height: 70,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.file_upload_outlined,
                                    size: 30,
                                    color: Color(0xFF2F80ED)),
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    const Text('OR Paste Link',
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _sheetField(linkController, 'Paste Photo Link'),
                    const SizedBox(height: 20),
                    const Text('Photo Title',
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _sheetField(titleController, 'Enter Photo title'),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: uploading
                                  ? null
                                  : () => Navigator.of(sheetCtx).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5E5E5),
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26)),
                              ),
                              child: const Text('Cancel',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: uploading ? null : doUpload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.black54,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26)),
                              ),
                              child: uploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Upload',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showAddPhotosBottomSheet(BuildContext context) {
    final TextEditingController _photosLinkController = TextEditingController();
    final TextEditingController _photosTitleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Photos',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFFDDDDDD), width: 1.2),
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Upload Profile',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // Handle profile image upload
                    // Remember: add mounted guard before setState when async
                  },
                  // FIX 7: SizedBox instead of Container (no extra render object)
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    // FIX 2: fit + explicit size + errorBuilder fallback
                    child: Image.asset(
                      'assets/images/upload.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.upload_outlined,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Paste Link label + field
                const Text(
                  'OR Paste Link',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _photosLinkController,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'Paste Photo Link',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade400, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Video Title label + field
                const Text(
                  'Photo Title',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _photosTitleController,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'Enter Photo title',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade400, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Cancel / Add buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5E5E5),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle add video logic
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Upload',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _photosLinkController.dispose();
      _photosTitleController.dispose();
    });
  }

  Widget _buildFieldLabel(String labelText) {
    return RichText(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // FIX 1: Added optional validator parameter
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: Colors.black,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  // Custom dropdown built on a PopupMenuButton so the open list matches the
  // app's options-menu styling: white card, rounded corners, and full-width
  // dividers between options. Wrapped in a FormField to keep validation.
  Widget _buildDropdownField({
    required String hintText,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        // Keep the field's internal value in sync with the parent (e.g. when
        // the city resets after the country changes).
        if (field.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) field.didChange(value);
          });
        }
        final hasError = field.errorText != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth;
                return Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: hasError ? Colors.red : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: PopupMenuButton<String>(
              enabled: items.isNotEmpty,
              position: PopupMenuPosition.under,
              color: Colors.white,
              elevation: 6,
              constraints: BoxConstraints(
                minWidth: fieldWidth,
                maxWidth: fieldWidth,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (val) {
                field.didChange(val);
                onChanged(val);
              },
              itemBuilder: (_) => [
                for (int i = 0; i < items.length; i++) ...[
                  PopupMenuItem<String>(
                    value: items[i],
                    height: 44,
                    child: Text(
                      items[i],
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (i < items.length - 1)
                    const PopupMenuDivider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                ],
              ],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value ?? hintText,
                        style: TextStyle(
                          color: value == null
                              ? Colors.grey.shade400
                              : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
                  ],
                ),
              ),
                  ),
                );
              },
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  // Media Header configuration matching top controls (Edit/Add row setup)
  // Header: "Videos (N)". Empty → only a bigger + button. With items → a
  // small edit (pencil) + a small + button.
  Widget _simpleMediaHeader(String title,
      {required VoidCallback onAdd,
      required VoidCallback onEdit,
      required bool hasItems}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            if (hasItems) ...[
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                      color: Color(0xFFEBF3FF), shape: BoxShape.circle),
                  child: Image.asset(
                    'assets/images/edit_icon.png',
                    width: 16,
                    height: 16,
                    color: const Color(0xFF2F80ED),
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF2F80ED)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: onAdd,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(hasItems ? 7 : 9),
                decoration: const BoxDecoration(
                    color: Color(0xFFB7F0CD), shape: BoxShape.circle),
                child: Icon(Icons.add,
                    size: hasItems ? 18 : 22, color: const Color(0xFF1F8A4D)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _completeMediaCard({String? title, String? link, String? url}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: (url != null && url.isNotEmpty)
                ? Image.network(
                    url,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _mediaPlaceholder(),
                  )
                : _mediaPlaceholder(video: url == null),
          ),
          if ((title ?? '').isNotEmpty || (link ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((title ?? '').isNotEmpty)
                    Text(title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  if ((link ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(link!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF60A5FA), fontSize: 12)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _mediaPlaceholder({bool video = false}) {
    return Container(
      height: 170,
      width: double.infinity,
      color: const Color(0xFFEDEDED),
      child: Center(
        child: Icon(video ? Icons.play_circle_fill : Icons.image,
            color: Colors.black45, size: 40),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMediaSectionHeader({
    required String title,
    required String subtitle,
    required VoidCallback onEditTap,
    required VoidCallback onAddTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF3FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onAddTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFE6FDF9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 18, color: Color(0xFF2DD4BF)),
              ),
            ),
          ],
        )
      ],
    );
  }

  // Builder for Video Item Frame Card Layout
  Widget _buildVideoMediaCard({
    required String imageAsset,
    required String title,
    required String linkText,
    required int currentSlideIndex,
    required int totalSlidesCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  'assets/images/$imageAsset.png',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              // Play Button Icon Overlay
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 28),
              ),
              // Tiny mock Youtube watermark tag style decoration
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Colors.black45,
                  child: const Text(
                    'YouTube',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  linkText,
                  style: TextStyle(
                    color: Colors.blue.shade400,
                    fontSize: 12,

                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                _buildSliderNavigationRow(currentSlideIndex, totalSlidesCount),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Builder for Photo Item Frame Card Layout
  Widget _buildPhotoMediaCard({
    required String imageAsset,
    required String title,
    required String linkText,
    required int currentSlideIndex,
    required int totalSlidesCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              'assets/images/$imageAsset.jpg',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  linkText,
                  style: TextStyle(
                    color: Colors.blue.shade400,
                    fontSize: 12,
                    
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                _buildSliderNavigationRow(currentSlideIndex, totalSlidesCount),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Shared Bottom Slider Indicators and Arrows navigation controller design
  Widget _buildSliderNavigationRow(int currentIndex, int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            // Step back action logic
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Transform.flip(
              flipX: true,
              child: Image.asset(
                'assets/images/arrow_icon.png',
                width: 14,
                height: 14,
              ),
            ),
          ),
        ),
        Text(
          '$currentIndex of $totalCount',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () {
            // Step forward action logic
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/arrow_icon.png',
              width: 14,
              height: 14,
            ),
          ),
        ),
      ],
    );
  }
}