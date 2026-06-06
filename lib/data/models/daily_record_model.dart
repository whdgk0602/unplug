class DailyRecordModel {
  final String date; // 'YYYY-MM-DD'
  final int usageMinutes;
  final int unusedMinutes;
  final int resourceEarned;
  final int targetSnapshot;

  const DailyRecordModel({
    required this.date,
    this.usageMinutes = 0,
    this.unusedMinutes = 0,
    this.resourceEarned = 0,
    this.targetSnapshot = 180,
  });

  DailyRecordModel copyWith({
    String? date,
    int? usageMinutes,
    int? unusedMinutes,
    int? resourceEarned,
    int? targetSnapshot,
  }) {
    return DailyRecordModel(
      date: date ?? this.date,
      usageMinutes: usageMinutes ?? this.usageMinutes,
      unusedMinutes: unusedMinutes ?? this.unusedMinutes,
      resourceEarned: resourceEarned ?? this.resourceEarned,
      targetSnapshot: targetSnapshot ?? this.targetSnapshot,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'usage_minutes': usageMinutes,
      'unused_minutes': unusedMinutes,
      'resource_earned': resourceEarned,
      'target_snapshot': targetSnapshot,
    };
  }

  factory DailyRecordModel.fromMap(Map<String, dynamic> map) {
    return DailyRecordModel(
      date: map['date'] as String,
      usageMinutes: map['usage_minutes'] as int? ?? 0,
      unusedMinutes: map['unused_minutes'] as int? ?? 0,
      resourceEarned: map['resource_earned'] as int? ?? 0,
      targetSnapshot: map['target_snapshot'] as int? ?? 180,
    );
  }

  bool get goalAchieved => usageMinutes <= targetSnapshot;
  double get goalProgress => targetSnapshot > 0 ? (usageMinutes / targetSnapshot).clamp(0.0, 2.0) : 0.0;
}
