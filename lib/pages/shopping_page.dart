import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingPage extends StatefulWidget {
  final String userId;

  const ShoppingPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ShoppingPageState createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  List<Map<String, dynamic>> productosBajoStock = [];

  // Función para eliminar un producto
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

        return Column(
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
          .collection('despensas')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar productos'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No hay productos próximos a vencer'));
        }

        var productos = snapshot.data!.docs;
        var productosPorVencer = <String, Map<String, dynamic>>{};

        for (var producto in productos) {
          try {
            DateTime fechaCaducidad =
                DateFormat('dd/MM/yyyy').parse(producto['fechaCaducidad']);
            DateTime ahora = DateTime.now();
            int diferenciaDias = fechaCaducidad.difference(ahora).inDays;

            if (diferenciaDias <= 7) {
              var nombre = producto['nombre'];
              if (productosPorVencer.containsKey(nombre)) {
                productosPorVencer[nombre]!['cantidad'] += producto['cantidad'];
              } else {
                productosPorVencer[nombre] = {
                  'fechaCaducidad': producto['fechaCaducidad'],
                  'cantidad': producto['cantidad'],
                };
              }
            }
          } catch (e) {
            print('Error al procesar fecha de caducidad: $e');
          }
        }

        if (productosPorVencer.isEmpty) {
          return const Center(child: Text('No hay productos por vencer'));
        }

        return Column(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ir a Comprar'),
        backgroundColor: const Color(0xFFB0C4DE),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(10.0),
              child:
                  Text('Productos anteriores', style: TextStyle(fontSize: 18)),
            ),
            StreamBuilder<QuerySnapshot>(
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
                  return const Center(
                      child: Text('No hay productos en la lista'));
                }

                var productos = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    var producto = productos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
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
            ),
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('Productos en Bajo Stock',
                  style: TextStyle(fontSize: 18)),
            ),
            _buildBajoStockSection(),
            const Padding(
              padding: EdgeInsets.all(10.0),
              child:
                  Text('Productos por Vencer', style: TextStyle(fontSize: 18)),
            ),
            _buildPorVencerSection(),
          ],
        ),
      ),
    );
  }
}
