import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:wall_changer/wall_changer.dart';
import 'package:win32/win32.dart';

Future<void> setWallpaperFromFile(String path, {String target = 'both'}) async {
  if (Platform.isAndroid) {
    await WallChanger.setWallpaper(path, target: target);
  } else if (Platform.isWindows) {
    _setWindowsWallpaper(path);
  } else {
    throw UnsupportedError('Plataforma no soportada');
  }
}

void _setWindowsWallpaper(String path) {
  final pathPtr = path.toNativeUtf16();
  try {
    final ok = SystemParametersInfo(
      SPI_SETDESKWALLPAPER,
      0,
      pathPtr,
      SPIF_UPDATEINIFILE | SPIF_SENDCHANGE,
    );
    if (ok == 0) throw Exception('Windows rechazó el cambio de fondo');
  } finally {
    free(pathPtr);
  }
}