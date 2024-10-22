import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pantry_page.dart';
import 'shopping_page.dart';
import 'recipes_page.dart';
import 'user_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String username = user?.displayName ?? 'Usuario';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Banner de Bienvenida
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(80),
              color: const Color(0xFF4A618D),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido $username!',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '¿Qué quieres hacer hoy?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botones apilados como en la imagen
            _buildHomeButton(
              context,
              icon: Icons.shopping_cart_outlined,
              label: 'Ir de compras',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShoppingPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildHomeButton(
              context,
              icon: Icons.restaurant_menu,
              label: 'Quiero cocinar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipesPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildHomeButton(
              context,
              icon: Icons.kitchen,
              label: 'Mis despensas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PantryPage(userId: user!.uid)),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildHomeButton(
              context,
              icon: Icons.person_outline,
              label: 'Usuario',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF4A618D)),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A618D),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF4A618D)),
          ],
        ),
      ),
    );
  }
}
