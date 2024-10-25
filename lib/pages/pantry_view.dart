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
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .get()
        .then((QuerySnapshot querySnapshot) {
      Map<String, List<Map<String, dynamic>>> agrupadosPorNombre = {};

      for (var doc in querySnapshot.docs) {
        final nombre = doc['nombre'];
        DateTime? fechaCaducidad;
        DateTime? fechaIngreso;
        fechaIngreso = DateFormat('dd/MM/yyyy').parse(doc['fechaIngreso']);

        try {
          fechaCaducidad = doc['fechaCaducidad'] != "Sin registrar"
              ? DateFormat('dd/MM/yyyy').parse(doc['fechaCaducidad'])
              : null;
        } catch (e) {
          print('Error al convertir las fechas: $e');
        }

        if (!agrupadosPorNombre.containsKey(nombre)) {
          agrupadosPorNombre[nombre] = [];
        }
        agrupadosPorNombre[nombre]?.add({
          'id': doc.id,
          'fechaCaducidad': fechaCaducidad != null
              ? DateFormat('dd/MM/yyyy').format(fechaCaducidad)
              : 'Sin registrar',
          'fechaIngreso': DateFormat('dd/MM/yyyy').format(fechaIngreso),
          'color': fechaCaducidad != null
              ? _getColorBasedOnExpiry(fechaCaducidad)
              : Colors.grey,
          'stockMinimo': doc['stockMinimo'] ?? 0, // Control de stockMinimo
        });
      }

      setState(() {
        productosAgrupados = agrupadosPorNombre.entries
            .map((entry) => {'nombre': entry.key, 'productos': entry.value})
            .toList();
      });
    });
  }

  // Obtener color basado en la fecha de caducidad
  Color _getColorBasedOnExpiry(DateTime expiryDate) {
  final now = DateTime.now();
  final difference = expiryDate.difference(now).inDays;

  if (difference < 0) {
    return Colors.red; // Rojo para fechas pasadas
  } else if (difference <= 7) {
    return Colors.orange; // Naranja para dentro de una semana
  } else {
    return Colors.green; // Verde para después de una semana
  }
}


  // Modal para agregar producto manualmente
  void _agregarProductoManual(BuildContext context) {
    final _nombreController = TextEditingController();
    final _cantidadController = TextEditingController();
    final _stockMinimoController = TextEditingController();
    DateTime? _fechaCaducidad;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar nuevo producto '),
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
                  decoration: const InputDecoration(
                      labelText: 'Stock mínimo (opcional)'),
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
                  final cantidad = int.parse(_cantidadController.text);
                  final ahora = DateTime.now();
                  final fechaIngreso = DateFormat('dd/MM/yyyy').format(ahora);
                  final stockMinimo = _stockMinimoController.text.isNotEmpty
                      ? int.parse(_stockMinimoController.text)
                      : 0;

                  _guardarProducto(
                    _nombreController.text,
                    cantidad,
                    _fechaCaducidad!,
                    fechaIngreso,
                    stockMinimo,
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
  void _guardarProducto(String nombre, int cantidad, DateTime fechaCaducidad,
      String fechaIngreso, int? stockMinimo) async {
    String fechaV = DateFormat('dd/MM/yyyy').format(fechaCaducidad);
    for (int i = 0; i < cantidad; i++) {
      final producto = {
        'nombre': nombre,
        'fechaCaducidad': fechaV,
        'fechaIngreso': fechaIngreso,
        'stockMinimo': stockMinimo,
      };

      FirebaseFirestore.instance
          .collection('despensas')
          .doc(widget.despensaId)
          .collection('productos')
          .add(producto);

      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('lista_productos')
          .doc(nombre)
          .set({
        'nombre': nombre,
      }, SetOptions(merge: true));
    }
    _loadProductos();
  }

  void _actualizarProducto(String id, String nuevoNombre,
      String nuevaFechaCaducidad, int? nuevoStockMinimo) {
    FirebaseFirestore.instance
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .doc(id)
        .update({
      'nombre': nuevoNombre,
      'fechaCaducidad': nuevaFechaCaducidad,
      'stockMinimo': nuevoStockMinimo,
    }).then((_) {
      _loadProductos();
    });
  }

  void _editarProducto(BuildContext context, Map<String, dynamic> producto) {
    final _nombreController = TextEditingController(text: producto['nombre']);
    final _fechaCaducidadController =
        TextEditingController(text: producto['fechaCaducidad']);
    final _stockMinimoController =
        TextEditingController(text: producto['stockMinimo'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Producto'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nombreController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre del Producto'),
                ),
                TextField(
                  controller: _fechaCaducidadController,
                  decoration:
                      const InputDecoration(labelText: 'Fecha de Vencimiento'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: producto['fechaCaducidad'] != 'Sin registrar'
                          ? DateFormat('dd/MM/yyyy')
                              .parse(producto['fechaCaducidad'])
                          : DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      _fechaCaducidadController.text =
                          DateFormat('dd/MM/yyyy').format(pickedDate);
                    }
                  },
                ),
                TextField(
                  controller: _stockMinimoController,
                  decoration: const InputDecoration(
                      labelText: 'Stock Mínimo (opcional)'),
                  keyboardType: TextInputType.number,
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
                final nuevoNombre = _nombreController.text;
                final nuevaFechaCaducidad = _fechaCaducidadController.text;
                final nuevoStockMinimo = _stockMinimoController.text.isNotEmpty
                    ? int.parse(_stockMinimoController.text)
                    : null;

                _actualizarProducto(producto['id'], nuevoNombre,
                    nuevaFechaCaducidad, nuevoStockMinimo);
                Navigator.of(context).pop();
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarProducto(String productoId) {
    FirebaseFirestore.instance
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .doc(productoId)
        .delete()
        .then((_) {
      _loadProductos();
    });
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
          final productos = producto['productos'] as List<Map<String, dynamic>>;
          final cantidad = productos.length;

          return ExpansionTile(
            title: Text('$nombre ($cantidad unidades)',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                )),
            initiallyExpanded: expandedStates[nombre] ?? false,
            onExpansionChanged: (isExpanded) {
              setState(() {
                expandedStates[nombre] = isExpanded;
              });
            },
            children: productos.map<Widget>((productoIndividual) {
              final fechaCaducidad = productoIndividual['fechaCaducidad'];
              final fechaIngreso = productoIndividual['fechaIngreso'];
              final stockMinimo = productoIndividual['stockMinimo'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: productoIndividual['color'],
                ),
                title: Text('Fecha de caducidad: $fechaCaducidad',
                    style: TextStyle(color: productoIndividual['color'])),
                subtitle: Text(
                  'Ingreso: ${fechaIngreso ?? 'Sin registrar'}\n'
                  'Stock Minimo: ${stockMinimo}',
                  style: TextStyle(color: producto['color']),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _editarProducto(context, productoIndividual),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          _eliminarProducto(productoIndividual['id']),
                    ),
                  ],
                ),
              );
            }).toList(),
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
