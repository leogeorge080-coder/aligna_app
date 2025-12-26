class UserEvent {
  final String id;
  final String userId;
  final String eventType;
  final Map<String, dynamic> eventPayload;
  final DateTime createdAt;

  const UserEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.eventPayload,
    required this.createdAt,
  });

  factory UserEvent.fromJson(Map<String, dynamic> json) {
    return UserEvent(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      eventType: (json['event_type'] as String?) ?? 'unknown',
      eventPayload: (json['event_payload'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
