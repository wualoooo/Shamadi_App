import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'dart:async';
import 'timer.dart';
import 'concentration_screen.dart';
import 'timer_model.dart'; // Importa el modelo

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<int>? _proximitySubscription;
  bool _isNear = false;

  @override
  void initState() {
    super.initState();
    _startProximityListener();
  }

  @override
  void dispose() {
    _proximitySubscription?.cancel();
    super.dispose();
  }

  void _startProximityListener() async {
    try {
      _proximitySubscription = ProximitySensor.events.listen((int event) {
        bool isNear = event > 0;
        setState(() {
          _isNear = isNear;
        });
        
        final timerModel = Provider.of<TimerModel>(context, listen: false);
        if (timerModel.isRunning && isNear && timerModel.showConcentrationScreen) {
          timerModel.setShowConcentrationScreen(false);
        }
        
        print('Sensor de proximidad: ${isNear ? "Cerca" : "Lejos"}');
      });
    } catch (e) {
      print('Error al iniciar sensor de proximidad: $e');
    }
  }

  void _openTimerPicker(BuildContext context) async {
    final timerModel = Provider.of<TimerModel>(context, listen: false);
    
    if (timerModel.isRunning) {
      return;
    }

    final selectedTime = await showModalBottomSheet<Map<String, int>>( 
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const TimerPickerBottomSheet(),
    );
    
    if (selectedTime != null) {
      final selectedMinutes = selectedTime['minutos'] ?? 0;
      final selectedSeconds = selectedTime['segundos'] ?? 0;
      
      if (selectedMinutes > 0 || selectedSeconds > 0) {
        timerModel.setTotalSeconds((selectedMinutes * 60) + selectedSeconds);
      }
    }
  }

  void _toggleConcentrationScreen(BuildContext context) {
    final timerModel = Provider.of<TimerModel>(context, listen: false);
    if (timerModel.isRunning && !_isNear) {
      timerModel.toggleConcentrationScreen();
    }
  }

  void _hideConcentrationScreen(BuildContext context) {
    final timerModel = Provider.of<TimerModel>(context, listen: false);
    timerModel.setShowConcentrationScreen(false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerModel>(
      builder: (context, timerModel, child) {
        String minutesStr = (timerModel.remainingSeconds ~/ 60).toString().padLeft(2, '0');
        String secondsStr = (timerModel.remainingSeconds % 60).toString().padLeft(2, '0');

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 160.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: timerModel.isRunning ? null : () => _openTimerPicker(context),
                          child: _buildTimeSquare(minutesStr),
                        ),
                        _buildSeparator(),
                        GestureDetector(
                          onTap: timerModel.isRunning ? null : () => _openTimerPicker(context),
                          child: _buildTimeSquare(secondsStr),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),
                    Text(
                      'Minutos                          Segundos           ',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 60),
                    
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 270,
                          height: 270,
                          child: CircularProgressIndicator(
                            value: timerModel.progress,
                            strokeWidth: 5,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>( 
                              const Color(0xFF9333EA),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleConcentrationScreen(context),
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all( 
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/meditacion.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container( 
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    
                    ElevatedButton(
                      onPressed: () {
                        if (timerModel.isRunning) {
                          timerModel.stopTimer();
                        } else {
                          timerModel.startTimer();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937).withOpacity(0.4),
                        minimumSize: const Size(134, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: Colors.black.withOpacity(0.25),
                      ),
                      child: Text(
                        timerModel.isRunning ? 'Detener' : 'Inicio',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (timerModel.showConcentrationScreen)
                GestureDetector(
                  onTap: () => _hideConcentrationScreen(context),
                  child: Container(
                    color: Colors.black87,
                    width: double.infinity,
                    height: double.infinity,
                    child: ConcentrationScreen(remainingSeconds: timerModel.remainingSeconds),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ... (mantén _buildTimeSquare y _buildSeparator igual)
  Widget _buildTimeSquare(String digits) {
    return Container( 
      width: 130,
      height: 96,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEADDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6155F5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          digits,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4F378A),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: const Text(
        ':',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w300,
          color: Colors.white,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}