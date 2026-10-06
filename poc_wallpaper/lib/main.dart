import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'firebase_options.dart';
import 'wallpaper_service.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  debugPrint('PRUEBA segundo plano: ${message.data}');
  await _applyWallpaperFromMessage(message.data);
}

Future<void> _applyWallpaperFromMessage(Map<String, dynamic> data) async {
  if (data['type'] != 'wallpaper') return;
  final url = data['imageUrl'] as String?;
  if (url == null) return;
  try {
    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      debugPrint('PRUEBA descarga fallida: ${res.statusCode}');
      return;
    }
    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}${Platform.pathSeparator}incoming_wallpaper.jpg');
    await file.writeAsBytes(res.bodyBytes);
    await setWallpaperFromFile(file.path);
    debugPrint('PRUEBA fondo aplicado');
    await file.delete();
  } catch (e) {
    debugPrint('PRUEBA error al aplicar: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      FirebaseMessaging.onMessage.listen((m) {
        debugPrint('PRUEBA primer plano: ${m.data}');
        _applyWallpaperFromMessage(m.data);
      });
    } catch (e) {
      debugPrint('Error al iniciar Firebase: $e');
    }
  }
  runApp(const MaterialApp(home: PocPage()));
}

class PocPage extends StatefulWidget {
  const PocPage({super.key});
  @override
  State<PocPage> createState() => _PocPageState();
}

class _PocPageState extends State<PocPage> {
  String _status = 'Listo';
  String _fcm = 'Sin iniciar';

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) _loadToken();
  }

  Future<void> _loadToken() async {
    setState(() => _fcm = 'Obteniendo token...');
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM token: $token');
      if (mounted) setState(() => _fcm = token ?? 'Token nulo');
    } catch (e) {
      debugPrint('Error FCM: $e');
      if (mounted) setState(() => _fcm = 'Error: $e');
    }
  }

  Future<void> _run() async {
    setState(() => _status = 'Descargando...');
    try {
      final url = Platform.isAndroid
          ? 'https://picsum.photos/1080/1920.jpg'
          : 'https://picsum.photos/1920/1080.jpg';
      final res = await http.get(Uri.parse(url));
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}${Platform.pathSeparator}poc_wallpaper.jpg');
      await file.writeAsBytes(res.bodyBytes);
      setState(() => _status = 'Aplicando...');
      await setWallpaperFromFile(file.path);
      setState(() => _status = 'Fondo cambiado');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _run,
                    child: const Text('Cambiar fondo'),
                  ),
                  const SizedBox(height: 16),
                  Text(_status),
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 32),
                    const Text('Token FCM (mantén pulsado para copiar):'),
                    const SizedBox(height: 8),
                    SelectableText(_fcm),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadToken,
                      child: const Text('Reintentar token'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}