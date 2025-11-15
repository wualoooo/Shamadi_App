import 'package:flutter/material.dart';

class ConcentrationScreen extends StatelessWidget {
  final int remainingSeconds;

  const ConcentrationScreen({super.key, required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    String minutesStr = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    String secondsStr = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timer,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Modo Concentración',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$minutesStr:$secondsStr',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tiempo restante',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'levanta el telefono o presiona cualquier botón\npara ver el progreso',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}