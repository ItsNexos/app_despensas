import 'package:app_despensas/pages/Recipes/Crud/recipe_edit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecipeViewPage extends StatefulWidget {
  final String recipeId;
  final User user;
  final bool isPublic; // Indica si la receta es pública o pertenece al usuario

  const RecipeViewPage({
    Key? key,
    required this.recipeId,
    required this.user,
    this.isPublic = false, // Por defecto, no es pública
  }) : super(key: key);

  @override
  _RecipeViewPageState createState() => _RecipeViewPageState();
}

class _RecipeViewPageState extends State<RecipeViewPage> {
  Map<String, dynamic> recipeData = {};
  List<Map<String, dynamic>> ingredients = [];
  Map<String, bool> userProductsMap = {};

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    // Cargar productos del usuario
    final despensasRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .collection('despensas');

    final despensasSnapshot = await despensasRef.get();
    for (var despensa in despensasSnapshot.docs) {
      final productosSnapshot =
          await despensa.reference.collection('productos').get();
      for (var producto in productosSnapshot.docs) {
        userProductsMap[producto['nombre']] = true; // Producto disponible
      }
    }

    // Cargar receta y sus ingredientes
    final recipeCollection = widget.isPublic
        ? FirebaseFirestore.instance.collection('recetas') // Recetas públicas
        : FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.user.uid)
            .collection('recetas'); // Recetas del usuario

    final recipeDoc = await recipeCollection.doc(widget.recipeId).get();
    final ingredientesSnapshot =
        await recipeDoc.reference.collection('ingredientes').get();
    if (mounted) {
      setState(() {
        recipeData = recipeDoc.data() ?? {};
        recipeData['porciones'] = recipeData['porciones'] ?? 1;
        ingredients = ingredientesSnapshot.docs.map((doc) {
          return {
            'nombre': doc['nombre'] ?? 'Desconocido',
            'cantidad': doc['cantidad'] ?? 0,
            'medida': doc['medida'] ?? 'unidades',
            'principal': doc['principal'] ?? false,
          };
        }).toList();
      });
    }
  }

  void _prepareRecipeModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return PrepareRecipeModal(
          ingredients: ingredients,
          user: widget.user, // Pasamos el user al modal
        );
      },
    );
  }

  Future<void> _saveRecipe() async {
    final publicRecipeRef =
        FirebaseFirestore.instance.collection('recetas').doc(widget.recipeId);

    final userRecipeRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .collection('recetas')
        .doc();

    final recipeDoc = await publicRecipeRef.get();
    final ingredientesSnapshot =
        await publicRecipeRef.collection('ingredientes').get();

    await userRecipeRef.set(recipeDoc.data()!);

    for (var ingredientDoc in ingredientesSnapshot.docs) {
      await userRecipeRef.collection('ingredientes').doc(ingredientDoc.id).set(
            ingredientDoc.data(),
          );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Receta guardada exitosamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF124580)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          recipeData['titulo'] ?? 'Receta',
          style: const TextStyle(
            color: Color(0xFF124580),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de datos principales (tiempo y porciones)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 4,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TIEMPO ESTIMADO",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A618D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer,
                                size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              "${recipeData['tiempoEstimado']} min",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PORCIONES",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A618D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people,
                                size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              "${recipeData['porciones']}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Etiquetas",
                style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9EA5AF),
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 1),
              // Etiquetas
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: recipeData['categorias']?.map<Widget>((category) {
                      return Chip(
                        side: BorderSide(style: BorderStyle.none),
                        label: Text(
                          category,
                          style: const TextStyle(
                              color: Color(0xFF4c525a),
                              fontWeight: FontWeight.w500),
                        ),
                        backgroundColor:
                            const Color(0xFF51a5ea).withOpacity(0.5),
                      );
                    }).toList() ??
                    [],
              ),
              const SizedBox(height: 20),

              // Sección de ingredientes
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 4,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.menu_book, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "INGREDIENTES",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A618D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...ingredients.map((ingredient) {
                      final hasIngredient =
                          userProductsMap[ingredient['nombre']] ?? false;
                      return Row(
                        children: [
                          Icon(
                            hasIngredient ? Icons.check_circle : Icons.cancel,
                            color: hasIngredient ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${ingredient['cantidad']} ${ingredient['medida']} de ${ingredient['nombre']}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (ingredient['principal'] == true)
                            const Icon(Icons.star, color: Colors.amber),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sección de preparación
              Container(
                width: double.infinity, // Ocupa todo el ancho disponible
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, // Color de fondo
                  borderRadius: BorderRadius.circular(16), // Bordes redondeados
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 4,
                      blurRadius: 6,
                      offset: const Offset(0, 3), // Sombras sutiles
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.restaurant, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "PREPARACIÓN",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A618D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recipeData['preparacion'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80.0)
            ],
          ),
        ),
      ),
      floatingActionButton: widget.isPublic
          ? FloatingActionButton.extended(
              onPressed: _saveRecipe,
              backgroundColor: const Color(0xFF2c5b92),
              icon: const Icon(
                Icons.favorite_border,
                color: Colors.white,
              ),
              label: const Text(
                "Guardar Receta",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _prepareRecipeModal,
              backgroundColor: const Color(0xFF2c5b92),
              icon: const Icon(
                Icons.kitchen,
                color: Colors.white,
              ),
              label: const Text(
                "Preparar Receta",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class PrepareRecipeModal extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final User user; // Recibe el user como parámetro

  const PrepareRecipeModal(
      {Key? key, required this.ingredients, required this.user})
      : super(key: key);

  @override
  _PrepareRecipeModalState createState() => _PrepareRecipeModalState();
}

class _PrepareRecipeModalState extends State<PrepareRecipeModal> {
  Map<String, int> userProductQuantities =
      {}; // Cantidades de productos del usuario
  Map<String, int> requiredQuantities =
      {}; // Cantidades requeridas para cada ingrediente
  bool isLoading = true; // Estado de carga inicial
  bool isUsingProducts = false; // Estado de uso de productos

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  Future<void> _loadUserProducts() async {
    final user = widget.user;
    final despensasRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('despensas');

    final despensasSnapshot = await despensasRef.get();

    if (despensasSnapshot.docs.isNotEmpty) {
      for (var despensaDoc in despensasSnapshot.docs) {
        final productosSnapshot =
            await despensaDoc.reference.collection('productos').get();
        for (var productDoc in productosSnapshot.docs) {
          final productName = productDoc['nombre'];
          final unitsSnapshot =
              await productDoc.reference.collection('unidades_productos').get();
          userProductQuantities[productName] = unitsSnapshot.docs.length;
        }
      }
    }

    if (mounted) {
      setState(() {
        for (var ingredient in widget.ingredients) {
          final ingredientName = ingredient['nombre'];
          final requiredAmount = ingredient['cantidad'];
          final unitMeasure = ingredient['medida'];

          if (userProductQuantities.containsKey(ingredientName)) {
            if (unitMeasure == 'unidades') {
              requiredQuantities[ingredientName] = requiredAmount;
            } else {
              requiredQuantities[ingredientName] = 1;
            }
          } else {
            requiredQuantities.remove(ingredientName);
          }
        }
        isLoading = false; // Termina la carga inicial
      });
    }
  }

  Future<void> _useProducts() async {
    setState(() {
      isUsingProducts = true; // Inicia el estado de uso de productos
    });

    final despensasRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .collection('despensas');

    for (var ingredient in widget.ingredients) {
      final name = ingredient['nombre'];
      final neededQuantity = requiredQuantities[name] ?? 0;
      int remaining = neededQuantity;
      final despensasSnapshot = await despensasRef.get();

      for (var despensaDoc in despensasSnapshot.docs) {
        final productosSnapshot = await despensaDoc.reference
            .collection('productos')
            .where('nombre', isEqualTo: name)
            .get();

        for (var productDoc in productosSnapshot.docs) {
          final unitsSnapshot =
              await productDoc.reference.collection('unidades_productos').get();
          for (var unitDoc in unitsSnapshot.docs) {
            if (remaining > 0) {
              await unitDoc.reference.delete();
              remaining--;
            } else {
              break;
            }
          }
        }
      }
    }

    setState(() {
      isUsingProducts = false; // Termina el estado de uso de productos
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Productos utilizados correctamente")),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasIngredients = widget.ingredients.any((ingredient) {
      final name = ingredient['nombre'];
      return requiredQuantities.containsKey(name);
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Utilizarás estos productos!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!hasIngredients)
            Text(
              "No tienes ingredientes de esta receta",
              style: TextStyle(fontSize: 16, color: Colors.red),
            )
          else
            ...widget.ingredients.map((ingredient) {
              final name = ingredient['nombre'];
              final requiredAmount = requiredQuantities[name] ?? 0;
              final availableQuantity = userProductQuantities[name] ?? 0;
              int displayedAmount = requiredAmount;

              if (availableQuantity < requiredAmount) {
                displayedAmount = availableQuantity;
              }

              if (requiredQuantities.containsKey(name)) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$name",
                      style: TextStyle(fontSize: 16),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: displayedAmount > 0
                              ? () {
                                  setState(() {
                                    requiredQuantities[name] =
                                        (displayedAmount - 1)
                                            .clamp(0, availableQuantity);
                                  });
                                }
                              : null,
                        ),
                        Text(
                          "$displayedAmount",
                          style: TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: displayedAmount < availableQuantity
                              ? () {
                                  setState(() {
                                    requiredQuantities[name] =
                                        (displayedAmount + 1)
                                            .clamp(0, availableQuantity);
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return SizedBox.shrink();
              }
            }).toList(),
          const SizedBox(height: 20),
          if (isUsingProducts)
            const CircularProgressIndicator(
              color: Color(0xFF124580),
            )
          else
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF124580)),
              onPressed: _useProducts,
              child: const Text(
                "Usar productos",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
