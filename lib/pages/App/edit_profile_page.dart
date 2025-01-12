import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  EditProfilePage({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF124580),
      body: Stack(
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
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Text(
                          'Editar Perfil',
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
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0XFF6DBDFF),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Flexible(
                      child: Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Contenedor blanco redondeado
          Positioned(
            top: MediaQuery.of(context).size.height * 0.33,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    _buildInfoField(
                      icon: Icons.person,
                      label: 'Nombre',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoField(
                      icon: Icons.mail,
                      label: 'Correo',
                      controller: _emailController,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoField(
                      icon: Icons.lock,
                      label: 'Contraseña actual',
                      controller: _currentPasswordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoField(
                      icon: Icons.lock,
                      label: 'Nueva contraseña',
                      controller: _newPasswordController,
                      obscureText: true,
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfileChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF37679E),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Guardar Cambios',
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
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6DBDFF), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3C3F44).withOpacity(0.8),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: Color(0xFF3C3F44).withOpacity(0.5),
              ),
            ),
          ),
        ),
        const Divider(
          color: Colors.grey,
          height: 1,
        ),
      ],
    );
  }

  Future<void> _saveProfileChanges() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    // Validar campos
    if (name.isEmpty || email.isEmpty || currentPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, rellena todos los campos.';
      });
      return;
    }

    try {
      // Comprobar contraseña actual
      final user = FirebaseAuth.instance.currentUser;
      final credential = EmailAuthProvider.credential(
          email: user!.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);

      // Actualizar perfil
      if (newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }
      await user.updateDisplayName(name);
      await user.updateEmail(email);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil actualizado exitosamente.'),
          duration: const Duration(seconds: 3),
        ),
      );

      // Volver a la pantalla de perfil
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'La contraseña actual no es correcta.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ha ocurrido un error. Por favor, inténtalo de nuevo.';
      });
    }
  }
}
