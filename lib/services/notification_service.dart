import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Se ejecuta cuando llega una notificación con la app cerrada o en segundo
/// plano. Debe ser una función de nivel superior (fuera de cualquier clase).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Notificación en segundo plano: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  // Callback opcional para navegar cuando el usuario toca una notificación.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  static const AndroidNotificationChannel _canalAndroid = AndroidNotificationChannel(
    'canal_alta_importancia',
    'Notificaciones importantes',
    description: 'Este canal se usa para notificaciones importantes de PetCard.',
    importance: Importance.high,
  );

  Future<void> inicializar() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
    _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(_canalAndroid);
    }

    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initIOS = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: initAndroid, iOS: initIOS),
      onDidReceiveNotificationResponse: (respuesta) {
        if (respuesta.payload != null) {
          final data = jsonDecode(respuesta.payload!) as Map<String, dynamic>;
          onNotificationTap?.call(data);
        }
      },
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage mensaje) {
      final notif = mensaje.notification;
      if (notif != null) {
        _localNotifications.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _canalAndroid.id,
              _canalAndroid.name,
              channelDescription: _canalAndroid.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: jsonEncode(mensaje.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((mensaje) {
      onNotificationTap?.call(mensaje.data);
    });

    final mensajeInicial = await _fcm.getInitialMessage();
    if (mensajeInicial != null) {
      onNotificationTap?.call(mensajeInicial.data);
    }

    await _registrarTokenActual();
    _fcm.onTokenRefresh.listen((nuevoToken) {
      _apiService.actualizarTokenFcm(nuevoToken).catchError((e) {
        print('⚠️ No se pudo actualizar el token FCM: $e');
      });
    });
  }

  Future<void> _registrarTokenActual() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _apiService.actualizarTokenFcm(token);
        print('✅ Token FCM registrado: $token');
      }
    } catch (e) {
      print('⚠️ No se pudo registrar el token FCM: $e');
    }
  }

  Future<void> eliminarToken() async {
    try {
      await _fcm.deleteToken();
    } catch (_) {}
  }
}