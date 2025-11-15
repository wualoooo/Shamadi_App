import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:do_not_disturb/do_not_disturb.dart';

class TimerModel extends ChangeNotifier {
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  double _progress = 0.0;
  bool _isRunning = false;
  bool _showConcentrationScreen = false;
  Timer? _timer;
  final DoNotDisturbPlugin _dndPlugin = DoNotDisturbPlugin();

  // Getters
  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  double get progress => _progress;
  bool get isRunning => _isRunning;
  bool get showConcentrationScreen => _showConcentrationScreen;

  // Setters
  void setTotalSeconds(int seconds) {
    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    _progress = 0.0;
    notifyListeners();
  }

  void setShowConcentrationScreen(bool show) {
    _showConcentrationScreen = show;
    notifyListeners();
  }

  // Nuevo método para iniciar automáticamente con 1 hora
  void startOneHourTimer() {
    if (_isRunning) {
      stopTimer();
    }
    
    _totalSeconds = 60 * 60; // 1 hora en segundos
    _remainingSeconds = _totalSeconds;
    _progress = 0.0;
    _isRunning = false;
    _showConcentrationScreen = false;
    
    // Iniciar el timer automáticamente
    startTimer();
    
    notifyListeners();
  }

  // Funciones del timer
  Future<void> _enableDND() async {
    try {
      bool hasAccess = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (hasAccess) {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.priority);
        print('Modo No Molestar activado');
      } else {
        await _dndPlugin.openNotificationPolicyAccessSettings();
      }
    } catch (e) {
      print('Error al activar DND: $e');
    }
  }

  Future<void> _disableDND() async {
    try {
      bool hasAccess = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (hasAccess) {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
        print('Modo No Molestar desactivado');
      }
    } catch (e) {
      print('Error al desactivar DND: $e');
    }
  }

  void startTimer() {
    if (_isRunning || _totalSeconds <= 0) return;

    _isRunning = true;
    _remainingSeconds = _totalSeconds;
    _progress = 0.0;
    _showConcentrationScreen = true;

    _enableDND();
    WakelockPlus.enable();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _progress = _remainingSeconds / _totalSeconds;
        
        if (_remainingSeconds % 60 == 0 && _remainingSeconds > 0) {
          print('Tiempo restante: ${_remainingSeconds ~/ 60} minutos');
        }
        notifyListeners();
      } else {
        stopTimer();
        print('Timer completado!');
      }
    });

    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _showConcentrationScreen = false;
    
    _disableDND();
    WakelockPlus.disable();
    
    notifyListeners();
  }

  void toggleConcentrationScreen() {
    if (_isRunning) {
      _showConcentrationScreen = !_showConcentrationScreen;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disableDND();
    WakelockPlus.disable();
    super.dispose();
  }
}