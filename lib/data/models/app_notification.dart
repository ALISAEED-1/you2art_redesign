/// A notification row, mirroring `public.notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.actorName,
    required this.body,
    required this.hasActions,
    required this.timeLabel,
    this.photo,
    this.brand,
  });

  final String id;
  final String actorName;
  final String body;
  final bool hasActions;
  final String timeLabel;
  final String? photo;
  final String? brand; // 'filmfare' | 'sparkle' | null

  factory AppNotification.fromMap(Map<String, dynamic> m) {
    return AppNotification(
      id: m['id'] as String,
      actorName: (m['actor_name'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      hasActions: m['has_actions'] == true,
      timeLabel: (m['time_label'] as String?) ?? '',
      photo: m['photo'] as String?,
      brand: m['brand'] as String?,
    );
  }
}
