// lib/alarms/alarm_model.dart

class Alarm {
  final String? id;
  final String time;
  final List<String> days;
  bool isActive;

  Alarm({this.id, required this.time, required this.days, this.isActive = false});

  // --- CÓDIGO CORREGIDO (Guardar) ---
  // Guarda 'days' como una lista (Array), no como un texto.
  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'days': days, // ¡ASÍ DEBE SER!
      'isActive': isActive,
    };
  }

  // --- CÓDIGO CORREGIDO (Leer) ---
  // Lee 'days' como una lista (Array) de Firestore.
  factory Alarm.fromMap(Map<String, dynamic> map, String documentId) {
    return Alarm(
      id: documentId,
      time: map['time'] ?? '',
      // Esto convierte el Array de Firestore a List<String>
      days: List<String>.from(map['days'] ?? []), 
      isActive: map['isActive'] ?? false,
    );
  }
}