import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RecipeAddPage extends StatefulWidget {
  final String user;

  const RecipeAddPage({Key? key, required this.user}) : super(key: key);

  @override
  _RecipeAddPageState createState() => _RecipeAddPageState();
}

class _RecipeAddPageState extends State<RecipeAddPage> {
  bool _isMainIngredient = false;

  bool _publishForOthers = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _preparationController = TextEditingController();
  TextEditingController _estimatedTimeController = TextEditingController();
  TextEditingController _servingsController = TextEditingController();

  List<Map<String, dynamic>> ingredients = [];
  TextEditingController _ingredientNameController = TextEditingController();
  TextEditingController _ingredientQuantityController = TextEditingController();
  String _ingredientUnit = 'unidades';

  List<String> userProducts = []; // Lista de productos del usuario
  List<String> filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  // Método para cargar productos de la despensa del usuario
  Future<void> _loadUserProducts() async {
    final despensasRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user)
        .collection('despensas');

    final despensasSnapshot = await despensasRef.get();
    List<String> loadedProducts = [];

    for (var despensaDoc in despensasSnapshot.docs) {
      final productosSnapshot =
          await despensaDoc.reference.collection('productos').get();
      for (var productDoc in productosSnapshot.docs) {
        loadedProducts.add(productDoc['nombre']);
      }
    }

    setState(() {
      userProducts = loadedProducts.toSet().toList(); // Evitar duplicados
    });
  }

  // Filtra las sugerencias de acuerdo con lo que el usuario escribe
  void _filterSuggestions(String query) {
    setState(() {
      filteredSuggestions = userProducts
          .where(
              (product) => product.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Agregar un ingrediente a la receta
  void _addIngredient() {
    if (_ingredientNameController.text.isNotEmpty &&
        _ingredientQuantityController.text.isNotEmpty) {
      setState(() {
        String ingredientName = _ingredientNameController.text;
        if (!userProducts.contains(ingredientName)) {
          userProducts.add(ingredientName);
        }

        ingredients.add({
          'nombre': ingredientName,
          'cantidad': int.parse(_ingredientQuantityController.text),
          'medida': _ingredientUnit,
          'principal': _isMainIngredient, // Añadir atributo principal
        });

        // Limpiar campos después de añadir
        _ingredientNameController.clear();
        _ingredientQuantityController.clear();
        _ingredientUnit = 'unidades';
        _isMainIngredient = false; // Resetear el checkbox
      });
    }
  }

  // Guardar la receta en Firestore
  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      final recipeData = {
        'titulo': _titleController.text,
        'preparacion': _preparationController.text,
        'categorias': selectedCategories,
        'tiempoEstimado': int.tryParse(_estimatedTimeController.text) ?? 0,
        'porciones':
            int.tryParse(_servingsController.text) ?? 1, // Agregar porciones
      };

      final recipeRef = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user)
          .collection('recetas')
          .add(recipeData);

      for (var ingredient in ingredients) {
        await recipeRef.collection('ingredientes').add(ingredient);
      }

      // Si la casilla de "Publicar receta para otros usuarios" está marcada, guardamos la receta en la colección pública
      if (_publishForOthers) {
        final publicRecipeRef =
            FirebaseFirestore.instance.collection('recetas').doc(recipeRef.id);
        await publicRecipeRef.set(recipeData);
        for (var ingredient in ingredients) {
          await publicRecipeRef.collection('ingredientes').add(ingredient);
        }
      }

      Navigator.of(context).pop();
    }
  }

  List<String> selectedCategories = [];
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
  void dispose() {
    _titleController.dispose();
    _preparationController.dispose();
    _estimatedTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Añadir Receta"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa la preparación";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
              Text("Ingredientes:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = ingredients[index];
                  return ListTile(
                    title: Text(
                        "${ingredient['cantidad']} ${ingredient['medida']} de ${ingredient['nombre']}"),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          ingredients.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
              // Campo para seleccionar ingredientes con sugerencias
              TextFormField(
                controller: _ingredientNameController,
                decoration: const InputDecoration(
                  labelText: "Nombre del ingrediente",
                ),
                onChanged:
                    _filterSuggestions, // Filtra las sugerencias a medida que se escribe
              ),
              // Muestra las sugerencias filtradas debajo del campo de texto
              if (_ingredientNameController.text.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = filteredSuggestions[index];
                    return ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        _ingredientNameController.text = suggestion;
                        setState(() {
                          filteredSuggestions = [];
                        });
                      },
                    );
                  },
                ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ingredientQuantityController,
                      decoration: const InputDecoration(labelText: "Cantidad"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                ],
              ),
              const SizedBox(height: 20),
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
                child: const Text("Agregar ingrediente"),
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
                title: const Text("Publicar receta para otros usuarios"),
                value: _publishForOthers,
                onChanged: (bool? value) {
                  setState(() {
                    _publishForOthers = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveRecipe,
                child: const Text("Guardar receta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
