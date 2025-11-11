import 'dart:ui';

import 'package:flutter/material.dart';

class RepetirBottomSheet extends StatefulWidget {
  final List<String> diasSeleccionados;

  const RepetirBottomSheet({super.key, required this.diasSeleccionados});

  @override
  _RepetirBottomSheetState createState() => _RepetirBottomSheetState();
}

class _RepetirBottomSheetState extends State<RepetirBottomSheet> {
  late List<bool> _diasSeleccionados;

  @override
  void initState() {
    super.initState();
    _diasSeleccionados = List<bool>.filled(7, false);
    // Inicializar los días seleccionados
    final dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    for (int i = 0; i < dias.length; i++) {
      if (widget.diasSeleccionados.contains(dias[i])) {
        _diasSeleccionados[i] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
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
              // Barra de arrastre
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 5),
              // Título
              const Text(
                'Repetir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              // Lista de días
              ListView.builder(
                shrinkWrap: true,
                itemCount: dias.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(
                      dias[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    value: _diasSeleccionados[index],
                    onChanged: (value) {
                      setState(() {
                        _diasSeleccionados[index] = value!;
                      });
                    },
                    activeColor: const Color(0xFF007DED),
                  );
                },
              ),
              const SizedBox(height: 5),
              // Botón de guardar
              ElevatedButton(
                onPressed: () {
                  final List<String> diasSeleccionados = [];
                  for (int i = 0; i < _diasSeleccionados.length; i++) {
                    if (_diasSeleccionados[i]) {
                      diasSeleccionados.add(dias[i]);
                    }
                  }
                  Navigator.of(context).pop(diasSeleccionados);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007DED),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}