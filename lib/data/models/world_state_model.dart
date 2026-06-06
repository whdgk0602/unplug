import 'package:project001/core/constants/app_constants.dart';

class WorldStateModel {
  final String themeId;
  final int stage;
  final int totalResource;
  final String? lastGrowthDate;

  const WorldStateModel({
    this.themeId = 'island',
    this.stage = 0,
    this.totalResource = 0,
    this.lastGrowthDate,
  });

  WorldStateModel copyWith({
    String? themeId,
    int? stage,
    int? totalResource,
    String? lastGrowthDate,
  }) {
    return WorldStateModel(
      themeId: themeId ?? this.themeId,
      stage: stage ?? this.stage,
      totalResource: totalResource ?? this.totalResource,
      lastGrowthDate: lastGrowthDate ?? this.lastGrowthDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'theme_id': themeId,
      'stage': stage,
      'total_resource': totalResource,
      'last_growth_date': lastGrowthDate,
    };
  }

  factory WorldStateModel.fromMap(Map<String, dynamic> map) {
    return WorldStateModel(
      themeId: map['theme_id'] as String? ?? 'island',
      stage: map['stage'] as int? ?? 0,
      totalResource: map['total_resource'] as int? ?? 0,
      lastGrowthDate: map['last_growth_date'] as String?,
    );
  }

  int get nextStageRequirement => AppConstants.resourceRequiredForStage(stage);
  int get totalResourceForCurrentStage => AppConstants.totalResourceForStage(stage);
  int get resourceInCurrentStage => totalResource - totalResourceForCurrentStage;

  double get stageProgress {
    final req = nextStageRequirement;
    if (req <= 0 || stage >= AppConstants.maxStage) return 1.0;
    return (resourceInCurrentStage / req).clamp(0.0, 1.0);
  }

  bool get isMaxStage => stage >= AppConstants.maxStage;
}
