import 'package:app_despensas/pages/pantry_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PantryPage extends StatefulWidget {
  final String userId; // Recibe el userId desde otra página
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
    _loadPantries(widget.userId); // Carga las despensas de Firestore
    searchController.addListener(_filterPantries);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Método para cargar las despensas desde Firestore
  void _loadPantries(String userId) async {
    FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('despensas')
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        pantries = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'icon': Icons
                .kitchen, // Puedes mapear un ícono específico si lo tienes en la base de datos
            'title': doc['nombre'],
            'subtitle': doc['categoria'],
            'quantity': '0 productos', // Puedes mapear la cantidad si lo tienes
            'color': Colors.grey[200],
            'alertColor': const Color(0XFF5E6773),
          };
        }).toList();
        filteredPantries = pantries; // Inicializa la lista filtrada
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

  void _showEditPantryDialog(BuildContext context, String pantryId,
      String currentName, String currentCategory, IconData currentIcon) {
    String updatedName = currentName;
    String updatedCategory = currentCategory;
    IconData updatedIcon = currentIcon;

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
                controller: TextEditingController(
                    text: currentName), // Pre-fill the name
                onChanged: (value) {
                  updatedName = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration:
                    const InputDecoration(hintText: 'Categoría de la despensa'),
                controller: TextEditingController(
                    text: currentCategory), // Pre-fill the category
                onChanged: (value) {
                  updatedCategory = value;
                },
              ),
              const SizedBox(height: 10),
              DropdownButton<IconData>(
                value: updatedIcon,
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
                    updatedIcon = value!;
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
                // Actualizar la despensa en Firestore
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.userId)
                    .collection('despensas')
                    .doc(pantryId)
                    .update({
                  'nombre': updatedName,
                  'categoria': updatedCategory,
                  'icono': updatedIcon.codePoint,
                }).then((_) {
                  _loadPantries(widget.userId); // Recargar las despensas
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Despensas'),
        backgroundColor: const Color(0xFFB0C4DE),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Acción para las notificaciones
            },
          ),
        ],
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildPantryItem(
                      context,
                      icon: pantry['icon'],
                      title: pantry['title'],
                      subtitle: pantry['subtitle'],
                      quantity: pantry['quantity'],
                      color: pantry['color'],
                      alertColor: pantry['alertColor'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PantryView(
                              despensaId: pantry['id'],
                              despensaNombre: pantry['title'],
                            ),
                          ),
                        );
                      },
                      onDelete: () {
                        // Eliminar despensa en Firestore
                        FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(widget.userId)
                            .collection('despensas')
                            .doc(pantry['id'])
                            .delete();
                        setState(() {
                          pantries.removeAt(index);
                          _filterPantries();
                        });
                      },
                      onEdit: () {
                        _showEditPantryDialog(
                            context,
                            pantry['id'],
                            pantry['title'],
                            pantry['subtitle'],
                            pantry['icon']);
                      },
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
        backgroundColor: const Color(0xFF4A618D),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: const Color(0xFFB0C4DE),
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'Despensa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Recetas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Plan Sem.',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
        ],
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
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required VoidCallback onEdit, // <-- Agregar onEdit
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  quantity,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit), // <-- Agregar botón de editar
                  onPressed: onEdit, // <-- Llamar a onEdit
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
