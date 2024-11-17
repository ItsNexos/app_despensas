import 'package:app_despensas/pages/recipe_edit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecipeViewPage extends StatefulWidget {
  final String recipeId;
  final User user; // Se pasa el User al constructor

  const RecipeViewPage({Key? key, required this.recipeId, required this.user})
      : super(key: key);

  @override
  _RecipeViewPageState createState() => _RecipeViewPageState();
}

class _RecipeViewPageState extends State<RecipeViewPage> {
  Map<String, dynamic> recipeData = {};
  List<Map<String, dynamic>> ingredients = [];

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    final recipeDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid) // Usamos widget.user.uid
        .collection('recetas')
        .doc(widget.recipeId)
        .get();

    final ingredientesSnapshot =
        await recipeDoc.reference.collection('ingredientes').get();

    setState(() {
      if (recipeDoc.data() != null) {
        recipeData = recipeDoc.data()!;
        recipeData['porciones'] = recipeDoc.data()!['porciones'] ?? 1;
      } else {
        recipeData = {};
        print("recipeDoc.data() es null");
      }

      if (ingredientesSnapshot.docs.isNotEmpty) {
        ingredients = ingredientesSnapshot.docs
            .map((doc) => {
                  'nombre': doc['nombre'] ?? 'Desconocido',
                  'cantidad': doc['cantidad'] ?? 0,
                  'medida': doc['medida'] ?? 'unidades',
                  'principal': doc['principal'] ?? false,
                })
            .toList();
      } else {
        ingredients = [];
        print("ingredientesSnapshot.docs está vacío");
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipeData['titulo'] ?? 'Receta'),
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipeData['titulo'] ?? '',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Categorías: ${recipeData['categorias']?.join(', ') ?? 'Sin categoría'}",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Porciones: ${recipeData['porciones']}", // Mostrar porciones
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                "Ingredientes:",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...ingredients.map((ingredient) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${ingredient['cantidad']} ${ingredient['medida']} de ${ingredient['nombre']}",
                      style: TextStyle(fontSize: 18),
                    ),
                    if (ingredient['principal'] == true)
                      Icon(Icons.star,
                          color: Colors
                              .amber), // Ícono de estrella para ingredientes principales
                  ],
                );
              }).toList(),

              const SizedBox(height: 20),
              Text(
                "Preparación:",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                recipeData['preparacion'] ?? '',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              // Botones en la parte inferior
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _prepareRecipeModal,
                    child: const Text("Preparar receta"),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeEditPage(
                                recipeId: widget.recipeId,
                                user: widget.user,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _useProducts,
              child: const Text("Usar productos"),
            ),
        ],
      ),
    );
  }
}
