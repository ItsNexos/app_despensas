import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingPage extends StatefulWidget {
  final String userId;

  const ShoppingPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ShoppingPageState createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> productosBajoStock = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _eliminarProducto(String productoId) {
    FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('lista_productos')
        .doc(productoId)
        .delete()
        .catchError((error) {
      print('Error al eliminar producto: $error');
    });
  }

  Widget _buildBajoStockSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('despensas')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar despensas'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay despensas disponibles'));
        }

        var productosAgrupados = <String, List<QueryDocumentSnapshot>>{};
        var idsDespensas = snapshot.data!.docs.map((doc) => doc.id).toList();

        for (var despensaId in idsDespensas) {
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(widget.userId)
              .collection('despensas')
              .doc(despensaId)
              .collection('productos')
              .get()
              .then((productosSnapshot) {
            for (var producto in productosSnapshot.docs) {
              final nombre = producto['nombre'];
              if (!productosAgrupados.containsKey(nombre)) {
                productosAgrupados[nombre] = [];
              }
              productosAgrupados[nombre]?.add(producto);
            }

            var productosBajoStockLocal =
                productosAgrupados.entries.where((entry) {
              final productosConMismoNombre = entry.value;
              final totalProductos = productosConMismoNombre.length;
              final stockMinimo = productosConMismoNombre.first['stockMinimo'];
              return totalProductos <= stockMinimo;
            }).toList();

            if (mounted) {
              setState(() {
                productosBajoStock = productosBajoStockLocal.map((entry) {
                  return {
                    'nombre': entry.key,
                    'cantidad': entry.value.length,
                  };
                }).toList();
              });
            }
          }).catchError((error) {
            print('Error al obtener productos: $error');
          });
        }

        if (productosBajoStock.isEmpty) {
          return const Center(child: Text('No hay productos en bajo stock'));
        }

        return ListView(
          children: productosBajoStock.map<Widget>((producto) {
            return ListTile(
              title: Text('${producto['nombre']} - Bajo Stock'),
              subtitle: Text('Cantidad actual: ${producto['cantidad']}'),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPorVencerSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('despensas')
          .snapshots(),
      builder: (context, despensasSnapshot) {
        if (despensasSnapshot.hasError) {
          return const Center(child: Text('Error al cargar despensas'));
        }

        if (!despensasSnapshot.hasData ||
            despensasSnapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No hay productos próximos a vencer'));
        }

        var productosPorVencer = <String, Map<String, dynamic>>{};
        DateTime ahora = DateTime.now();

        // Recorrer todas las despensas del usuario y sus productos en una sola iteración
        for (var despensa in despensasSnapshot.data!.docs) {
          var despensaProductosRef = despensa.reference.collection('productos');

          // Obtener los productos de la despensa actual
          despensaProductosRef.get().then((productosSnapshot) {
            for (var producto in productosSnapshot.docs) {
              try {
                if (producto.data().containsKey('fechaCaducidad')) {
                  DateTime fechaCaducidad = DateFormat('dd/MM/yyyy')
                      .parse(producto['fechaCaducidad']);
                  int diferenciaDias = fechaCaducidad.difference(ahora).inDays;

                  if (diferenciaDias <= 7) {
                    var nombre = producto['nombre'];
                    if (productosPorVencer.containsKey(nombre)) {
                      productosPorVencer[nombre]!['cantidad'] += 1;
                    } else {
                      productosPorVencer[nombre] = {
                        'fechaCaducidad': producto['fechaCaducidad'],
                        'cantidad':
                            1, // Inicializa con 1 al encontrar el primer producto
                      };
                    }
                  }
                }
              } catch (e) {
                print('Error al procesar fecha de caducidad: $e');
              }
            }

            // Actualizar la vista si el widget está montado
            if (mounted) {
              setState(() {
                productosPorVencer = productosPorVencer;
              });
            }
          }).catchError((error) {
            print(
                'Error al obtener productos de la despensa ${despensa.id}: $error');
          });
        }

        if (productosPorVencer.isEmpty) {
          return const Center(child: Text('No hay productos por vencer'));
        }

        return ListView(
          children: productosPorVencer.entries.map<Widget>((entry) {
            var nombre = entry.key;
            var detalles = entry.value;
            return ListTile(
              title: Text('$nombre - Próximo a vencer'),
              subtitle: Text(
                  'Fecha de caducidad: ${detalles['fechaCaducidad']} - Cantidad por vencer: ${detalles['cantidad']}'),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProductosCompradosSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('lista_productos')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar productos'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay productos comprados'));
        }

        var productos = snapshot.data!.docs;
        return ListView.builder(
          itemCount: productos.length,
          itemBuilder: (context, index) {
            var producto = productos[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: ListTile(
                title: Text(producto['nombre']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _eliminarProducto(producto.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ir a Comprar'),
        backgroundColor: const Color(0xFFB0C4DE),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bajo Stock'),
            Tab(text: 'Por Vencer'),
            Tab(text: 'Productos Comprados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBajoStockSection(),
          _buildPorVencerSection(),
          _buildProductosCompradosSection(),
        ],
      ),
    );
  }
}
