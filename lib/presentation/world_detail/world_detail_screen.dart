import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project001/core/theme/app_colors.dart';
import 'package:project001/core/utils/time_formatter.dart';
import 'package:project001/data/models/growth_history_model.dart';
import 'package:project001/data/models/world_state_model.dart';
import 'package:project001/data/services/share_service.dart';
import 'package:project001/presentation/home/widgets/island_widget.dart';
import 'package:project001/presentation/providers/providers.dart';

class WorldDetailScreen extends ConsumerStatefulWidget {
  const WorldDetailScreen({super.key});

  @override
  ConsumerState<WorldDetailScreen> createState() => _WorldDetailScreenState();
}

class _WorldDetailScreenState extends ConsumerState<WorldDetailScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  List<GrowthHistoryModel> _history = [];
  bool _loadingHistory = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final repo = ref.read(worldRepositoryProvider);
    final history = await repo.getGrowthHistory();
    if (mounted) setState(() { _history = history; _loadingHistory = false; });
  }

  Future<void> _shareCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      // Offstage 위젯이 첫 프레임을 그릴 시간을 준다.
      await Future.delayed(const Duration(milliseconds: 50));
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final file = await ShareService.savePngToTemp(byteData.buffer.asUint8List());

      final sentToInstagram = await ShareService.shareToInstagramStory(file);
      if (!sentToInstagram) {
        await ShareService.shareGeneric(file, text: '나의 섬이 자라고 있어요 🌱 Unplug');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유 카드 생성 중 오류가 발생했어요')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worldAsync = ref.watch(worldProvider);
    final totalAsync = ref.watch(totalUnusedMinutesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.ios_share_rounded),
            tooltip: '인스타 스토리로 공유',
            onPressed: _isSharing ? null : _shareCard,
          ),
        ],
      ),
      body: worldAsync.when(
        data: (world) => Stack(
          children: [
            // 화면 밖으로 위치시켜 렌더링되는 9:16 공유 카드 (Instagram 스토리용)
            // Offstage는 paint()를 건너뛰어 캡처가 빈 이미지가 되므로 Positioned로 화면 밖에 배치한다.
            Positioned(
              left: -9999,
              top: 0,
              child: IgnorePointer(
                child: RepaintBoundary(
                  key: _shareCardKey,
                  child: _ShareCardContent(
                    world: world,
                    totalMinutes: totalAsync.value ?? 0,
                  ),
                ),
              ),
            ),
            CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Full island visual
                  Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: AppColors.skyGradient,
                        ),
                      ),
                      child: Center(
                        child: IslandWidget(stage: world.stage, size: MediaQuery.of(context).size.width * 0.85),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stage info
                        Row(
                          children: [
                            IslandStageLabel(stage: world.stage),
                            const Spacer(),
                            totalAsync.when(
                              data: (total) => Text(
                                '총 ${TimeFormatter.formatMinutes(total)} 절약',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Resources card
                        _ResourceCard(world: world),
                        const SizedBox(height: 24),

                        // Growth history
                        Text('성장 히스토리', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),

                        if (_loadingHistory)
                          const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        else if (_history.isEmpty)
                          _EmptyHistory()
                        else
                          ..._history.map((h) => _GrowthHistoryItem(history: h)),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('오류가 발생했어요')),
      ),
    );
  }
}

// ── Instagram 스토리용 9:16 공유 카드 (화면에는 보이지 않고 캡처 전용) ─────────────────

class _ShareCardContent extends StatelessWidget {
  final WorldStateModel world;
  final int totalMinutes;

  const _ShareCardContent({required this.world, required this.totalMinutes});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SizedBox(
        width: 360,
        height: 640,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.skyGradient,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Unplug',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              IslandWidget(stage: world.stage, size: 220, animate: false),
              const SizedBox(height: 24),
              IslandStageLabel(stage: world.stage),
              const SizedBox(height: 16),
              Text(
                '총 ${TimeFormatter.formatMinutes(totalMinutes)} 절약했어요',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '덜 쓸수록 자라나는 세계',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final WorldStateModel world;
  const _ResourceCard({required this.world});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat('총 씨앗', '🌱 ${world.totalResource}', AppColors.accent),
              _Stat('현재 단계', 'Lv.${world.stage}', AppColors.primary),
              _Stat('다음까지', world.isMaxStage ? '완성!' : '${world.nextStageRequirement - world.resourceInCurrentStage}', AppColors.primaryDark),
            ],
          ),
          if (!world.isMaxStage) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: world.stageProgress,
                minHeight: 12,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '다음 단계까지 ${((1 - world.stageProgress) * 100).round()}% 남았어요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
      ],
    );
  }
}

class _GrowthHistoryItem extends StatelessWidget {
  final GrowthHistoryModel history;
  const _GrowthHistoryItem({required this.history});

  @override
  Widget build(BuildContext context) {
    final date = TimeFormatter.fromDateKey(history.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('${history.toStage}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv.${history.fromStage} → Lv.${history.toStage}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryDark),
                ),
                Text(
                  TimeFormatter.formatDateFull(date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Text('🌱', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🌊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '아직 성장 기록이 없어요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '씨앗을 모아 섬을 키워보세요!',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
