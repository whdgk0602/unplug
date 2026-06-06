class AppConstants {
  AppConstants._();

  static const int defaultTargetMinutes = 180; // 3 hours
  static const int defaultSleepStartHour = 0;
  static const int defaultSleepEndHour = 7;
  static const int minTargetMinutes = 60; // 1 hour
  static const int maxTargetMinutes = 480; // 8 hours

  // Resource calculation: 1 minute unused = 1 seed
  static const int resourcePerMinute = 1;

  // Island stages and required resources per stage
  static const int maxStage = 12;
  static const List<int> stageRequirements = [
    0,    // stage 0→1: 즉시 (시작 상태)
    60,   // stage 1→2: 1시간
    120,  // stage 2→3: 2시간
    180,  // stage 3→4: 3시간
    240,  // stage 4→5: 4시간
    300,  // stage 5→6: 5시간
    400,  // stage 6→7: ~6.7시간
    500,  // stage 7→8: ~8.3시간
    600,  // stage 8→9: 10시간
    700,  // stage 9→10: ~11.7시간
    800,  // stage 10→11: ~13.3시간
    900,  // stage 11→12: 15시간
    1000, // stage 12: 최종 낙원
  ];

  static int resourceRequiredForStage(int stage) {
    if (stage < 0 || stage >= stageRequirements.length) return 0;
    return stageRequirements[stage];
  }

  static int totalResourceForStage(int stage) {
    int total = 0;
    for (int i = 0; i < stage && i < stageRequirements.length; i++) {
      total += stageRequirements[i];
    }
    return total;
  }

  // Status messages based on performance
  static const List<String> positiveMessages = [
    '오늘 고요했네요 🌿',
    '잘 참아냈어요 ✨',
    '세계가 조금 더 자랐어요 🌱',
    '오늘 하루도 수고했어요 🌙',
    '조용한 하루였네요 🍃',
  ];

  static const List<String> neutralMessages = [
    '내일 다시 시작해요 🌅',
    '오늘은 쉬어가는 날이에요 ☁️',
    '매일 조금씩 나아가고 있어요 🌊',
  ];
}
