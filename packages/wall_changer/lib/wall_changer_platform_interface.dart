import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wall_changer_method_channel.dart';

abstract class WallChangerPlatform extends PlatformInterface {
  /// Constructs a WallChangerPlatform.
  WallChangerPlatform() : super(token: _token);

  static final Object _token = Object();

  static WallChangerPlatform _instance = MethodChannelWallChanger();

  /// The default instance of [WallChangerPlatform] to use.
  ///
  /// Defaults to [MethodChannelWallChanger].
  static WallChangerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WallChangerPlatform] when
  /// they register themselves.
  static set instance(WallChangerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
