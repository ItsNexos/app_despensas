import 'package:app_despensas/pages/addProduct_page.dart';
import 'package:app_despensas/pages/voice_page.dart'; // Importación de VoicePage
import 'package:flutter/material.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({Key? key}) : super(key: key);

  @override
  _PantryPageState createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  List<Map<String, dynamic>> pantries = [
    {
      'icon': Icons.shopping_cart,
      'title': 'Compras',
      'subtitle': 'Productos por clasificar',
      'quantity': '10 unidades',
      'color': Colors.grey[200],
      'alertColor': const Color(0XFF5E6773),
      'isFixed': true,
    },
    {
      'icon': Icons.favorite,
      'title': 'Favoritos',
      'subtitle': '3 productos',
      'quantity': '3 unidades',
      'color': Colors.grey[200],
      'alertColor': const Color(0xFFEC6856),
      'isFixed': true,
    },
    {
      'icon': Icons.kitchen,
      'title': 'Refrigerador',
      'subtitle': 'Productos en buen estado',
      'quantity': '16 unidades',
      'color': Colors.grey[200],
      'alertColor': const Color(0xFF4A78BE),
      'isFixed': true,
    },
    {
      'icon': Icons.chair,
      'title': 'Mueble',
      'subtitle': 'Productos almacenados',
      'quantity': '50 unidades',
      'color': Colors.grey[200],
      'alertColor': const Color(0xFF7E6853),
      'isFixed': true,
    },
  ];

  List<Map<String, dynamic>> filteredPantries = []; // Lista filtrada
  TextEditingController searchController = TextEditingController();
  
  // Lista de íconos disponibles para seleccionar
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

  IconData selectedIcon = Icons.kitchen; // Ícono por defecto al agregar

  @override
  void initState() {
    super.initState();
    filteredPantries = pantries; // Inicializa la lista filtrada con todas las despensas
    searchController.addListener(_filterPantries); // Agrega un listener al controlador de búsqueda
  }

  @override
  void dispose() {
    searchController.dispose(); // Libera el controlador al finalizar
    super.dispose();
  }

  void _filterPantries() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredPantries = pantries.where((pantry) {
        return pantry['title'].toLowerCase().contains(query);
      }).toList(); // Filtra las despensas según la búsqueda
    });
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
                      isFixed: pantry['isFixed'],
                      onTap: () {
                        // Acción al presionar una despensa
                        print('Navegar a los productos de ${pantry['title']}');
                      },
                      onDelete: () {
                        // Eliminar despensa y actualizar la interfaz
                        setState(() {
                          pantries.removeAt(pantries.indexOf(pantry)); // Elimina de la lista original
                          _filterPantries(); // Filtra la lista después de la eliminación
                        });
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
          _showAddOptions(context);
        },
        backgroundColor: const Color(0xFF4A618D),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: const Color(0xFFB0C4DE),
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          // Acción al cambiar de pestaña
        },
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
    required bool isFixed,
    required VoidCallback onTap,
    required VoidCallback onDelete,
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

  void _showAddOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Añadir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_box),
                title: const Text('Agregar Despensa'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPantryDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_shopping_cart),
                title: const Text('Agregar Producto'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddProductOptions(context);
                },
              ),
            ],
          ),
        );
      },
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
                decoration: const InputDecoration(hintText: 'Nombre de la despensa'),
                onChanged: (value) {
                  name = value; // Captura el nombre de la despensa
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(hintText: 'Categoría de la despensa'),
                onChanged: (value) {
                  category = value; // Captura la categoría de la despensa
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
                        Icon(iconData, size: 24, color: const Color(0xFF5E6773)), // Ícono en el menú
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedIcon = value!; // Almacena el ícono seleccionado
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Agrega la nueva despensa
                setState(() {
                  pantries.add({
                    'icon': selectedIcon,
                    'title': name,
                    'subtitle': '0 productos',
                    'quantity': '0 unidades',
                    'color': Colors.grey[200],
                    'alertColor': const Color(0xFF5E6773),
                    'isFixed': false,
                    'category': category, // Almacena la categoría
                  });
                });
                Navigator.pop(context); // Cierra el diálogo después de agregar
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _showAddProductOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Agregar por voz'),
                onTap: () {
                  // Navegar a la página de escaneo
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VoicePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard),
                title: const Text('Agregar manualmente'),
                onTap: () {
                  // Navegar a la página de agregar producto
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProductPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
