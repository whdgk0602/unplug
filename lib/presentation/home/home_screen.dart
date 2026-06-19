import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project001/core/constants/app_constants.dart';
import 'package:project001/core/theme/app_colors.dart';
import 'package:project001/core/utils/time_formatter.dart';
import 'package:project001/data/models/daily_record_model.dart';
import 'package:project001/data/models/world_state_model.dart';
import 'package:project001/data/services/widget_service.dart';
import 'package:project001/presentation/home/widgets/island_widget.dart';
import 'package:project001/presentation/providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final settings = ref.read(settingsProvider).value;
      if (settings != null) {
        final notifier = ref.read(todayRecordProvider.notifier);
        final record = await notifier.refresh(settings);
        if (notifier.lastResourceDelta > 0) {
          await ref.read(worldProvider.notifier).addResource(notifier.lastResourceDelta);
        }
        final world = ref.read(worldProvider).value;
        if (world != null) {
          await WidgetService.update(
            world: world,
            todayUnusedMinutes: record.unusedMinutes,
            todayResourceEarned: record.resourceEarned,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final worldAsync = ref.watch(worldProvider);
    final todayAsync = ref.watch(todayRecordProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: false,
              floating: true,
              backgroundColor: Colors.transparent,
              title: const Text(
                'Unplug',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, color: AppColors.textSecondary),
                  tooltip: '세계 전체 보기',
                  onPressed: () => context.push('/world-detail'),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: settingsAsync.when(
                data: (settings) => worldAsync.when(
                  data: (world) => todayAsync.when(
                    data: (today) => _HomeContent(
                      world: world,
                      today: today,
                      isRefreshing: _isRefreshing,
                    ),
                    loading: () => const _LoadingContent(),
                    error: (_, __) => const _ErrorContent(),
                  ),
                  loading: () => const _LoadingContent(),
                  error: (_, __) => const _ErrorContent(),
                ),
                loading: () => const _LoadingContent(),
                error: (_, __) => const _ErrorContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final WorldStateModel world;
  final DailyRecordModel? today;
  final bool isRefreshing;

  const _HomeContent({required this.world, required this.today, required this.isRefreshing});

  String get _statusMessage {
    if (today == null) return '내일부터 자라기 시작해요 🌱';
    if (today!.goalAchieved && today!.unusedMinutes > 0) {
      final idx = today!.unusedMinutes % AppConstants.positiveMessages.length;
      return AppConstants.positiveMessages[idx];
    }
    final idx = DateTime.now().day % AppConstants.neutralMessages.length;
    return AppConstants.neutralMessages[idx];
  }

  @override
  Widget build(BuildContext context) {
    final unusedMinutes = today?.unusedMinutes ?? 0;
    final resourceEarned = today?.resourceEarned ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Island
          GestureDetector(
            onTap: () => context.push('/world-detail'),
            child: IslandWidget(stage: world.stage, size: 280),
          ),

          const SizedBox(height: 4),
          IslandStageLabel(stage: world.stage),
          const SizedBox(height: 24),

          // Status message
          Text(
            _statusMessage,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Today stats card
          _TodayStatsCard(unusedMinutes: unusedMinutes, resourceEarned: resourceEarned),
          const SizedBox(height: 16),

          // Progress to next stage
          _StageProgressCard(world: world),
          const SizedBox(height: 16),

          // Permission banner (if needed)
          const _PermissionBanner(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _TodayStatsCard extends StatelessWidget {
  final int unusedMinutes;
  final int resourceEarned;

  const _TodayStatsCard({required this.unusedMinutes, required this.resourceEarned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4))],
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘 절약한 시간', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  TimeFormatter.formatMinutes(unusedMinutes),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: AppColors.border),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('오늘 씨앗', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text(
                      '+$resourceEarned',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageProgressCard extends StatelessWidget {
  final WorldStateModel world;

  const _StageProgressCard({required this.world});

  @override
  Widget build(BuildContext context) {
    if (world.isMaxStage) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏆', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text('완전한 낙원을 이뤘어요!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      );
    }

    final progress = world.stageProgress;
    final needed = world.nextStageRequirement;
    final earned = world.resourceInCurrentStage;
    final remaining = needed - earned;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('다음 단계까지', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '🌱 $earned / $needed 씨앗  (앞으로 $remaining 씨앗 더)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PermissionBanner extends ConsumerWidget {
  const _PermissionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider);
    if (hasPermission) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF8F00)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('데모 모드', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFFE65100))),
                const SizedBox(height: 2),
                Text(
                  '시뮬레이션 데이터로 작동 중입니다.\n설정에서 실제 스크린타임 권한을 허용하면 정확한 섬이 자랍니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFE65100)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 400,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 400,
      child: Center(child: Text('데이터를 불러오는 중 오류가 발생했어요.')),
    );
  }
}
