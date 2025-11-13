// lib/alarms/alarms_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'editar_alarma.dart';
import 'alarm_model.dart'; // <-- NUEVA IMPORTACIÓN
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- ¡NUEVA IMPORTACIÓN!
// 'database_helper.dart' ya no se usa

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // Ya no necesitamos la lista local, _databaseHelper, ni _isLoading
  // ¡El StreamBuilder se encargará de todo!

  void _editarAlarma(Alarm alarma) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => EditarAlarma(
        alarma: alarma,
        onGuardar: (Alarm alarmaActualizada) async {
          if (alarmaActualizada.id != null) {
            // --- LÓGICA ACTUALIZADA (UPDATE) ---
            await FirebaseFirestore.instance
                .collection('alarms')
                .doc(alarmaActualizada.id)
                .update(alarmaActualizada.toMap());
          }
          // No necesitas _loadAlarms(), el StreamBuilder lo actualiza solo
        },
        onEliminar: (Alarm alarmaAEliminar) async {
          if (alarmaAEliminar.id != null) {
            // --- LÓGICA ACTUALIZADA (DELETE) ---
            await FirebaseFirestore.instance
                .collection('alarms')
                .doc(alarmaAEliminar.id)
                .delete();
            Navigator.of(context).pop(); // Cierra el bottom sheet
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
          // --- LÓGICA ACTUALIZADA (INSERT) ---
          await FirebaseFirestore.instance
              .collection('alarms')
              .add(alarma.toMap());
          // No necesitas _loadAlarms()
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
                    // --- ¡ESTE ES EL GRAN CAMBIO! ---
                    // Usamos StreamBuilder para leer los datos en tiempo real
                    child: StreamBuilder<QuerySnapshot>(
                      // Escuchamos la colección 'alarms'
                      stream: FirebaseFirestore.instance.collection('alarms').snapshots(),
                      builder: (context, snapshot) {
                        // Manejo de errores
                        if (snapshot.hasError) {
                          return Center(child: Text('Error al cargar alarmas', style: TextStyle(color: Colors.white)));
                        }
                        // Estado de carga
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        }
                        
                        // Convertimos los documentos de Firebase a objetos Alarm
                        final alarms = snapshot.data!.docs.map((doc) {
                          return Alarm.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                        }).toList();

                        // Si no hay alarmas
                        if (alarms.isEmpty) {
                           return Center(
                            child: Text(
                              'No hay alarmas.\nPresiona + para agregar una.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          );
                        }

                        // Tu ListView.builder existente, ahora usa los datos del Stream
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
                                      // --- LÓGICA ACTUALIZADA (SWITCH) ---
                                      // Actualiza solo el campo 'isActive'
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
                // (Tu botón de agregar no cambia nada)
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