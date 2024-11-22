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
  TextEditingController _ingredientNameController = TextEditingController();
  TextEditingController _ingredientQuantityController = TextEditingController();
  TextEditingController _servingsController = TextEditingController();
  TextEditingController _estimatedTimeController = TextEditingController();

  String _ingredientUnit = 'unidades';
  bool _isMainIngredient = false;
  String _userName = '';

  List<Map<String, dynamic>> ingredients = [];
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
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .get();

    setState(() {
      _userName = userDoc.data()?['nombre'] ?? 'Usuario Desconocido';
    });
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
      final ingredientesSnapshot =
          await recipeDoc.reference.collection('ingredientes').get();

      setState(() {
        _titleController.text = recipeData['titulo'] ?? '';
        _preparationController.text = recipeData['preparacion'] ?? '';
        _estimatedTimeController.text =
            recipeData['tiempoEstimado']?.toString() ?? '';
        selectedCategories = List<String>.from(recipeData['categorias'] ?? []);
        _servingsController.text = recipeData['porciones']?.toString() ?? '1';

        ingredients = ingredientesSnapshot.docs.map((doc) {
          return {
            'nombre': doc['nombre'],
            'cantidad': doc['cantidad'],
            'medida': doc['medida'],
            'principal': doc['principal'] ?? false,
          };
        }).toList();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      ingredients.removeAt(index);
    });
  }

  void _addIngredient() {
    if (_ingredientNameController.text.isNotEmpty &&
        _ingredientQuantityController.text.isNotEmpty) {
      setState(() {
        ingredients.add({
          'nombre': _ingredientNameController.text,
          'cantidad': int.parse(_ingredientQuantityController.text),
          'medida': _ingredientUnit,
          'principal': _isMainIngredient,
        });
        _ingredientNameController.clear();
        _ingredientQuantityController.clear();
        _ingredientUnit = 'unidades';
        _isMainIngredient = false;
      });
    }
  }

  Future<void> _updateRecipe(bool updateForOthers) async {
    final recipeData = {
      'titulo': _titleController.text,
      'preparacion': _preparationController.text,
      'categorias': selectedCategories,
      'porciones': int.tryParse(_servingsController.text) ?? 1,
      'tiempoEstimado': int.tryParse(_estimatedTimeController.text) ?? 0,
      'autor': _userName, // Actualizar el autor
    };

    // Actualizar receta del usuario
    final recipeRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .collection('recetas')
        .doc(widget.recipeId);

    await recipeRef.update(recipeData);

    // Eliminar ingredientes anteriores
    final ingredientesSnapshot =
        await recipeRef.collection('ingredientes').get();
    for (var doc in ingredientesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Agregar ingredientes nuevos
    for (var ingredient in ingredients) {
      await recipeRef.collection('ingredientes').add(ingredient);
    }

    // Si se solicita, actualizar también en la colección pública
    if (updateForOthers) {
      final publicRecipeRef =
          FirebaseFirestore.instance.collection('recetas').doc(widget.recipeId);

      // Verificar si la receta ya existe en la colección pública
      final publicRecipeSnapshot = await publicRecipeRef.get();

      if (publicRecipeSnapshot.exists) {
        await publicRecipeRef.update(recipeData);
      } else {
        await publicRecipeRef.set(recipeData);
      }

      // Actualizar ingredientes en la receta pública
      final publicIngredientesSnapshot =
          await publicRecipeRef.collection('ingredientes').get();
      for (var doc in publicIngredientesSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var ingredient in ingredients) {
        await publicRecipeRef.collection('ingredientes').add(ingredient);
      }
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _preparationController.dispose();
    _servingsController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar receta"),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                TextFormField(
                  controller: _estimatedTimeController,
                  decoration: const InputDecoration(
                    labelText: "Tiempo estimado (minutos)",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor ingresa el tiempo estimado";
                    }
                    if (int.tryParse(value) == null) {
                      return "Por favor ingresa un número válido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _servingsController,
                  decoration: const InputDecoration(labelText: "Porciones"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor ingresa el número de porciones";
                    }
                    if (int.tryParse(value) == null) {
                      return "Por favor ingresa un número válido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ingredientes:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = ingredients[index];
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${ingredient['cantidad']} ${ingredient['medida']} de ${ingredient['nombre']}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              if (ingredient['principal'] ==
                                  true) // Verifica si es principal
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20, // Tamaño de la estrellita
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                ingredients.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                    // Campos para agregar un nuevo ingrediente
                    TextFormField(
                      controller: _ingredientNameController,
                      decoration:
                          InputDecoration(labelText: "Nombre del ingrediente"),
                    ),
                    TextFormField(
                      controller: _ingredientQuantityController,
                      decoration: InputDecoration(labelText: "Cantidad"),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButton<String>(
                      value: _ingredientUnit,
                      items: [
                        'unidades',
                        'g',
                        'kg',
                        'lt',
                        'ml',
                        "tazas",
                        "cucharadas"
                      ].map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _ingredientUnit = newValue!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text("Ingrediente principal"),
                      value: _isMainIngredient,
                      onChanged: (bool? value) {
                        setState(() {
                          _isMainIngredient = value ?? false;
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: _addIngredient,
                      child: Text("Agregar ingrediente"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text("Categorías:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}
