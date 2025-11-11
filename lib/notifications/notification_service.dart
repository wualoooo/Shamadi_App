import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Inicialización
  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('ic_notification');
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(settings);
  }

  // Solicitar permisos para Android 13+
  Future<void> requestPermissions() async {
    try {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      print("Error solicitando permisos: $e");
    }
  }

  // Programa notificación diaria
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'shamadi_channel',
        'Recordatorios Shamadi',
        channelDescription: 'Recordatorios diarios de la app Shamadi',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      );

      final details = NotificationDetails(android: androidDetails);

      await notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print("Error programando notificación: $e");
    }
  }

  // Cancela notificación específica
  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }

  // Cancela todas las notificaciones de un tipo
  Future<void> cancelAllNotifications(List<int> ids) async {
    for (int id in ids) {
      await notificationsPlugin.cancel(id);
    }
  }
}