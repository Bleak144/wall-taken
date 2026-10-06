import 'package:flutter_test/flutter_test.dart';
import 'package:wall_changer/wall_changer.dart';
import 'package:wall_changer/wall_changer_platform_interface.dart';
import 'package:wall_changer/wall_changer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWallChangerPlatform
    with MockPlatformInterfaceMixin
    implements WallChangerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WallChangerPlatform initialPlatform = WallChangerPlatform.instance;

  test('$MethodChannelWallChanger is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWallChanger>());
  });

  test('getPlatformVersion', () async {
    WallChanger wallChangerPlugin = WallChanger();
    MockWallChangerPlatform fakePlatform = MockWallChangerPlatform();
    WallChangerPlatform.instance = fakePlatform;

    expect(await wallChangerPlugin.getPlatformVersion(), '42');
  });
}
