class BlockEnhanceRequest {
  final String programId;
  final int day;
  final String blockId;
  final String moodKey; // fine|stressed|tired_busy|curious
  final String language; // en/ar/hi/es
  final List<String> fallbackLines;
  final String? intention; // optional

  const BlockEnhanceRequest({
    required this.programId,
    required this.day,
    required this.blockId,
    required this.moodKey,
    required this.language,
    required this.fallbackLines,
    this.intention,
  });

  String get cacheKey =>
      'aligna:enhance:v1:$programId:d$day:$blockId:$moodKey:$language';
}
