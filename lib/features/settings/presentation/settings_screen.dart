import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/settings/application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final lowData = ref.watch(lowDataModeProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'ظاهر',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('خودکار'),
                icon: Icon(Icons.brightness_auto_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('روشن'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('تیره'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (value) {
              ref.read(themeModeProvider.notifier).setMode(value.first);
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            value: lowData,
            onChanged: (value) =>
                ref.read(lowDataModeProvider.notifier).setEnabled(value),
            title: const Text('حالت کم‌مصرف اینترنت'),
            subtitle: const Text(
              'کاهش درخواست‌های پس‌زمینه و بروزرسانی‌های غیرضروری',
            ),
            secondary: const Icon(Icons.data_saver_on_rounded),
          ),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.language_rounded),
            title: Text('زبان و تاریخ'),
            subtitle: Text('فارسی • تقویم شمسی • اعداد فارسی'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('نسخه برنامه'),
            subtitle: Text('۰.۲.۰'),
          ),
        ],
      ),
    );
  }
}
