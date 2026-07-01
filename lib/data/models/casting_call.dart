/// A casting call, mirroring `public.casting_calls`.
class CastingCall {
  const CastingCall({
    required this.id,
    required this.projectTitle,
    required this.ownerName,
    required this.ownerPhoto,
    required this.createdAt,
    this.ownerId,
    this.shortDescription,
    this.location,
    this.locationFull,
    this.type,
    this.crewRequired,
    this.shoot,
    this.shootDetails,
    this.budget,
    this.budgetFull,
    this.position,
    this.age,
    this.height,
    this.gender,
    this.email,
    this.phone,
    this.publishedDate,
    this.appliedByMe = false,
    this.applicantsCount = 0,
    this.isMine = false,
  });

  final String id;
  final String? ownerId;
  final String ownerName;
  final String ownerPhoto;
  final String projectTitle;
  final String? shortDescription;
  final String? location;
  final String? locationFull;
  final String? type;
  final String? crewRequired;
  final String? shoot;
  final String? shootDetails;
  final String? budget;
  final String? budgetFull;
  final String? position;
  final String? age;
  final String? height;
  final String? gender;
  final String? email;
  final String? phone;
  final String? publishedDate;
  final DateTime createdAt;
  final bool appliedByMe;
  final int applicantsCount;
  final bool isMine;

  String get locationLabel => (location ?? '').isNotEmpty ? location! : '—';
  String get typeLabel => (type ?? '').isNotEmpty ? type! : '—';
  String get shootLabel => (shoot ?? '').isNotEmpty ? shoot! : '—';
  String get budgetLabel => (budget ?? '').isNotEmpty ? budget! : '—';

  factory CastingCall.fromMap(Map<String, dynamic> m) {
    final appsCount = m['casting_applications'];
    int count = 0;
    if (appsCount is List && appsCount.isNotEmpty) {
      final c = appsCount.first['count'];
      if (c is int) count = c;
    }
    // Prefer the owner's CURRENT profile (avatar/name) over the snapshot stored
    // on the casting call at creation time, so avatar/name changes show here too.
    final owner = m['profiles'];
    String? liveAvatar;
    String liveName = '';
    if (owner is Map) {
      final a = owner['avatar_url'];
      if (a is String && a.isNotEmpty) liveAvatar = a;
      final fn = (owner['first_name'] as String?)?.trim() ?? '';
      final ln = (owner['last_name'] as String?)?.trim() ?? '';
      liveName = [fn, ln].where((s) => s.isNotEmpty).join(' ');
    }
    return CastingCall(
      id: m['id'] as String,
      ownerId: m['owner_id'] as String?,
      ownerName: liveName.isNotEmpty
          ? liveName
          : ((m['owner_name'] as String?) ?? 'You2Art User'),
      ownerPhoto: liveAvatar ??
          ((m['owner_photo'] as String?) ?? 'assets/images/profile_pic.png'),
      projectTitle: (m['project_title'] as String?) ?? 'Untitled',
      shortDescription: m['short_description'] as String?,
      location: m['location'] as String?,
      locationFull: m['location_full'] as String?,
      type: m['type'] as String?,
      crewRequired: m['crew_required'] as String?,
      shoot: m['shoot'] as String?,
      shootDetails: m['shoot_details'] as String?,
      budget: m['budget'] as String?,
      budgetFull: m['budget_full'] as String?,
      position: m['position'] as String?,
      age: m['age'] as String?,
      height: m['height'] as String?,
      gender: m['gender'] as String?,
      email: m['email'] as String?,
      phone: m['phone'] as String?,
      publishedDate: m['published_date'] as String?,
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      appliedByMe: m['applied'] == true,
      isMine: m['is_mine'] == true,
      applicantsCount: count,
    );
  }
}
