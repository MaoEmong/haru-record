import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../app/responsive_type.dart';
import '../background/daily_insight_worker.dart';
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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Column(
                children: [
                  const _SettingsPageHeader(),
                  const SizedBox(height: 12),
                  _SettingsStatusArea(
                    message: _status,
                    repository: DiagnosticsRepository(
                      widget.dependencies.database,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const _TrustCard(),
                  const SizedBox(height: 22),
                  const _SettingsSectionLabel('기록'),
                  _SettingsGroup(
                    children: [
                _SettingsRow(
                  key: const ValueKey('tracking-switch'),
                  icon: Icons.route_outlined,
                  title: '하루 기록',
                  subtitle: settings.trackingEnabled
                      ? '오늘의 흐름을 기록하고 있어요'
                      : '쉬고 있어요',
                  trailing: Switch(
                    value: settings.trackingEnabled,
                    onChanged: _busy
                        ? null
                        : (enabled) => _toggleTracking(settings, enabled),
                  ),
                  onTap: _busy
                      ? null
                      : () => _toggleTracking(
                          settings,
                          !settings.trackingEnabled,
                        ),
                ),
                _SettingsRow(
                  key: const ValueKey('movement-threshold-edit'),
                  icon: Icons.directions_walk,
                  title: '움직임으로 볼 거리',
                  trailing: _SettingValue('${settings.minimumMovementMeters} m'),
                  onTap: () => _editNumber(
                    title: '움직임으로 볼 거리',
                    initialValue: settings.minimumMovementMeters,
                    suffix: 'm',
                    onSave: (value) => _save(
                      settings.copyWith(minimumMovementMeters: value),
                    ),
                  ),
                ),
                _SettingsRow(
                  key: const ValueKey('stay-threshold-edit'),
                  icon: Icons.timer_outlined,
                  title: '머문 곳으로 볼 시간',
                  trailing: _SettingValue('${settings.minimumStayMinutes}분'),
                  onTap: () => _editNumber(
                    title: '머문 곳으로 볼 시간',
                    initialValue: settings.minimumStayMinutes,
                    suffix: '분',
                    onSave: (value) =>
                        _save(settings.copyWith(minimumStayMinutes: value)),
                  ),
                ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SettingsSectionLabel('알림'),
                  _SettingsGroup(
                    children: [
                _SettingsRow(
                  key: const ValueKey('notification-switch'),
                  icon: Icons.notifications_none_outlined,
                  title: '돌아보기 알림',
                  subtitle: settings.notificationEnabled
                      ? '어제 하루가 정리되면 알려드릴게요'
                      : '쉬고 있어요',
                  trailing: Switch(
                    value: settings.notificationEnabled,
                    onChanged: _busy
                        ? null
                        : (enabled) => _toggleNotifications(settings, enabled),
                  ),
                  onTap: _busy
                      ? null
                      : () => _toggleNotifications(
                          settings,
                          !settings.notificationEnabled,
                        ),
                ),
                _SettingsRow(
                  key: const ValueKey('notification-time-edit'),
                  icon: Icons.schedule_outlined,
                  title: '돌아보기 알림 시간',
                  trailing: _SettingValue(
                    '${settings.notificationHour.toString().padLeft(2, '0')}:'
                    '${settings.notificationMinute.toString().padLeft(2, '0')}',
                  ),
                  onTap: () => _editNotificationTime(settings),
                ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SettingsSectionLabel('데이터'),
                  _SettingsGroup(
                    children: [
                _SettingsRow(
                  key: const ValueKey('retention-days-edit'),
                  icon: Icons.storage_outlined,
                  title: '자세한 위치 보관 기간',
                  trailing: _SettingValue('${settings.rawPointRetentionDays}일'),
                  onTap: () => _editNumber(
                    title: '자세한 위치 보관 기간',
                    initialValue: settings.rawPointRetentionDays,
                    suffix: '일',
                    onSave: (value) => _save(
                      settings.copyWith(rawPointRetentionDays: value),
                    ),
                  ),
                ),
                _SettingsRow(
                  icon: Icons.auto_awesome_outlined,
                  title: '어제 돌아보기 만들기',
                  subtitle: '어제 기록으로 돌아보기를 다시 만들어요',
                  onTap: _busy ? null : _runProcessing,
                ),
                _SettingsRow(
                  key: const ValueKey('delete-raw-points-button'),
                  icon: Icons.delete_sweep_outlined,
                  title: '자세한 위치 기록 비우기',
                  subtitle: '돌아보기와 하루 요약은 남겨둘게요',
                  onTap: _busy ? null : _confirmDeleteRawPoints,
                ),
                _SettingsRow(
                  icon: Icons.delete_forever_outlined,
                  title: '이 기기의 기록 모두 지우기',
                  subtitle: '위치, 장소, 요약, 돌아보기를 모두 지워요',
                  onTap: _busy ? null : _confirmDeleteAllLocalData,
                ),
                    ],
                  ),
                  ],
                ),
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
      '자세한 위치, 방문한 곳, 하루 요약, 돌아보기를 모두 지워요.',
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

class _SettingsPageHeader extends StatelessWidget {
  const _SettingsPageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '설정',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: responsiveTitleFontSize(
                context,
                30,
                minScale: 0.92,
                maxScale: 1.14,
              ),
              fontWeight: FontWeight.w300,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '기록 방식과 보관 기준을 조정해요.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
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
        color: message == null ? AppColors.paleBlue : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 56, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.blueGrey, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ] else
                const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingValue extends StatelessWidget {
  const _SettingValue(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.edit_outlined, color: AppColors.muted, size: 18),
      ],
    );
  }
}
