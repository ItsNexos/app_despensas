import 'package:app_despensas/pages/user_auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _getUserData() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF124580),
      body: _user != null
          ? Stack(
              children: [
                // Sección superior azul
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.30,
                  child: Container(
                    color: const Color(0xFF124580),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Header con botón de retroceso y título
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text(
                                'Perfil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Avatar del usuario
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0XFF6DBDFF),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 45,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _user?.displayName ?? 'Usuario',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Contenedor blanco redondeado
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.32,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),

                          // Campo de Nombre
                          _buildInfoField(
                            icon: Icons.person,
                            label: 'Nombre',
                            value: _user?.displayName ?? 'No registrado',
                            iconColor: const Color(0xFF6DBDFF),
                          ),
                          const SizedBox(height: 20),
                          // Campo de Correo
                          _buildInfoField(
                            icon: Icons.mail,
                            label: 'Correo',
                            value: _user?.email ?? '',
                            iconColor: const Color(0xFF6DBDFF),
                          ),
                          const SizedBox(height: 20),
                          // Campo de Contraseña
                          _buildInfoField(
                            icon: Icons.lock,
                            label: 'Contraseña',
                            value: '••••••••',
                            iconColor: const Color(0xFF6DBDFF),
                            showEndIcon: true,
                          ),
                          const SizedBox(height: 60),

                          // Botón Editar perfil
                          SizedBox(
                            width: 300, // Ancho fijo de 300 píxeles
                            child: ElevatedButton(
                              onPressed: () {
                                // Implementar edición de perfil
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF37679E),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'Editar perfil',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Botón Cerrar Sesión
                          SizedBox(
                            width: 300, // Ancho fijo de 300 píxeles
                            child: ElevatedButton(
                              onPressed: _signOut,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color(0XFF3C3F44).withOpacity(0.3),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'Cerrar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool showEndIcon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.blue.shade300,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3C3F44).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
