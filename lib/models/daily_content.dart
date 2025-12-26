import 'dart:ui';

class DailyContent {
  final String id;
  final String languageCode;
  final String programId; // e.g., 'money', 'health', 'love', 'healing'
  final int dayNumber; // 1 through 7 for Phase 1
  final String title;
  final String focus;
  final String question;
  final String microAction;
  final String? audioUrl; // URL to the ElevenLabs MP3 file
  final String? journalPrompt; // The language-specific reflection question
  final String? mentorMessage; // The text coach message to display
  final AuraConfig? auraConfig; // JSON object defining colors and pulse speed
  final String? videoUrl;

  const DailyContent({
    required this.id,
    required this.languageCode,
    required this.programId,
    required this.dayNumber,
    required this.title,
    required this.focus,
    required this.question,
    required this.microAction,
    this.audioUrl,
    this.journalPrompt,
    this.mentorMessage,
    this.auraConfig,
    this.videoUrl,
  });

  factory DailyContent.fromJson(Map<String, dynamic> json) {
    return DailyContent(
      id: (json['id'] as String?) ?? '',
      languageCode: (json['language_code'] as String?) ?? '',
      programId: (json['program_id'] as String?) ?? '',
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      title: (json['title'] as String?) ?? '',
      focus: (json['focus'] as String?) ?? '',
      question: (json['question'] as String?) ?? '',
      microAction: (json['micro_action'] as String?) ?? '',
      audioUrl: json['audio_url'] as String?,
      journalPrompt: json['journal_prompt'] as String?,
      mentorMessage: json['mentor_message'] as String?,
      auraConfig: json['aura_config'] != null
          ? AuraConfig.fromJson(json['aura_config'] as Map<String, dynamic>)
          : null,
      videoUrl: json['video_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language_code': languageCode,
      'program_id': programId,
      'day_number': dayNumber,
      'title': title,
      'focus': focus,
      'question': question,
      'micro_action': microAction,
      'audio_url': audioUrl,
      'journal_prompt': journalPrompt,
      'mentor_message': mentorMessage,
      'aura_config': auraConfig?.toJson(),
      'video_url': videoUrl,
    };
  }
}

class AuraConfig {
  final String primaryColor; // Hex color code
  final String secondaryColor; // Hex color code
  final double pulseSpeed; // Animation speed multiplier

  const AuraConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.pulseSpeed,
  });

  factory AuraConfig.fromJson(Map<String, dynamic> json) {
    return AuraConfig(
      primaryColor: (json['primaryColor'] as String?) ?? '#FFFFFF',
      secondaryColor: (json['secondaryColor'] as String?) ?? '#000000',
      pulseSpeed: (json['pulseSpeed'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'pulseSpeed': pulseSpeed,
    };
  }

  Color get primaryColorValue => Color(
    int.parse(primaryColor.replaceFirst('#', ''), radix: 16) + 0xFF000000,
  );
  Color get secondaryColorValue => Color(
    int.parse(secondaryColor.replaceFirst('#', ''), radix: 16) + 0xFF000000,
  );
}
