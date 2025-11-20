import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shamadi_app/alarms/alarms_screen.dart';
import 'package:shamadi_app/information/information_screen.dart';
import 'package:shamadi_app/notifications/notifications_screen.dart';
import 'package:shamadi_app/home_screen/home_screen.dart';// importar el HomeScreen


class ButtonNavigatorWidget extends StatefulWidget {
  const ButtonNavigatorWidget({super.key, required this.title});

  final String title;

  @override
  State<ButtonNavigatorWidget> createState() => _ButtonNavigatorWidgetState();
}

class _ButtonNavigatorWidgetState extends State<ButtonNavigatorWidget> {
  int _selectIndex = 0;// HomeScreen.dart de manera predeterminada

  static const List<Widget> _sections = [
    HomeScreen(), // index 0
    AlarmScreen(),
    NotificationsContent(),
    InfoScreen(),
  ];

  // Gradiente para el icono seleccionado
  final Gradient _selectedGradient = const LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Iconos no seleccionados: color del icono dentro del círculo
  final Color _unselectedIconColor = Colors.white70;

  // Tamaño y diseño del círculo
  final double _circleSize = 42.0;
  final double _iconSize = 20.0;
  final Duration _animationDuration = const Duration(milliseconds: 240);

 // widget personalizado para un icono circular de navegación
Widget _navCircleIcon(IconData iconData, bool isSelected) {
    return AnimatedContainer(
      // Duración de la animación para los cambios de estilo
      duration: _animationDuration,
      // Tamaño fijo para el contenedor circular
      width: _circleSize,
      height: _circleSize,
      // Centra el contenido (icono) dentro del contenedor
      alignment: Alignment.center,
      // Decoración visual del contenedor
      decoration: BoxDecoration(
        // Forma circular
        shape: BoxShape.circle,
        // Si está seleccionado, usa gradiente, sino usa color sólido
        gradient: isSelected ? _selectedGradient : null,
        color: isSelected ? null : Colors.white.withOpacity(0.04),
        // Sombra solo cuando está seleccionado
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF9333EA).withOpacity(0.25),
                  blurRadius: 8,  // Difuminado de la sombra
                  offset: const Offset(0, 3),  // Posición de la sombra (x, y)
                ),
              ]
            : null,
      ),
      // Icono que muestra dentro del círculo
      child: Icon(
        iconData,           // Icono a mostrar
        size: _iconSize,    // Tamaño del icono
        // Color blanco si está seleccionado, color no seleccionado por defecto
        color: isSelected ? Colors.white : _unselectedIconColor,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cálculo para un ángulo de 13° para el gradiente de fondo
    double angle = 13 * pi / 180;
    double x = cos(angle);
    double y = sin(angle);

    return Scaffold(
      extendBodyBehindAppBar: true, // Permite que el cuerpo esté detrás del AppBar
      extendBody: true, // Extiende el cuerpo detrás del BottomNavigationBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar transparente
        elevation: 0, // Sin sombra
        toolbarHeight: 70, // Altura del AppBar
        title: Row(
          children: [
            Image.asset('assets/images/icon.png', height: 28, width: 28), // Icono de la app
            const SizedBox(width: 8),
            const Text(
              'Shamadi', // Título de la app
              style: TextStyle(
                fontFamily: 'Inter',    // Fuente personalizada
                fontSize: 20,
                fontWeight: FontWeight.w600, // Peso de fuente semi-negrita
                color: Colors.white, // Color blanco
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration( // Gradiente de fondo
          gradient: LinearGradient(
            begin: Alignment(-x, -y), // Dirección del gradiente
            end: Alignment(x, y), // Dirección del gradiente
            colors: const [
              Color(0xFF111827), 
              Color(0xFF1E3A8A), 
              Color(0xFF111827), 
            ],
          ),
        ),
        child: _sections[_selectIndex],
      ),
      bottomNavigationBar: SafeArea( // Asegura que el BottomNavigationBar no se superponga con elementos del sistema
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: ClipRRect( // Bordes redondeados para el BottomNavigationBar
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto de desenfoque de fondo
              child: Container(
                height: 80, //tamaño del BottomNavigationBar
                decoration: BoxDecoration( // Fondo semitransparente con borde
                  color: const Color(0xFF1F2937).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16.0), // Bordes redondeados
                  border: Border.all(color: Colors.white.withOpacity(0.06)), // Borde sutil
                ),
                child: BottomNavigationBar( // Barra de navegación inferior
                  backgroundColor: Colors.transparent, // Fondo transparente para mostrar el contenedor decorado
                  elevation: 0,
                  type: BottomNavigationBarType.fixed, 
                  // Labels siempre en blanco
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white,
                  showUnselectedLabels: true, // Mostrar etiquetas no seleccionadas
                  currentIndex: _selectIndex, // Índice actual seleccionado
                  onTap: _onItemTapped,
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  items: [
                    BottomNavigationBarItem( // Elemento de navegación: Inicio
                      icon: _navCircleIcon(Icons.home_outlined, _selectIndex == 0), // Icono no seleccionado
                      activeIcon: _navCircleIcon(Icons.home, true), // Icono seleccionado
                      label: 'Inicio',
                    ),
                    BottomNavigationBarItem( // Elemento de navegación: Alarmas
                      icon: _navCircleIcon(Icons.alarm_outlined, _selectIndex == 1),
                      activeIcon: _navCircleIcon(Icons.alarm, true), // Icono seleccionado
                      label: 'Alarmas',
                    ),
                    BottomNavigationBarItem( // Elemento de navegación: Notificaciones
                      icon: _navCircleIcon(Icons.notifications_outlined, _selectIndex == 2),
                      activeIcon: _navCircleIcon(Icons.notifications, true), // Icono seleccionado
                      label: 'Notificaciones',
                    ),
                    BottomNavigationBarItem( // Elemento de navegación: Acerca de
                      icon: _navCircleIcon(Icons.info_outline, _selectIndex == 3),
                      activeIcon: _navCircleIcon(Icons.info, true), // Icono seleccionado
                      label: 'Acerca de',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}