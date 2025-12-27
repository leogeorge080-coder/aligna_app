// lib/screens/programs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/program.dart';
import '../persistence/prefs.dart';
import '../providers/app_providers.dart';
import '../services/program_service.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String _tab = 'money';
  late Future<List<Program>> _programsFuture;

  @override
  void initState() {
    super.initState();
    _programsFuture = ProgramService.getAllPrograms();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaleFactor.clamp(1.0, 1.1);

    return MediaQuery(
      data: media.copyWith(textScaleFactor: textScale),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {
              _programsFuture = ProgramService.getAllPrograms();
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Program>>(
        future: _programsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Catalogue load failed: ${snap.error}'),
            );
          }

          final items = (snap.data ?? [])
            ..sort((a, b) => a.durationDays.compareTo(b.durationDays));

          print('📋 [ProgramsScreen] Loaded ${items.length} programs');
          for (final p in items) {
            print(
              '📋 [ProgramsScreen] Program: ${p.title} (${p.id}) - track: ${p.track}',
            );
          }

          final activeId = ref.watch(activeProgramIdProvider);
          print('📋 [ProgramsScreen] Active ID: $activeId');

          final active = activeId == null
              ? null
              : items
                    .where((p) => p.id == activeId)
                    .cast<Program?>()
                    .firstOrNull;

          print(
            '📋 [ProgramsScreen] Active program found: ${active != null ? active.title : 'null'}',
          );

          // Tabs (track filter)
          // Note: keep compatibility with older track naming:
          // - "identity" might be used in older catalogue for confidence/self-concept.
          final tracks = const [
            ('money', 'Money'),
            ('wealth', 'Wealth'),
            ('love', 'Love'),
            ('health', 'Health'),
            ('confidence', 'Confidence'),
            ('support', 'Support'),
            ('purpose', 'Purpose'),
          ];

          String normalizeTrack(String value) {
            return value
                .toLowerCase()
                .trim()
                .replaceAll(' ', '_')
                .replaceAll('-', '_');
          }

          bool matchesTab(Program p) {
            final t = normalizeTrack(p.track);
            final tab = normalizeTrack(_tab);

            switch (_tab) {
              case 'confidence':
                // Support both "confidence" and legacy "identity"
                return t == 'confidence' || t == 'identity';
              case 'money':
                return t == tab || t == 'abundance' || t == 'wealth';
              default:
                return t == tab;
            }
          }

          final filtered = items.where(matchesTab).toList()
            ..sort((a, b) => a.durationDays.compareTo(b.durationDays));

          print('📋 [ProgramsScreen] Current tab: $_tab');
          print('📋 [ProgramsScreen] Filtered programs: ${filtered.length}');
          for (final p in filtered) {
            print(
              '📋 [ProgramsScreen] Filtered: ${p.title} - track: ${p.track}',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (activeId != null) ...[
                _ActiveProgramCard(
                  active: active,
                  activeId: activeId,
                  onResume: () =>
                      ref.read(shellTabIndexProvider.notifier).state = 2,
                  onClear: () async {
                    await Prefs.clearActiveProgramId();
                    ref.read(activeProgramIdProvider.notifier).state = null;
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 14),
              ],

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (key, label) in tracks)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: _tab == key,
                          label: Text(label),
                          onSelected: (_) => setState(() => _tab = key),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    'No programs in this track yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

              for (final p in filtered) ...[
                _ProgramTile(
                  p: p,
                  isActive: p.id == activeId,
                  onPick: () => _selectProgram(p.id),
                ),
                const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    ),
    );
  }

  Future<void> _selectProgram(String programId) async {
    await Prefs.setActiveProgramId(programId);
    ref.read(activeProgramIdProvider.notifier).state = programId;

    // Go back to Coach tab immediately (nice handoff)
    ref.read(shellTabIndexProvider.notifier).state = 2;
  }
}

class _ActiveProgramCard extends StatelessWidget {
  const _ActiveProgramCard({
    required this.active,
    required this.activeId,
    required this.onResume,
    required this.onClear,
  });

  final Program? active;
  final String activeId;
  final VoidCallback onResume;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final title = active?.title ?? 'Money';
    final sub = active == null
        ? 'Resume your active program.'
        : '${active!.durationDays} days • ${active!.description}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Active',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(sub),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onResume,
                  child: const Text('Resume in Coach'),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({
    required this.p,
    required this.isActive,
    required this.onPick,
  });

  final Program p;
  final bool isActive;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      title: Row(
        children: [
          Expanded(
            child: Text(
              p.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text('${p.durationDays} days • ${p.description}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPick,
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
