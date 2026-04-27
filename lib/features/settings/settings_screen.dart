import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../background/daily_insight_worker.dart';
import '../debug/debug_validation_seeder.dart';
import '../diagnostics/diagnostics_repository.dart';
import '../diagnostics/diagnostics_snapshot.dart';
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
            _status = '하루를 기록하려면 위치 권한이 필요해요';
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
        _status = '하루 기록을 바꾸지 못했어요';
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
          _status = '돌아보기 알림을 받으려면 알림 권한이 필요해요';
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
      _status = '어제 기록으로 돌아보기를 만들고 있어요...';
    });
    try {
      final result = await widget.dependencies.runDailyProcessingNow();
      widget.onDataChanged?.call();
      setState(() {
        _status = _processingMessage(result);
      });
    } catch (_) {
      setState(() {
        _status = '돌아보기를 만들지 못했어요';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _seedDebugYesterdayVisit() async {
    await DebugValidationSeeder(
      widget.dependencies.database,
    ).seedYesterdayVisit();
    widget.onDataChanged?.call();
    setState(() {
      _status = '검증용 어제 기록을 넣었어요';
    });
  }

  String _processingMessage(DailyProcessingResult result) {
    return switch (result.outcome) {
      DailyProcessingOutcome.createdReflection => '어제 돌아보기를 만들었어요',
      DailyProcessingOutcome.noRawRecords => '아직 돌아볼 기록이 없어요',
      DailyProcessingOutcome.noYesterdayRecords =>
        '어제 기록이 아직 없어요. 오늘 기록은 내일 돌아볼 수 있어요',
      DailyProcessingOutcome.noHighlights => '어제 기록은 봤지만 특별한 변화는 없었어요',
    };
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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _SettingsStatusArea(
                message: _status,
                repository: DiagnosticsRepository(widget.dependencies.database),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  const _TrustCard(),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    key: const ValueKey('tracking-switch'),
                    tileColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: AppColors.border),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: const Text('하루 기록'),
                    subtitle: Text(
                      settings.trackingEnabled ? '오늘의 흐름을 기록하고 있어요' : '꺼져 있어요',
                    ),
                    value: settings.trackingEnabled,
                    onChanged: _busy
                        ? null
                        : (enabled) => _toggleTracking(settings, enabled),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    key: const ValueKey('notification-switch'),
                    tileColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: AppColors.border),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: const Text('돌아보기 알림'),
                    subtitle: Text(
                      settings.notificationEnabled
                          ? '어제 하루가 정리되면 알려드릴게요'
                          : '꺼져 있어요',
                    ),
                    value: settings.notificationEnabled,
                    onChanged: _busy
                        ? null
                        : (enabled) => _toggleNotifications(settings, enabled),
                  ),
                  const SizedBox(height: 18),
                  _EditableSettingsValueTile(
                    key: const ValueKey('movement-threshold-edit'),
                    title: '움직임으로 볼 거리',
                    value: '${settings.minimumMovementMeters} m',
                    icon: Icons.directions_walk,
                    onTap: () => _editNumber(
                      title: '움직임으로 볼 거리',
                      initialValue: settings.minimumMovementMeters,
                      suffix: 'm',
                      onSave: (value) => _save(
                        settings.copyWith(minimumMovementMeters: value),
                      ),
                    ),
                  ),
                  _EditableSettingsValueTile(
                    key: const ValueKey('stay-threshold-edit'),
                    title: '머문 곳으로 볼 시간',
                    value: '${settings.minimumStayMinutes}분',
                    icon: Icons.timer_outlined,
                    onTap: () => _editNumber(
                      title: '머문 곳으로 볼 시간',
                      initialValue: settings.minimumStayMinutes,
                      suffix: '분',
                      onSave: (value) =>
                          _save(settings.copyWith(minimumStayMinutes: value)),
                    ),
                  ),
                  _EditableSettingsValueTile(
                    key: const ValueKey('retention-days-edit'),
                    title: '자세한 위치 보관 기간',
                    value: '${settings.rawPointRetentionDays}일',
                    icon: Icons.storage_outlined,
                    onTap: () => _editNumber(
                      title: '자세한 위치 보관 기간',
                      initialValue: settings.rawPointRetentionDays,
                      suffix: '일',
                      onSave: (value) => _save(
                        settings.copyWith(rawPointRetentionDays: value),
                      ),
                    ),
                  ),
                  _EditableSettingsValueTile(
                    key: const ValueKey('notification-time-edit'),
                    title: '돌아보기 알림 시간',
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
                    label: const Text('어제 돌아보기 만들기'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('delete-raw-points-button'),
                    onPressed: _busy ? null : _confirmDeleteRawPoints,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('자세한 위치 기록 비우기'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _confirmDeleteAllLocalData,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('이 기기의 기록 모두 지우기'),
                  ),
                  if (widget.dependencies.showDebugValidationTools) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _seedDebugYesterdayVisit,
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('검증용 어제 기록 넣기'),
                    ),
                  ],
                ],
              ),
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
    final confirmed = await _confirm(
      '자세한 위치 기록 비우기',
      '돌아보기와 하루 요약은 그대로 남겨둘게요.',
    );
    if (!confirmed) return;
    await widget.dependencies.maintenanceService.deleteRawLocationPoints();
    widget.onDataChanged?.call();
    setState(() {
      _status = '자세한 위치 기록을 비웠어요';
    });
  }

  Future<void> _confirmDeleteAllLocalData() async {
    final confirmed = await _confirm(
      '이 기기의 기록 모두 지우기',
      '자세한 위치, 자주 간 곳, 하루 요약, 돌아보기를 모두 지워요.',
    );
    if (!confirmed) return;
    await widget.dependencies.maintenanceService.deleteAllLocalData();
    widget.onDataChanged?.call();
    setState(() {
      _status = '이 기기의 기록을 모두 지웠어요';
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

class _TrustCard extends StatelessWidget {
  const _TrustCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.quietPanel(),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기록은 이 기기에만 저장돼요',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              '움직임이 있을 때 중심으로 살펴 배터리 사용을 줄여요',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsStatusArea extends StatelessWidget {
  const _SettingsStatusArea({required this.message, required this.repository});

  final String? message;
  final DiagnosticsRepository repository;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('settings-status-area'),
      decoration: BoxDecoration(
        color: message == null ? AppColors.paleBlue : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: message == null ? Colors.transparent : AppColors.border,
        ),
      ),
      child: SizedBox(
        height: 44,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: message == null
                ? FutureBuilder<DiagnosticsSnapshot>(
                    key: const ValueKey('settings-diagnostics-summary'),
                    future: repository.load(),
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      final text = data == null
                          ? '기록 상태 확인 중'
                          : '기록 상태 확인 · 위치 ${data.locationPointCount}개 · '
                                '방문 ${data.visitCount}개 · 돌아보기 ${data.reflectionCount}개';
                      return Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  )
                : Text(
                    message!,
                    key: ValueKey(message),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
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
      tileColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      leading: Icon(icon, color: AppColors.ink),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 8),
          const Icon(Icons.edit_outlined, color: AppColors.muted),
        ],
      ),
      onTap: onTap,
    );
  }
}
