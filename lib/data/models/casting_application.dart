/// One application to a casting call, mirroring `public.casting_applications`.
class CastingApplication {
  const CastingApplication({
    required this.id,
    required this.castingCallId,
    required this.name,
    required this.photo,
    required this.status,
    required this.createdAt,
    this.age,
    this.height,
    this.gender,
    this.experience,
    this.note,
    this.phone,
    this.email,
  });

  final String id;
  final String castingCallId;
  final String name;
  final String photo;
  final String status; // received | accepted | rejected | wishlist
  final DateTime createdAt;
  final String? age;
  final String? height;
  final String? gender;
  final String? experience;
  final String? note;
  final String? phone;
  final String? email;

  factory CastingApplication.fromMap(Map<String, dynamic> m) {
    return CastingApplication(
      id: m['id'] as String,
      castingCallId: m['casting_call_id'] as String,
      name: (m['applicant_name'] as String?) ?? 'Applicant',
      photo:
          (m['applicant_photo'] as String?) ?? 'assets/images/profile_pic.png',
      status: (m['status'] as String?) ?? 'received',
      age: m['age'] as String?,
      height: m['height'] as String?,
      gender: m['gender'] as String?,
      experience: m['experience'] as String?,
      note: m['note'] as String?,
      phone: m['phone'] as String?,
      email: m['email'] as String?,
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}
