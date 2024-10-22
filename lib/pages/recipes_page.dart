import 'package:flutter/material.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        backgroundColor: const Color(0xFFB0C4DE),
      ),
      body: const Center(
        child: Text(
          'Estás en la página de recetas',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
