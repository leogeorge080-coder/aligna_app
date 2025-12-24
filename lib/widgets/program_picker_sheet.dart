import 'package:flutter/material.dart';
import '../models/program_catalogue_item.dart';

class ProgramPickerSheet extends StatefulWidget {
  const ProgramPickerSheet({
    super.key,
    required this.items,
    required this.isPro,
    required this.onPick,
    required this.onUpsellRequested,
  });

  final List<ProgramCatalogueItem> items;
  final bool isPro;

  final void Function(ProgramCatalogueItem item) onPick;
  final VoidCallback onUpsellRequested;

  @override
  State<ProgramPickerSheet> createState() => _ProgramPickerSheetState();
}

class _ProgramPickerSheetState extends State<ProgramPickerSheet> {
  String _tab = 'money';
  String _searchQuery = '';
  String _sortBy = 'duration'; // 'duration', 'alphabetical'

  @override
  Widget build(BuildContext context) {
    final tracks = const [
      ('money', 'Money'),
      ('wealth', 'Wealth'),
      ('health', 'Health'),
      ('love', 'Love'),
      ('confidence', 'Confidence'),
      ('support', 'Support'),
    ];

    var filtered = widget.items.where((p) => p.track == _tab).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.title.toLowerCase().contains(query) ||
                p.shortDescription.toLowerCase().contains(query),
          )
          .toList();
    }

    // Apply sorting
    if (_sortBy == 'alphabetical') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else {
      // Default: duration
      filtered.sort((a, b) => a.durationDays.compareTo(b.durationDays));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choose a program',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search programs...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),

            // Sort
            Row(
              children: [
                const Text('Sort by:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(
                      value: 'duration',
                      child: Text('Duration'),
                    ),
                    DropdownMenuItem(
                      value: 'alphabetical',
                      child: Text('Name'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _sortBy = value!),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tabs
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

            // List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final locked = p.proOnly && !widget.isPro;

                  return ListTile(
                    title: Text(
                      p.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${p.durationDays} days • ${p.shortDescription}',
                    ),
                    trailing: locked
                        ? TextButton(
                            onPressed: widget.onUpsellRequested,
                            child: const Text('Pro'),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: locked
                        ? widget.onUpsellRequested
                        : () => widget.onPick(p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
