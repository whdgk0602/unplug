import 'dart:math';

abstract class ScreenTimeService {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<int> getTodayUsageMinutes();
  Future<Map<String, int>> getUsageForDays(int days);
}

/// Mock implementation for development/demo.
/// Returns simulated screen time data so UI can be tested without
/// granting real device permissions.
///
/// TODO: Replace with platform-specific implementations:
///   - iOS: DeviceActivityMonitor + FamilyControls entitlement
///   - Android: UsageStatsManager via MethodChannel
class MockScreenTimeService implements ScreenTimeService {
  bool _permissionGranted = false;
  final Random _random = Random(42);

  @override
  Future<bool> hasPermission() async => _permissionGranted;

  @override
  Future<bool> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _permissionGranted = true;
    return true;
  }

  @override
  Future<int> getTodayUsageMinutes() async {
    if (!_permissionGranted) return 0;
    // Simulate usage that increases throughout the day
    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    // Base usage rate: ~3 hours for a full day
    final baseUsage = (minutesSinceMidnight * (180.0 / (24 * 60))).round();
    // Add some randomness (+/- 30 min)
    final variance = _random.nextInt(60) - 30;
    return (baseUsage + variance).clamp(0, 600);
  }

  @override
  Future<Map<String, int>> getUsageForDays(int days) async {
    if (!_permissionGranted) return {};
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      // Generate realistic usage: 90-300 min per day
      final seed = date.year * 10000 + date.month * 100 + date.day;
      final dayRandom = Random(seed);
      result[dateKey] = 90 + dayRandom.nextInt(210);
    }
    return result;
  }
}
