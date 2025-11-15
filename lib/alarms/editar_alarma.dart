import 'dart:ui';
import 'package:flutter/material.dart';
import 'alarm_model.dart';
import 'repetir.dart';

class EditarAlarma extends StatefulWidget {
  final Alarm? alarma;
  final Function(Alarm) onGuardar;
  final Function(Alarm)? onEliminar;

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
  late TimeOfDay _hora;
  late List<String> _dias;
  late bool _activa;
  late String? _id;

  @override
  void initState() {
    super.initState();
    if (widget.alarma != null) {
      _id = widget.alarma!.id;
      final parts = widget.alarma!.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1].split(' ')[0]);
      final isPM = widget.alarma!.time.contains('PM');
      _hora = TimeOfDay(
        hour: isPM && hour != 12 ? hour + 12 : hour,
        minute: minute,
      );
      _dias = List.from(widget.alarma!.days);
      _activa = widget.alarma!.isActive;
    } else {
      _id = null;
      _hora = TimeOfDay.now();
      _dias = [];
      _activa = true;
    }
  }

  void _seleccionarHora() async {
    final TimeOfDay? nuevaHora = await showTimePicker(
      context: context,
      initialTime: _hora,
    );
    if (nuevaHora != null) {
      setState(() {
        _hora = nuevaHora;
      });
    }
  }

  void _abrirRepetir() async {
    final List<String>? nuevosDias = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => RepetirBottomSheet(diasSeleccionados: _dias),
    );
    if (nuevosDias != null) {
      setState(() {
        _dias = nuevosDias;
      });
    }
  }

  String _formatearHora(TimeOfDay hora) {
    final hour = hora.hourOfPeriod;
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
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withOpacity(0.4),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
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
              ListTile(
                onTap: _seleccionarHora,
                title: Text(
                  'Hora',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Inter',
                  ),
                ),
                trailing: Text(
                  _formatearHora(_hora),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                onTap: _abrirRepetir,
                title: Text(
                  'Repetir',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Inter',
                  ),
                ),
                trailing: Text(
                  _dias.isEmpty ? 'Nunca' : _dias.join(', '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
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
                      _activa = value;
                    });
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF007DED),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (widget.alarma != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.onEliminar != null) {
                            final alarmaParaEliminar = Alarm(
                              id: _id,
                              time: widget.alarma!.time,
                              days: widget.alarma!.days,
                              isActive: widget.alarma!.isActive,
                            );
                            widget.onEliminar!(alarmaParaEliminar);
                          }
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.8),
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
                  if (widget.alarma != null) const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final alarma = Alarm(
                            id: _id,
                            time: _formatearHora(_hora),
                            days: _dias,
                            isActive: _activa,
                          );
                          widget.onGuardar(alarma);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
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