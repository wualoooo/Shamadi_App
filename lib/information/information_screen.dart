import 'dart:math';
import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cálculo para un ángulo de 13° para el gradiente
    final double angle = 13 * pi / 180;
    final double x = cos(angle);
    final double y = sin(angle);

    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo sueperpuesta
          SizedBox(
            height: 500,
            width: double.infinity,
            child: Image.asset(
              'assets/images/Imagen.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Sección inferior con gradiente semitransparente
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 473.3,
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
                gradient: LinearGradient(
                  begin: Alignment(-x, -y),
                  end: Alignment(x, y),
                  colors: const [
                    Color(0xFF111827),
                    Color(0xFF1E3A8A),
                    Color(0xFF111827),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 18, left: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      'Shamadi es una app de concentración, reduce distracciones con herramientas simples. Incluye temporizadores personalizables y alertas de hidratación para mantener hábitos saludables mientras trabajas o estudias.',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/UTVM_logo.png',
                      height: 100,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
