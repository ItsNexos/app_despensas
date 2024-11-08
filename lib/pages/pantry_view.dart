import 'package:app_despensas/pages/product_card.dart';
import 'package:app_despensas/pages/voice_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

class PantryView extends StatefulWidget {
  final String despensaId;
  final String despensaNombre;
  final String userId;

  const PantryView(
      {Key? key,
      required this.despensaId,
      required this.despensaNombre,
      required this.userId})
      : super(key: key);

  @override
  _PantryViewState createState() => _PantryViewState();
}

class _PantryViewState extends State<PantryView> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> productosAgrupados = [];
  Map<String, bool> expandedStates = {};
  TextEditingController searchController = TextEditingController();

  // Nuevo
  List<String> selectedProductIds = [];

  @override
  void initState() {
    super.initState();
    _loadProductos();
    searchController.addListener(_filterProducts);
  }

// Para buscar productos
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Cargar productos agrupados por nombre
  Future<void> _loadProductos() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .get();

    List<Map<String, dynamic>> productosList = [];

    for (var doc in querySnapshot.docs) {
      final nombre = doc['nombre'];
      final stockMinimo = doc['stockMinimo'];

      QuerySnapshot unidadesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('despensas')
          .doc(widget.despensaId)
          .collection('productos')
          .doc(doc.id)
          .collection('unidades_productos')
          .get();

      List<Map<String, dynamic>> unidades = unidadesSnapshot.docs
          .map((unidadDoc) => {
                'id': unidadDoc.id,
                'fechaIngreso': unidadDoc['fechaIngreso'],
                'fechaVencimiento': unidadDoc['fechaVencimiento'],
              })
          .toList();

      productosList.add({
        'id': doc.id,
        'nombre': nombre,
        'stockMinimo': stockMinimo,
        'unidades': unidades,
      });
    }

    if (mounted) {
      setState(() {
        productosAgrupados = productosList;
        products = productosList;
        filteredProducts = productosList;
      });
    }
  }

  void _filterProducts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        return product['nombre'].toLowerCase().contains(query);
      }).toList();
    });
  }

  // Modificación del método _agregarProductoManual
  void _agregarProductoManual(BuildContext context) {
    final _nombreController = TextEditingController();
    final _cantidadController = TextEditingController();
    final _stockMinimoController = TextEditingController();
    String _fechaCaducidad =
        ''; // Inicializar como string vacío en lugar de DateTime?
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar nuevo producto'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Producto',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un nombre';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese una cantidad';
                      }
                      final cantidad = int.tryParse(value);
                      if (cantidad == null) {
                        return 'Por favor ingrese un número válido';
                      }
                      if (cantidad <= 0) {
                        return 'La cantidad debe ser mayor a 0';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _stockMinimoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock mínimo',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final stock = int.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'El stock mínimo debe ser un número válido mayor o igual a 0';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fecha de vencimiento: '),
                      TextButton(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _fechaCaducidad =
                                  DateFormat('dd/MM/yyyy').format(pickedDate);
                            });
                          }
                        },
                        child: Text(
                          _fechaCaducidad.isEmpty
                              ? 'Opcional'
                              : _fechaCaducidad,
                        ),
                      ),
                      if (_fechaCaducidad.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _fechaCaducidad =
                                  ''; // Reinicia a un string vacío
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final nombre = _nombreController.text;
                  final cantidad = int.parse(_cantidadController.text);
                  final stockMinimo = _stockMinimoController.text.isEmpty
                      ? 0
                      : int.parse(_stockMinimoController.text);
                  final fechaIngreso =
                      DateFormat('dd/MM/yyyy').format(DateTime.now());

                  _guardarProducto(
                    nombre,
                    cantidad,
                    stockMinimo,
                    fechaIngreso,
                    _fechaCaducidad, // Enviar string vacío si no se elige fecha
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

// Modificación del método _guardarProducto para aceptar fecha de vencimiento opcional
  void _guardarProducto(String nombre, int cantidad, int stockMinimo,
      String fechaIngreso, String fechaVencimiento) async {
    final productoRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .doc(nombre);

    // Guardar información del producto
    await productoRef.set({
      'nombre': nombre,
      'stockMinimo': stockMinimo,
    });

    // Guardar cada unidad del producto
    for (int i = 0; i < cantidad; i++) {
      Map<String, dynamic> unidadData = {
        'fechaIngreso': fechaIngreso,
      };

      unidadData['fechaVencimiento'] = fechaVencimiento;

      await productoRef.collection('unidades_productos').add(unidadData);
    }

    _loadProductos();
  }

  // Editar producto existente
  void _editarProducto(BuildContext context, Map<String, dynamic> producto) {
    final _nombreController = TextEditingController(text: producto['nombre']);
    final _stockMinimoController =
        TextEditingController(text: producto['stockMinimo'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Producto'),
          content: Column(
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _stockMinimoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock Mínimo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoNombre = _nombreController.text;
                final nuevoStockMinimo = int.parse(_stockMinimoController.text);

                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(widget.userId)
                    .collection('despensas')
                    .doc(widget.despensaId)
                    .collection('productos')
                    .doc(producto['id'])
                    .update({
                  'nombre': nuevoNombre,
                  'stockMinimo': nuevoStockMinimo,
                });

                Navigator.of(context).pop();
                _loadProductos();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Editar la fecha de vencimiento de una unidad específica
  void _editarFechaVencimiento(BuildContext context, String productoId,
      Map<String, dynamic> unidad) async {
    DateTime? nuevaFecha;

    nuevaFecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (nuevaFecha != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('despensas')
          .doc(widget.despensaId)
          .collection('productos')
          .doc(productoId)
          .collection('unidades_productos')
          .doc(unidad['id'])
          .update({
        'fechaVencimiento': DateFormat('dd/MM/yyyy').format(nuevaFecha),
      });

      _loadProductos();
    }
  }

  // Eliminar producto completo
  void _eliminarProducto(String productoId) {
    final productoRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .doc(productoId);

    productoRef.collection('unidades_productos').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    productoRef.delete().then((_) => _loadProductos());
  }

  void _navigateToVoicePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VoicePage(despensaId: widget.despensaId),
      ),
    );
    _loadProductos();
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
          widget.despensaNombre,
          style: const TextStyle(
            color: Color(0xFF124580),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5D83B1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar producto',
                  hintStyle: TextStyle(color: Colors.white),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                style: const TextStyle(color: Colors.white),
                textAlignVertical: TextAlignVertical.center,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: filteredProducts[index],
                  onDeleteProduct: (id) {
                    _eliminarProducto(id);
                    _loadProductos(); // Recargar después de eliminar
                  },
                  onEditProduct: _editarProducto,
                  onEditExpiration: _editarFechaVencimiento,
                  onUnitDeleted:
                      _loadProductos, // Recargar después de eliminar una unidad
                  userId: widget.userId,
                  despensaId: widget.despensaId,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFF2C5B92),
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add_box),
            label: 'Agregar producto manualmente',
            onTap: () => _agregarProductoManual(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.mic),
            label: 'Agregar por voz',
            onTap: _navigateToVoicePage,
          ),
        ],
      ),
    );
  }
}
