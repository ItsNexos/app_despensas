import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PantryService {
  final String userId;

  PantryService({required this.userId});

  // Método para cargar las despensas
  Future<List<Map<String, dynamic>>> loadPantries() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('despensas')
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'icon': Icons.kitchen, // Mapea el ícono si lo tienes en Firestore
        'title': doc['nombre'],
        'subtitle': doc['categoria'],
        'quantity': '0 productos', // Mapea la cantidad si lo tienes
        'color': Colors.grey[200],
        'alertColor': const Color(0XFF5E6773),
      };
    }).toList();
  }

  // Método para agregar una nueva despensa
  Future<void> addPantry(String name, String category, IconData icon) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('despensas')
        .add({
      'nombre': name,
      'categoria': category,
      'icono': icon.codePoint,
    });
  }

  // Método para eliminar una despensa
  Future<void> deletePantry(String pantryId) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('despensas')
        .doc(pantryId)
        .delete();
  }

  // Método para editar una despensa existente
  Future<void> updatePantry(
      String pantryId, String name, String category, IconData icon) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('despensas')
        .doc(pantryId)
        .update({
      'nombre': name,
      'categoria': category,
      'icono': icon.codePoint,
    });
  }
}
