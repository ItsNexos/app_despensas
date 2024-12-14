import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_despensas/pages/Recipes/Views/recipes_view.dart';

class ExploreRecipes extends StatefulWidget {
  const ExploreRecipes({Key? key}) : super(key: key);

  @override
  _ExploreRecipesState createState() => _ExploreRecipesState();
}

class _ExploreRecipesState extends State<ExploreRecipes> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> allRecipes = [];
  List<Map<String, dynamic>> filteredRecipes = [];
  String selectedFilter = "Usuarios"; // Radiobutton default
  List<String> selectedCategories = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final recipesRef = FirebaseFirestore.instance.collection('recetas');
    final snapshot = await recipesRef.get();

    final recipes = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'titulo': data['titulo'],
        'tiempoEstimado': data['tiempoEstimado'] ?? 'N/A',
        'porciones': data['porciones'] ?? 'N/A',
        'autor': data['autor'] ?? 'Anónimo',
        'categorias': data['categorias'] ?? [],
      };
    }).toList();

    setState(() {
      allRecipes = recipes;
      filteredRecipes = recipes;
    });
  }

  void _filterRecipes() {
    List<Map<String, dynamic>> temp = allRecipes;

    // Filtro por radiobutton
    if (selectedFilter == "DespensApp") {
      temp = temp.where((recipe) => recipe['autor'] == "DespensApp").toList();
    } else if (selectedFilter == "Usuarios") {
      temp = temp.where((recipe) => recipe['autor'] != "DespensApp").toList();
    }

    // Filtro por categorías
    if (selectedCategories.isNotEmpty) {
      temp = temp.where((recipe) {
        final recipeCategories = List<String>.from(recipe['categorias'] ?? []);
        return selectedCategories.any((cat) => recipeCategories.contains(cat));
      }).toList();
    }

    // Filtro por búsqueda
    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((recipe) => recipe['titulo']
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredRecipes = temp;
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
          _filterRecipes();
        },
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
      ),
    );
  }

  Widget _buildRadioButtons() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20),
            value: "Usuarios",
            activeColor: const Color(0xFF2C5B92),
            groupValue: selectedFilter,
            title: const Text(
              "Usuarios",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 105, 110, 116)),
              textAlign: TextAlign.center,
            ),
            onChanged: (value) {
              setState(() {
                selectedFilter = value!;
              });
              _filterRecipes();
            },
          ),
        ),
        Expanded(
          child: RadioListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20),
            value: "DespensApp",
            activeColor: const Color(0xFF2C5B92),
            groupValue: selectedFilter,
            title: const Text(
              "DespensApp",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 105, 110, 116)),
              textAlign: TextAlign.center,
            ),
            onChanged: (value) {
              setState(() {
                selectedFilter = value!;
              });
              _filterRecipes();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final categories = [
      'Entrada',
      'Plato de fondo',
      'Ensalada',
      'Repostería',
      'Bebestible',
      'Vegetariano',
      'Carnes',
      'Vegano'
    ]; // Ejemplo de categorías

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategories.contains(category);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedCategories.remove(category);
                } else {
                  selectedCategories.add(category);
                }
              });
              _filterRecipes();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color(0xFF51A5EA)
                    : const Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: selectedCategories.contains(category)
                      ? Colors.white
                      : Color(0xFF2C5B92),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecipeList() {
    if (filteredRecipes.isEmpty) {
      return const Center(
        child: Text("No hay recetas aún"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = filteredRecipes[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              recipe['titulo'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.timer,
                    size: 16, color: Color.fromARGB(205, 114, 163, 236)),
                const SizedBox(width: 5),
                Text("${recipe['tiempoEstimado']} min"),
                const SizedBox(width: 15),
                const Icon(Icons.people,
                    size: 16, color: Color.fromARGB(205, 114, 163, 236)),
                const SizedBox(width: 5),
                Text("${recipe['porciones']} porciones"),
              ],
            ),
            trailing: Text(
              "Autor: ${recipe['autor']}",
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF2C5B92)),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Asegura alineación a la izquierda
        children: [
          _buildSearchBar(),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Sugeridas por:",
              style: TextStyle(
                  fontSize: 15, color: Color.fromARGB(255, 105, 110, 116)),
            ),
          ),
          _buildRadioButtons(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Etiquetas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          _buildCategories(),
          Expanded(
            child: _buildRecipeList(),
          ),
        ],
      ),
    );
  }
}
