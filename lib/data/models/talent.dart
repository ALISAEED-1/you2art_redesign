/// A talent / production-house entry shown on the Talent grid.
/// Mirrors `public.talents`.
class Talent {
  const Talent({
    required this.id,
    required this.name,
    required this.type,
    this.role,
    this.photo,
  });

  final String id;
  final String name;
  final String type; // 'talent' | 'production'
  final String? role;
  final String? photo;

  bool get isProduction => type == 'production';

  factory Talent.fromMap(Map<String, dynamic> map) {
    return Talent(
      id: map['id'] as String,
      name: map['name'] as String,
      type: (map['type'] as String?) ?? 'talent',
      role: map['role'] as String?,
      photo: map['photo'] as String?,
    );
  }
}
