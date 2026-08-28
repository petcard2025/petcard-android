import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'petcard_notificaciones';
  static const String _channelName = 'PetCard Notificaciones';
  static const String _historyKey = 'petcard_notificaciones_historial';

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Recordatorios de citas, vacunas y alimentacion',
          importance: Importance.high,
        ),
      );
      await android.requestNotificationsPermission();
    }
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch % 2147483647;
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Recordatorios de citas, vacunas y alimentacion',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } catch (_) {}

    try {
      await _guardarEnHistorial(title, body);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<List<Map<String, dynamic>>> getHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_historyKey) ?? '[]';
    final list = jsonDecode(str) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<int> getNoLeidas() async {
    final historial = await getHistorial();
    return historial.where((n) => n['leida'] == false).length;
  }

  Future<void> marcarLeida(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final historial = await getHistorial();
    if (index >= 0 && index < historial.length) {
      historial[index]['leida'] = true;
      await prefs.setString(_historyKey, jsonEncode(historial));
    }
  }

  Future<void> marcarTodasLeidas() async {
    final prefs = await SharedPreferences.getInstance();
    final historial = await getHistorial();
    for (final n in historial) {
      n['leida'] = true;
    }
    await prefs.setString(_historyKey, jsonEncode(historial));
  }

  Future<void> limpiarHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await cancelAll();
  }

  Future<void> _guardarEnHistorial(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final historial = await getHistorial();
    historial.insert(0, {
      'titulo': title,
      'mensaje': body,
      'fecha': DateTime.now().toIso8601String(),
      'leida': false,
    });
    if (historial.length > 50) {
      historial.removeRange(50, historial.length);
    }
    await prefs.setString(_historyKey, jsonEncode(historial));
  }
}
