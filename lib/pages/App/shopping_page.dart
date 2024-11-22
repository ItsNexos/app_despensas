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
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int bajoStockCount = 0;
  int vencidosCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _fetchCounts();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _fetchCounts() async {
    int bajoStock = await _countBajoStock();
    int vencidos = await _countVencidos();

    if (mounted) {
      setState(() {
        bajoStockCount = bajoStock;
        vencidosCount = vencidos;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getExpiryColor(String fechaVencimientoStr) {
    try {
      final fechaVencimiento =
          DateFormat('dd/MM/yyyy').parse(fechaVencimientoStr);
      final now = DateTime.now();
      if (fechaVencimiento.isBefore(now)) {
        return Colors.red;
      } else if (fechaVencimiento.isBefore(now.add(Duration(days: 7)))) {
        return Colors.yellow;
      } else {
        return Colors.green;
      }
    } catch (e) {
      print('Error al parsear fecha: $e');
      return Colors.grey;
    }
  }

  IconData _getIconFromCode(int code) {
    return IconData(code, fontFamily: 'MaterialIcons');
  }

  Widget _buildBajoStockSection() {
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
          return const Center(child: Text('No hay despensas disponibles'));
        }

        return ListView(
          children: despensasSnapshot.data!.docs.map((despensaDoc) {
            return StreamBuilder<QuerySnapshot>(
              stream: despensaDoc.reference.collection('productos').snapshots(),
              builder: (context, productosSnapshot) {
                if (productosSnapshot.hasError) {
                  return const Center(child: Text('Error al cargar productos'));
                }
                if (!productosSnapshot.hasData ||
                    productosSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                var productos =
                    productosSnapshot.data!.docs.where((productoDoc) {
                  final nombreProducto =
                      productoDoc['nombre']?.toString().toLowerCase() ?? '';
                  return _searchQuery.isEmpty ||
                      nombreProducto.contains(_searchQuery);
                }).toList();

                return Column(
                  children: productos.map((productoDoc) {
                    final stockMinimo = productoDoc['stockMinimo'] ?? 0;

                    return FutureBuilder<QuerySnapshot>(
                      future: productoDoc.reference
                          .collection('unidades_productos')
                          .get(),
                      builder: (context, unidadesSnapshot) {
                        if (unidadesSnapshot.hasError) {
                          return const Center(
                              child: Text('Error al cargar unidades'));
                        }
                        if (!unidadesSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final unidades = unidadesSnapshot.data!.docs;
                        final cantidadActual = unidades.length;

                        if (cantidadActual > stockMinimo) {
                          return const SizedBox.shrink();
                        }
                        return Card(
                          color: Colors.white,
                          elevation: 4, // Eliminar sombra
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: ExpansionTile(
                            leading: despensaDoc['icono'] != null
                                ? Icon(
                                    _getIconFromCode(despensaDoc['icono']),
                                    size: 30,
                                    color: Color(0xFF5D83B1),
                                  )
                                : const Icon(
                                    Icons.shopping_basket,
                                    color: Color(0xFF5D83B1),
                                    size: 30,
                                  ),
                            title: Text(
                              productoDoc['nombre'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3C3F44),
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.amber,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Cantidad actual: $cantidadActual/$stockMinimo",
                                  style: const TextStyle(
                                    color: Color(0xFF4C525A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              ],
                            ),
                            children: unidades.map<Widget>((unidadDoc) {
                              final fechaVencimientoStr =
                                  unidadDoc['fechaVencimiento'];
                              final fechaIngresoStr = unidadDoc['fechaIngreso'];
                              return ListTile(
                                title: Text(
                                  "Fecha vencimiento: $fechaVencimientoStr",
                                  style: TextStyle(
                                    color: _getExpiryColor(fechaVencimientoStr),
                                  ),
                                ),
                                subtitle: Text(
                                  "Fecha ingreso: $fechaIngresoStr",
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
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
          return const Center(child: Text('No hay despensas disponibles'));
        }

        return ListView(
          children: despensasSnapshot.data!.docs.map((despensaDoc) {
            return StreamBuilder<QuerySnapshot>(
              stream: despensaDoc.reference.collection('productos').snapshots(),
              builder: (context, productosSnapshot) {
                if (productosSnapshot.hasError) {
                  return const Center(child: Text('Error al cargar productos'));
                }
                if (!productosSnapshot.hasData ||
                    productosSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                var productos =
                    productosSnapshot.data!.docs.where((productoDoc) {
                  final nombreProducto =
                      productoDoc['nombre']?.toString().toLowerCase() ?? '';
                  return _searchQuery.isEmpty ||
                      nombreProducto.contains(_searchQuery);
                }).toList();

                return Column(
                  children: productos.map((productoDoc) {
                    return FutureBuilder<QuerySnapshot>(
                      future: productoDoc.reference
                          .collection('unidades_productos')
                          .get(),
                      builder: (context, unidadesSnapshot) {
                        if (unidadesSnapshot.hasError) {
                          return const Center(
                              child: Text('Error al cargar unidades'));
                        }
                        if (!unidadesSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final unidadesVencidas =
                            unidadesSnapshot.data!.docs.where((unidadDoc) {
                          final fechaVencimientoStr =
                              unidadDoc['fechaVencimiento'];
                          try {
                            final fechaVencimiento = DateFormat('dd/MM/yyyy')
                                .parse(fechaVencimientoStr);
                            return fechaVencimiento.isBefore(DateTime.now());
                          } catch (e) {
                            print('Error al parsear fecha: $e');
                            return false;
                          }
                        }).toList();

                        if (unidadesVencidas.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          color: Colors.white,
                          elevation: 0, // Eliminar sombra
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 8),
                          child: ExpansionTile(
                            leading: despensaDoc['icono'] != null
                                ? Icon(
                                    _getIconFromCode(despensaDoc['icono']),
                                    size: 30,
                                    color: Color(0xFF5D83B1),
                                  )
                                : const Icon(
                                    Icons.shopping_basket,
                                    color: Color(0xFF5D83B1),
                                    size: 30,
                                  ),
                            title: Text(
                              productoDoc['nombre'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3C3F44),
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 15,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Productos vencidos: ${unidadesVencidas.length}",
                                  style: const TextStyle(
                                      color: Color(0xFF4C525A),
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            children: unidadesVencidas.map<Widget>((unidadDoc) {
                              final fechaVencimientoStr =
                                  unidadDoc['fechaVencimiento'];
                              final fechaIngresoStr = unidadDoc['fechaIngreso'];
                              return ListTile(
                                title: Text(
                                  "Fecha vencimiento: $fechaVencimientoStr",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _getExpiryColor(fechaVencimientoStr),
                                  ),
                                ),
                                subtitle: Text(
                                  "Fecha ingreso: $fechaIngresoStr",
                                  style: const TextStyle(fontSize: 15),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            );
          }).toList(),
        );
      },
    );
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
        title: const Text(
          'Lista de compras',
          style: TextStyle(
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
                controller: _searchController,
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
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            isScrollable: true,
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF124580),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Bajo Stock'),
                    const SizedBox(width: 5),
                    _buildCountBadge(bajoStockCount),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Vencidos'),
                    const SizedBox(width: 4),
                    _buildCountBadge(vencidosCount),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBajoStockSection(),
                _buildPorVencerSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
            color: Color(0xFF5D83B1), fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<int> _countBajoStock() async {
    int totalCount = 0;
    final despensasSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('despensas')
        .get();

    for (var despensaDoc in despensasSnapshot.docs) {
      final productosSnapshot =
          await despensaDoc.reference.collection('productos').get();
      for (var productoDoc in productosSnapshot.docs) {
        final stockMinimo = productoDoc['stockMinimo'] ?? 0;
        final unidadesSnapshot =
            await productoDoc.reference.collection('unidades_productos').get();
        if (unidadesSnapshot.docs.length <= stockMinimo) {
          totalCount++;
        }
      }
    }
    return totalCount;
  }

  Future<int> _countVencidos() async {
    int vencidosCount = 0;
    final despensasSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('despensas')
        .get();

    for (var despensaDoc in despensasSnapshot.docs) {
      final productosSnapshot =
          await despensaDoc.reference.collection('productos').get();
      for (var productoDoc in productosSnapshot.docs) {
        final unidadesSnapshot =
            await productoDoc.reference.collection('unidades_productos').get();

        final hasVencidas = unidadesSnapshot.docs.any((unidadDoc) {
          final fechaVencimientoStr = unidadDoc['fechaVencimiento'];
          if (fechaVencimientoStr != null && fechaVencimientoStr.isNotEmpty) {
            try {
              final fechaVencimiento =
                  DateFormat('dd/MM/yyyy').parse(fechaVencimientoStr);
              return fechaVencimiento.isBefore(DateTime.now());
            } catch (e) {
              print('Error parsing date: $fechaVencimientoStr');
              return false;
            }
          }
          return false;
        });

        if (hasVencidas) {
          vencidosCount++;
        }
      }
    }
    return vencidosCount;
  }
}
