// Habitat Data & Storage Management Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/storage_service.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/storage_summary.dart';

class DataStoragePage extends StatefulWidget {
  const DataStoragePage({super.key});

  @override
  State<DataStoragePage> createState() => _DataStoragePageState();
}

class _DataStoragePageState extends State<DataStoragePage> {
  late final StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService(ProfileRepository(LocalDatabase.instance));
  }

  void _showExportDialog() {
    final json = _storageService.exportJson();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitatTheme.surfacePrimary,
        title: const Text(
          'PORTABLE JSON BACKUP',
          style: TextStyle(fontFamily: HabitatTheme.fontHeading, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: Container(
          width: double.maxFinite,
          height: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HabitatTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HabitatTheme.surfaceBorder),
          ),
          child: SingleChildScrollView(
            child: Text(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: HabitatTheme.youngLeaf),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Data payload generated and ready for export.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: HabitatTheme.growthGreen, foregroundColor: HabitatTheme.forest),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitatTheme.surfacePrimary,
        title: const Text(
          'DELETE ALL LOCAL DATA',
          style: TextStyle(fontFamily: HabitatTheme.fontHeading, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.redAccent),
        ),
        content: const Text(
          'Are you sure you want to delete all local Habitat data? This will permanently erase your completed tasks, water history, nap sessions, and streaks.',
          style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: HabitatTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              _storageService.resetAllData();
              Navigator.of(ctx).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All local data has been reset to defaults.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _storageService.getStorageInfo();

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('DATA & STORAGE'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            StorageSummary(info: info),
            const SizedBox(height: 20),

            SettingsSection(
              title: 'DATA EXPORT & BACKUPS',
              children: [
                SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: 'Export My Data (JSON)',
                  subtitle: 'Generate portable JSON backup of all tasks and history',
                  onTap: _showExportDialog,
                ),
                SettingsTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear Cache & Temp Artifacts',
                  subtitle: 'Removes temporary files without affecting your tasks',
                  onTap: () {
                    _storageService.clearCache();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Cache cleared cleanly.')),
                    );
                  },
                ),
              ],
            ),

            SettingsSection(
              title: 'DANGER ZONE',
              children: [
                SettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete All Local Data',
                  subtitle: 'Irreversibly wipe all tasks, history, and streak progress',
                  isDestructive: true,
                  onTap: _showDeleteDataDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
