import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _nameError = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _passwordMismatchError = false;

  String? _emailErrorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _signUp() async {
    setState(() {
      _nameError = _nameController.text.isEmpty;
      _emailError = !_isValidEmail(_emailController.text);
      _passwordError = _passwordController.text.length < 6;
      _passwordMismatchError =
          _passwordController.text != _confirmPasswordController.text;

      _emailErrorMessage = _emailController.text.isEmpty
          ? 'Por favor ingrese su correo'
          : 'Correo inválido';
    });

    if (_nameError || _emailError || _passwordError || _passwordMismatchError) {
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      await user?.updateDisplayName(_nameController.text);

      await _firestore.collection('usuarios').doc(user?.uid).set({
        'nombre': _nameController.text,
        'correo': _emailController.text,
      });

      await _firestore
          .collection('usuarios')
          .doc(user?.uid)
          .collection('despensas')
          .doc('Productos no ordenados')
          .set({
        'nombre': 'Productos no ordenados',
        'descripcion': 'Productos para ordenar',
        'icono': 58261,
      });

      // Cerrar sesión después de crear la cuenta
      await FirebaseAuth.instance.signOut();

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog("El correo ya está registrado. Intente con otro.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Error en el registro",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Aceptar",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF124580),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 20),
            Text("¡Éxito!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Cuenta creada exitosamente.",
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text(
              "OK",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF124580),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF124580),
      body: Stack(
        children: [
          // Sección azul
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.28,
            child: Container(
              color: Color(0xFF124580),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Creación de cuenta",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Complete los campos para crear una cuenta",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.24,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Campo nombre
                    _buildTextField(
                      controller: _nameController,
                      hintText: "Nombre",
                      error: _nameError ? "Por favor ingrese su nombre" : null,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 20),

                    // Campo correo
                    _buildTextField(
                      controller: _emailController,
                      hintText: "Correo electrónico",
                      error: _emailError ? _emailErrorMessage : null,
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 20),

                    // Campo contraseña
                    _buildPasswordField(
                      controller: _passwordController,
                      hintText: "Contraseña",
                      error: _passwordError
                          ? "La contraseña debe tener al menos 6 caracteres"
                          : null,
                      isPasswordVisible: _isPasswordVisible,
                      onVisibilityToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Campo confirmar contraseña
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      hintText: "Confirmar contraseña",
                      error: _passwordMismatchError
                          ? "Las contraseñas no coinciden"
                          : null,
                      isPasswordVisible: _isConfirmPasswordVisible,
                      onVisibilityToggle: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 60),

                    // Botón registrarse
                    ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF124580),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        "Registrarse",
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

                    // Botón iniciar sesión
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFF124580)),
                        minimumSize: Size(321, 48),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        "Iniciar sesión",
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? error,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Color(0xFF3C3F44)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFFA3B3B9)),
        hintText: hintText,
        errorText: error,
        // Ajuste de padding para centrar verticalmente el contenido
        contentPadding: EdgeInsets.symmetric(vertical: 16.0),
        // Estilo para el hintText
        hintStyle: TextStyle(
          color: Color(0xFFA3B3B9), // Color por defecto del hintText
        ),

        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: error != null
                ? Color(0xFFE4352A).withOpacity(0.8) // Color de error
                : Color(0xFFA3B3B9), // Color normal
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: error != null
                ? Color(0xFFE4352A).withOpacity(0.8) // Color de error
                : Color(0xFF6DBDFF), // Color al enfocarse
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    String? error,
    required bool isPasswordVisible,
    required VoidCallback onVisibilityToggle,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Color(0xFF3C3F44)),
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: error,
        // Ajuste de padding para centrar verticalmente el contenido
        contentPadding: EdgeInsets.symmetric(vertical: 16.0),
        // Estilo para el hintText
        hintStyle: TextStyle(
          color: Color(0xFFA3B3B9), // Color por defecto del hintText
        ),

        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: error != null
                ? Color(0xFFE4352A).withOpacity(0.8) // Color de error
                : Color(0xFFA3B3B9), // Color normal
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: error != null
                ? Color(0xFFE4352A).withOpacity(0.8) // Color de error
                : Color(0xFF6DBDFF), // Color al enfocarse
          ),
        ),

        prefixIcon: Icon(Icons.lock, color: Color(0xFFA3B3B9)),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Color(0xFFA3B3B9),
          ),
          onPressed: onVisibilityToggle,
        ),
      ),
    );
  }
}
