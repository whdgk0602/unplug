import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project001/core/constants/app_constants.dart';
import 'package:project001/core/theme/app_colors.dart';
import 'package:project001/core/utils/time_formatter.dart';
import 'package:project001/presentation/providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SectionHeader('목표 설정'),
            _TargetUsageTile(
              targetMinutes: settings.targetUsageMinutes,
              onChanged: (v) => ref.read(settingsProvider.notifier).updateTargetUsage(v),
            ),
            _SleepWindowTile(
              startHour: settings.sleepStartHour,
              startMinute: settings.sleepStartMinute,
              endHour: settings.sleepEndHour,
              endMinute: settings.sleepEndMinute,
              onChanged: (sh, sm, eh, em) =>
                  ref.read(settingsProvider.notifier).updateSleepWindow(sh, sm, eh, em),
            ),

            const Divider(height: 24),
            _SectionHeader('알림'),
            _SwitchTile(
              title: '저녁 요약 알림',
              subtitle: '하루 1회, 저녁에 절약 요약을 알려드려요',
              value: settings.notificationEnabled,
              onChanged: (v) => ref.read(settingsProvider.notifier).updateNotification(v),
            ),

            const Divider(height: 24),
            _SectionHeader('권한'),
            _PermissionTile(),

            const Divider(height: 24),
            _SectionHeader('프라이버시'),
            _InfoTile(
              icon: Icons.lock_outline,
              title: '온디바이스 저장',
              subtitle: '모든 데이터는 이 기기에만 저장됩니다.\n외부 서버로 전송되지 않아요.',
            ),

            const Divider(height: 24),
            _SectionHeader('앱'),
            _InfoTile(
              icon: Icons.info_outline,
              title: '버전',
              subtitle: 'Unplug 1.0.0',
            ),
            _ActionTile(
              icon: Icons.star_outline,
              title: '리뷰 남기기',
              color: AppColors.warning,
              onTap: () => _showReviewDialog(context),
            ),
            _ActionTile(
              icon: Icons.delete_outline,
              title: '데이터 초기화',
              color: AppColors.error,
              onTap: () => _showResetDialog(context),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('오류가 발생했어요')),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 초기화'),
        content: const Text('세계와 모든 기록이 삭제됩니다.\n이 작업은 되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(settingsProvider.notifier).resetAll();
              await ref.read(worldProvider.notifier).reset();
              final messenger = ScaffoldMessenger.of(context);
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('데이터가 초기화되었습니다')),
                );
              }
            },
            child: const Text('초기화', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('리뷰 남기기 ⭐'),
        content: const Text('Unplug가 도움이 되셨나요?\n앱 스토어에 리뷰를 남겨주시면 큰 힘이 됩니다!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('나중에')),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('남기기', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Section ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Target Usage ───────────────────────────────────────────────────────────────

class _TargetUsageTile extends StatefulWidget {
  final int targetMinutes;
  final ValueChanged<int> onChanged;

  const _TargetUsageTile({required this.targetMinutes, required this.onChanged});

  @override
  State<_TargetUsageTile> createState() => _TargetUsageTileState();
}

class _TargetUsageTileState extends State<_TargetUsageTile> {
  late int _local;

  @override
  void initState() {
    super.initState();
    _local = widget.targetMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final label = TimeFormatter.formatMinutes(_local);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text('하루 목표 사용시간', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
          Slider(
            value: _local.toDouble(),
            min: AppConstants.minTargetMinutes.toDouble(),
            max: AppConstants.maxTargetMinutes.toDouble(),
            divisions: (AppConstants.maxTargetMinutes - AppConstants.minTargetMinutes) ~/ 30,
            onChanged: (v) => setState(() => _local = v.round()),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1시간', style: Theme.of(context).textTheme.bodySmall),
              Text('8시간', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sleep Window ───────────────────────────────────────────────────────────────

class _SleepWindowTile extends StatelessWidget {
  final int startHour, startMinute, endHour, endMinute;
  final Function(int, int, int, int) onChanged;

  const _SleepWindowTile({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.onChanged,
  });

  String _fmt(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return _InfoTile(
      icon: Icons.bedtime_outlined,
      title: '수면 제외 시간',
      subtitle: '${_fmt(startHour, startMinute)} ~ ${_fmt(endHour, endMinute)}\n수면 중 비사용 시간은 집계하지 않아요.',
      trailing: TextButton(
        onPressed: () => _showTimePicker(context),
        child: const Text('변경'),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startHour, minute: startMinute),
      helpText: '수면 시작 시간',
    );
    if (startTime == null || !context.mounted) return;
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: endHour, minute: endMinute),
      helpText: '기상 시간',
    );
    if (endTime == null) return;
    onChanged(startTime.hour, startTime.minute, endTime.hour, endTime.minute);
  }
}

// ── Permission ─────────────────────────────────────────────────────────────────

class _PermissionTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider);
    return _InfoTile(
      icon: Icons.security_outlined,
      title: '스크린타임 권한',
      subtitle: hasPermission ? '권한이 허용되어 있습니다' : '권한이 없어 시뮬레이션 데이터를 사용 중입니다',
      trailing: hasPermission
          ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
          : TextButton(
              onPressed: () async {
                final service = ref.read(screenTimeServiceProvider);
                await service.requestPermission();
                ref.read(hasPermissionProvider.notifier).state = await service.hasPermission();
              },
              child: const Text('허용'),
            ),
    );
  }
}

// ── Shared Tiles ───────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _InfoTile({required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
        tileColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
