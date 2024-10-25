import 'package:app_despensas/pages/home_page.dart';
import 'package:app_despensas/pages/user_auth/sign_up_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false; // Control de visibilidad de la contraseña
  bool _emailError = false; // Estado del error del email
  bool _passwordError = false; // Estado del error de contraseña
  String? _emailErrorMessage; // Mensaje de error para el email

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validación del formato del email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Lógica del login
  Future<void> _login() async {
    setState(() {
      _emailError = _emailController.text.isEmpty ||
          !_isValidEmail(_emailController.text);
      _passwordError = _passwordController.text.isEmpty;
      _emailErrorMessage = _emailController.text.isEmpty
          ? 'Por favor ingrese su correo'
          : 'Correo inválido';
    });

    if (_emailError || _passwordError) return; // No continuar si hay errores

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showErrorDialog();
    }
  }

  // Modal para mostrar error de credenciales
  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Credenciales incorrectas",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A4247).withOpacity(0.95),
            )),
        content: Text("Correo o contraseña inválidos",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3C3F44).withOpacity(0.90),
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Aceptar",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF124580).withOpacity(0.85),
            )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF124580), // Fondo azul
      body: Stack(
        children: [
          // Parte azul con el título y la instrucción
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              color: Color(0xFF124580), // Fondo azul
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Inicio de sesión",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Ingrese sus credenciales para continuar",
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

          // Contenedor Blanco
          Positioned(
            top: MediaQuery.of(context).size.height * 0.30,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Campo de Email
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: Color(0xFF3C3F44)),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Color(0xFFA3B3B9)),
                        hintText: "Correo electrónico",
                        errorText: _emailError ? _emailErrorMessage : null,

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
                            color: _emailError ? Color(0xFFE4352A).withOpacity(0.8) : Color(0xFFA3B3B9),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: _emailError ? Color(0xFFE4352A).withOpacity(0.8)  : Color(0xFF6DBDFF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Campo de Contraseña
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(color: Color(0xFF3C3F44)),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock, color: Color(0xFFA3B3B9)),
                        hintText: "Contraseña",
                        // Ajuste de padding para centrar verticalmente el contenido
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0),

                        // Estilo para el hintText
                        hintStyle: TextStyle(
                          color: Color(
                              0xFFA3B3B9), // Color por defecto del hintText
                        ),

                        errorText: _passwordError
                            ? 'Por favor ingrese su contraseña'
                            : null,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                _passwordError ? Color(0xFFE4352A).withOpacity(0.8) : Color(0xFFA3B3B9),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                _passwordError ? Color(0xFFE4352A).withOpacity(0.8) : Color(0xFF6DBDFF),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Color(0xFFA3B3B9),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Enlace de "Olvidaste tu contraseña"
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Implementar lógica de recuperación
                        },
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF124580),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 70),

                    // Botón de Iniciar Sesión
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF124580),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize: Size(321, 48),
                      ),
                      child: Text(
                        "Iniciar sesión",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Separador con "o"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Color(0xFFA3B3B9),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "o",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFA3B3B9).withOpacity(0.90),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color(0xFFA3B3B9),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botón de Registrarse
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFF124580)),
                        minimumSize: Size(321, 48), // Largo adaptable
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15), // Borde radius de 10px
                        ),
                      ),
                      child: Text(
                        "Registrarse",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF124580),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
