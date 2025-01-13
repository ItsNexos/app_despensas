import 'package:app_despensas/pages/Recipes/Views/recipes_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Suggestions extends StatefulWidget {
  const Suggestions({Key? key}) : super(key: key);

  @override
  _SuggestionsState createState() => _SuggestionsState();
}

class _SuggestionsState extends State<Suggestions> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> sugeridas = [];
  List<Map<String, dynamic>> filteredRecipes = [];
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
    List<Map<String, dynamic>> sugeridasRecetas = await Future.wait(
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
    if (mounted) {
      setState(() {
        sugeridas = sugeridasRecetas
            .where((recipe) => recipe['missingMainIngredients'].isEmpty)
            .toList();
        filteredRecipes = List.from(sugeridas);
        isLoading = false;
      });
    }
  }

  void _filterRecipes(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRecipes = List.from(sugeridas);
      } else {
        filteredRecipes = sugeridas
            .where((recipe) =>
                recipe['titulo'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
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
            fontSize: 18,
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
                const SizedBox(width: 50),
                Text(
                  "Coincidencias: ${recipe['percentageMatch']}%",
                  style: TextStyle(
                    color: _getPercentageColor(recipe['percentageMatch']),
                    fontWeight: FontWeight.w700,
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
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Color(0xFF124580),
            ))
          : sugeridas.isEmpty
              ? const Center(
                  child: Text(
                    '¡Ups! Aún no tenemos recetas para sugerirte. Agrega más productos a tus despensas para obtener recomendaciones :)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF124580),
                    ),
                    textAlign: TextAlign.center,
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
                              itemCount: filteredRecipes.length,
                              itemBuilder: (context, index) =>
                                  _buildRecipeTile(filteredRecipes[index]),
                            ),
                    ),
                  ],
                ),
    );
  }
}
