import 'package:app_despensas/pages/recipes_add.dart';
import 'package:app_despensas/pages/public_recipes.dart'; // Importa la nueva página PublicRecipesPage
import 'package:app_despensas/pages/recipes_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({Key? key}) : super(key: key);

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
  }

  Future<List<Map<String, dynamic>>> _getRecipesWithMatches() async {
    final recipesRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('recetas');

    final despensasRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('despensas');

    final despensasSnapshot = await despensasRef.get();
    List<String> userProducts = [];
    for (var despensa in despensasSnapshot.docs) {
      final productosSnapshot =
          await despensa.reference.collection('productos').get();
      userProducts
          .addAll(productosSnapshot.docs.map((doc) => doc['nombre'] as String));
    }

    final recipesSnapshot = await recipesRef.get();
    List<Map<String, dynamic>> recipesWithMatches = await Future.wait(
      recipesSnapshot.docs.map((recipeDoc) async {
        final recipeData = recipeDoc.data();
        final ingredientesSnapshot =
            await recipeDoc.reference.collection('ingredientes').get();
        final ingredientes = ingredientesSnapshot.docs
            .map((doc) => doc['nombre'] as String)
            .toList();

        final matchCount = ingredientes
            .where((ingredient) => userProducts.contains(ingredient))
            .length;

        return {
          'id': recipeDoc.id,
          'titulo': recipeData['titulo'],
          'tiempoEstimado': recipeData['tiempoEstimado'],
          'preparacion': recipeData['preparacion'],
          'matchCount': matchCount,
        };
      }).toList(),
    );

    recipesWithMatches
        .sort((a, b) => b['matchCount'].compareTo(a['matchCount']));
    return recipesWithMatches;
  }

  void _showDeleteConfirmationDialog(String recipeId) {
    bool deleteForOthers = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar eliminación"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("¿Estás seguro de que deseas eliminar esta receta?"),
              Row(
                children: [
                  Checkbox(
                    value: deleteForOthers,
                    onChanged: (bool? value) {
                      setState(() {
                        deleteForOthers = value ?? false;
                      });
                    },
                  ),
                  const Text("Eliminar para todos"),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el cuadro de diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                // Eliminar la receta de la colección del usuario
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user!.uid)
                    .collection('recetas')
                    .doc(recipeId)
                    .delete();

                // Eliminar también de la colección pública si se selecciona la opción
                if (deleteForOthers) {
                  FirebaseFirestore.instance
                      .collection('recetas')
                      .doc(recipeId)
                      .delete();
                }
                Navigator.pop(context);
                // Recargar la lista de recetas
                setState(() {
                  _getRecipesWithMatches(); // Actualiza la lista llamando a la función de nuevo
                });
              },
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecipeList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getRecipesWithMatches(),
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
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  recipe['titulo'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      "Tiempo estimado: ${recipe['tiempoEstimado']} min",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ingredientes: ${recipe['matchCount']} coincidencias",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(recipe['id']);
                      },
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeViewPage(
                        recipeId: recipe['id'],
                        user: user!,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        backgroundColor: const Color(0xFFB0C4DE),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Recetas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PublicRecipesPage(),
                      ),
                    );
                  },
                  child: const Text('Explorar recetas'),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeAddPage(
                    user: user!.uid,
                  ),
                ),
              );
            },
            child: const Text('Agregar receta'),
          ),
          Expanded(
            child: _buildRecipeList(),
          ),
        ],
      ),
    );
  }
}
