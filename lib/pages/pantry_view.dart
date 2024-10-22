import 'package:app_despensas/pages/voice_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

class PantryView extends StatefulWidget {
  final String despensaId;
  final String despensaNombre;
  final String
      userId; // Necesitamos el ID del usuario para acceder a su lista de productos

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

        try {
          fechaCaducidad =
              DateFormat('dd/MM/yyyy').parse(doc['fechaCaducidad']);
          fechaIngreso = DateFormat('dd/MM/yyyy').parse(doc['fechaIngreso']);
        } catch (e) {
          // Si hay un error en el formato de la fecha, lo puedes manejar aquí
          print('Error al convertir las fechas: $e');
        }

        if (!agrupadosPorNombre.containsKey(nombre)) {
          agrupadosPorNombre[nombre] = [];
        }
        agrupadosPorNombre[nombre]?.add({
          'id': doc.id,
          'fechaCaducidad': fechaCaducidad != null
              ? DateFormat('dd/MM/yyyy').format(fechaCaducidad)
              : 'Fecha inválida',
          'fechaIngreso': fechaIngreso != null
              ? DateFormat('dd/MM/yyyy').format(fechaIngreso)
              : 'Fecha inválida',
          'color': fechaCaducidad != null
              ? _getColorBasedOnExpiry(fechaCaducidad)
              : Colors.grey,
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

    if (difference <= 7) {
      return Colors.red;
    } else if (difference <= 30) {
      return Colors.orange;
    } else {
      return Colors.green;
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
                      : null;

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
        'cantidad': 1,
      };

      if (stockMinimo != null) {
        producto['stockMinimo'] = stockMinimo;
      }

      FirebaseFirestore.instance
          .collection('despensas')
          .doc(widget.despensaId)
          .collection('productos')
          .add(producto);

      // Guardar en "lista_productos" dentro del usuario logueado
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

  // Eliminar producto con confirmación
  void _eliminarProducto(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmación'),
        content:
            const Text('¿Estás seguro de que deseas eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('despensas')
                  .doc(widget.despensaId)
                  .collection('productos')
                  .doc(id)
                  .delete()
                  .then((_) {
                _loadProductos();
                Navigator.of(context).pop();
              });
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.despensaNombre),
        backgroundColor: const Color(0xFFB0C4DE),
      ),
      body: ListView.builder(
        itemCount: productosAgrupados.length,
        itemBuilder: (context, index) {
          final grupo = productosAgrupados[index];
          final nombre = grupo['nombre'];
          final productos = grupo['productos'];
          final cantidad = productos.length;
          final isExpanded = expandedStates[nombre] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  title: Text('$nombre ($cantidad unidades)'),
                  onTap: () {
                    setState(() {
                      expandedStates[nombre] = !isExpanded;
                    });
                  },
                ),
                if (isExpanded)
                  Column(
                    children: productos.map<Widget>((producto) {
                      return ListTile(
                        title: Text('$nombre'),
                        subtitle: Text(
                          'Ingreso: ${producto['fechaIngreso']} Vencimiento: ${producto['fechaCaducidad']}',
                          style: TextStyle(color: producto['color']),
                        ),
                        leading: Icon(Icons.circle, color: producto['color']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _eliminarProducto(producto['id']),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: SpeedDial(
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF4A618D),
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.edit),
            label: 'Manual',
            onTap: () => _agregarProductoManual(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.mic),
            label: 'Dictar por voz',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VoicePage()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code),
            label: 'Escanear código',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
