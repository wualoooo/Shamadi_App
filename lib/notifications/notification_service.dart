import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Servicio centralizado para manejar todas las notificaciones locales de la app
class NotificationService {
  // Patrón Singleton para una única instancia del servicio
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Plugin principal de notificaciones locales
  final FlutterLocalNotificationsPlugin notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Controla si el servicio ya fue inicializado
  bool _isInitialized = false;

  /// Inicializa el servicio de notificaciones con la configuración básica
  /// Crea el canal de notificaciones y prepara el sistema
  Future<void> init() async {
    try {
      // Configuración para Android
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('ic_notification');
      
      // Configuración general de inicialización (Android)
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      // Inicializar el plugin con la configuración
      await notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notificacion tocada por el usuario - ID: ${response.id}');
        },
      );
      
      // Crear el canal de notificaciones específico de Shamadi
      await _createNotificationChannel();
      
      _isInitialized = true;
      
      print('Servicio de notificaciones inicializado correctamente');
    } catch (e) {
      print('Error inicializando el servicio de notificaciones: $e');
    }
  }

  /// Crea el canal de notificaciones específico para Shamadi en Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'shamadi_channel', // ID único del canal
      'Recordatorios Shamadi', // Nombre visible para el usuario
      description: 'Recordatorios diarios de la app Shamadi para habitos saludables',
      importance: Importance.max, // Máxima importancia (sonido, vibración, etc.)
      playSound: true, // Reproducir sonido
      enableVibration: true, // Activar vibración
      showBadge: true, // Mostrar badge en el icono de la app
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    print('Canal de notificaciones creado: shamadi_channel');
  }

  /// Solicita permisos al usuario para mostrar notificaciones
  /// Retorna true si los permisos fueron concedidos, false si fueron denegados
  Future<bool> requestPermissions() async {
    try {
      if (!_isInitialized) {
        await init();
      }

      // Solicitar permisos (específico de Android)
      final bool? granted = await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      print('Estado de permisos de notificacion: ${granted == true ? "CONCEDIDOS" : "DENEGADOS"}');
      
      return granted == true;
    } catch (e) {
      print("Error al solicitar permisos de notificacion: $e");
      return false;
    }
  }

  /// Programa y muestra una notificación individual después de un delay específico
  /// [id]: Identificador único de la notificación
  /// [title]: Título de la notificación
  /// [body]: Cuerpo/mensaje de la notificación
  /// [intervalHours]: Intervalo en horas (para registro/logs)
  /// [startDelaySeconds]: Segundos de espera antes de mostrar la notificación
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required int intervalHours,
    int startDelaySeconds = 0,
  }) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      print('Programando notificacion: "$title" (ID: $id) después de $startDelaySeconds segundos');

      // Configuración específica para Android
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'shamadi_channel', // Mismo ID del canal creado
        'Recordatorios Shamadi',
        channelDescription: 'Recordatorios diarios de la app Shamadi',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: 'ic_notification', // Icono de la notificación
        color: Color(0xFF007DED), // Color azul de Shamadi
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      // Programar la notificación después del delay especificado
      Future.delayed(Duration(seconds: startDelaySeconds), () {
        notificationsPlugin.show(id, title, body, details);
        print('Notificacion mostrada: "$title" (ID: $id)');
      });

      print('Notificacion programada: "$title" (ID: $id)');
      
    } catch (e) {
      print('Error programando notificacion "$title": $e');
    }
  }

  /// Cancela una notificación específica por su ID
  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
    print('Notificacion cancelada (ID: $id)');
  }

  /// Cancela múltiples notificaciones usando una lista de IDs
  /// Usado para cancelar todas las notificaciones de un tipo específico
  Future<void> cancelAllNotifications(List<int> ids) async {
    for (int id in ids) {
      await notificationsPlugin.cancel(id);
    }
    print('Total de notificaciones canceladas: ${ids.length}');
  }
}