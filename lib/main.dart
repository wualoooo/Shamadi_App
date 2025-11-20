import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shamadi_app/menu.dart';
import 'package:shamadi_app/notifications/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shamadi_app/home_screen/timer_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase
  await Firebase.initializeApp();

  // Inicializa notificaciones
  await NotificationService().init();
  
   // Inicia la aplicación con el proveedor de estado para TimerModel
   runApp(
    ChangeNotifierProvider(
      create: (context) => TimerModel(),
      child: const MyApp(),
    ),
  );
}

/// Widget principal de la aplicación Shamadi
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