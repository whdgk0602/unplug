import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project001/core/theme/app_colors.dart';
import 'package:project001/core/utils/time_formatter.dart';
import 'package:project001/data/models/daily_record_model.dart';
import 'package:project001/presentation/providers/providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '일간'),
            Tab(text: '주간'),
            Tab(text: '월간'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DailyTab(),
          _WeeklyTab(),
          _MonthlyTab(),
        ],
      ),
    );
  }
}

// ── Daily Tab ──────────────────────────────────────────────────────────────────

class _DailyTab extends ConsumerWidget {
  const _DailyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final todayAsync = ref.watch(todayRecordProvider);
    final totalAsync = ref.watch(totalUnusedMinutesProvider);

    return settingsAsync.when(
      data: (settings) => todayAsync.when(
        data: (today) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SummaryCard(
              title: '오늘 목표',
              value: TimeFormatter.formatMinutes(settings.targetUsageMinutes),
              icon: Icons.flag_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: '오늘 사용',
              value: TimeFormatter.formatMinutes(today?.usageMinutes ?? 0),
              icon: Icons.phone_android_outlined,
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: '오늘 절약',
              value: TimeFormatter.formatMinutes(today?.unusedMinutes ?? 0),
              icon: Icons.savings_outlined,
              color: AppColors.success,
            ),
            const SizedBox(height: 24),
            Text('목표 달성률', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _UsageDonut(today: today, target: settings.targetUsageMinutes),
            const SizedBox(height: 24),
            totalAsync.when(
              data: (total) => _SummaryCard(
                title: '누적 절약 시간',
                value: TimeFormatter.formatMinutes(total),
                icon: Icons.access_time_filled,
                color: AppColors.primaryDark,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('오류가 발생했어요')),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('오류가 발생했어요')),
    );
  }
}

class _UsageDonut extends StatelessWidget {
  final DailyRecordModel? today;
  final int target;

  const _UsageDonut({required this.today, required this.target});

