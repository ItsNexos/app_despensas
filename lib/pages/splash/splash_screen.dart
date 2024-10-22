import 'package:app_despensas/pages/home_page.dart';
import 'package:app_despensas/pages/user_auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    // Redirigir después de la animación
    Future.delayed(const Duration(seconds: 4), () {
      _checkAuthentication();
    });
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5E5E5),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                "¡Bienvenido a la app de despensas!",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
