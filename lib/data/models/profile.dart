/// A user's profile, mirroring the `public.profiles` table in Supabase.
class Profile {
  const Profile({
    required this.id,
    this.phone,
    this.firstName,
    this.lastName,
    this.category,
    this.country,
    this.city,
    this.bio,
    this.avatarUrl,
  });

  final String id;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? category;
  final String? country;
  final String? city;
  final String? bio;
  final String? avatarUrl;

  /// "First Last", trimmed, skipping any empty parts.
  String get fullName => [firstName, lastName]
      .where((e) => (e ?? '').trim().isNotEmpty)
      .join(' ')
      .trim();

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      phone: map['phone'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      category: map['category'] as String?,
      country: map['country'] as String?,
      city: map['city'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
