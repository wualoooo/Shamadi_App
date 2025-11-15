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
  Timer? _alarmCheckTimer;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _startAlarmChecker();
  }

  @override
  void dispose() {
    _alarmCheckTimer?.cancel();
    super.dispose();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _startAlarmChecker() {
    // Verificar cada minuto si alguna alarma debe activarse
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkActiveAlarms();
      }
    });
  }

  void _checkActiveAlarms() async {
    final now = DateTime.now();
    final currentTime = _formatTime(TimeOfDay.fromDateTime(now));
    final currentDay = _getCurrentDayAbbreviation();
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('alarms')
          .where('isActive', isEqualTo: true)
          .get();
      
      for (final doc in snapshot.docs) {
        final alarm = Alarm.fromMap(doc.data(), doc.id);
        
        // Verificar si la alarma debe activarse ahora
        if (_shouldAlarmTrigger(alarm, currentTime, currentDay)) {
          _triggerAlarm(alarm);
        }
      }
    } catch (e) {
      print('Error checking alarms: $e');
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

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

  bool _shouldAlarmTrigger(Alarm alarm, String currentTime, String currentDay) {
    // Verificar si coincide la hora
    if (alarm.time != currentTime) return false;
    
    // Verificar días de repetición
    if (alarm.days.isNotEmpty) {
      return alarm.days.contains(currentDay);
    }
    
    // Si no tiene días de repetición, se activa solo hoy
    return true;
  }

  void _triggerAlarm(Alarm alarm) async {
    // Verificar si el widget todavía está montado
    if (!mounted) return;
    
    // Obtener el TimerModel y configurar 1 hora automáticamente
    final timerModel = Provider.of<TimerModel>(context, listen: false);
    
    // Configurar 1 hora (60 minutos) y iniciar automáticamente
    timerModel.startOneHourTimer();
    
    // Mostrar notificación
    await _showAlarmNotification();
    
    // Mostrar diálogo en la aplicación
    _showAlarmTriggeredDialog();
    
    // Desactivar la alarma si no es recurrente
    if (alarm.days.isEmpty && alarm.id != null) {
      await FirebaseFirestore.instance
          .collection('alarms')
          .doc(alarm.id)
          .update({'isActive': false});
    }
  }

  Future<void> _showAlarmNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_channel',
      'Alarmas',
      channelDescription: 'Canal para notificaciones de alarmas',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      'Alarma Activada',
      'Se ha iniciado el temporizador por 1 hora automáticamente',
      platformChannelSpecifics,
    );
  }

  void _showAlarmTriggeredDialog() {
    // Verificar si el widget está montado antes de mostrar el diálogo
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF007DED), fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }

  void _editarAlarma(Alarm alarma) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => EditarAlarma(
        alarma: alarma,
        onGuardar: (Alarm alarmaActualizada) async {
          if (alarmaActualizada.id != null) {
            await FirebaseFirestore.instance
                .collection('alarms')
                .doc(alarmaActualizada.id)
                .update(alarmaActualizada.toMap());
          }
        },
        onEliminar: (Alarm alarmaAEliminar) async {
          if (alarmaAEliminar.id != null) {
            await FirebaseFirestore.instance
                .collection('alarms')
                .doc(alarmaAEliminar.id)
                .delete();
            // NO llamar Navigator.of(context).pop() aquí
            // El bottom sheet se cerrará automáticamente desde EditarAlarma
          }
        },
      ),
    );
  }

  void _agregarAlarma() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => EditarAlarma(
        onGuardar: (Alarm alarma) async {
          await FirebaseFirestore.instance
              .collection('alarms')
              .add(alarma.toMap());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double angle = 13 * pi / 180;
    final double x = cos(angle);
    final double y = sin(angle);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF111827),
                  Color(0xFF581C87),
                  Color(0xFF111827),
                ],
                begin: Alignment(-x, -y),
                end: Alignment(x, y),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('alarms').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error al cargar alarmas', style: TextStyle(color: Colors.white)));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        }
                        
                        final alarms = snapshot.data!.docs.map((doc) {
                          return Alarm.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                        }).toList();

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

                        return ListView.builder(
                          itemCount: alarms.length,
                          itemBuilder: (context, index) {
                            final alarm = alarms[index];
                            return GestureDetector(
                              onTap: () => _editarAlarma(alarm),
                              child: Card(
                                color: const Color(0xFF1F2937).withOpacity(0.4),
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(16),
                                  title: Text(
                                    alarm.time,
                                    style: TextStyle(
                                      fontSize: 24, 
                                      fontFamily: 'Inter',
                                      color: Color.fromARGB(255, 255, 255, 255)),
                                  ),
                                  subtitle: Text(
                                    alarm.days.isEmpty ? 'No repetir' : alarm.days.join(', '),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white70),
                                  ),
                                  trailing: Switch(
                                    value: alarm.isActive,
                                    onChanged: (value) async {
                                      if (alarm.id != null) {
                                        await FirebaseFirestore.instance
                                            .collection('alarms')
                                            .doc(alarm.id)
                                            .update({'isActive': value});
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
                          child: Icon(Icons.add, color: Colors.white, size: 35),
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

  // Función auxiliar para comparar horas de alarmas
  int _compareAlarmTimes(String timeA, String timeB) {
    TimeOfDay _parseTime(String timeStr) {
      final parts = timeStr.split(':');
      final hourMin = parts[1].split(' ');
      final hour = int.parse(parts[0]);
      final minute = int.parse(hourMin[0]);
      final isPM = hourMin[1] == 'PM';
      
      return TimeOfDay(
        hour: isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour),
        minute: minute,
      );
    }
    
    final timeOfDayA = _parseTime(timeA);
    final timeOfDayB = _parseTime(timeB);
    
    final totalMinutesA = timeOfDayA.hour * 60 + timeOfDayA.minute;
    final totalMinutesB = timeOfDayB.hour * 60 + timeOfDayB.minute;
    
    return totalMinutesA.compareTo(totalMinutesB);
  }
}