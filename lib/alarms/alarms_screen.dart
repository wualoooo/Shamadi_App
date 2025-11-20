import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'editar_alarma.dart';
import 'alarm_model.dart';
import 'package:shamadi_app/home_screen/timer_model.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  Timer? _alarmCheckTimer; // Timer que verifica alarmas periódicamente
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin(); // Plugin para notificaciones locales

  @override
  void initState() {
    super.initState();
    _initializeNotifications(); // Configura las notificaciones al iniciar
    _startAlarmChecker(); // Inicia la verificación periódica de alarmas
  }

  @override
  void dispose() {
    _alarmCheckTimer?.cancel(); // Limpia el timer al destruir
    super.dispose();
  }

  // Configura el sistema de notificaciones
  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Ícono de la app
    
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Inicia la verificación periódica de alarmas
  void _startAlarmChecker() {
    // Verificar cada 30 segundos si alguna alarma debe activarse
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) { // Solo si el widget está activo
        _checkActiveAlarms();
      }
    });
  }

  // Verifica todas las alarmas activas en Firestore
  void _checkActiveAlarms() async {
    final now = DateTime.now();
    final currentTime = _formatTime(TimeOfDay.fromDateTime(now)); // Hora actual formateada
    final currentDay = _getCurrentDayAbbreviation(); // Día actual abreviado
    
    try {
      // Obtiene todas las alarmas activas de Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('alarms')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Revisa cada alarma para ver si debe activarse
      for (final doc in snapshot.docs) {
        final alarm = Alarm.fromMap(doc.data(), doc.id);
        
        // Verificar si la alarma debe activarse ahora
        if (_shouldAlarmTrigger(alarm, currentTime, currentDay)) {
          _triggerAlarm(alarm); // Activa la alarma
        }
      }
    } catch (e) {
      print('Error checking alarms: $e');
    }
  }

  // Convierte TimeOfDay a string formato "h:mm AM/PM"
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod; // Hora en formato 12h
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Obtiene la abreviación del día actual (Lun, Mar, etc.)
  String _getCurrentDayAbbreviation() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday: return 'Lun';
      case DateTime.tuesday: return 'Mar';
      case DateTime.wednesday: return 'Mie';
      case DateTime.thursday: return 'Jue';
      case DateTime.friday: return 'Vie';
      case DateTime.saturday: return 'Sab';
      case DateTime.sunday: return 'Dom';
      default: return '';
    }
  }

  // Determina si una alarma debe activarse
  bool _shouldAlarmTrigger(Alarm alarm, String currentTime, String currentDay) {
    // Verificar si coincide la hora exacta
    if (alarm.time != currentTime) return false;
    
    // Verificar días de repetición (si tiene)
    if (alarm.days.isNotEmpty) {
      return alarm.days.contains(currentDay); // True si hoy está en los días de repetición
    }
    
    // Si no tiene días de repetición, se activa solo hoy (alarma única)
    return true;
  }

  // Ejecuta las acciones cuando una alarma se activa
  void _triggerAlarm(Alarm alarm) async {
    // Verificar si el widget todavía está montado
    if (!mounted) return;
    
    // Obtener el TimerModel y configurar 1 hora automáticamente
    final timerModel = Provider.of<TimerModel>(context, listen: false);
    
    // Configurar 1 hora (60 minutos) y iniciar automáticamente
    timerModel.startOneHourTimer();
    
    // Mostrar notificación en el sistema
    await _showAlarmNotification();
    
    // Mostrar diálogo en la aplicación
    _showAlarmTriggeredDialog();
    
    // Desactivar la alarma si no es recurrente (solo se ejecuta una vez)
    if (alarm.days.isEmpty && alarm.id != null) {
      await FirebaseFirestore.instance
          .collection('alarms')
          .doc(alarm.id)
          .update({'isActive': false});
    }
  }

  // Muestra notificación local cuando se activa una alarma
  Future<void> _showAlarmNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_channel', // ID del canal
      'Alarmas', // Nombre del canal
      channelDescription: 'Canal para notificaciones de alarmas',
      importance: Importance.max, // Máxima importancia
      priority: Priority.high, // Alta prioridad
      playSound: true, // Reproduce sonido
      enableVibration: true, // Hace vibrar
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      'Alarma Activada', // Título
      'Se ha iniciado el temporizador por 1 hora automáticamente', // Cuerpo
      platformChannelSpecifics,
    );
  }

  // Muestra diálogo de alerta cuando se activa una alarma
  void _showAlarmTriggeredDialog() {
    // Verificar si el widget está montado antes de mostrar el diálogo
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937), // Fondo oscuro
        title: const Text(
          'Alarma Activada',
          style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
        content: const Text(
          'Se ha configurado el temporizador por 1 hora automáticamente.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cierra el diálogo
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF007DED), fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }

  // Abre pantalla para editar una alarma existente
  void _editarAlarma(Alarm alarma) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Ocupa casi toda la pantalla
      backgroundColor: Colors.transparent, // Fondo transparente para efecto blur
      builder: (BuildContext context) => EditarAlarma(
        alarma: alarma,
        onGuardar: (Alarm alarmaActualizada) async {
          // Actualiza la alarma en Firestore
          if (alarmaActualizada.id != null) {
            await FirebaseFirestore.instance
                .collection('alarms')
                .doc(alarmaActualizada.id)
                .update(alarmaActualizada.toMap());
          }
        },
        onEliminar: (Alarm alarmaAEliminar) async {
          // Elimina la alarma de Firestore
          if (alarmaAEliminar.id != null) {
            await FirebaseFirestore.instance
                .collection('alarms')
                .doc(alarmaAEliminar.id)
                .delete();
          }
        },
      ),
    );
  }

  // Abre pantalla para crear nueva alarma
  void _agregarAlarma() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => EditarAlarma(
        onGuardar: (Alarm alarma) async {
          // Guarda nueva alarma en Firestore
          await FirebaseFirestore.instance
              .collection('alarms')
              .add(alarma.toMap());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cálculos para el gradiente diagonal
    final double angle = 13 * pi / 180;
    final double x = cos(angle);
    final double y = sin(angle);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF111827),
                  Color(0xFF581C87),
                  Color(0xFF111827),
                ],
                begin: Alignment(-x, -y), // Inicio del gradiente
                end: Alignment(x, y), // Fin del gradiente
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título "Alarmas"
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Alarmas',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Lista de alarmas
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('alarms').snapshots(), // Stream en tiempo real
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error al cargar alarmas', style: TextStyle(color: Colors.white)));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        }
                        
                        // Convierte documentos de Firestore a objetos Alarm
                        final alarms = snapshot.data!.docs.map((doc) {
                          return Alarm.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                        }).toList();

                        // Mensaje si no hay alarmas
                        if (alarms.isEmpty) {
                           return Center(
                            child: Text(
                              'No hay alarmas.\nPresiona + para agregar una.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          );
                        }

                        // Ordenar alarmas por hora
                        alarms.sort((a, b) => _compareAlarmTimes(a.time, b.time));

                        // Lista de alarmas
                        return ListView.builder(
                          itemCount: alarms.length,
                          itemBuilder: (context, index) {
                            final alarm = alarms[index];
                            return GestureDetector(
                              onTap: () => _editarAlarma(alarm), // Al tocar, edita la alarma
                              child: Card(
                                color: const Color(0xFF1F2937).withOpacity(0.4), // Fondo semi-transparente
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(16),
                                  // Hora de la alarma
                                  title: Text(
                                    alarm.time,
                                    style: TextStyle(
                                      fontSize: 24, 
                                      fontFamily: 'Inter',
                                      color: Color.fromARGB(255, 255, 255, 255)),
                                  ),
                                  // Días de repetición
                                  subtitle: Text(
                                    alarm.days.isEmpty ? 'No repetir' : alarm.days.join(', '),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white70),
                                  ),
                                  // Switch para activar/desactivar
                                  trailing: Switch(
                                    value: alarm.isActive,
                                    onChanged: (value) async {
                                      if (alarm.id != null) {
                                        await FirebaseFirestore.instance
                                            .collection('alarms')
                                            .doc(alarm.id)
                                            .update({'isActive': value}); // Actualiza estado en Firestore
                                      }
                                    },
                                    activeThumbColor: Color.fromARGB(255, 255, 255, 255),
                                    activeTrackColor: const Color(0xFF007DED),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botón flotante para agregar alarma
          Positioned(
            right: 20,
            bottom: 150,
            child: GestureDetector(
              onTap: _agregarAlarma,
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, color: Colors.white, size: 35), // Ícono "+"
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Función auxiliar para comparar horas de alarmas y ordenarlas
  int _compareAlarmTimes(String timeA, String timeB) {
    // Convierte string de hora a objeto TimeOfDay
    TimeOfDay _parseTime(String timeStr) {
      final parts = timeStr.split(':');
      final hourMin = parts[1].split(' ');
      final hour = int.parse(parts[0]);
      final minute = int.parse(hourMin[0]);
      final isPM = hourMin[1] == 'PM';
      
      return TimeOfDay(
        hour: isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour), // Convierte a formato 24h
        minute: minute,
      );
    }
    
    final timeOfDayA = _parseTime(timeA);
    final timeOfDayB = _parseTime(timeB);
    
    // Convierte a minutos totales para comparar
    final totalMinutesA = timeOfDayA.hour * 60 + timeOfDayA.minute;
    final totalMinutesB = timeOfDayB.hour * 60 + timeOfDayB.minute;
    
    return totalMinutesA.compareTo(totalMinutesB); // Compara por minutos totales
  }
}