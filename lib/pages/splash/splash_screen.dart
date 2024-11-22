import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_despensas/pages/App/home_page.dart';
import 'package:app_despensas/pages/user_auth/login_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({super.key, this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador de la animación
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Configuración de animación de desvanecimiento
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Verificación de internet y redirección después de la animación
    Future.delayed(const Duration(seconds: 4), () {
      _checkInternetConnection();
    });
  }

  // Verifica conexión a internet
  Future<void> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // Si no hay conexión, mostrar mensaje y cerrar la app
      _showNoInternetDialog();
    } else {
      // Si hay conexión, verificar autenticación
      _checkAuthentication();
    }
  }

  // Verifica si el usuario está autenticado
  void _checkAuthentication() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Si el usuario está logueado, navega a HomePage
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    } else {
      // Si no está logueado, navega a LoginPage
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginPage()));
    }
  }

  // Muestra un diálogo de error y cierra la app
  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sin conexión a internet"),
        content: const Text(
            "Esta aplicación requiere conexión a internet para funcionar. Por favor, verifica tu conexión e inténtalo de nuevo."),
        actions: [
          TextButton(
            onPressed: () {
              exit(0); // Cierra la aplicación
            },
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF124580), // Fondo azul
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icon.svg', // Ruta al archivo SVG
                width: 250,
                height: 250,
              ),
              const Text(
                "DespensApp",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
