// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shamadi_app/menu.dart';

// TZ database (paquete timezone)
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Usar el fork mantenido
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:shamadi_app/notifications/notification_service.dart';

import 'package:provider/provider.dart';
import 'package:shamadi_app/home_screen/timer_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la base de datos IANA de zonas horarias
  tz.initializeTimeZones();

  // Obtiene la zona horaria local; el paquete puede devolver un String
  // o un objeto con la propiedad timezoneId, así que lo manejamos robustamente.
  final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
  String tzId;

  if (tzInfo is String) {
    tzId = tzInfo;
  } else {
    try {
      // Si es un objeto con timezoneId (p. ej. TimezoneInfo), úsalo
      tzId = (tzInfo as dynamic).timezoneId ?? tzInfo.toString();
    } catch (_) {
      tzId = tzInfo.toString();
    }
  }

  // Intenta establecer la ubicación local; si falla, usa UTC como fallback
  try {
    tz.setLocalLocation(tz.getLocation(tzId));
  } catch (e) {
    tz.setLocalLocation(tz.UTC);
  }

  // Inicializa notificaciones
  await NotificationService().init();

   runApp(
    ChangeNotifierProvider(
      create: (context) => TimerModel(),
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shamadi',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const ButtonNavigatorWidget(title: 'Shamadi'),
    );
  }
}