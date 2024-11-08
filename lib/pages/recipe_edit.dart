import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecipeEditPage extends StatefulWidget {
  final String recipeId;
  final User user;

  const RecipeEditPage({Key? key, required this.recipeId, required this.user})
      : super(key: key);

  @override
  _RecipeEditPageState createState() => _RecipeEditPageState();
}

class _RecipeEditPageState extends State<RecipeEditPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _preparationController = TextEditingController();
  List<String> selectedCategories = [];
  bool updateForOthers = false; // Definimos la variable

  // Definición de categorías
  final List<String> categories = [
    'Entrada',
    'Plato de fondo',
    'Ensalada',
    'Repostería',
    'Bebestible',
    'Vegetariano',
    'Carnes',
    'Vegano'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    final recipeDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .collection('recetas')
        .doc(widget.recipeId)
        .get();

    if (recipeDoc.exists) {
      final recipeData = recipeDoc.data()!;
      setState(() {
        _titleController.text = recipeData['titulo'] ?? '';
        _preparationController.text = recipeData['preparacion'] ?? '';
        selectedCategories = List<String>.from(recipeData['categorias'] ?? []);
      });
    }
  }

  Future<void> _updateRecipe(bool updateForOthers) async {
    final recipeData = {
      'titulo': _titleController.text,
      'preparacion': _preparationController.text,
      'categorias': selectedCategories,
    };

    // Actualizar receta del usuario
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .collection('recetas')
        .doc(widget.recipeId)
        .update(recipeData);

    // Si se solicita, actualizar también en la colección pública
    if (updateForOthers) {
      await FirebaseFirestore.instance
          .collection('recetas')
          .doc(widget.recipeId)
          .update(recipeData);
    }

    Navigator.of(context).pop(); // Regresar tras actualizar
  }

  @override
  void dispose() {
    _titleController.dispose();
    _preparationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar receta"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration:
                    const InputDecoration(labelText: "Título de la receta"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa un título";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _preparationController,
                decoration: const InputDecoration(labelText: "Preparación"),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa la preparación";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text("Categorías:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: categories.map((category) {
                  return FilterChip(
                    label: Text(category),
                    selected: selectedCategories.contains(category),
                    onSelected: (isSelected) {
                      setState(() {
                        if (isSelected) {
                          selectedCategories.add(category);
                        } else {
                          selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text(
                    "Actualizar cambios a la receta para los demás usuarios"),
                value: updateForOthers,
                onChanged: (bool? value) {
                  setState(() {
                    updateForOthers = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _updateRecipe(updateForOthers);
                  }
                },
                child: const Text("Guardar cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
