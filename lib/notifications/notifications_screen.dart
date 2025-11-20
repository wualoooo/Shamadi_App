import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shamadi_app/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla principal de configuración de notificaciones programadas
/// Permite activar/desactivar recordatorios para hábitos saludables
class NotificationsContent extends StatefulWidget {
  const NotificationsContent({Key? key}) : super(key: key);
  
  @override
  State<NotificationsContent> createState() => _NotificationsContentState();
}

class _NotificationsContentState extends State<NotificationsContent> {
  // Estados de los interruptores de notificaciones
  bool hidratacion = false;
  bool horaDormir = false;
  bool silencioMental = false;
  bool _isLoading = true;

  final NotificationService _notificationService = NotificationService();
  final Map<String, Timer> _activeTimers = {}; // Almacena timers activos por tipo

  // Configuración completa de notificaciones con mensajes rotativos
  final Map<String, Map<String, dynamic>> _notificationConfig = {
    'hidratacion': {
      'intervalHours': 3, // Cada 3 horas
      'notifications': [
        {'id': 1, 'title': '¡Hora de Hidratarse!', 'body': 'Toma un vaso de agua para mantenerte hidratado'},
        {'id': 2, 'title': '¡Mantente Hidratado!', 'body': 'Recuerda beber agua regularmente'},
        {'id': 3, 'title': 'Hidratación Esencial', 'body': 'Tu cuerpo necesita agua para funcionar correctamente'},
        {'id': 4, 'title': 'Pausa para el Agua', 'body': 'Toma un descanso y bebe agua'},
      ],
    },
    'horaDormir': {
      'intervalHours': 1, // Cada hora por la noche
      'notifications': [
        {'id': 5, 'title': 'Preparación para Dormir', 'body': 'Comienza a relajarte para dormir'},
        {'id': 6, 'title': '¡Hora de Apagar Pantallas!', 'body': 'Desconecta dispositivos para mejor sueño'},
        {'id': 7, 'title': '¡Hora de Dormir!', 'body': 'Es hora de descansar. Buenas noches'},
      ],
    },
    'silencioMental': {
      'intervalHours': 4, // Cada 4 horas
      'notifications': [
        {'id': 8, 'title': 'Momento de Silencio Mental', 'body': 'Toma 5 minutos para respirar y centrarte'},
        {'id': 9, 'title': 'Pausa Meditativa', 'body': 'Respira y centra tu mente'},
        {'id': 10, 'title': 'Silencio Interior', 'body': 'Libera el estrés con unos minutos de paz'},
        {'id': 11, 'title': 'Reflexión', 'body': 'Momento de gratitud y paz mental'},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    // Limpieza: cancela todos los timers activos al destruir el widget
    _activeTimers.forEach((key, timer) {
      timer.cancel();
    });
    _activeTimers.clear();
    super.dispose();
  }

  /// Inicializa el servicio de notificaciones y carga las preferencias guardadas
  Future<void> _initializeNotifications() async {
    await _notificationService.init();
    await _loadPreferences();
  }

  /// Carga los estados de los interruptores desde SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hidratacion = prefs.getBool('hidratacion') ?? false;
      horaDormir = prefs.getBool('horaDormir') ?? false;
      silencioMental = prefs.getBool('silencioMental') ?? false;
      _isLoading = false;
    });
  }

  /// Guarda el estado de un interruptor en SharedPreferences
  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Maneja el cambio de estado de un interruptor
  /// Activa/desactiva las notificaciones según el nuevo valor
  Future<void> _onSwitchChanged(String type, bool value) async {
    setState(() {
      switch (type) {
        case 'hidratacion': 
          hidratacion = value; 
          break;
        case 'horaDormir': 
          horaDormir = value; 
          break;
        case 'silencioMental': 
          silencioMental = value; 
          break;
      }
    });

    await _savePreference(type, value);
    
    if (value) {
      // Si se activa, solicitar permisos y programar notificaciones
      final hasPermission = await _notificationService.requestPermissions();
      if (hasPermission) {
        await _scheduleNotifications(type);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesitan permisos para programar notificaciones'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Si se desactiva, cancelar notificaciones existentes
      await _cancelNotifications(type);
    }
  }

  /// Programa notificaciones rotativas para un tipo específico
  /// Usa mensajes diferentes en rotación según el intervalo configurado
  Future<void> _scheduleNotifications(String type) async {
    final config = _notificationConfig[type]!;
    final notifications = config['notifications'] as List<Map<String, dynamic>>;
    final intervalHours = config['intervalHours'] as int;
    
    print('Programando ${notifications.length} notificaciones rotativas para: $type cada $intervalHours horas');
    
    int currentIndex = 0;
    
    // Cancelar timer existente si hay uno
    if (_activeTimers.containsKey(type)) {
      _activeTimers[type]!.cancel();
    }
    
    // Función para mostrar la notificación actual
    void showCurrentNotification() {
      final notification = notifications[currentIndex];
      
      _notificationService.scheduleRecurringNotification(
        id: notification['id'] as int,
        title: notification['title'] as String,
        body: notification['body'] as String,
        intervalHours: intervalHours,
        startDelaySeconds: 0,
      );
      
      print('Notificación rotativa ${currentIndex + 1}/${notifications.length}: "${notification['title']}"');
      
      // Avanzar al siguiente índice (rotar)
      currentIndex = (currentIndex + 1) % notifications.length;
    }
    
    // Mostrar primera notificación inmediatamente
    showCurrentNotification();
    
    // Programar timer recurrente para las siguientes notificaciones
    final timer = Timer.periodic(Duration(hours: intervalHours), (timer) {
      showCurrentNotification();
    });
    
    _activeTimers[type] = timer;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notificaciones de $type programadas: se rotarán ${notifications.length} mensajes cada $intervalHours horas'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Cancela todas las notificaciones de un tipo específico
  /// Detiene el timer y elimina las notificaciones programadas
  Future<void> _cancelNotifications(String type) async {
    final config = _notificationConfig[type]!;
    final notifications = config['notifications'] as List<Map<String, dynamic>>;
    final ids = notifications.map((notification) => notification['id'] as int).toList();
    
    // Cancelar el timer activo si existe
    if (_activeTimers.containsKey(type)) {
      _activeTimers[type]!.cancel();
      _activeTimers.remove(type);
    }
    
    await _notificationService.cancelAllNotifications(ids);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notificaciones de $type canceladas'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Construye un elemento de lista con interruptor para cada tipo de notificación
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
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
    // Cálculo para el gradient diagonal (13 grados)
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
                  // Título principal de la pantalla
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
                  
                  // Subtítulo explicativo
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Activa los recordatorios que necesites:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Lista de interruptores de notificaciones
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      children: [
                        const SizedBox(height: 8),
                        _buildSwitchTile('Recordatorio de hidratación', hidratacion, 'hidratacion'),
                        _buildSwitchTile('Hora de dormir', horaDormir, 'horaDormir'),
                        _buildSwitchTile('Silencio mental', silencioMental, 'silencioMental'),
                        const SizedBox(height: 56), // Espacio inferior para scroll
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}