import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/content_providers.dart';
import '../providers/hymnal_providers.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

const _kDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _enabled;
  late TimeOfDay _time;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(reminderSettingsProvider);
    _enabled = settings.enabled;
    _time = TimeOfDay(hour: settings.hour, minute: settings.minute);
    _days = {...settings.days};
  }

  Future<void> _save() async {
    if (_enabled && _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day for the reminder')),
      );
      return;
    }
    if (_enabled) {
      final allowed = await notificationService.requestPermission();
      if (!allowed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications are blocked in system settings')),
          );
          setState(() => _enabled = false);
        }
        return;
      }
      await notificationService.scheduleWeekly(
        hour: _time.hour,
        minute: _time.minute,
        weekdays: _days,
      );
    } else {
      await notificationService.cancelDaily();
    }
    await ref.read(reminderSettingsProvider.notifier).update(
          enabled: _enabled,
          hour: _time.hour,
          minute: _time.minute,
          days: _days,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_enabled ? 'Reminder saved' : 'Reminder turned off')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final softColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_none_rounded,
                          color: AppColors.orange, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daily Reminder',
                                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                            Text('Get notified for devotion time',
                                style: TextStyle(fontSize: 12.5, color: softColor)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enabled,
                        onChanged: (value) => setState(() => _enabled = value),
                      ),
                    ],
                  ),
                  if (_enabled) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: softColor),
                        const SizedBox(width: 6),
                        Text('Reminder Time',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: softColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked =
                            await showTimePicker(context: context, initialTime: _time);
                        if (picked != null) setState(() => _time = picked);
                      },
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _time.format(context),
                                style: const TextStyle(
                                    fontSize: 15.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, color: softColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Days',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: softColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var weekday = 1; weekday <= 7; weekday++)
                          _DayChip(
                            label: _kDayLabels[weekday - 1],
                            selected: _days.contains(weekday),
                            onTap: () => setState(() {
                              if (!_days.remove(weekday)) _days.add(weekday);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Save Reminder',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.orange),
              title: const Text('Dark mode',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              value: isDark,
              onChanged: (value) => ref.read(themeModeProvider.notifier).setDark(value),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data != null
                    ? 'SDA Pack · Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                    : 'SDA Pack';
                return Text(version, style: TextStyle(fontSize: 12.5, color: softColor));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orange : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.orange : Theme.of(context).dividerColor,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}
