/// A photo or video on a user's profile, mirroring `public.profile_media`.
class ProfileMedia {
  const ProfileMedia({
    required this.id,
    required this.type,
    this.url,
    this.title,
    this.link,
  });

  final String id;
  final String type; // 'photo' | 'video'
  final String? url;
  final String? title;
  final String? link;

  bool get isVideo => type == 'video';

  factory ProfileMedia.fromMap(Map<String, dynamic> m) {
    return ProfileMedia(
      id: m['id'] as String,
      type: (m['type'] as String?) ?? 'photo',
      url: m['url'] as String?,
      title: m['title'] as String?,
      link: m['link'] as String?,
    );
  }
}
