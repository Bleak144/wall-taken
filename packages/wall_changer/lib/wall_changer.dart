import 'package:flutter/services.dart';

class WallChanger {
  static const MethodChannel _channel = MethodChannel('wall_changer');

  static Future<void> setWallpaper(String path, {String target = 'both'}) async {
    await _channel.invokeMethod('setWallpaper', {'path': path, 'target': target});
  }
}