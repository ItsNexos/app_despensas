import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart'; // Para formato de fechas

class PantryView extends StatefulWidget {
  final String despensaId;
  final String despensaNombre;

  const PantryView(
      {Key? key, required this.despensaId, required this.despensaNombre})
      : super(key: key);

  @override
  _PantryViewState createState() => _PantryViewState();
}

class _PantryViewState extends State<PantryView> {
  List<Map<String, dynamic>> productos = [];

  @override
  void initState() {
    super.initState();
    _loadProductos(); // Cargar productos de Firestore al iniciar
  }

  // Cargar productos desde Firestore
  void _loadProductos() async {
    FirebaseFirestore.instance
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        productos = querySnapshot.docs.map((doc) {
          return {
            'nombre': doc['nombre'],
            'fechaCaducidad': doc['fechaCaducidad'],
            'fechaIngreso': doc['fechaIngreso'],
            'color':
                _getColorBasedOnExpiry(DateTime.parse(doc['fechaCaducidad'])),
          };
        }).toList();
      });
    });
  }

  // Obtener color basado en la fecha de caducidad
  Color _getColorBasedOnExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;

    if (difference <= 7) {
      return Colors.red; // Expira en menos de una semana
    } else if (difference <= 30) {
      return Colors.orange; // Expira en menos de un mes
    } else {
      return Colors.green; // Expira en más de un mes
    }
  }

  // Modal para agregar producto manualmente
  void _agregarProductoManual(BuildContext context) {
    final _nombreController = TextEditingController();
    final _cantidadController = TextEditingController();
    final _stockMinimoController = TextEditingController(); // Para stock mínimo
    DateTime? _fechaCaducidad;
    bool showStockMinimo =
        false; // Para controlar si se muestra el campo de stock mínimo

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Producto Manualmente'),
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
                              ? 'Seleccionar fecha'
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
                  final fechaIngreso = DateTime.now();
                  final stockMinimo = _stockMinimoController.text.isNotEmpty
                      ? int.parse(_stockMinimoController.text)
                      : null; // Si no está vacío, agregar el stock mínimo

                  _guardarProducto(
                    _nombreController.text,
                    cantidad,
                    _fechaCaducidad!,
                    fechaIngreso,
                    stockMinimo, // Pasar el stock mínimo
                  );
                  Navigator.of(context).pop(); // Cerrar modal
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
      DateTime fechaIngreso, int? stockMinimo) {
    for (int i = 0; i < cantidad; i++) {
      final producto = {
        'nombre': nombre,
        'fechaCaducidad': fechaCaducidad.toIso8601String(),
        'fechaIngreso': fechaIngreso.toIso8601String(),
        'cantidad': 1,
      };

      if (stockMinimo != null) {
        producto['stockMinimo'] =
            stockMinimo; // Agregar stock mínimo solo si se ingresó
      }

      FirebaseFirestore.instance
          .collection('despensas')
          .doc(widget.despensaId)
          .collection('productos')
          .add(producto);
    }
    _loadProductos(); // Refrescar la lista después de agregar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.despensaNombre),
        backgroundColor: const Color(0xFFB0C4DE),
      ),
      body: ListView.builder(
        itemCount: productos.length,
        itemBuilder: (context, index) {
          final producto = productos[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.shopping_bag), // Icono genérico
              title: Text(producto['nombre']),
              subtitle: Text(
                'Fecha de caducidad: ${producto['fechaCaducidad']}\n'
                'Fecha de ingreso: ${producto['fechaIngreso']}',
              ),
              trailing: Icon(Icons.circle,
                  color: producto[
                      'color']), // Muestra el color basado en caducidad
            ),
          );
        },
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
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
            onTap: () {},
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
