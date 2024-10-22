import 'package:flutter/material.dart';

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ir a Comprar'),
        backgroundColor: const Color(0xFFB0C4DE),
      ),
      body: const Center(
        child: Text(
          'Estás en la página de compras',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
