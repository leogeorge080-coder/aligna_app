// lib/screens/programs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/program_catalogue_loader.dart';
import '../models/program_catalogue_item.dart';
import '../persistence/prefs.dart';
import '../providers/app_providers.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String _tab = 'money';

  Future<List<ProgramCatalogueItem>> _load() async {
    final raw = await ProgramCatalogueLoader.load();
    return raw
        .map((m) => ProgramCatalogueItem.fromJson(m))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<ProgramCatalogueItem>>(
        future: _load(),
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

          final activeId = ref.watch(activeProgramIdProvider);

          final active = activeId == null
              ? null
              : items
                    .where((p) => p.programId == activeId)
                    .cast<ProgramCatalogueItem?>()
                    .firstOrNull;

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

          bool _matchesTab(ProgramCatalogueItem p) {
            final t = p.track;

            switch (_tab) {
              case 'confidence':
                // Support both "confidence" and legacy "identity"
                return t == 'confidence' || t == 'identity';
              default:
                return t == _tab;
            }
          }

          final filtered = items.where(_matchesTab).toList()
            ..sort((a, b) => a.durationDays.compareTo(b.durationDays));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (activeId != null) ...[
                _ActiveProgramCard(
                  active: active,
                  activeId: activeId,
                  onResume: () =>
                      ref.read(shellTabIndexProvider.notifier).state = 0,
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
                  isActive: p.programId == activeId,
                  onPick: () => _selectProgram(p.programId),
                ),
                const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectProgram(String programId) async {
    await Prefs.setActiveProgramId(programId);
    ref.read(activeProgramIdProvider.notifier).state = programId;

    // Go back to Coach tab immediately (nice handoff)
    ref.read(shellTabIndexProvider.notifier).state = 0;
  }
}

class _ActiveProgramCard extends StatelessWidget {
  const _ActiveProgramCard({
    required this.active,
    required this.activeId,
    required this.onResume,
    required this.onClear,
  });

  final ProgramCatalogueItem? active;
  final String activeId;
  final VoidCallback onResume;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final title = active?.title ?? activeId;
    final sub = active == null
        ? 'Resume your active program.'
        : '${active!.durationDays} days • ${active!.shortDescription}';

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

  final ProgramCatalogueItem p;
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
      subtitle: Text('${p.durationDays} days • ${p.shortDescription}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPick,
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
