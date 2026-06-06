import 'package:project001/core/constants/app_constants.dart';

class SettingsModel {
  final int targetUsageMinutes;
  final int sleepStartHour;
  final int sleepStartMinute;
  final int sleepEndHour;
  final int sleepEndMinute;
  final bool notificationEnabled;
  final bool onboardingDone;

  const SettingsModel({
    this.targetUsageMinutes = AppConstants.defaultTargetMinutes,
    this.sleepStartHour = AppConstants.defaultSleepStartHour,
    this.sleepStartMinute = 0,
    this.sleepEndHour = AppConstants.defaultSleepEndHour,
    this.sleepEndMinute = 0,
    this.notificationEnabled = false,
    this.onboardingDone = false,
  });

  SettingsModel copyWith({
    int? targetUsageMinutes,
    int? sleepStartHour,
    int? sleepStartMinute,
    int? sleepEndHour,
    int? sleepEndMinute,
    bool? notificationEnabled,
    bool? onboardingDone,
  }) {
    return SettingsModel(
      targetUsageMinutes: targetUsageMinutes ?? this.targetUsageMinutes,
      sleepStartHour: sleepStartHour ?? this.sleepStartHour,
      sleepStartMinute: sleepStartMinute ?? this.sleepStartMinute,
      sleepEndHour: sleepEndHour ?? this.sleepEndHour,
      sleepEndMinute: sleepEndMinute ?? this.sleepEndMinute,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'target_usage_minutes': targetUsageMinutes,
      'sleep_start_hour': sleepStartHour,
      'sleep_start_minute': sleepStartMinute,
      'sleep_end_hour': sleepEndHour,
      'sleep_end_minute': sleepEndMinute,
      'notification_enabled': notificationEnabled ? 1 : 0,
      'onboarding_done': onboardingDone ? 1 : 0,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      targetUsageMinutes: map['target_usage_minutes'] as int? ?? AppConstants.defaultTargetMinutes,
      sleepStartHour: map['sleep_start_hour'] as int? ?? 0,
      sleepStartMinute: map['sleep_start_minute'] as int? ?? 0,
      sleepEndHour: map['sleep_end_hour'] as int? ?? 7,
      sleepEndMinute: map['sleep_end_minute'] as int? ?? 0,
      notificationEnabled: (map['notification_enabled'] as int? ?? 0) == 1,
      onboardingDone: (map['onboarding_done'] as int? ?? 0) == 1,
    );
  }

  int get activeWindowMinutes {
    final sleepStartTotal = sleepStartHour * 60 + sleepStartMinute;
    final sleepEndTotal = sleepEndHour * 60 + sleepEndMinute;
    int sleepDuration;
    if (sleepEndTotal >= sleepStartTotal) {
      sleepDuration = sleepEndTotal - sleepStartTotal;
    } else {
      sleepDuration = (24 * 60 - sleepStartTotal) + sleepEndTotal;
    }
    return (24 * 60) - sleepDuration;
  }
}
