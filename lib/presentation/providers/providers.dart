import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project001/core/constants/app_constants.dart';
import 'package:project001/core/utils/time_formatter.dart';
import 'package:project001/data/models/daily_record_model.dart';
import 'package:project001/data/models/settings_model.dart';
import 'package:project001/data/models/world_state_model.dart';
import 'package:project001/data/repositories/daily_record_repository.dart';
import 'package:project001/data/repositories/settings_repository.dart';
import 'package:project001/data/repositories/world_repository.dart';
import 'package:project001/data/services/screen_time_service.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository());
final dailyRecordRepositoryProvider = Provider<DailyRecordRepository>((ref) => DailyRecordRepository());
final worldRepositoryProvider = Provider<WorldRepository>((ref) => WorldRepository());
final screenTimeServiceProvider = Provider<ScreenTimeService>((ref) => MockScreenTimeService());

// ── Settings ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsModel>> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _repo.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setOnboardingDone() async {
    await _repo.setOnboardingDone();
    state = AsyncValue.data(state.value!.copyWith(onboardingDone: true));
  }

  Future<void> updateTargetUsage(int minutes) async {
    await _repo.updateTargetUsage(minutes);
    state = AsyncValue.data(state.value!.copyWith(targetUsageMinutes: minutes));
  }

  Future<void> updateSleepWindow(int startHour, int startMin, int endHour, int endMin) async {
    await _repo.updateSleepWindow(startHour, startMin, endHour, endMin);
    state = AsyncValue.data(state.value!.copyWith(
      sleepStartHour: startHour,
      sleepStartMinute: startMin,
      sleepEndHour: endHour,
      sleepEndMinute: endMin,
    ));
  }

  Future<void> updateNotification(bool enabled) async {
    await _repo.updateNotification(enabled);
    state = AsyncValue.data(state.value!.copyWith(notificationEnabled: enabled));
  }

  Future<void> resetAll() async {
    await _repo.resetAll();
    state = AsyncValue.data(const SettingsModel());
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsModel>>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

// ── World State ───────────────────────────────────────────────────────────────

class WorldNotifier extends StateNotifier<AsyncValue<WorldStateModel>> {
  final WorldRepository _worldRepo;

  WorldNotifier(this._worldRepo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final world = await _worldRepo.getWorldState();
      state = AsyncValue.data(world);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addResource(int amount) async {
    final dateKey = TimeFormatter.toDateKey(DateTime.now());
    final newState = await _worldRepo.addResource(amount, dateKey);
    state = AsyncValue.data(newState);
  }

  Future<void> reset() async {
    await _worldRepo.resetWorld();
    state = const AsyncValue.data(WorldStateModel());
  }

  Future<void> reload() async => _load();
}

final worldProvider =
    StateNotifierProvider<WorldNotifier, AsyncValue<WorldStateModel>>((ref) {
  return WorldNotifier(ref.watch(worldRepositoryProvider));
});

// ── Today's Record ────────────────────────────────────────────────────────────

class TodayRecordNotifier extends StateNotifier<AsyncValue<DailyRecordModel?>> {
  final DailyRecordRepository _recordRepo;
  final ScreenTimeService _screenTimeService;

  TodayRecordNotifier(this._recordRepo, this._screenTimeService)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final record = await _recordRepo.getTodayRecord();
      state = AsyncValue.data(record);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  int lastResourceDelta = 0;

  Future<DailyRecordModel> refresh(SettingsModel settings) async {
    final previous = await _recordRepo.getTodayRecord();
    final usageMinutes = await _screenTimeService.getTodayUsageMinutes();
    final unusedMinutes = (settings.targetUsageMinutes - usageMinutes).clamp(0, settings.targetUsageMinutes);
    final resourceEarned = unusedMinutes * AppConstants.resourcePerMinute;
    final dateKey = TimeFormatter.toDateKey(DateTime.now());

    final record = DailyRecordModel(
      date: dateKey,
      usageMinutes: usageMinutes,
      unusedMinutes: unusedMinutes,
      resourceEarned: resourceEarned,
      targetSnapshot: settings.targetUsageMinutes,
    );

    await _recordRepo.upsertRecord(record);
    // 같은 날 여러 번 새로고침해도 중복 적립되지 않도록 이전 값과의 차이만 반영
    lastResourceDelta = resourceEarned - (previous?.resourceEarned ?? 0);
    state = AsyncValue.data(record);
    return record;
  }
}

final todayRecordProvider =
    StateNotifierProvider<TodayRecordNotifier, AsyncValue<DailyRecordModel?>>((ref) {
  return TodayRecordNotifier(
    ref.watch(dailyRecordRepositoryProvider),
    ref.watch(screenTimeServiceProvider),
  );
});

// ── Weekly Records ────────────────────────────────────────────────────────────

final weeklyRecordsProvider = FutureProvider<List<DailyRecordModel>>((ref) async {
  final repo = ref.watch(dailyRecordRepositoryProvider);
  return repo.getLast7Days();
});

final monthlyRecordsProvider = FutureProvider<List<DailyRecordModel>>((ref) async {
  final repo = ref.watch(dailyRecordRepositoryProvider);
  return repo.getLast30Days();
});

final totalUnusedMinutesProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(dailyRecordRepositoryProvider);
  return repo.getTotalUnusedMinutes();
});

// ── Permission ────────────────────────────────────────────────────────────────

final hasPermissionProvider = StateProvider<bool>((ref) => false);
