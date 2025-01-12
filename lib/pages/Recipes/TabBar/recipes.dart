import 'package:app_despensas/pages/Recipes/Crud/recipe_edit.dart';
import 'package:app_despensas/pages/Recipes/Crud/recipes_add.dart';
import 'package:app_despensas/pages/Recipes/Views/recipes_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Recipes extends StatefulWidget {
  const Recipes({Key? key}) : super(key: key);

  @override
  _RecipesState createState() => _RecipesState();
}

class _RecipesState extends State<Recipes> {
  final User? user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> todas = [];
  bool isLoading = true;
  List<Map<String, dynamic>> filteredRecipes = [];
  String searchQuery = "";

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
        return {
          'id': recipeDoc.id,
          'titulo': recipeData['titulo'],
          'tiempoEstimado': recipeData['tiempoEstimado'],
          'porciones': recipeData['porciones'] ?? 1,
        };
      }).toList(),
    );
    if (mounted) {
      setState(() {
        todas = todasRecetas;
        filteredRecipes = todasRecetas;
        isLoading = false;
      });
    }
  }

  void _filterRecipes(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredRecipes = List.from(todas);
      } else {
        filteredRecipes = todas
            .where((recipe) =>
                recipe['titulo'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
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
                Navigator.of(context).pop();
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

                await FirebaseFirestore.instance
                    .collection('recetas')
                    .doc(recipeId)
                    .delete();

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receta eliminada exitosamente'),
                  ),
                );
                if (mounted) {
                  setState(() {
                    _loadRecetas();
                  });
                }
              },
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        onChanged: _filterRecipes,
        decoration: InputDecoration(
          hintText: "Buscar recetas",
          hintStyle: TextStyle(color: Colors.white),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: const Color(0xFF5D83b1),
          contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildRecipeTile(Map<String, dynamic> recipe) {
    return Card(
      color: Colors.white,
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
                recipeId: recipe['id'],
                user: user!,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          recipe['titulo'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer,
                    size: 16, color: Color.fromARGB(205, 114, 163, 236)),
                const SizedBox(width: 5),
                Text("${recipe['tiempoEstimado']} min"),
                const SizedBox(width: 15),
                const Icon(Icons.people,
                    size: 16, color: Color.fromARGB(205, 114, 163, 236)),
                const SizedBox(width: 5),
                Text("${recipe['porciones']}"),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeEditPage(
                      recipeId: recipe['id'],
                      user: user!,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(recipe['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Color(0xFF124580),
            ))
          : todas.isEmpty
              ? const Center(
                  child: Text(
                    'No existen recetas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF124580),
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: filteredRecipes.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay coincidencias',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF124580),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredRecipes.length + 1,
                              itemBuilder: (context, index) {
                                if (index == filteredRecipes.length) {
                                  return const SizedBox(height: 80.0);
                                }
                                return _buildRecipeTile(filteredRecipes[index]);
                              },
                            ),
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
        label: const Text(
          "Añadir receta",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: const Color(0xFF2c5b92),
      ),
    );
  }
}
