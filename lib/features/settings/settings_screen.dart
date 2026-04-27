import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import 'settings_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.dependencies,
    this.onDataChanged,
  });

  final AppDependencies dependencies;
  final VoidCallback? onDataChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<AppSettings> _settings;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _settings = widget.dependencies.settingsRepository.load();
  }

  Future<void> _save(AppSettings settings) async {
    await widget.dependencies.settingsRepository.save(settings);
    setState(() {
      _settings = Future.value(settings);
    });
  }

  Future<void> _toggleTracking(AppSettings settings, bool enabled) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      if (enabled) {
        final granted = await widget.dependencies.permissionService
            .ensureLocationTrackingPermission();
        if (!granted) {
          setState(() {
            _status = 'Location permission is required';
          });
          return;
        }
      }
      await widget.dependencies.saveTrackingEnabled(
        settings: settings,
        enabled: enabled,
      );
      final updated = settings.copyWith(trackingEnabled: enabled);
      setState(() {
        _settings = Future.value(updated);
      });
    } catch (error) {
      setState(() {
        _status = 'Tracking update failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _toggleNotifications(AppSettings settings, bool enabled) async {
    final updated = settings.copyWith(notificationEnabled: enabled);
    await _save(updated);
    if (enabled) {
      final granted = await widget.dependencies.permissionService
          .ensureNotificationPermission();
      if (!granted) {
        setState(() {
          _status = 'Notification permission is required';
        });
        return;
      }
      await widget.dependencies.notificationService.scheduleDailyInsight(
        hour: updated.notificationHour,
        minute: updated.notificationMinute,
      );
    } else {
      await widget.dependencies.notificationService.cancelDailyInsight();
    }
  }

  Future<void> _runProcessing() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await widget.dependencies.runDailyProcessingNow();
      widget.onDataChanged?.call();
      setState(() {
        _status = 'Daily processing finished';
      });
    } catch (_) {
      setState(() {
        _status = 'Daily processing failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: _settings,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final settings = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              key: const ValueKey('tracking-switch'),
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: const Text('Tracking'),
              subtitle: Text(
                settings.trackingEnabled
                    ? 'Tracking active'
                    : 'Tracking paused',
              ),
              value: settings.trackingEnabled,
              onChanged: _busy
                  ? null
                  : (enabled) => _toggleTracking(settings, enabled),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: const Text('Daily notification'),
              subtitle: Text(settings.notificationEnabled ? 'On' : 'Off'),
              value: settings.notificationEnabled,
              onChanged: _busy
                  ? null
                  : (enabled) => _toggleNotifications(settings, enabled),
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(_status!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            _EditableSettingsValueTile(
              key: const ValueKey('movement-threshold-edit'),
              title: 'Movement threshold',
              value: '${settings.minimumMovementMeters} m',
              icon: Icons.directions_walk,
              onTap: () => _editNumber(
                title: 'Movement threshold',
                initialValue: settings.minimumMovementMeters,
                suffix: 'm',
                onSave: (value) =>
                    _save(settings.copyWith(minimumMovementMeters: value)),
              ),
            ),
            _EditableSettingsValueTile(
              key: const ValueKey('stay-threshold-edit'),
              title: 'Minimum stay',
              value: '${settings.minimumStayMinutes} min',
              icon: Icons.timer_outlined,
              onTap: () => _editNumber(
                title: 'Minimum stay',
                initialValue: settings.minimumStayMinutes,
                suffix: 'min',
                onSave: (value) =>
                    _save(settings.copyWith(minimumStayMinutes: value)),
              ),
            ),
            _EditableSettingsValueTile(
              key: const ValueKey('retention-days-edit'),
              title: 'Raw point retention',
              value: '${settings.rawPointRetentionDays} days',
              icon: Icons.storage_outlined,
              onTap: () => _editNumber(
                title: 'Raw point retention',
                initialValue: settings.rawPointRetentionDays,
                suffix: 'days',
                onSave: (value) =>
                    _save(settings.copyWith(rawPointRetentionDays: value)),
              ),
            ),
            _EditableSettingsValueTile(
              key: const ValueKey('notification-time-edit'),
              title: 'Notification time',
              value:
                  '${settings.notificationHour.toString().padLeft(2, '0')}:'
                  '${settings.notificationMinute.toString().padLeft(2, '0')}',
              icon: Icons.notifications_active_outlined,
              onTap: () => _editNotificationTime(settings),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _runProcessing,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run daily processing now'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _confirmDeleteRawPoints,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Delete raw location points'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _confirmDeleteAllLocalData,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Delete all local data'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _confirmDeleteRawPoints() async {
    final confirmed = await _confirm(
      'Delete raw location points',
      'Summaries and insights will stay available.',
    );
    if (!confirmed) return;
    await widget.dependencies.maintenanceService.deleteRawLocationPoints();
    widget.onDataChanged?.call();
    setState(() {
      _status = 'Raw location points deleted';
    });
  }

  Future<void> _confirmDeleteAllLocalData() async {
    final confirmed = await _confirm(
      'Delete all local data',
      'This removes points, places, visits, summaries, and insights from this device.',
    );
    if (!confirmed) return;
    await widget.dependencies.maintenanceService.deleteAllLocalData();
    widget.onDataChanged?.call();
    setState(() {
      _status = 'All local data deleted';
    });
  }

  Future<void> _editNumber({
    required String title,
    required int initialValue,
    required String suffix,
    required Future<void> Function(int value) onSave,
  }) async {
    var input = initialValue.toString();
    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextFormField(
            key: const ValueKey('number-setting-field'),
            initialValue: initialValue.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(suffixText: suffix),
            onChanged: (value) {
              input = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(input);
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (value == null) return;
    await onSave(value);
  }

  Future<void> _editNotificationTime(AppSettings settings) async {
    var hourInput = settings.notificationHour.toString();
    var minuteInput = settings.notificationMinute.toString();
    final updated = await showDialog<AppSettings>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notification time'),
          content: Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const ValueKey('hour-setting-field'),
                  initialValue: settings.notificationHour.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hour'),
                  onChanged: (value) {
                    hourInput = value;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const ValueKey('minute-setting-field'),
                  initialValue: settings.notificationMinute.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minute'),
                  onChanged: (value) {
                    minuteInput = value;
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final hour = int.tryParse(hourInput);
                final minute = int.tryParse(minuteInput);
                if (hour == null || minute == null) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pop(
                  settings.copyWith(
                    notificationHour: hour,
                    notificationMinute: minute,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (updated == null) return;
    await _save(updated);
  }
}

class _EditableSettingsValueTile extends StatelessWidget {
  const _EditableSettingsValueTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value),
          const SizedBox(width: 8),
          const Icon(Icons.edit_outlined),
        ],
      ),
      onTap: onTap,
    );
  }
}
