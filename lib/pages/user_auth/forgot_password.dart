import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailController = TextEditingController();
  bool _isEmailValid = false;
  String _errorMessage = '';

  void _validateEmail() {
    setState(() {
      _isEmailValid = EmailValidator.validate(_emailController.text.trim());
      _errorMessage = _isEmailValid ? '' : 'Correo electrónico inválido';
    });
  }

  void _sendPasswordResetEmail() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      // Muestra un mensaje de éxito o navega a otra pantalla
    } catch (e) {
      // Maneja el error de Firebase
      print('Error enviando correo de recuperación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF124580),
      appBar: AppBar(
        backgroundColor: Color(0xFF124580),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color.fromARGB(255, 253, 253, 253)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Sección azul
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height *
                0.18, //posición de la  en lo azul
            child: Container(
              color: Color(0xFF124580),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Recuperar contraseña",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Ingresa tu correo electrónico para recuperar tu contraseña",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.21,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 1,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 30),

                      // Campo correo
                      TextField(
                        controller: _emailController,
                        style: TextStyle(color: Color(0xFF3C3F44)),
                        onChanged: (_) {
                          _validateEmail();
                        },
                        decoration: InputDecoration(
                          prefixIcon:
                              Icon(Icons.email, color: Color(0xFFA3B3B9)),
                          hintText: 'Correo electrónico',
                          errorText:
                              _errorMessage.isNotEmpty ? _errorMessage : null,
                          errorStyle: TextStyle(height: 0.8),

                          // Ajuste de padding para centrar verticalmente el contenido
                          contentPadding: EdgeInsets.symmetric(vertical: 16.0),

                          // Estilo para el hintText
                          hintStyle: TextStyle(
                            color: Color(
                                0xFFA3B3B9), // Color por defecto del hintText
                          ),

                          // Color campo erroneo o correcto
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: _errorMessage.isEmpty
                                  ? Color(0xFFA3B3B9) // Gris por defecto
                                  : Color(0xFFE4352A)
                                      .withOpacity(0.8), // Rojo si hay error
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: _errorMessage.isEmpty
                                  ? Color(
                                      0xFF6DBDFF) // Azul cuando está correcto
                                  : Color(0xFFE4352A).withOpacity(
                                      0.8), // Rojo cuando es inválido
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed:
                            _isEmailValid ? _sendPasswordResetEmail : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF124580),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          minimumSize: Size(321, 48),
                        ),
                        child: Text(
                          'Enviar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
