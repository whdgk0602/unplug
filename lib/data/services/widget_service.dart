import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:project001/core/utils/time_formatter.dart';
import 'package:project001/data/models/world_state_model.dart';

class WidgetService {
  static const _providerName = 'UnplugWidgetProvider';

  static const _stageLabels = [
    '황량한 바다',
    '모래섬',
    '새싹 섬',
    '야자수 섬',
    '쌍야자 섬',
    '오두막 섬',
    '부두 섬',
    '등대 섬',
    '풍요로운 섬',
    '낙원 직전',
    '완전한 낙원',
    '신비로운 낙원',
    '전설의 섬',
  ];

  static Future<void> update({
    required WorldStateModel world,
    required int todayUnusedMinutes,
    required int todayResourceEarned,
  }) async {
    if (!Platform.isAndroid) return;

    final stage = world.stage.clamp(1, 12);
    final label = world.stage < _stageLabels.length ? _stageLabels[world.stage] : '전설의 섬';

    await HomeWidget.saveWidgetData<int>('stage', stage);
    await HomeWidget.saveWidgetData<String>('stageLabel', 'Lv.${world.stage} $label');
    await HomeWidget.saveWidgetData<String>(
      'unusedText',
      '오늘 ${TimeFormatter.formatMinutes(todayUnusedMinutes)} 절약',
    );
    await HomeWidget.saveWidgetData<String>('resourceText', '🌱 +$todayResourceEarned');
    await HomeWidget.updateWidget(androidName: _providerName);
  }
}
