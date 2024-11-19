import 'package:app_despensas/pages/Recipes/Crud/recipes_add.dart';
import 'package:app_despensas/pages/Recipes/Views/recipes_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRecipes extends StatefulWidget {
  const MyRecipes({Key? key}) : super(key: key);

  @override
  _MyRecipesState createState() => _MyRecipesState();
}

class _MyRecipesState extends State<MyRecipes> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> sugeridas = [];
  List<Map<String, dynamic>> todas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecetas();
  }

  Future<void> _loadRecetas() async {
    final recetasRef = FirebaseFirestore.instance
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

    final recetasSnapshot = await recetasRef.get();
    List<Map<String, dynamic>> todasRecetas = await Future.wait(
      recetasSnapshot.docs.map((recipeDoc) async {
        final recipeData = recipeDoc.data();
        final ingredientesSnapshot =
            await recipeDoc.reference.collection('ingredientes').get();

        final allIngredients = ingredientesSnapshot.docs
            .map((doc) => doc['nombre'] as String)
            .toList();
        final mainIngredients = ingredientesSnapshot.docs
            .where((doc) => doc['principal'] == true)
            .map((doc) => doc['nombre'] as String)
            .toList();

        final ownedMainIngredients = mainIngredients
            .where((ingredient) => userProducts.contains(ingredient))
            .toList();
        final missingMainIngredients = mainIngredients
            .where((ingredient) => !userProducts.contains(ingredient))
            .toList();

        final percentageMatch = ((userProducts
                        .where((product) => allIngredients.contains(product))
                        .length /
                    allIngredients.length) *
                100)
            .toInt();

        return {
          'id': recipeDoc.id,
          'titulo': recipeData['titulo'],
          'tiempoEstimado': recipeData['tiempoEstimado'],
          'porciones': recipeData['porciones'] ?? 1,
          'ingredientes': allIngredients,
          'mainIngredients': mainIngredients,
          'ownedMainIngredients': ownedMainIngredients,
          'missingMainIngredients': missingMainIngredients,
          'percentageMatch': percentageMatch,
        };
      }).toList(),
    );

    setState(() {
      sugeridas = todasRecetas
          .where((recipe) => recipe['missingMainIngredients'].isEmpty)
          .toList();
      todas = todasRecetas;
      isLoading = false;
    });
  }

  void _showDeleteConfirmationDialog(String recipeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar eliminación"),
          content:
              const Text("¿Estás seguro de que deseas eliminar esta receta?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                // Elimina la receta del usuario en Firestore
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user!.uid)
                    .collection('recetas')
                    .doc(recipeId)
                    .delete();

                Navigator.of(context).pop(); // Cierra el diálogo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receta eliminada exitosamente'),
                  ),
                );
                setState(() {
                  // Recarga la lista de recetas
                  _loadRecetas();
                });
              },
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRecipeTile(Map<String, dynamic> recipe) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeViewPage(
                recipeId: recipe['id'], // Pasa el ID de la receta
                user: user!, // Pasa el usuario actual
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          recipe['titulo'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text("${recipe['tiempoEstimado']} min"),
                const SizedBox(width: 15),
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text("${recipe['porciones']}"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "Coincidencias: ${recipe['percentageMatch']}%",
                  style: TextStyle(
                    color: _getPercentageColor(recipe['percentageMatch']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                if (recipe['missingMainIngredients'].isNotEmpty)
                  Row(
                    children: const [
                      SizedBox(width: 4),
                      Icon(Icons.warning, size: 14, color: Colors.amber),
                      SizedBox(width: 5),
                      Text(
                        "Faltan ingredientes principales",
                        style: TextStyle(color: Colors.amber),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            _showDeleteConfirmationDialog(recipe['id']);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ExpansionTile(
                  title: const Text(
                    "Sugeridas",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: sugeridas.map(_buildRecipeTile).toList(),
                ),
                ExpansionTile(
                  title: const Text(
                    "Todas",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: todas.map(_buildRecipeTile).toList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeAddPage(user: user!.uid),
            ),
          );
        },
        label: const Text("Añadir receta"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF5D83B1),
      ),
    );
  }
}
