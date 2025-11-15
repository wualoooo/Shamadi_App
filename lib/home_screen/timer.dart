import 'package:flutter/material.dart';
import 'dart:ui';

class TimerPickerBottomSheet extends StatefulWidget {
  const TimerPickerBottomSheet({super.key});

  @override
  _TimerPickerBottomSheetState createState() => _TimerPickerBottomSheetState();
}

class _TimerPickerBottomSheetState extends State<TimerPickerBottomSheet> {
  int _minutes = 0;
  int _seconds = 0;

  // Funciones para incrementar minutos
  void _incrementMinutes() {
    setState(() {
      if (_minutes < 180) {
        _minutes++;
      }
    });
  }

  // Funciones para decrementar minutos
  void _decrementMinutes() {
    setState(() {
      if (_minutes > 0) {
        _minutes--;
      }
    });
  }

  // Funciones para incrementar segundos
  void _incrementSeconds() {
    setState(() {
      if (_seconds < 59) { // Máximo 59 segundos
        _seconds++;
      } else {
        _seconds = 0; // Reiniciar segundos
        if (_minutes < 180) { // Incrementar minutos si no excede el máximo
          _minutes++;
        }
      }
    });
  }

  void _decrementSeconds() { // Funciones para decrementar segundos
    setState(() {
      if (_seconds > 0) {
        _seconds--;
      } else {
        if (_minutes > 0) { // Si segundos es 0, decrementar minutos si es posible
          _minutes--;
          _seconds = 59; // Establecer segundos a 59
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // Construcción del bottom sheet con fondo borroso
    return ClipRRect( // Necesario para que el BackdropFilter respete los bordes
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter( // Efecto de desenfoque de fondo 
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Nivel de desenfoque                            
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withOpacity(0.4), // Fondo semitransparente
            borderRadius: const BorderRadius.only( // Bordes redondeados en la parte superior
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),

        child: Column(
          mainAxisSize: MainAxisSize.min, // Ajusta el tamaño al contenido
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
              'Configuración de tiempo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Máximo: 180 minutos',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 10),
            
            // Selector de minutos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón de menos
                _buildCircularButton(Icons.remove, _decrementMinutes),
                const SizedBox(width: 20),
                
                // Display de minutos
                _buildTimeDisplay('min', _minutes),
                const SizedBox(width: 20),
                
                // Botón de más
                _buildCircularButton(Icons.add, _incrementMinutes),
              ],
            ),
            const SizedBox(height: 10),
            
            // Selector de segundos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón de menos
                _buildCircularButton(Icons.remove, _decrementSeconds),
                const SizedBox(width: 20),
                
                // Display de segundos
                _buildTimeDisplay('sec', _seconds),
                const SizedBox(width: 20),
                
                // Botón de más
                _buildCircularButton(Icons.add, _incrementSeconds),
              ],
            ),
            const SizedBox(height: 10),
            
  Center(
    child: ElevatedButton( // Botón Aceptar
      onPressed: () => Navigator.of(context).pop({ // Retornar minutos y segundos seleccionados
        'minutos': _minutes,
        'segundos': _seconds,
      }),
      style: ElevatedButton.styleFrom( // Estilo personalizado con gradiente
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: Ink( // Contenedor con gradiente
        decoration: BoxDecoration(
          gradient: const LinearGradient( // Gradiente de colores
            colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 134,
          height: 48,
          alignment: Alignment.center,
          child: const Text(
            'Aceptar',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  ),
            const SizedBox(height: 10),
          ],
        ),
        ),
      ),
      );
    }

      // Construcción del botón circular con icono
      Widget _buildCircularButton(IconData icon, VoidCallback onPressed) {
        return Container( // Contenedor circular con gradiente
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2094FE), Color(0xFF007DED)], // Degradado azul
              begin: Alignment.centerLeft, // Inicio del gradiente
              end: Alignment.centerRight, // Fin del gradiente
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
            splashRadius: 30,
          ),
        );
      }

      // Construcción del display de tiempo (minutos/segundos)
    Widget _buildTimeDisplay(String label, int value) {
      return Column(
        children: [
          Container(
            width: 80,
            height: 45,
            child: Center(
              child: Text(
                value.toString().padLeft(2, '0'), // Formatear con dos dígitos
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Inter',
              fontSize: 14,
            ),
          ),
        ],
      );
    }
  }