import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/core/services/notification_service.dart';
import 'package:hava/features/settings/application/settings_controller.dart';
import 'package:hava/features/settings/presentation/alert_settings_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _alerts = false;
  bool _loadingAlerts = true;

  @override
  void initState() {
    super.initState();
    NotificationService.isEnabled().then((value) {
      if (!mounted) return;
      setState(() {
        _alerts = value;
        _loadingAlerts = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final lowData = ref.watch(lowDataModeProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ظاهر', style: TextStyle(fontWeight: FontWeight.w900)),
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
          const Text(
            'هشدارها و داده',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _alerts,
            onChanged: _loadingAlerts
                ? null
                : (value) async {
                    setState(() => _loadingAlerts = true);
                    final success =
                        await NotificationService.setWeatherAlerts(value);
                    if (!mounted) return;
                    setState(() {
                      _alerts = success ? value : false;
                      _loadingAlerts = false;
                    });
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('مجوز اعلان فعال نشد.'),
                        ),
                      );
                    }
                  },
            title: const Text('هشدار بارش'),
            subtitle: const Text(
              'اگر احتمال بارش چند ساعت آینده بالا باشد اطلاع بده',
            ),
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('تنظیم جزئی هشدارها'),
            subtitle: const Text('آستانه بارش، باد، UV و کیفیت هوا'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AlertSettingsScreen(),
              ),
            ),
          ),
          SwitchListTile(
            value: lowData,
            onChanged: (value) =>
                ref.read(lowDataModeProvider.notifier).setEnabled(value),
            title: const Text('حالت کم‌مصرف اینترنت'),
            subtitle: const Text(
              'کاهش بروزرسانی‌های غیرضروری و مصرف داده پس‌زمینه',
            ),
            secondary: const Icon(Icons.data_saver_on_rounded),
          ),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.widgets_outlined),
            title: Text('ویجت صفحه اصلی'),
            subtitle: Text('ویجت «هوا» را از فهرست Widgetهای اندروید اضافه کن'),
          ),
          const ListTile(
            leading: Icon(Icons.language_rounded),
            title: Text('زبان و تاریخ'),
            subtitle: Text('فارسی • تقویم شمسی • اعداد فارسی'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('نسخه برنامه'),
            subtitle: Text('۱.۰.۰'),
          ),
        ],
      ),
    );
  }
}
