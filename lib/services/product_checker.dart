import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductChecker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkExpiringProducts(String userId) async {
    try {
      final despensasSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('despensas')
          .get();

      for (var despensa in despensasSnapshot.docs) {
        final productosSnapshot = await _firestore
            .collection('usuarios')
            .doc(userId)
            .collection('despensas')
            .doc(despensa.id)
            .collection('productos')
            .get();

        for (var producto in productosSnapshot.docs) {
          final unidadesSnapshot = await _firestore
              .collection('usuarios')
              .doc(userId)
              .collection('despensas')
              .doc(despensa.id)
              .collection('productos')
              .doc(producto.id)
              .collection('unidades_productos')
              .get();

          for (var unidad in unidadesSnapshot.docs) {
            final fechaVencimientoStr = unidad.data()['fechaVencimiento'];
            if (fechaVencimientoStr == null || fechaVencimientoStr.isEmpty)
              continue;

            try {
              final fechaVencimiento =
                  DateFormat('dd/MM/yyyy').parse(fechaVencimientoStr);
              final diferenciaDias =
                  fechaVencimiento.difference(DateTime.now()).inDays;
              if (diferenciaDias <= 2) {
                return true;
              }
            } catch (e) {
              print('Error al procesar fecha: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error en checkExpiringProducts: $e');
    }
    return false;
  }

  Future<bool> checkLowStockProducts(String userId) async {
    try {
      final despensasSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('despensas')
          .get();

      for (var despensa in despensasSnapshot.docs) {
        final productosSnapshot = await _firestore
            .collection('usuarios')
            .doc(userId)
            .collection('despensas')
            .doc(despensa.id)
            .collection('productos')
            .get();

        for (var producto in productosSnapshot.docs) {
          final stockMinimo = producto.data()['stockMinimo'];
          if (stockMinimo == null) continue;

          final unidadesSnapshot = await _firestore
              .collection('usuarios')
              .doc(userId)
              .collection('despensas')
              .doc(despensa.id)
              .collection('productos')
              .doc(producto.id)
              .collection('unidades_productos')
              .get();

          final cantidadActual = unidadesSnapshot.size;
          if (cantidadActual <= stockMinimo) {
            return true;
          }
        }
      }
    } catch (e) {
      print('Error en checkLowStockProducts: $e');
    }
    return false;
  }
}
