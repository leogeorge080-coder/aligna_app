class UserContext {
  final double moodScore;
  final String lastTarotCard;
  final String activeFrequency;
  final int streakCount;

  const UserContext({
    required this.moodScore,
    required this.lastTarotCard,
    required this.activeFrequency,
    required this.streakCount,
  });

  factory UserContext.empty() {
    return const UserContext(
      moodScore: 0.0,
      lastTarotCard: 'neutral',
      activeFrequency: 'neutral',
      streakCount: 0,
    );
  }

  factory UserContext.fromJson(Map<String, dynamic> json) {
    return UserContext(
      moodScore: (json['mood_score'] as num?)?.toDouble() ?? 0.0,
      lastTarotCard: (json['last_tarot_card'] as String?) ?? 'neutral',
      activeFrequency: (json['active_frequency'] as String?) ?? 'neutral',
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson({required String userId}) {
    return {
      'user_id': userId,
      'mood_score': moodScore,
      'last_tarot_card': lastTarotCard,
      'active_frequency': activeFrequency,
      'streak_count': streakCount,
    };
  }

  UserContext copyWith({
    double? moodScore,
    String? lastTarotCard,
    String? activeFrequency,
    int? streakCount,
  }) {
    return UserContext(
      moodScore: moodScore ?? this.moodScore,
      lastTarotCard: lastTarotCard ?? this.lastTarotCard,
      activeFrequency: activeFrequency ?? this.activeFrequency,
      streakCount: streakCount ?? this.streakCount,
    );
  }
}
