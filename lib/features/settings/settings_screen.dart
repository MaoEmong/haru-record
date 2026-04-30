import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../core/logging/app_logger.dart';
import '../../shared/widgets/music_player_widgets.dart';
import '../background/daily_insight_worker.dart';
import '../diagnostics/diagnostics_snapshot.dart';
import 'settings_models.dart';
import 'settings_view_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    required this.dependencies,
    this.onDataChanged,
  });

  final AppDependencies dependencies;
  final VoidCallback? onDataChanged;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  String? _status;
  var _diagnosticsRefreshVersion = 0;

  Future<void> _save(AppSettings settings) async {
    await saveSettings(widget.dependencies, settings);
    ref.invalidate(settingsProvider(widget.dependencies));
    _refreshDiagnostics();
  }

  Future<void> _toggleTracking(AppSettings settings, bool enabled) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final result = await toggleTracking(
        widget.dependencies,
        settings: settings,
        enabled: enabled,
      );
      switch (result) {
        case ToggleTrackingPermissionDenied():
          setState(() {
            _status = '하루를 기록하려면 위치 권한이 필요해요';
          });
        case ToggleTrackingUpdated():
          ref.invalidate(settingsProvider(widget.dependencies));
          _refreshDiagnostics();
      }
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Tracking setting update failed.',
        error: error,
        stackTrace: stackTrace,
      );
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
    final result = await toggleNotifications(
      widget.dependencies,
      settings: settings,
      enabled: enabled,
    );
    switch (result) {
      case ToggleNotificationPermissionDenied():
        setState(() {
          _status = '돌아보기 알림을 받으려면 알림 권한이 필요해요';
        });
      case ToggleNotificationUpdated():
        ref.invalidate(settingsProvider(widget.dependencies));
        _refreshDiagnostics();
    }
  }

  Future<void> _runProcessing() async {
    setState(() {
      _busy = true;
      _status = '어제 기록으로 돌아보기를 만들고 있어요...';
    });
    try {
      final result = await runDailyProcessing(widget.dependencies);
      widget.onDataChanged?.call();
      _refreshDiagnostics();
      setState(() {
        _status = _processingMessage(result);
      });
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Manual daily processing failed.',
        error: error,
        stackTrace: stackTrace,
      );
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

  void _refreshDiagnostics() {
    setState(() {
      _diagnosticsRefreshVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider(widget.dependencies));
    final diagnostics = ref.watch(
      settingsDiagnosticsProvider(
        SettingsDiagnosticsQuery(
          dependencies: widget.dependencies,
          refreshVersion: _diagnosticsRefreshVersion,
        ),
      ),
    );
    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('설정을 불러오지 못했어요')),
      data: (settings) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Column(
                children: [
                  const _SettingsPageHeader(),
                  const SizedBox(height: 2),
                  _SettingsStatusArea(
                    message: _status,
                    diagnostics: diagnostics,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: 96 + MediaQuery.paddingOf(context).bottom,
                ),
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
                          iconBackground: const Color(0xFF0D2A0D),
                          title: '하루 기록',
                          subtitle: settings.trackingEnabled
                              ? '오늘의 흐름을 기록하고 있어요'
                              : '쉬고 있어요',
                          trailing: Switch(
                            value: settings.trackingEnabled,
                            onChanged: _busy
                                ? null
                                : (enabled) =>
                                      _toggleTracking(settings, enabled),
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
                          iconBackground: const Color(0xFF10233A),
                          title: '움직임으로 볼 거리',
                          trailing: _SettingValue(
                            '${settings.minimumMovementMeters} m',
                          ),
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
                          iconBackground: const Color(0xFF2B2410),
                          title: '머문 곳으로 볼 시간',
                          trailing: _SettingValue(
                            '${settings.minimumStayMinutes}분',
                          ),
                          onTap: () => _editNumber(
                            title: '머문 곳으로 볼 시간',
                            initialValue: settings.minimumStayMinutes,
                            suffix: '분',
                            onSave: (value) => _save(
                              settings.copyWith(minimumStayMinutes: value),
                            ),
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
                          iconBackground: const Color(0xFF18233A),
                          title: '돌아보기 알림',
                          subtitle: settings.notificationEnabled
                              ? '어제 하루가 정리되면 알려드릴게요'
                              : '쉬고 있어요',
                          trailing: Switch(
                            value: settings.notificationEnabled,
                            onChanged: _busy
                                ? null
                                : (enabled) =>
                                      _toggleNotifications(settings, enabled),
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
                          iconBackground: const Color(0xFF1B1B2F),
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
                          iconBackground: const Color(0xFF202020),
                          title: '자세한 위치 보관 기간',
                          trailing: _SettingValue(
                            '${settings.rawPointRetentionDays}일',
                          ),
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
                          iconBackground: const Color(0xFF0D2A0D),
                          title: '어제 돌아보기 만들기',
                          subtitle: '어제 기록으로 돌아보기를 다시 만들어요',
                          onTap: _busy ? null : _runProcessing,
                        ),
                        _SettingsRow(
                          key: const ValueKey('delete-raw-points-button'),
                          icon: Icons.delete_sweep_outlined,
                          iconBackground: const Color(0xFF331D12),
                          title: '자세한 위치 기록 비우기',
                          subtitle: '돌아보기와 하루 요약은 남겨둘게요',
                          danger: true,
                          onTap: _busy ? null : _confirmDeleteRawPoints,
                        ),
                        _SettingsRow(
                          icon: Icons.delete_forever_outlined,
                          iconBackground: const Color(0xFF3A1111),
                          title: '이 기기의 기록 모두 지우기',
                          subtitle: '위치, 장소, 요약, 돌아보기를 모두 지워요',
                          danger: true,
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
    await deleteRawLocationPoints(widget.dependencies);
    widget.onDataChanged?.call();
    _refreshDiagnostics();
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
    await deleteAllLocalData(widget.dependencies);
    widget.onDataChanged?.call();
    ref.invalidate(settingsProvider(widget.dependencies));
    _refreshDiagnostics();
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
    return const MpPageHeader(title: '설정', subtitle: '기록 방식과 보관 기준을 조정해요.');
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mpSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.mpAccent.withValues(alpha: 0.24)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '기록은 이 기기에만 저장돼요',
                style: TextStyle(
                  color: AppColors.mpText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '움직임이 있을 때 중심으로 살펴 배터리 사용을 줄여요',
                style: TextStyle(color: AppColors.mpTextSub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsStatusArea extends StatelessWidget {
  const _SettingsStatusArea({required this.message, required this.diagnostics});

  final String? message;
  final AsyncValue<DiagnosticsSnapshot> diagnostics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DecoratedBox(
        key: const ValueKey('settings-status-area'),
        decoration: BoxDecoration(
          color: AppColors.mpSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: message == null
                ? AppColors.mpBorder
                : AppColors.mpAccent.withValues(alpha: 0.28),
          ),
        ),
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SettingsStatusText(
              message: message,
              diagnostics: diagnostics,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsStatusText extends StatelessWidget {
  const _SettingsStatusText({required this.message, required this.diagnostics});

  final String? message;
  final AsyncValue<DiagnosticsSnapshot> diagnostics;

  @override
  Widget build(BuildContext context) {
    final text = message ?? _diagnosticsText(diagnostics.value);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _BreathingStatusText(
        key: ValueKey('settings-status-$text'),
        text: text,
      ),
    );
  }

  String _diagnosticsText(DiagnosticsSnapshot? data) {
    if (data == null) return '기록 상태 확인 중';
    return '기록 상태 확인 · 방문 ${data.visitCount}개 · 돌아보기 ${data.reflectionCount}개';
  }
}

class _BreathingStatusText extends StatelessWidget {
  const _BreathingStatusText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final breath = 1 - (value - 0.5).abs() * 2;
        return Transform.scale(
          key: const ValueKey('settings-status-breath'),
          scale: 1 + breath * 0.025,
          child: Opacity(opacity: 0.72 + breath * 0.28, child: child),
        );
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.mpTextSub,
          fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mpText,
          fontSize: 16,
          fontWeight: FontWeight.w700,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mpSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.mpBorder),
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(height: 1, indent: 66, color: AppColors.mpBorder),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    this.subtitle,
    this.trailing,
    this.danger = false,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = danger ? const Color(0xFFFF6B6B) : AppColors.mpText;
    final secondary = danger ? const Color(0xFFFF9A9A) : AppColors.mpTextSub;
    final iconColor = danger ? const Color(0xFFFF6B6B) : AppColors.mpAccent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(icon, color: iconColor, size: 19),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(color: secondary, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ] else
                Icon(Icons.chevron_right, color: secondary),
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
            color: AppColors.mpTextSub,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.edit_outlined, color: AppColors.mpTextSub, size: 18),
      ],
    );
  }
}
