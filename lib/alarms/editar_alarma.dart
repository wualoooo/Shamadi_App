import 'dart:ui';
import 'package:flutter/material.dart';
import 'alarm_model.dart';
import 'repetir.dart';

class EditarAlarma extends StatefulWidget {
  final Alarm? alarma; // Alarma a editar (null si es nueva)
  final Function(Alarm) onGuardar; // Callback al guardar
  final Function(Alarm)? onEliminar; // Callback al eliminar

  const EditarAlarma({
    super.key,
    this.alarma,
    required this.onGuardar,
    this.onEliminar,
  });

  @override
  _EditarAlarmaState createState() => _EditarAlarmaState();
}

class _EditarAlarmaState extends State<EditarAlarma> {
  late TimeOfDay _hora; // Hora seleccionada
  late List<String> _dias; // Días de repetición seleccionados
  late bool _activa; // Estado activo/inactivo
  late String? _id; // ID de la alarma (null para nuevas)

  @override
  void initState() {
    super.initState();
    // Si se está editando una alarma existente, carga sus datos
    if (widget.alarma != null) {
      _id = widget.alarma!.id;
      // Parsea la hora del string al formato TimeOfDay
      final parts = widget.alarma!.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1].split(' ')[0]);
      final isPM = widget.alarma!.time.contains('PM');
      _hora = TimeOfDay(
        hour: isPM && hour != 12 ? hour + 12 : hour, // Convierte a 24h
        minute: minute,
      );
      _dias = List.from(widget.alarma!.days); // Copia los días
      _activa = widget.alarma!.isActive;
    } else {
      // Valores por defecto para nueva alarma
      _id = null;
      _hora = TimeOfDay.now(); // Hora actual
      _dias = []; // Sin días de repetición
      _activa = true; // Activa por defecto
    }
  }

  // Abre el selector de hora nativo
  void _seleccionarHora() async {
    final TimeOfDay? nuevaHora = await showTimePicker(
      context: context,
      initialTime: _hora, // Hora actual como inicial
    );
    if (nuevaHora != null) {
      setState(() {
        _hora = nuevaHora; // Actualiza la hora seleccionada
      });
    }
  }

  // Abre el selector de días de repetición
  void _abrirRepetir() async {
    final List<String>? nuevosDias = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => RepetirBottomSheet(diasSeleccionados: _dias),
    );
    if (nuevosDias != null) {
      setState(() {
        _dias = nuevosDias; // Actualiza los días seleccionados
      });
    }
  }

  // Convierte TimeOfDay a string formato "h:mm AM/PM"
  String _formatearHora(TimeOfDay hora) {
    final hour = hora.hourOfPeriod; // Hora en formato 12h
    final minute = hora.minute.toString().padLeft(2, '0');
    final period = hora.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Efecto blur de fondo
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withOpacity(0.4), // Fondo semi-transparente
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ocupa solo el espacio necesario
            children: [
              // Barra superior indicadora
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Título (Nueva alarma o Editar alarma)
              Text(
                widget.alarma == null ? 'Nueva alarma' : 'Editar alarma',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              // Selector de hora
              ListTile(
                onTap: _seleccionarHora, // Al tocar abre selector de hora
                title: Text(
                  'Hora',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Inter',
                  ),
                ),
                trailing: Text(
                  _formatearHora(_hora), // Muestra la hora formateada
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Selector de días de repetición
              ListTile(
                onTap: _abrirRepetir, // Al tocar abre selector de días
                title: Text(
                  'Repetir',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Inter',
                  ),
                ),
                trailing: Text(
                  _dias.isEmpty ? 'Nunca' : _dias.join(', '), // Muestra días o "Nunca"
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              // Switch activar/desactivar
              ListTile(
                title: Text(
                  'Activa',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Inter',
                  ),
                ),
                trailing: Switch(
                  value: _activa,
                  onChanged: (value) {
                    setState(() {
                      _activa = value; // Actualiza estado activo/inactivo
                    });
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF007DED), // Color azul cuando está activo
                ),
              ),
              const SizedBox(height: 20),
              // Botones de acción
              Row(
                children: [
                  // Botón Eliminar (solo visible cuando se edita)
                  if (widget.alarma != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.onEliminar != null) {
                            // Crea objeto alarma para eliminar
                            final alarmaParaEliminar = Alarm(
                              id: _id,
                              time: widget.alarma!.time,
                              days: widget.alarma!.days,
                              isActive: widget.alarma!.isActive,
                            );
                            widget.onEliminar!(alarmaParaEliminar); // Ejecuta callback
                          }
                          Navigator.of(context).pop(); // Cierra el bottom sheet
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.8), // Fondo rojo
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  if (widget.alarma != null) const SizedBox(width: 10), // Espacio entre botones
                  // Botón Guardar
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF9333EA)], // Gradiente morado
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Crea objeto alarma con los datos actuales
                          final alarma = Alarm(
                            id: _id,
                            time: _formatearHora(_hora),
                            days: _dias,
                            isActive: _activa,
                          );
                          widget.onGuardar(alarma); // Ejecuta callback de guardado
                          Navigator.of(context).pop(); // Cierra el bottom sheet
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Fondo transparente para mostrar el gradiente
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}