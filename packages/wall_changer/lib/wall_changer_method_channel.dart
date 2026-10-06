import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wall_changer_platform_interface.dart';

/// An implementation of [WallChangerPlatform] that uses method channels.
class MethodChannelWallChanger extends WallChangerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wall_changer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
