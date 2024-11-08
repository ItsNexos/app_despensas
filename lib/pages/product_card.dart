import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(String) onDeleteProduct;
  final Function(BuildContext, Map<String, dynamic>) onEditProduct;
  final Function(BuildContext, String, Map<String, dynamic>) onEditExpiration;
  final Function() onUnitDeleted;
  final String userId;
  final String despensaId;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onDeleteProduct,
    required this.onEditProduct,
    required this.onEditExpiration,
    required this.onUnitDeleted,
    required this.userId,
    required this.despensaId,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isExpanded = false;

  Color _getExpirationColor(String? expirationDate) {
    // Si no hay fecha de vencimiento, retornar gris
    if (expirationDate == null || expirationDate.isEmpty) {
      return Colors.grey[100]!;
    }

    final DateFormat format = DateFormat('dd/MM/yyyy');
    final DateTime expDate = format.parse(expirationDate);
    final DateTime now = DateTime.now();
    final Duration difference = expDate.difference(now);

    if (difference.isNegative) {
      return Colors.red[100]!;
    } else if (difference.inDays <= 7) {
      return Colors.orange[100]!;
    }
    return Colors.green[100]!;
  }

  Future<void> _deleteUnit(String unitId, BuildContext context) async {
    // Verificamos primero si es la última unidad
    final unidadesSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .doc(widget.product['id'])
        .collection('unidades_productos')
        .get();

    if (unidadesSnapshot.docs.length == 1) {
      // Es la última unidad, mostrar confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text(
                'Esta es la última unidad del producto. Al eliminarla, se eliminará el producto completo. ¿Desea continuar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          );
        },
      );

      if (confirmar != true) return;
    }

    // Proceder con la eliminación
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('despensas')
        .doc(widget.despensaId)
        .collection('productos')
        .doc(widget.product['id'])
        .collection('unidades_productos')
        .doc(unitId)
        .delete();

    // Si era la última unidad, eliminar el producto
    if (unidadesSnapshot.docs.length == 1) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('despensas')
          .doc(widget.despensaId)
          .collection('productos')
          .doc(widget.product['id'])
          .delete();
    }

    widget.onUnitDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final unidades = widget.product['unidades'] as List<dynamic>;
    final stockMinimo = widget.product['stockMinimo'];
    final hasMinimumStock = stockMinimo > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF5D83B1),
              child: Icon(
                Icons.shopping_basket,
                color: Colors.white,
              ),
            ),
            title: Text(
              widget.product['nombre'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              hasMinimumStock
                  ? '${unidades.length} uds. • Unidades mínimas: $stockMinimo'
                  : '${unidades.length} uds.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (String value) {
                    switch (value) {
                      case 'edit':
                        widget.onEditProduct(context, widget.product);
                        break;
                      case 'delete':
                        widget.onDeleteProduct(widget.product['id']);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Editar'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Eliminar'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded && unidades.isNotEmpty)
            Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unidades.length,
                  itemBuilder: (context, index) {
                    final unidad = unidades[index];
                    final fechaVencimiento =
                        unidad['fechaVencimiento'] as String?;
                    final color = _getExpirationColor(fechaVencimiento);

                    return Container(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 4,
                        top: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          'Fecha de vencimiento: ${fechaVencimiento?.isNotEmpty == true ? fechaVencimiento : "Sin registrar"}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          'Fecha de ingreso: ${unidad['fechaIngreso']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_calendar_outlined,
                                  size: 20),
                              onPressed: () => widget.onEditExpiration(
                                context,
                                widget.product['id'],
                                unidad,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () =>
                                  _deleteUnit(unidad['id'], context),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
        ],
      ),
    );
  }
}
