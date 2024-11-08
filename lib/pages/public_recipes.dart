import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicRecipesPage extends StatelessWidget {
  const PublicRecipesPage({Key? key}) : super(key: key);

  // Obtiene las recetas públicas de la base de datos
  Future<List<Map<String, dynamic>>> _getPublicRecipes() async {
    final publicRecipesRef = FirebaseFirestore.instance.collection('recetas');
    final publicRecipesSnapshot = await publicRecipesRef.get();

    return publicRecipesSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'titulo': data['titulo'],
        'tiempoEstimado': data['tiempoEstimado'],
        'preparacion': data['preparacion'],
      };
    }).toList();
  }

  // Función para guardar la receta en la colección del usuario
  void _saveRecipe(
      BuildContext context, Map<String, dynamic> recipeData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Guarda la receta en la colección de recetas del usuario
    final userRecipeRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('recetas')
        .doc();

    await userRecipeRef.set({
      'titulo': recipeData['titulo'],
      'tiempoEstimado': recipeData['tiempoEstimado'],
      'preparacion': recipeData['preparacion'],
    });

    // Guarda los ingredientes de la receta en la colección de ingredientes del usuario
    final ingredientsRef = FirebaseFirestore.instance
        .collection('recetas')
        .doc(recipeData['id'])
        .collection('ingredientes');
    final ingredientsSnapshot = await ingredientsRef.get();

    for (var ingredientDoc in ingredientsSnapshot.docs) {
      await userRecipeRef.collection('ingredientes').add(ingredientDoc.data());
    }

    // Mostrar un Snackbar, asegurándonos de que el ScaffoldMessenger esté disponible
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receta guardada exitosamente')),
      );
    }
  }

  // Muestra los detalles de la receta seleccionada en un diálogo
  void _showRecipeDetails(BuildContext context, Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(recipe['titulo'], textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tiempo estimado: ${recipe['tiempoEstimado']} min"),
                const SizedBox(height: 16),
                // Mostrar los ingredientes de la receta
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('recetas')
                      .doc(recipe['id'])
                      .collection('ingredientes')
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final ingredients = snapshot.data!.docs;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Ingredientes:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...ingredients.map((doc) {
                          return Text(
                            "- ${doc['nombre']}: ${doc['cantidad']} ${doc['medida']}",
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text("Preparación:\n${recipe['preparacion']}"),
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                _saveRecipe(context, recipe);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.favorite_border),
              label: const Text('Guardar receta'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas Públicas'),
        backgroundColor: const Color(0xFFB0C4DE),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getPublicRecipes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data!;
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(recipe['titulo']),
                  subtitle:
                      Text("Tiempo estimado: ${recipe['tiempoEstimado']} min"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showRecipeDetails(context, recipe);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
