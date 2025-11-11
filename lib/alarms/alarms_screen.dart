import 'dart:math';
import 'package:flutter/material.dart';
import 'editar_alarma.dart';
import 'database_helper.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<Alarm> alarms = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  void _loadAlarms() async {
    List<Alarm> loadedAlarms = await _databaseHelper.getAlarms();
    setState(() {
      alarms = loadedAlarms;
      _isLoading = false;
    });
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
            await _databaseHelper.updateAlarm(alarmaActualizada);
          } else {
            await _databaseHelper.insertAlarm(alarmaActualizada);
          }
          _loadAlarms();
        },
        onEliminar: (Alarm alarmaAEliminar) async {
          if (alarmaAEliminar.id != null) {
            await _databaseHelper.deleteAlarm(alarmaAEliminar.id!);
            _loadAlarms();
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
          await _databaseHelper.insertAlarm(alarma);
          _loadAlarms();
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
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : ListView.builder(
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
                                        setState(() {
                                          alarm.isActive = value;
                                        });
                                        if (alarm.id != null) {
                                          await _databaseHelper.updateAlarm(alarm);
                                        }
                                      },
                                      activeThumbColor: Color.fromARGB(255, 255, 255, 255),
                                      activeTrackColor: const Color(0xFF007DED),
                                    ),
                                  ),
                                ),
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
}