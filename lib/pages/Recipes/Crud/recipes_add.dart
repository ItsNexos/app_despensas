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
  bool _hasError = false;

  TextEditingController _titleController = TextEditingController();
  TextEditingController _preparationController = TextEditingController();
  TextEditingController _estimatedTimeController = TextEditingController();
  TextEditingController _servingsController = TextEditingController();

  List<Map<String, dynamic>> ingredients = [];
  TextEditingController _ingredientNameController = TextEditingController();
  TextEditingController _ingredientQuantityController = TextEditingController();
  String _ingredientUnit = 'unidades';
  String _userName = '';

  List<String> userProducts = [];
  List<String> filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user)
        .get();

    setState(() {
      _userName = userDoc.data()?['nombre'] ?? 'Usuario Desconocido';
    });
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
      userProducts = loadedProducts.toSet().toList();
    });
  }

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
          'principal': _isMainIngredient,
        });

        _ingredientNameController.clear();
        _ingredientQuantityController.clear();
        _ingredientUnit = 'unidades';
        _isMainIngredient = false;
      });
    }
  }

  // Guardar la receta en Firestore
  Future<void> _saveRecipe() async {
    setState(() {
      _hasError = _estimatedTimeController.text.isEmpty ||
          int.tryParse(_estimatedTimeController.text) == null ||
          int.tryParse(_estimatedTimeController.text)! <= 0;
    });
    if (_formKey.currentState!.validate() && !_hasError) {
      final recipeData = {
        'titulo': _titleController.text,
        'preparacion': _preparationController.text,
        'categorias': selectedCategories,
        'tiempoEstimado': int.tryParse(_estimatedTimeController.text) ?? 0,
        'porciones': int.tryParse(_servingsController.text) ?? 1,
        'autor': _userName,
      };

      final recipeRef = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user)
          .collection('recetas')
          .add(recipeData);

      for (var ingredient in ingredients) {
        await recipeRef.collection('ingredientes').add(ingredient);
      }

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
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF124580)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Añadir receta",
          style: TextStyle(
              color: Color(0xFF124580),
              fontSize: 24,
              fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                color: Color(0xFFF4F6F8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo nombre de receta
                      Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: Color(0xFF51A5EA),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Nombre de la receta",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2C5B92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: "Agregar nombre",
                          hintStyle: TextStyle(
                            color: Color(0xFF606368),
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Por favor ingresa un título a la receta";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(Icons.people, color: Color(0xFF51A5EA)),
                          const SizedBox(width: 8),
                          Text(
                            "Porciones",
                            style: TextStyle(
                              color: Color(0xFF2C5B92),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle,
                                      size: 25,
                                      color:
                                          Color(0xFF124580).withOpacity(0.8)),
                                  onPressed: () {
                                    setState(() {
                                      int currentValue = int.tryParse(
                                              _servingsController.text) ??
                                          1;
                                      if (currentValue > 1) {
                                        _servingsController.text =
                                            (currentValue - 1).toString();
                                      }
                                    });
                                  },
                                ),
                                Container(
                                  width: 80,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF4F6F8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Color(0xFF124580).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _servingsController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: Color(0xFF124580),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "1",
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle,
                                      size: 25,
                                      color:
                                          Color(0xFF124580).withOpacity(0.8)),
                                  onPressed: () {
                                    setState(() {
                                      int currentValue = int.tryParse(
                                              _servingsController.text) ??
                                          1;
                                      _servingsController.text =
                                          (currentValue + 1).toString();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: Color(0xFF51A5EA)),
                          const SizedBox(width: 8),
                          Text(
                            "Tiempo estimado",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2C5B92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 30),
                          SizedBox(
                              width: 100,
                              height: 48,
                              child: TextFormField(
                                controller: _estimatedTimeController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Minutos",
                                  hintStyle: TextStyle(
                                    color: Color(0xFF606368),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _hasError
                                          ? Colors.red
                                          : Color(0xFF124580),
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _hasError
                                          ? Colors.red
                                          : Color(0xFF51A5EA),
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _hasError
                                          ? Colors.red
                                          : Color(0xFF124580).withOpacity(0.2),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restaurant_menu,
                                  color: Color(0xFF51A5EA)),
                              const SizedBox(width: 8),
                              Text(
                                "Ingredientes",
                                style: TextStyle(
                                  color: Color(0xFF2C5B92),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Lista de ingredientes existente
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: ingredients.length,
                            itemBuilder: (context, index) {
                              final ingredient = ingredients[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Row(
                                  children: [
                                    if (ingredient['principal'])
                                      Icon(Icons.star,
                                          color: Colors.amber, size: 16),
                                    Expanded(
                                      child: Text(
                                        "${ingredient['cantidad']} ${ingredient['medida']} de ${ingredient['nombre']}",
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF3C3F44)),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      ingredients.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Campo de nombre del ingrediente
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF4F6F8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF124580).withOpacity(0.2),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: TextFormField(
                              controller: _ingredientNameController,
                              decoration: InputDecoration(
                                hintText: "Nombre del ingrediente",
                                border: InputBorder.none,
                                // Estilo para el hintText
                                hintStyle: TextStyle(
                                  color: Color(0xFF606368),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              onChanged: _filterSuggestions,
                              onTapOutside: (value) {
                                setState(() {
                                  filteredSuggestions.clear();
                                });
                              },
                            ),
                          ),
                          if (filteredSuggestions.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredSuggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = filteredSuggestions[index];
                                return ListTile(
                                  title: Text(suggestion),
                                  onTap: () {
                                    setState(() {
                                      _ingredientNameController.text =
                                          suggestion;
                                      filteredSuggestions.clear();
                                    });
                                  },
                                );
                              },
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF4F6F8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Color(0xFF124580).withOpacity(0.2),
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: TextFormField(
                                    controller: _ingredientQuantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: "Cantidad",
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: Color(0xFF606368),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF4F6F8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Color(0xFF124580).withOpacity(0.2),
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _ingredientUnit,
                                      isExpanded: true,
                                      hint: Text("Unidad"),
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
                                          child: Text(
                                            unit,
                                            style: TextStyle(
                                              color: Color(0xFF606368),
                                              fontSize: 15,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _ingredientUnit = newValue!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Checkbox de ingrediente principal
                          Container(
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                Icon(Icons.star, color: Colors.amber, size: 25),
                                const SizedBox(width: 8),
                                Text(
                                  "Ingrediente principal",
                                  style: TextStyle(
                                    color: Color(0xFF3C3F44).withOpacity(0.7),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Spacer(),
                                Checkbox(
                                  value: _isMainIngredient,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isMainIngredient = value ?? false;
                                    });
                                  },
                                  activeColor: Color(0xFF51A5EA),
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: Color(0xFF606368),
                                    width: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Botón de agregar ingrediente
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2C5B92),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                minimumSize: Size(160, 48),
                              ),
                              onPressed: _addIngredient,
                              icon: Icon(Icons.playlist_add,
                                  size: 20, color: Colors.white),
                              label: Text(
                                "Agregar ingrediente",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(Icons.checklist, color: Color(0xFF51A5EA)),
                          const SizedBox(width: 8),
                          Text(
                            "Preparación",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2C5B92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _preparationController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Agregar instrucciones",
                          hintStyle: TextStyle(
                            color: Color(0xFF606368),
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFF124580).withOpacity(0.2),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFF51A5EA),
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFF124580).withOpacity(0.2),
                              width: 1.0,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una preparacion';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Icon(Icons.bookmark, color: Color(0xFF51A5EA)),
                          const SizedBox(width: 8),
                          Text(
                            "Etiquetas:",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2C5B92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8.0,
                        children: categories.map((category) {
                          return FilterChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                color: selectedCategories.contains(category)
                                    ? Colors.white
                                    : Color(0xFF2C5B92),
                              ),
                            ),
                            selected: selectedCategories.contains(category),
                            selectedColor: Color(0xFF51A5EA),
                            backgroundColor: const Color(0xFFF4F6F8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Color(0xFF51A5EA)),
                            ),
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(Icons.public_outlined, color: Color(0xFF51A5EA)),
                          const SizedBox(width: 8),
                          Text(
                            "Publicar receta para otros",
                            style: TextStyle(
                              color: Color(0xFF2C5B92),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          Switch(
                            value: _publishForOthers,
                            onChanged: (value) {
                              setState(() {
                                _publishForOthers = value;
                              });
                            },
                            activeColor: Color(0xFF2C5B92),
                            activeTrackColor: Color(0xFFB3E5FC),
                            inactiveThumbColor: Color(0xFF4C525A),
                            inactiveTrackColor: Color(0xFFF4F6F8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C5B92),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _saveRecipe,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Añadir receta",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
