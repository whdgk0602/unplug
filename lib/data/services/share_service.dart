import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static const _channel = MethodChannel('com.unplug.app/share');

  static Future<File> savePngToTemp(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/unplug_growth_card.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Instagram 앱이 설치되어 있으면 스토리 편집 화면으로 바로 전달.
  /// 설치되어 있지 않거나 Android가 아니면 false를 반환해 일반 공유로 대체하게 한다.
  static Future<bool> shareToInstagramStory(File imageFile) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('shareToInstagramStory', {
        'imagePath': imageFile.path,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> shareGeneric(File imageFile, {String? text}) async {
    await Share.shareXFiles([XFile(imageFile.path)], text: text);
  }
}
