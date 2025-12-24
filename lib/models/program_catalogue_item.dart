class ProgramCatalogueItem {
  final String programId;
  final String title;
  final int durationDays;
  final String track; // money/love/identity/health/purpose/support
  final bool isSupportProgram;
  final bool proOnly;
  final String shortDescription;

  const ProgramCatalogueItem({
    required this.programId,
    required this.title,
    required this.durationDays,
    required this.track,
    required this.isSupportProgram,
    required this.proOnly,
    required this.shortDescription,
  });

  factory ProgramCatalogueItem.fromJson(Map<String, dynamic> m) {
    return ProgramCatalogueItem(
      programId: (m['programId'] as String?) ?? '',
      title: (m['title'] as String?) ?? '',
      durationDays: (m['durationDays'] as num?)?.toInt() ?? 0,
      track: (m['track'] as String?) ?? 'support',
      isSupportProgram: (m['isSupportProgram'] as bool?) ?? false,
      proOnly: (m['proOnly'] as bool?) ?? true,
      shortDescription: (m['shortDescription'] as String?) ?? '',
    );
  }
}
