class GrowthHistoryModel {
  final int? id;
  final String date;
  final int fromStage;
  final int toStage;

  const GrowthHistoryModel({
    this.id,
    required this.date,
    required this.fromStage,
    required this.toStage,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'from_stage': fromStage,
      'to_stage': toStage,
    };
  }

  factory GrowthHistoryModel.fromMap(Map<String, dynamic> map) {
    return GrowthHistoryModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      fromStage: map['from_stage'] as int,
      toStage: map['to_stage'] as int,
    );
  }
}
