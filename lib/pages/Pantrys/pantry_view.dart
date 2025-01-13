import 'package:app_despensas/pages/Pantrys/Products/product_card.dart';
import 'package:app_despensas/pages/Pantrys/Products/voice_page.dart';
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
  bool isLoading = false;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> productosAgrupados = [];
  Map<String, bool> expandedStates = {};
  TextEditingController searchController = TextEditingController();

  List<String> selectedProductIds = [];

  @override
  void initState() {
    super.initState();
    _loadProductos();
    searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProductos() async {
    setState(() {
      isLoading = true;
    });
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
      final duracion = doc['duracion'];
      final tipoDuracion = doc['tipoDuracion'];
      final medida = doc['medida'];

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
        'duracion': duracion,
        'tipoDuracion': tipoDuracion,
        'medida': medida
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
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

  void _agregarProductoManual(BuildContext context) {
    final _nombreController = TextEditingController();
    final _cantidadController = TextEditingController();
    final _stockMinimoController = TextEditingController();
    String _medidaSeleccionada = 'Unidades';
    final _duracionController = TextEditingController();
    String _tipoDuracionSeleccionada = 'Días';

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Agregar nuevo producto',
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
                children: [
                  TextFormField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.sentences,
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
                  DropdownButtonFormField<String>(
                    value: _medidaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Unidad de medida',
                    ),
                    items: [
                      'Unidades',
                      'Gramos',
                      'Kilogramos',
                      'Litros',
                      'Mililitros'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(color: Color(0xFF3A4247)),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _medidaSeleccionada = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
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
                          return 'Valor inválido';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _duracionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duración',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese una duración';
                      }
                      final duracion = int.tryParse(value);
                      if (duracion == null || duracion <= 0) {
                        return 'La duración debe ser mayor a 0';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _tipoDuracionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de duración',
                    ),
                    items: ['Días', 'Semanas', 'Meses', 'Años']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(color: Color(0xFF3A4247)),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _tipoDuracionSeleccionada = newValue!;
                      });
                    },
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

                  int duracionOWO = int.parse(_duracionController.text);
                  _guardarProducto(
                    nombre,
                    cantidad,
                    stockMinimo,
                    fechaIngreso,
                    _medidaSeleccionada,
                    _tipoDuracionSeleccionada,
                    duracionOWO,
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

  void _guardarProducto(
      String nombre,
      int cantidad,
      int stockMinimo,
      String fechaIngreso,
      String medida,
      String tipoDuracion,
      int duracion) async {
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
      'medida': medida,
      'duracion': duracion,
      'tipoDuracion': tipoDuracion,
    });

    // Guardar cada unidad del producto
    for (int i = 0; i < cantidad; i++) {
      Map<String, dynamic> unidadData = {
        'fechaIngreso': fechaIngreso,
      };

      unidadData['fechaVencimiento'] =
          _calcularFechaVencimiento(fechaIngreso, duracion, tipoDuracion);

      await productoRef.collection('unidades_productos').add(unidadData);
    }

    _loadProductos();
  }

  // Editar producto existente
  void _editarProducto(BuildContext context, Map<String, dynamic> producto) {
    final _nombreController = TextEditingController(text: producto['nombre']);
    final _stockMinimoController =
        TextEditingController(text: producto['stockMinimo'].toString());
    final _duracionController =
        TextEditingController(text: producto['duracion'].toString());

    final _tipoDuracionController =
        TextEditingController(text: producto['tipoDuracion']);
    String duracion = _tipoDuracionController.text;

    final _medidaController = TextEditingController(text: producto['medida']);
    String medida = _medidaController.text;

    print(medida);

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Producto'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _medidaController.text,
                      decoration: const InputDecoration(
                        labelText: 'Unidad de medida',
                      ),
                      items: [
                        'Unidades',
                        'Gramos',
                        'Kilogramos',
                        'Litros',
                        'Mililitros'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          medida = newValue!;
                        });
                      },
                    ),
                    TextFormField(
                      controller: _stockMinimoController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Stock Mínimo'),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final stock = int.tryParse(value);
                          if (stock == null || stock < 0) {
                            return 'Valor inválido';
                          }
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _duracionController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duración'),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final stock = int.tryParse(value);
                          if (stock == null || stock < 0) {
                            return 'Valor inválido';
                          }
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: duracion,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de duración',
                      ),
                      items: ['Días', 'Semanas', 'Meses', 'Años']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          duracion = newValue!;
                        });
                      },
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
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final nuevoNombre = _nombreController.text;
                    final nuevoStockMinimo =
                        int.parse(_stockMinimoController.text);
                    final nuevaDuracion = int.parse(_duracionController.text);
                    final nuevoTipoDuracion = duracion;
                    final nuevaMedida = medida;

                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(widget.userId)
                        .collection('despensas')
                        .doc(widget.despensaId)
                        .collection('productos')
                        .doc(producto['id'])
                        .update({
                      'duracion': nuevaDuracion,
                      'medida': nuevaMedida,
                      'nombre': nuevoNombre,
                      'stockMinimo': nuevoStockMinimo,
                      'tipoDuracion': nuevoTipoDuracion,
                    });

                    Navigator.of(context).pop();
                    _loadProductos();
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

  void _agregarUnidadesProducto(
      BuildContext context, Map<String, dynamic> producto) {
    print('Producto recibido: $producto');
    final int duracion = producto['duracion'] ?? 0;
    final String tipoDuracion = producto['tipoDuracion'] ?? 'Días';
    final _cantidadController = TextEditingController();

    bool usarDuracion = true; // Por defecto usar la duración del producto
    String fechaIngreso = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String fechaVencimiento = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar unidades'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      if (cantidad == null || cantidad <= 0) {
                        return 'Ingrese un número válido mayor a 0';
                      }
                      return null;
                    },
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: usarDuracion,
                        onChanged: (value) {
                          setState(() {
                            usarDuracion = value!;
                          });
                        },
                      ),
                      const Text('Usar duración del producto'),
                    ],
                  ),
                  if (!usarDuracion)
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
                                fechaVencimiento =
                                    DateFormat('dd/MM/yyyy').format(pickedDate);
                              });
                            }
                          },
                          child: Text(
                            fechaVencimiento.isEmpty
                                ? 'Seleccionar'
                                : fechaVencimiento,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_cantidadController.text.isNotEmpty) {
                  final cantidad = int.parse(_cantidadController.text);
                  // Calcular fecha de vencimiento si "usarDuracion" está activo
                  if (usarDuracion) {
                    fechaVencimiento = _calcularFechaVencimiento(
                        fechaIngreso, duracion, tipoDuracion);
                  }

                  // Agregar unidades a Firestore
                  final productoRef = FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(widget.userId)
                      .collection('despensas')
                      .doc(widget.despensaId)
                      .collection('productos')
                      .doc(producto['id']);

                  for (int i = 0; i < cantidad; i++) {
                    await productoRef.collection('unidades_productos').add({
                      'fechaIngreso': fechaIngreso,
                      'fechaVencimiento': fechaVencimiento,
                    });
                  }

                  Navigator.of(context).pop();
                  _loadProductos();
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  String _calcularFechaVencimiento(
      String fechaIngreso, int duracion, String tipoDuracion) {
    DateTime fecha = DateFormat('dd/MM/yyyy').parse(fechaIngreso);

    switch (tipoDuracion) {
      case 'Días':
        fecha = fecha.add(Duration(days: duracion));
        break;
      case 'Semanas':
        fecha = fecha.add(Duration(days: duracion * 7));
        break;
      case 'Meses':
        fecha = DateTime(fecha.year, fecha.month + duracion, fecha.day);
        break;
      case 'Años':
        fecha = DateTime(fecha.year + duracion, fecha.month, fecha.day);
        break;
    }

    return DateFormat('dd/MM/yyyy').format(fecha);
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF124580),
              ),
            )
          : products.isEmpty
              ? const Center(
                  child: Text(
                    'Tu despensa está vacía. ¡Agrega productos para comenzar!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF124580),
                    ),
                    textAlign: TextAlign.center,
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
                          hintText: "Buscar producto",
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
                      child: filteredProducts.isEmpty
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
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: filteredProducts[index],
                                  onDeleteProduct: (id) {
                                    _eliminarProducto(id);
                                    _loadProductos();
                                  },
                                  onEditProduct: _editarProducto,
                                  onEditExpiration: _editarFechaVencimiento,
                                  onAddUnits: _agregarUnidadesProducto,
                                  onUnitDeleted: _loadProductos,
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
