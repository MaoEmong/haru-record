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
            _status = '위치 권한이 필요합니다';
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
        _status = '추적 상태를 변경하지 못했습니다';
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
    if (enabled) {
      final granted = await widget.dependencies.permissionService
          .ensureNotificationPermission();
      if (!granted) {
        setState(() {
          _status = '알림 권한이 필요합니다';
        });
        return;
      }
      await _save(updated);
      await widget.dependencies.notificationService.scheduleDailyInsight(
        hour: updated.notificationHour,
        minute: updated.notificationMinute,
      );
    } else {
      await _save(updated);
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
        _status = '오늘 처리를 완료했습니다';
      });
    } catch (_) {
      setState(() {
        _status = '오늘 처리를 완료하지 못했습니다';
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
              title: const Text('위치 추적'),
              subtitle: Text(settings.trackingEnabled ? '추적 중' : '추적 중지'),
              value: settings.trackingEnabled,
              onChanged: _busy
                  ? null
                  : (enabled) => _toggleTracking(settings, enabled),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const ValueKey('notification-switch'),
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: const Text('일일 알림'),
              subtitle: Text(settings.notificationEnabled ? '켜짐' : '꺼짐'),
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
              title: '이동 기준 거리',
              value: '${settings.minimumMovementMeters} m',
              icon: Icons.directions_walk,
              onTap: () => _editNumber(
                title: '이동 기준 거리',
                initialValue: settings.minimumMovementMeters,
                suffix: 'm',
                onSave: (value) =>
                    _save(settings.copyWith(minimumMovementMeters: value)),
              ),
            ),
            _EditableSettingsValueTile(
              key: const ValueKey('stay-threshold-edit'),
              title: '최소 체류 시간',
              value: '${settings.minimumStayMinutes}분',
              icon: Icons.timer_outlined,
              onTap: () => _editNumber(
                title: '최소 체류 시간',
                initialValue: settings.minimumStayMinutes,
                suffix: '분',
                onSave: (value) =>
                    _save(settings.copyWith(minimumStayMinutes: value)),
              ),
            ),
            _EditableSettingsValueTile(
              key: const ValueKey('retention-days-edit'),
              title: '원본 위치 보관 기간',
              value: '${settings.rawPointRetentionDays}일',
              icon: Icons.storage_outlined,
              onTap: () => _editNumber(
                title: '원본 위치 보관 기간',
                initialValue: settings.rawPointRetentionDays,
                suffix: '일',
                onSave: (value) =>
                    _save(settings.copyWith(rawPointRetentionDays: value)),
              ),
            ),
            _EditableSettingsValueTile(
              key: const ValueKey('notification-time-edit'),
              title: '알림 시간',
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
              label: const Text('오늘 처리 실행'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _confirmDeleteRawPoints,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('원본 위치 기록 삭제'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _confirmDeleteAllLocalData,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('모든 로컬 데이터 삭제'),
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
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('삭제'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _confirmDeleteRawPoints() async {
    final confirmed = await _confirm('원본 위치 기록 삭제', '요약과 인사이트는 유지됩니다.');
    if (!confirmed) return;
    await widget.dependencies.maintenanceService.deleteRawLocationPoints();
    widget.onDataChanged?.call();
    setState(() {
      _status = '원본 위치 기록을 삭제했습니다';
    });
  }

  Future<void> _confirmDeleteAllLocalData() async {
    final confirmed = await _confirm(
      '모든 로컬 데이터 삭제',
      '이 기기의 위치 기록, 장소, 방문, 요약, 인사이트를 모두 삭제합니다.',
    );
    if (!confirmed) return;
    await widget.dependencies.maintenanceService.deleteAllLocalData();
    widget.onDataChanged?.call();
    setState(() {
      _status = '모든 로컬 데이터를 삭제했습니다';
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
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(input);
                Navigator.of(context).pop(parsed);
              },
              child: const Text('저장'),
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
          title: const Text('알림 시간'),
          content: Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const ValueKey('hour-setting-field'),
                  initialValue: settings.notificationHour.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '시'),
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
                  decoration: const InputDecoration(labelText: '분'),
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
              child: const Text('취소'),
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
              child: const Text('저장'),
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
