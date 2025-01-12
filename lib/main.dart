import 'package:app_despensas/pages/splash/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_despensas/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa las notificaciones locales
  final notificationService = NotificationService();
  await notificationService.initializeNotifications();
  notificationService.scheduleDailyNotifications(); // Programación diaria
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Despensas',

      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF124580),
          brightness: Brightness.light,
        ).copyWith(
          primary: Color(0xFF124580),
          secondary: const Color(0xFF5D83b1),
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        primaryColor: Color(0xFF124580),
      ),

      home: SplashScreen(), // Usa la SplashScreen como pantalla inicial
    );
  }
}
