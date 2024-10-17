import 'package:app_despensas/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:app_despensas/pages/voice_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Agregar post frame callback para la navegación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
