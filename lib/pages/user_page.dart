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

  // Obtener los datos del usuario actual
  void _getUserData() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
  }

  // Cerrar sesión
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil del Usuario"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: _user != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Nombre: ${_user?.displayName ?? 'Nombre no registrado'}",
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Correo: ${_user?.email}",
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _signOut,
                    child: Text("Cerrar Sesión"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
