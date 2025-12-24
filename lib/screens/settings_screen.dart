import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Status'),
            subtitle: const Text('All features unlocked'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('English (restart required)'),
            onTap: () {
              // TODO: Implement language switch
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language switching coming soon')),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Download your reflections and progress'),
            onTap: () async {
              try {
                final data = await _collectUserData();
                await Share.share(data, subject: 'Aligna Data Export');
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Reset App Data'),
            subtitle: const Text('Clear all progress and reflections'),
            onTap: () => _showResetDialog(context),
          ),
        ],
      ),
    );
  }

  Future<String> _collectUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final data = <String, dynamic>{};

    for (final key in keys) {
      data[key] = prefs.get(key);
    }

    return data.toString();
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App Data'),
        content: const Text(
          'This will clear all your progress, reflections, and settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data reset. Restart the app.')),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