  @override
  Widget build(BuildContext context) {
    final used = today?.usageMinutes ?? 0;
    final unused = today?.unusedMinutes ?? 0;
    final over = (used - target).clamp(0, 999);

    final usedVal = used.clamp(0, target).toDouble();
    final unusedVal = unused.toDouble();

    if (usedVal + unusedVal == 0) {
      return Center(
        child: Text(
          '데이터가 없습니다',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 60,
          sections: [
            PieChartSectionData(
              value: usedVal,
              color: AppColors.warning,
              title: '사용\n${TimeFormatter.formatMinutes(used.clamp(0, target))}',
              radius: 40,
              titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            PieChartSectionData(
              value: unusedVal,
              color: AppColors.success,
              title: '절약\n${TimeFormatter.formatMinutes(unused)}',
              radius: 40,
              titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            if (over > 0)
              PieChartSectionData(
                value: over.toDouble(),
                color: AppColors.error.withOpacity(0.7),
                title: '초과\n${TimeFormatter.formatMinutes(over)}',
                radius: 40,
                titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly Tab ─────────────────────────────────────────────────────────────────

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyRecordsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return weeklyAsync.when(
      data: (records) => settingsAsync.when(
        data: (settings) => _WeeklyContent(records: records, target: settings.targetUsageMinutes),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('오류가 발생했어요')),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('오류가 발생했어요')),
    );
  }
}

class _WeeklyContent extends StatelessWidget {
  final List<DailyRecordModel> records;
  final int target;

  const _WeeklyContent({required this.records, required this.target});

  @override
  Widget build(BuildContext context) {
    final totalUnused = records.fold(0, (sum, r) => sum + r.unusedMinutes);
    final goalDays = records.where((r) => r.goalAchieved && r.unusedMinutes > 0).length;

    // Build 7-day data map
    final now = DateTime.now();
    final Map<String, DailyRecordModel?> dayMap = {};
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = TimeFormatter.toDateKey(d);
      dayMap[key] = null;
    }
    for (final r in records) {
      if (dayMap.containsKey(r.date)) dayMap[r.date] = r;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: '이번 주 절약',
                value: TimeFormatter.formatMinutes(totalUnused),
                icon: Icons.savings_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: '목표 달성일',
                value: '$goalDays / 7일',
                icon: Icons.check_circle_outline,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('비사용 시간 추이', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: _WeeklyBarChart(dayMap: dayMap, target: target),
        ),
        const SizedBox(height: 24),
        Text('일별 현황', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...dayMap.entries.map((e) => _DayRow(dateKey: e.key, record: e.value, target: target)),
      ],
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final Map<String, DailyRecordModel?> dayMap;
  final int target;

  const _WeeklyBarChart({required this.dayMap, required this.target});

  @override
  Widget build(BuildContext context) {
    final entries = dayMap.entries.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (target * 1.2).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final record = entries[groupIndex].value;
              return BarTooltipItem(
                TimeFormatter.formatMinutes(record?.unusedMinutes ?? 0),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= entries.length) return const SizedBox.shrink();
                final dateKey = entries[idx].key;
                final date = TimeFormatter.fromDateKey(dateKey);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    TimeFormatter.dayOfWeekShort(date),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((entry) {
          final idx = entry.key;
          final record = entry.value.value;
          final unused = record?.unusedMinutes ?? 0;
          final isToday = entry.value.key == TimeFormatter.toDateKey(DateTime.now());
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: unused.toDouble(),
                color: isToday ? AppColors.primary : AppColors.primaryLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                width: 28,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: target.toDouble(),
                  color: AppColors.border,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String dateKey;
  final DailyRecordModel? record;
  final int target;

  const _DayRow({required this.dateKey, required this.record, required this.target});

  @override
  Widget build(BuildContext context) {
    final date = TimeFormatter.fromDateKey(dateKey);
    final isToday = dateKey == TimeFormatter.toDateKey(DateTime.now());
    final achieved = record?.goalAchieved ?? false;
    final unused = record?.unusedMinutes ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isToday ? AppColors.primary.withOpacity(0.3) : AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Text(
                  TimeFormatter.dayOfWeekShort(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isToday ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isToday ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: record == null
                ? Text('기록 없음', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '절약 ${TimeFormatter.formatMinutes(unused)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: achieved ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '사용 ${TimeFormatter.formatMinutes(record!.usageMinutes)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
          ),
          if (record != null)
            Icon(
              achieved ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: achieved ? AppColors.success : AppColors.textHint,
              size: 20,
            ),
        ],
      ),
    );
  }
}

// ── Monthly Tab ────────────────────────────────────────────────────────────────

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlyRecordsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return monthlyAsync.when(
      data: (records) => settingsAsync.when(
        data: (settings) => _MonthlyContent(records: records, target: settings.targetUsageMinutes),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('오류가 발생했어요')),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('오류가 발생했어요')),
    );
  }
}

class _MonthlyContent extends StatelessWidget {
  final List<DailyRecordModel> records;
  final int target;

  const _MonthlyContent({required this.records, required this.target});

  @override
  Widget build(BuildContext context) {
    final totalUnused = records.fold(0, (sum, r) => sum + r.unusedMinutes);
    final goalDays = records.where((r) => r.goalAchieved && r.unusedMinutes > 0).length;

    // Best/worst day
    DailyRecordModel? bestDay, worstDay;
    for (final r in records) {
      if (r.unusedMinutes > 0) {
        if (bestDay == null || r.unusedMinutes > bestDay.unusedMinutes) bestDay = r;
        if (worstDay == null || r.usageMinutes > worstDay.usageMinutes) worstDay = r;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: '30일 총 절약',
                value: TimeFormatter.formatMinutes(totalUnused),
                icon: Icons.savings_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: '목표 달성일',
                value: '$goalDays / ${records.length}일',
                icon: Icons.check_circle_outline,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('30일 캘린더', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _CalendarHeatmap(records: records, target: target),
        const SizedBox(height: 24),
        Text('인사이트', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (bestDay != null)
          _InsightCard(
            label: '가장 고요한 날',
            value: '${TimeFormatter.formatDate(TimeFormatter.fromDateKey(bestDay.date))}  (${TimeFormatter.formatMinutes(bestDay.unusedMinutes)} 절약)',
            icon: '🌿',
            color: AppColors.accentLight,
          ),
        if (worstDay != null) ...[
          const SizedBox(height: 8),
          _InsightCard(
            label: '가장 많이 사용한 날',
            value: '${TimeFormatter.formatDate(TimeFormatter.fromDateKey(worstDay.date))}  (${TimeFormatter.formatMinutes(worstDay.usageMinutes)} 사용)',
            icon: '📱',
            color: const Color(0xFFFFF3E0),
          ),
        ],
      ],
    );
  }
}

class _CalendarHeatmap extends StatelessWidget {
  final List<DailyRecordModel> records;
  final int target;

  const _CalendarHeatmap({required this.records, required this.target});

  @override
  Widget build(BuildContext context) {
    final Map<String, DailyRecordModel> recordMap = {for (var r in records) r.date: r};
    final now = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final date = now.subtract(Duration(days: 29 - index));
        final key = TimeFormatter.toDateKey(date);
        final record = recordMap[key];

        Color cellColor;
        if (record == null) {
          cellColor = AppColors.border;
        } else if (!record.goalAchieved) {
          cellColor = AppColors.warning.withOpacity(0.4);
        } else {
          final intensity = (record.unusedMinutes / target).clamp(0.0, 1.0);
          cellColor = AppColors.success.withOpacity(0.2 + intensity * 0.6);
        }

        return Tooltip(
          message: record != null ? '절약 ${TimeFormatter.formatMinutes(record.unusedMinutes)}' : '기록 없음',
          child: Container(
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 9,
                  color: record != null && record.goalAchieved ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _InsightCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
