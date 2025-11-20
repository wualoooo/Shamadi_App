import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:do_not_disturb/do_not_disturb.dart';

class TimerModel extends ChangeNotifier {
  // Variables internas del timer
  int _totalSeconds = 0;        // Tiempo total configurado en segundos
  int _remainingSeconds = 0;    // Tiempo restante actual en segundos
  double _progress = 0.0;       // Progreso del timer (0.0 a 1.0)
  bool _isRunning = false;      // Indica si el timer está activo
  bool _showConcentrationScreen = false; // Controla si mostrar pantalla de concentración
  Timer? _timer;                // Timer que ejecuta el conteo cada segundo
  final DoNotDisturbPlugin _dndPlugin = DoNotDisturbPlugin(); // Plugin para Modo No Molestar

  // Getters para acceder a las variables desde fuera
  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  double get progress => _progress;
  bool get isRunning => _isRunning;
  bool get showConcentrationScreen => _showConcentrationScreen;

  // Setter para configurar el tiempo total
  void setTotalSeconds(int seconds) {
    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    _progress = 0.0;
    notifyListeners(); // Notifica a los widgets suscritos que hubo cambios
  }

  // Controla la visibilidad de la pantalla de concentración
  void setShowConcentrationScreen(bool show) {
    _showConcentrationScreen = show;
    notifyListeners();
  }

  // Método para iniciar automáticamente con 1 hora
  void startOneHourTimer() {
    if (_isRunning) {
      stopTimer(); // Detiene cualquier timer activo
    }
    
    _totalSeconds = 60 * 60; // 1 hora en segundos (3600)
    _remainingSeconds = _totalSeconds;
    _progress = 0.0;
    _isRunning = false;
    _showConcentrationScreen = false;
    
    // Inicia el timer automáticamente
    startTimer();
    
    notifyListeners();
  }

  // Activa el Modo No Molestar en el dispositivo
  Future<void> _enableDND() async {
    try {
      // Verifica si la app tiene permisos
      bool hasAccess = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (hasAccess) {
        // Activa el modo prioridad (solo notificaciones importantes)
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.priority);
        print('Modo No Molestar activado');
      } else {
        // Abre configuración para dar permisos
        await _dndPlugin.openNotificationPolicyAccessSettings();
      }
    } catch (e) {
      print('Error al activar DND: $e');
    }
  }

  // Desactiva el Modo No Molestar
  Future<void> _disableDND() async {
    try {
      bool hasAccess = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (hasAccess) {
        // Vuelve a permitir todas las notificaciones
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
        print('Modo No Molestar desactivado');
      }
    } catch (e) {
      print('Error al desactivar DND: $e');
    }
  }

  // Inicia el conteo del timer
  void startTimer() {
    if (_isRunning || _totalSeconds <= 0) return; // Evita iniciar si ya está corriendo o tiempo inválido

    _isRunning = true;
    _remainingSeconds = _totalSeconds;
    _progress = 0.0;
    _showConcentrationScreen = true; // Muestra la pantalla de concentración

    // Activa funciones especiales
    _enableDND(); // Modo No Molestar
    WakelockPlus.enable(); // Mantiene la pantalla encendida

    // Crea un timer que se ejecuta cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _progress = _remainingSeconds / _totalSeconds; // Calcula progreso (1.0 a 0.0)
        
        // Log cada minuto para debugging
        if (_remainingSeconds % 60 == 0 && _remainingSeconds > 0) {
          print('Tiempo restante: ${_remainingSeconds ~/ 60} minutos');
        }
        notifyListeners(); // Actualiza la UI
      } else {
        stopTimer(); // Detiene cuando llega a 0
        print('Timer completado!');
      }
    });

    notifyListeners();
  }

  // Detiene el timer y limpia recursos
  void stopTimer() {
    _timer?.cancel(); // Cancela el timer
    _isRunning = false;
    _showConcentrationScreen = false; // Oculta pantalla de concentración
    
    // Desactiva funciones especiales
    _disableDND(); // Desactiva No Molestar
    WakelockPlus.disable(); // Permite que la pantalla se apague
    
    notifyListeners();
  }

  // Alterna la pantalla de concentración (mostrar/ocultar)
  void toggleConcentrationScreen() {
    if (_isRunning) {
      _showConcentrationScreen = !_showConcentrationScreen;
      notifyListeners();
    }
  }

  // Limpieza cuando se destruye el modelo
  @override
  void dispose() {
    _timer?.cancel(); // Asegura que el timer se cancele
    _disableDND(); // Desactiva No Molestar
    WakelockPlus.disable(); // Asegura que wakelock se desactive
    super.dispose();
  }
}