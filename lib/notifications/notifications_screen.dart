import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shamadi_app/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsContent extends StatefulWidget {
  const NotificationsContent({Key? key}) : super(key: key);
  
  @override
  State<NotificationsContent> createState() => _NotificationsContentState();
}

class _NotificationsContentState extends State<NotificationsContent> {
  bool hidratacion = false;
  bool horaDormir = false;
  bool silencioMental = false;
  bool _isLoading = true;

  final NotificationService _notificationService = NotificationService();

  // HORARIOS SALUDABLES (ocultos al usuario)
  final Map<String, List<Map<String, dynamic>>> _notificationSchedules = {
    'hidratacion': [
      {'id': 0, 'time': TimeOfDay(hour: 8, minute: 0), 'title': '¡Hidratación Mañanera!', 'body': 'Empieza el día con un vaso de agua'},
      {'id': 1, 'time': TimeOfDay(hour: 10, minute: 30), 'title': '¡Hora del Agua!', 'body': 'Mantente hidratado durante la mañana'},
      {'id': 2, 'time': TimeOfDay(hour: 13, minute: 0), 'title': 'Agua después del Almuerzo', 'body': 'Ayuda a tu digestión con agua'},
      {'id': 3, 'time': TimeOfDay(hour: 16, minute: 0), 'title': 'Hidratación de Tarde', 'body': 'Recarga energías con agua'},
      {'id': 4, 'time': TimeOfDay(hour: 19, minute: 0), 'title': 'Agua antes de la Cena', 'body': 'Prepárate para la cena con agua'},
    ],
    'horaDormir': [
      {'id': 10, 'time': TimeOfDay(hour: 21, minute: 0), 'title': 'Preparación para Dormir', 'body': 'Comienza a relajarte para dormir'},
      {'id': 11, 'time': TimeOfDay(hour: 21, minute: 30), 'title': '¡Hora de Apagar Pantallas!', 'body': 'Desconecta dispositivos para mejor sueño'},
      {'id': 12, 'time': TimeOfDay(hour: 22, minute: 0), 'title': '¡Hora de Dormir!', 'body': 'Es hora de descansar. Buenas noches'},
    ],
    'silencioMental': [
      {'id': 20, 'time': TimeOfDay(hour: 7, minute: 0), 'title': 'Meditación Matutina', 'body': '5 minutos de silencio para empezar el día'},
      {'id': 21, 'time': TimeOfDay(hour: 13, minute: 30), 'title': 'Pausa Meditativa', 'body': 'Respira y centra tu mente al mediodía '},
      {'id': 22, 'time': TimeOfDay(hour: 18, minute: 0), 'title': 'Silencio del Atardecer', 'body': 'Libera el estrés del día con 5 minutos de paz'},
      {'id': 23, 'time': TimeOfDay(hour: 21, minute: 15), 'title': 'Reflexión Nocturna', 'body': 'Momento de gratitud y paz antes de dormir'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hidratacion = prefs.getBool('hidratacion') ?? false;
      horaDormir = prefs.getBool('horaDormir') ?? false;
      silencioMental = prefs.getBool('silencioMental') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Maneja el cambio del switch
  Future<void> _onSwitchChanged(String type, bool value) async {
    setState(() {
      switch (type) {
        case 'hidratacion': hidratacion = value; break;
        case 'horaDormir': horaDormir = value; break;
        case 'silencioMental': silencioMental = value; break;
      }
    });

    await _savePreference(type, value);
    
    if (value) {
      // Si activa, solicita permisos y programa todas las notificaciones del tipo
      await _notificationService.requestPermissions();
      await _scheduleAllNotifications(type);
    } else {
      // Si desactiva, cancela todas las notificaciones del tipo
      await _cancelAllNotifications(type);
    }
  }

  // Programa todas las notificaciones de un tipo
  Future<void> _scheduleAllNotifications(String type) async {
    final schedules = _notificationSchedules[type]!;
    
    for (final schedule in schedules) {
      await _scheduleSingleNotification(
        id: schedule['id'] as int,
        title: schedule['title'] as String,
        body: schedule['body'] as String,
        time: schedule['time'] as TimeOfDay,
      );
    }
  }

  // Programa una notificación individual
  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);

    // Si ya pasó hoy, programa para mañana
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notificationService.scheduleDailyNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
  }

  // Cancela todas las notificaciones de un tipo
  Future<void> _cancelAllNotifications(String type) async {
    final schedules = _notificationSchedules[type]!;
    final ids = schedules.map((schedule) => schedule['id'] as int).toList();
    await _notificationService.cancelAllNotifications(ids);
  }

  // Widget del switch SIMPLIFICADO
  Widget _buildSwitchTile(String title, bool value, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937).withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          trailing: Switch(
            value: value,
            onChanged: (val) => _onSwitchChanged(type, val),
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF007DED),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double angle = 13 * pi / 180;
    final double x = cos(angle);
    final double y = sin(angle);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [Color(0xFF111827), Color(0xFF581C87), Color(0xFF111827)],
          begin: Alignment(-x, -y),
          end: Alignment(x, y),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      children: [
                        const SizedBox(height: 8),
                        _buildSwitchTile('Recordatorio de hidratación', hidratacion, 'hidratacion'),
                        _buildSwitchTile('Hora de dormir', horaDormir, 'horaDormir'),
                        _buildSwitchTile('Silencio mental', silencioMental, 'silencioMental'),
                        const SizedBox(height: 56),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}