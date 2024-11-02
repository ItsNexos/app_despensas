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
            .collection('usuarios')
            .doc(userId)
            .collection('despensas')
            .doc(pantryId)
            .collection('productos')
            .get();
        int productCount = productsSnapshot.docs.length;

        loadedPantries.add({
          'id': pantryId,
          'icon': IconData(doc['icono'], fontFamily: 'MaterialIcons'),
          'title': doc['nombre'],
          'subtitle': doc['descripcion'],
          'quantity': '$productCount productos',
          'color': const Color.fromARGB(255, 238, 238, 238),
          'alertColor': const Color(0XFF5E6773),
        });
      }

      // Asegurarse de que el widget esté montado antes de llamar a setState
      if (mounted) {
        setState(() {
          pantries = loadedPantries;
          filteredPantries = pantries;
        });
      }
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

  // Cambios en el diálogo de confirmación para evitar la eliminación de "Productos no ordenados".
  void _confirmDelete(BuildContext context, String pantryId, int index) {
    if (filteredPantries[index]['title'] == 'Productos no ordenados') {
      // Muestra un mensaje o evita continuar si es la despensa predeterminada
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta despensa no se puede eliminar.')),
      );
      return;
    }

    // Código de eliminación original
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
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.userId)
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
                _showEditPantryDialog(
                    context, pantryId, title, subtitle, icon, index);
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

  // Cambios en _showEditPantryDialog para cambiar el campo de "categoria" a "descripcion" y permitir la edición del ícono.
  void _showEditPantryDialog(
      BuildContext context,
      String pantryId,
      String currentName,
      String currentDescription,
      IconData currentIcon,
      int index) {
    if (filteredPantries[index]['title'] == 'Productos no ordenados') {
      // Muestra un mensaje o evita continuar si es la despensa predeterminada
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta despensa no se puede editar.')),
      );
      return;
    }
    String updatedName = currentName;
    String updatedDescription = currentDescription;
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
                controller: TextEditingController(text: currentName),
                onChanged: (value) {
                  updatedName = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                    hintText: 'Descripción de la despensa'),
                controller: TextEditingController(text: currentDescription),
                onChanged: (value) {
                  updatedDescription = value;
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
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.userId)
                    .collection('despensas')
                    .doc(pantryId)
                    .update({
                  'nombre': updatedName,
                  'descripcion': updatedDescription,
                  'icono': updatedIcon.codePoint,
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
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
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

// Guardar nueva despensa
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
                decoration: const InputDecoration(hintText: 'Nombre'),
                onChanged: (value) {
                  name = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(hintText: 'Descripcion'),
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
                // Agregar despensa solo a la subcolección en usuarios
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.userId)
                    .collection('despensas')
                    .add({
                  'nombre': name,
                  'descripcion': category,
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
