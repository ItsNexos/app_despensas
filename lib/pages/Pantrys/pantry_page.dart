import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_despensas/pages/Pantrys/pantry_view.dart';

import 'package:shared_preferences/shared_preferences.dart';

class PantryPage extends StatefulWidget {
  final String userId;
  const PantryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _PantryPageState createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> pantries = [];
  List<Map<String, dynamic>> filteredPantries = [];
  Map<String, Color> pantryIconColors = {};
  TextEditingController searchController = TextEditingController();
  final Map<IconData, String> iconNames = {
    Icons.kitchen: 'Refrigerador',
    Icons.shopping_cart: 'Compras',
    Icons.favorite: 'Favoritos',
    Icons.ac_unit: 'Congelador',
    Icons.shelves: 'Mueble',
    Icons.medical_services: 'Botiquín',
    Icons.microwave: 'Microondas',
    Icons.set_meal: 'Carnes',
    Icons.fastfood: 'Comida rápida',
    Icons.liquor: 'Bebestibles',
    Icons.cookie: 'Snacks',
  };
  IconData selectedIcon = Icons.kitchen;

  @override
  void initState() {
    super.initState();
    _loadPantries(widget.userId).then((_) {
      _loadSavedColors();
    });
    searchController.addListener(_filterPantries);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Método para cargar colores guardados
  Future<void> _loadSavedColors() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pantryIconColors = Map.fromEntries(
        pantries.map((pantry) {
          final colorValue = prefs.getInt('pantry_color_${pantry['id']}');
          return MapEntry(
            pantry['id'],
            colorValue != null ? Color(colorValue) : const Color(0xFF5E6773),
          );
        }),
      );
    });
  }

  // Método para guardar color
  Future<void> _saveIconColor(String pantryId, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pantry_color_${pantryId}', color.value);
    setState(() {
      pantryIconColors[pantryId] = color;
    });
  }

  Future<void> _loadPantries(String userId) async {
    setState(() {
      isLoading = true;
    });

    final querySnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('despensas')
        .get();

    List<Map<String, dynamic>> loadedPantries = [];
    final prefs = await SharedPreferences.getInstance();

    for (var doc in querySnapshot.docs) {
      String pantryId = doc.id;
      QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('despensas')
          .doc(pantryId)
          .collection('productos')
          .get();

      final colorValue = prefs.getInt('pantry_color_${doc.id}');
      final iconColor =
          colorValue != null ? Color(colorValue) : const Color(0xFF5E6773);

      loadedPantries.add({
        'id': doc.id,
        'icon': IconData(doc['icono'], fontFamily: 'MaterialIcons'),
        'title': doc['nombre'],
        'total': productsSnapshot.docs.length,
        'iconColor': iconColor,
      });
    }

    if (mounted) {
      setState(() {
        pantries = loadedPantries;
        filteredPantries = pantries;
        isLoading = false;
      });
    }
  }

  void _filterPantries() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredPantries = pantries.where((pantry) {
        return pantry['title'].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF124580)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mis despensas',
          style: TextStyle(
            color: Color(0xFF124580),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF124580)),
            )
          : pantries.isEmpty
              ? const Center(
                  child: Text(
                    'No existen despensas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF124580),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Buscar despensas",
                          hintStyle: TextStyle(color: Colors.white),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF5D83b1),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                    Expanded(
                      child: filteredPantries.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay coincidencias',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF124580),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: filteredPantries.length,
                              itemBuilder: (context, index) {
                                final pantry = filteredPantries[index];
                                return GestureDetector(
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
                                  child: Container(
                                    height: 80,
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color.fromRGBO(
                                                  158, 158, 158, 1)
                                              .withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Parte del ícono con fondo gris
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: const BoxDecoration(
                                            color: Color(
                                                0xFFEBECED), // Fondo gris del ícono
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              bottomLeft: Radius.circular(10),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color.fromRGBO(
                                                    182, 182, 182, 0.205),
                                                spreadRadius: 1,
                                                blurRadius: 4,
                                                offset: const Offset(-5, 1),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            pantry['icon'],
                                            size: 45,
                                            color: pantry['iconColor'],
                                          ),
                                        ),

                                        // Parte de la información
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      pantry['title'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                        color:
                                                            Color(0xFF3A4247),
                                                      ),
                                                    ),
                                                    // Menú de 3 puntos
                                                    PopupMenuButton<String>(
                                                      icon: const Icon(
                                                          Icons.more_horiz),
                                                      onSelected:
                                                          (String value) {
                                                        if (value == 'edit') {
                                                          _showEditPantryDialog(
                                                              context, pantry);
                                                        } else if (value ==
                                                            'delete') {
                                                          _showDeleteConfirmationDialog(
                                                              context,
                                                              pantry['id']);
                                                        }
                                                      },
                                                      itemBuilder: (BuildContext
                                                              context) =>
                                                          [
                                                        const PopupMenuItem(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.edit),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text('Editar'),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                  Icons.delete),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text('Eliminar'),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    _buildStatusIcon(
                                                        Icons.event_busy,
                                                        Colors.red),
                                                    const SizedBox(width: 16),
                                                    _buildStatusIcon(
                                                        Icons.event,
                                                        Colors.orange),
                                                    const SizedBox(width: 16),
                                                    _buildStatusIcon(
                                                        Icons.event_available,
                                                        Colors.green),
                                                    const Spacer(),
                                                    // Agregar la cantidad de unidades antes de la flecha

                                                    Icon(
                                                      Icons.chevron_right,
                                                      color: Colors.grey[600],
                                                      size: 24,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          margin: const EdgeInsets.all(16),
          width: 200,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddPantryDialog(context),
            backgroundColor: const Color(0xFF2C5B92),
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Agregar despensa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusIcon(IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
      ],
    );
  }

  // Guardar nueva despensa
  void _showAddPantryDialog(BuildContext context) {
    String name = '';
    IconData tempSelectedIcon = selectedIcon;
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Nueva Despensa',
                style: TextStyle(
                  color: Color(0xFF124580),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(hintText: 'Nombre'),
                        onChanged: (value) {
                          name = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un nombre';
                          }
                          if (value.length > 20) {
                            return 'El nombre es demasiado largo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButton<IconData>(
                        value: tempSelectedIcon,
                        isExpanded: true,
                        hint: const Text('Seleccionar ícono'),
                        items: iconNames.entries.map((entry) {
                          return DropdownMenuItem<IconData>(
                            value: entry.key,
                            child: Row(
                              children: [
                                Icon(entry.key,
                                    size: 24, color: const Color(0xFF5E6773)),
                                const SizedBox(width: 8),
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: Color(0xFF3A4247),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            tempSelectedIcon = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      selectedIcon = tempSelectedIcon;

                      // Guardar en Firestore
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(widget.userId)
                          .collection('despensas')
                          .add({
                        'nombre': name,
                        'icono': selectedIcon.codePoint,
                      }).then((_) {
                        _loadPantries(widget.userId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Despensa creada exitosamente')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${error.toString()}')),
                        );
                      }).whenComplete(() {
                        Navigator.pop(context);
                      });
                    }
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPantryDialog(
      BuildContext context, Map<String, dynamic> pantry) {
    String name = pantry['title'];
    IconData currentIcon = pantry['icon'];
    Color iconColor = pantryIconColors[pantry['id']] ?? const Color(0xFF5E6773);
    final nameController = TextEditingController(text: name);

    Color tempIconColor = iconColor;

    Widget _buildColorOption(Color color, StateSetter setState) {
      return InkWell(
        onTap: () {
          setState(() {
            tempIconColor = color;
          });
          Navigator.pop(context);
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: color == tempIconColor ? Colors.black : Colors.grey,
              width: color == tempIconColor ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    final _formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Despensa'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: 'Nombre'),
                      onChanged: (value) {
                        name = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<IconData>(
                      value: currentIcon,
                      isExpanded: true,
                      hint: const Text('Seleccionar ícono'),
                      items: iconNames.entries.map((entry) {
                        return DropdownMenuItem<IconData>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(entry.key, size: 24, color: tempIconColor),
                              const SizedBox(width: 8),
                              Text(entry.value),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          currentIcon = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Color del ícono: '),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Seleccionar color'),
                                  content: SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildColorOption(
                                            Colors.blue, setState),
                                        _buildColorOption(Colors.red, setState),
                                        _buildColorOption(
                                            Colors.green, setState),
                                        _buildColorOption(
                                            Colors.orange, setState),
                                        _buildColorOption(
                                            Colors.purple, setState),
                                        _buildColorOption(
                                            Colors.teal, setState),
                                        _buildColorOption(
                                            Colors.pink, setState),
                                        _buildColorOption(
                                            Colors.brown, setState),
                                        _buildColorOption(
                                            const Color(0xFF5E6773), setState),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tempIconColor,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  // Validación: Nombre no puede estar vacío
                  if (_formKey.currentState!.validate()) {
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(widget.userId)
                        .collection('despensas')
                        .doc(pantry['id'])
                        .update({
                      'nombre': name,
                      'icono': currentIcon.codePoint,
                    });
                    await _saveIconColor(pantry['id'], tempIconColor);

                    // Actualizar el estado con los cambios definitivos
                    setState(() {
                      pantryIconColors[pantry['id']] = tempIconColor;
                      pantries = pantries.map((p) {
                        if (p['id'] == pantry['id']) {
                          return {
                            ...p,
                            'title': name,
                            'icon': currentIcon,
                            'iconColor': tempIconColor,
                          };
                        }
                        return p;
                      }).toList();
                      filteredPantries = pantries;
                    });

                    Navigator.pop(context);

                    // Mostrar mensaje de éxito
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Despensa actualizada exitosamente!'),
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String pantryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Despensa'),
          content:
              const Text('¿Estás seguro que deseas eliminar esta despensa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.userId)
                    .collection('despensas')
                    .doc(pantryId)
                    .delete()
                    .then((_) {
                  _loadPantries(widget.userId);
                  Navigator.pop(context);
                });
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
