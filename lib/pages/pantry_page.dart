import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_despensas/pages/pantry_view.dart';

class PantryPage extends StatefulWidget {
  final String userId;
  const PantryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _PantryPageState createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  List<Map<String, dynamic>> pantries = [];
  List<Map<String, dynamic>> filteredPantries = [];
  TextEditingController searchController = TextEditingController();
  final List<IconData> availableIcons = [
    Icons.kitchen,
    Icons.shopping_cart,
    Icons.favorite,
    Icons.local_grocery_store,
    Icons.local_drink,
    Icons.local_pizza,
    Icons.cake,
    Icons.local_offer,
  ];
  IconData selectedIcon = Icons.kitchen;

  @override
  void initState() {
    super.initState();
    _loadPantries(widget.userId);
    searchController.addListener(_filterPantries);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Cargar despensas y productos desde Firestore
  void _loadPantries(String userId) async {
    FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('despensas')
        .get()
        .then((QuerySnapshot querySnapshot) async {
      List<Map<String, dynamic>> loadedPantries = [];

      for (var doc in querySnapshot.docs) {
        String pantryId = doc.id;
        QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
            .collection('despensas')
            .doc(pantryId)
            .collection('productos')
            .get();
        int productCount = productsSnapshot.docs.length;

        loadedPantries.add({
          'id': pantryId,
          'icon': Icons.kitchen,
          'title': doc['nombre'],
          'subtitle': doc['categoria'],
          'quantity': '$productCount productos',
          'color': const Color.fromARGB(255, 238, 238, 238),
          'alertColor': const Color(0XFF5E6773),
        });
      }

      setState(() {
        pantries = loadedPantries;
        filteredPantries = pantries;
      });
    });
  }

  void _filterPantries() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredPantries = pantries.where((pantry) {
        return pantry['title'].toLowerCase().contains(query);
      }).toList();
    });
  }

  // Diálogo de confirmación de eliminación
  void _confirmDelete(BuildContext context, String pantryId, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Seguro que deseas eliminar esta despensa?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Eliminar despensa de Firestore
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.userId)
                    .collection('despensas')
                    .doc(pantryId)
                    .delete();
                FirebaseFirestore.instance
                    .collection('despensas')
                    .doc(pantryId)
                    .delete();

                setState(() {
                  pantries.removeAt(index);
                  _filterPantries();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Menú desplegable con pulsación larga
  void _showPantryOptions(BuildContext context, String pantryId, String title,
      String subtitle, IconData icon, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar despensa'),
              onTap: () {
                Navigator.pop(context);
                _showEditPantryDialog(context, pantryId, title, subtitle, icon);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Eliminar despensa'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, pantryId, index);
              },
            ),
          ],
        );
      },
    );
  }

  // Diálogo para editar despensa
  void _showEditPantryDialog(BuildContext context, String pantryId,
      String currentName, String currentCategory, IconData currentIcon) {
    String updatedName = currentName;
    String updatedCategory = currentCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Despensa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration:
                    const InputDecoration(hintText: 'Nombre de la despensa'),
                controller: TextEditingController(text: currentName),
                onChanged: (value) {
                  updatedName = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration:
                    const InputDecoration(hintText: 'Categoría de la despensa'),
                controller: TextEditingController(text: currentCategory),
                onChanged: (value) {
                  updatedCategory = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.userId)
                    .collection('despensas')
                    .doc(pantryId)
                    .update({
                  'nombre': updatedName,
                  'categoria': updatedCategory,
                }).then((_) {
                  _loadPantries(widget.userId);
                });
                Navigator.pop(context);
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Despensas'),
        backgroundColor: const Color(0xFFB0C4DE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPantries.length,
                itemBuilder: (context, index) {
                  final pantry = filteredPantries[index];
                  return GestureDetector(
                    onLongPress: () {
                      _showPantryOptions(
                        context,
                        pantry['id'],
                        pantry['title'],
                        pantry['subtitle'],
                        pantry['icon'],
                        index,
                      );
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantryView(
                            despensaId: pantry['id'],
                            despensaNombre: pantry['title'],
                            userId: user!.uid,
                          ),
                        ),
                      );
                    },
                    child: _buildPantryItem(
                      context,
                      icon: pantry['icon'],
                      title: pantry['title'],
                      subtitle: pantry['subtitle'],
                      quantity: pantry['quantity'],
                      color: pantry['color'],
                      alertColor: pantry['alertColor'],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPantryDialog(context);
        },
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF4A618D),
      ),
    );
  }

  Widget _buildPantryItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String quantity,
    required Color? color,
    required Color alertColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 40, color: alertColor),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            quantity,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  //Guardar despensa
  void _showAddPantryDialog(BuildContext context) {
    String name = '';
    String category = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nueva Despensa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration:
                    const InputDecoration(hintText: 'Nombre de la despensa'),
                onChanged: (value) {
                  name = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration:
                    const InputDecoration(hintText: 'Categoría de la despensa'),
                onChanged: (value) {
                  category = value;
                },
              ),
              const SizedBox(height: 10),
              DropdownButton<IconData>(
                value: selectedIcon,
                isExpanded: true,
                hint: const Text('Seleccionar ícono'),
                items: availableIcons.map((iconData) {
                  return DropdownMenuItem<IconData>(
                    value: iconData,
                    child: Row(
                      children: [
                        Icon(iconData,
                            size: 24, color: const Color(0xFF5E6773)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedIcon = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Agregar despensa a Firestore
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.userId)
                    .collection('despensas')
                    .add({
                  'nombre': name,
                  'categoria': category,
                  'icono': selectedIcon.codePoint,
                }).then((_) {
                  _loadPantries(widget.userId);
                });
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}
