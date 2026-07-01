/// A person in the network directory, mirroring `public.network_people`.
class NetworkPerson {
  const NetworkPerson({
    required this.id,
    required this.kind,
    required this.name,
    this.role,
    this.photo,
  });

  final String id;
  final String kind; // 'request' | 'connection' | 'suggestion'
  final String name;
  final String? role;
  final String? photo;

  factory NetworkPerson.fromMap(Map<String, dynamic> m) {
    return NetworkPerson(
      id: m['id'] as String,
      kind: (m['kind'] as String?) ?? 'connection',
      name: (m['name'] as String?) ?? '',
      role: m['role'] as String?,
      photo: m['photo'] as String?,
    );
  }
}
