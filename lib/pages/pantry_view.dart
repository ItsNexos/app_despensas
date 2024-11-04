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
  List<Map<String, dynamic>> productosAgrupados = [];
  Map<String, bool> expandedStates = {};

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  // Cargar productos agrupados por nombre
  void _loadProductos() async {
    FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .get()
        .then((QuerySnapshot querySnapshot) {
      List<Map<String, dynamic>> productosList = [];

      for (var doc in querySnapshot.docs) {
        final nombre = doc['nombre'];
        final stockMinimo = doc['stockMinimo'];

        FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.userId)
            .collection('despensas')
            .doc(widget.despensaId)
            .collection('productos')
            .doc(doc.id)
            .collection('unidades_productos')
            .get()
            .then((QuerySnapshot unidadesSnapshot) {
          List<Map<String, dynamic>> unidades = [];

          for (var unidadDoc in unidadesSnapshot.docs) {
            final fechaIngreso = unidadDoc['fechaIngreso'];
            final fechaVencimiento = unidadDoc['fechaVencimiento'];

            unidades.add({
              'id': unidadDoc.id,
              'fechaIngreso': fechaIngreso,
              'fechaVencimiento': fechaVencimiento,
            });
          }

          setState(() {
            productosList.add({
              'id': doc.id,
              'nombre': nombre,
              'stockMinimo': stockMinimo,
              'unidades': unidades,
            });
          });
        });
      }
      setState(() {
        productosAgrupados = productosList;
      });
    });
  }

  // Agregar nuevo producto con unidades
  void _agregarProductoManual(BuildContext context) {
    final _nombreController = TextEditingController();
    final _cantidadController = TextEditingController();
    final _stockMinimoController = TextEditingController();
    DateTime? _fechaCaducidad;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar nuevo producto'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nombreController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre del Producto'),
                ),
                TextField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
                TextField(
                  controller: _stockMinimoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock mínimo'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Fecha de vencimiento: '),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _fechaCaducidad = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          _fechaCaducidad == null
                              ? 'Seleccionar'
                              : DateFormat('dd/MM/yyyy')
                                  .format(_fechaCaducidad!),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nombreController.text.isNotEmpty &&
                    _cantidadController.text.isNotEmpty &&
                    _fechaCaducidad != null) {
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
                    _fechaCaducidad!,
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

  // Guardar producto en Firestore
  void _guardarProducto(String nombre, int cantidad, int stockMinimo,
      String fechaIngreso, DateTime fechaVencimiento) async {
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
      await productoRef.collection('unidades_productos').add({
        'fechaIngreso': fechaIngreso,
        'fechaVencimiento': DateFormat('dd/MM/yyyy').format(fechaVencimiento),
      });
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
      appBar: AppBar(
        title: Text(widget.despensaNombre),
      ),
      body: ListView.builder(
        itemCount: productosAgrupados.length,
        itemBuilder: (context, index) {
          final producto = productosAgrupados[index];
          final nombre = producto['nombre'];
          final stockMinimo = producto['stockMinimo'];
          final unidades = producto['unidades'];

          return ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$nombre (Stock mínimo: $stockMinimo)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editarProducto(context, producto);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _eliminarProducto(producto['id']);
                      },
                    ),
                  ],
                ),
              ],
            ),
            initiallyExpanded: expandedStates[nombre] ?? false,
            onExpansionChanged: (isExpanded) {
              setState(() {
                expandedStates[nombre] = isExpanded;
              });
            },
            children: [
              ...unidades.map<Widget>((unidad) {
                return ListTile(
                  title: Text('Ingreso: ${unidad['fechaIngreso']}'),
                  subtitle: Text('Vencimiento: ${unidad['fechaVencimiento']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editarFechaVencimiento(
                              context, producto['id'], unidad);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(widget.userId)
                              .collection('despensas')
                              .doc(widget.despensaId)
                              .collection('productos')
                              .doc(producto['id'])
                              .collection('unidades_productos')
                              .doc(unidad['id'])
                              .delete()
                              .then((_) => _loadProductos());
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).primaryColor,
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
