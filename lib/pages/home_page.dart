import 'package:app_despensas/models/pantry_model.dart';
import 'package:app_despensas/pages/user_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pantry_page.dart'; // Importa la pantalla de Pantry

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser; // Obtén el usuario actual
    return Scaffold(
      appBar: AppBar(
        title: const Text('APP despensas :D'),
        backgroundColor: Color(0xFFB0C4DE), // Color similar al diseño
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '¿Qué quieres hacer hoy?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Botones de opciones
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildOptionButton(
                    context,
                    icon: Icons.shopping_cart,
                    label: 'Ir a comprar',
                    onTap: () {
                      // Acción para ir a la pantalla de compras
                    },
                  ),
                  _buildOptionButton(
                    context,
                    icon: Icons.book,
                    label: 'Ver recetas',
                    onTap: () {
                      // Acción para ir a la pantalla de recetas
                    },
                  ),
                  _buildOptionButton(
                    context,
                    icon: Icons.kitchen,
                    label: 'Ver despensas',
                    onTap: () {
                      // Navega a la pantalla de PantryPage (Despensas)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantryPage(userId: user!.uid),
                        ),
                      );
                    },
                  ),
                  _buildOptionButton(
                    context,
                    icon: Icons.checklist,
                    label: 'Planificar',
                    onTap: () {
                      // Acción para ir a la pantalla de planificación
                    },
                  ),
                  _buildOptionButton(
                    context,
                    icon: Icons.person,
                    label: 'mi perfil',
                    onTap: () {
                      // Navega a la pantalla de PantryPage (Despensas)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir cada botón del Grid
  Widget _buildOptionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Color(0xFF6A7BA2)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A7BA2)),
            ),
          ],
        ),
      ),
    );
  }
}
