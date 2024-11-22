import 'package:app_despensas/pages/Recipes/Views/recipes_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExploreRecipes extends StatelessWidget {
  const ExploreRecipes({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _getPublicRecipes() async {
    final recipesRef = FirebaseFirestore.instance
        .collection('recetas'); // Colección pública de recetas
    final snapshot = await recipesRef.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'titulo': data['titulo'],
        'tiempoEstimado': data['tiempoEstimado'] ?? 'N/A',
        'porciones': data['porciones'] ?? 'N/A',
        'autor': data['autor'] ?? 'Anónimo', // Asegúrate de tener este campo
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPublicRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Error al cargar las recetas públicas'),
          );
        }

        final publicRecipes = snapshot.data ?? [];

        if (publicRecipes.isEmpty) {
          return const Center(
            child: Text('No hay recetas públicas disponibles'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: publicRecipes.length,
          itemBuilder: (context, index) {
            final recipe = publicRecipes[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  recipe['titulo'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${recipe['tiempoEstimado']} min",
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${recipe['porciones']} porciones",
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Text(
                  "Autor: " + recipe['autor'],
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeViewPage(
                        recipeId: recipe['id'],
                        user: user!,
                        isPublic: true,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
