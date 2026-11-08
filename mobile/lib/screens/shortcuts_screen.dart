import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_shortcut.dart';
import '../state/settings_provider.dart';
import '../theme/colors.dart';

class ShortcutsScreen extends StatelessWidget {
  const ShortcutsScreen({Key? key}) : super(key: key);

  void _showAddShortcutDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final pkgCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Application Shortcut'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'App Name (e.g. Disney+)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pkgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Android Package ID',
                  hintText: 'e.g. com.disney.disneyplus',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deep Link URI (Optional)',
                  hintText: 'e.g. https://www.disneyplus.com',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final pkg = pkgCtrl.text.trim();
              if (name.isNotEmpty && pkg.isNotEmpty) {
                final shortcut = AppShortcut(
                  id: 'shortcut-${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  packageId: pkg,
                  deepLink: linkCtrl.text.trim().isNotEmpty ? linkCtrl.text.trim() : null,
                  iconName: 'app',
                  isEnabled: true,
                  sortOrder: 10,
                );
                context.read<SettingsProvider>().addShortcut(shortcut);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Shortcut'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final shortcuts = settings.shortcuts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure App Shortcuts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Custom App',
            onPressed: () => _showAddShortcutDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: shortcuts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = shortcuts[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.tclRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.apps, color: AppColors.tclRed),
                ),
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  item.packageId,
                  style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: item.isEnabled,
                      activeColor: AppColors.tclRed,
                      onChanged: (val) {
                        final updatedList = List<AppShortcut>.from(shortcuts);
                        updatedList[index] = AppShortcut(
                          id: item.id,
                          name: item.name,
                          packageId: item.packageId,
                          deepLink: item.deepLink,
                          iconName: item.iconName,
                          isEnabled: val,
                          sortOrder: item.sortOrder,
                        );
                        settings.saveShortcuts(updatedList);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.statusRed),
                      onPressed: () => settings.removeShortcut(item.id),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
