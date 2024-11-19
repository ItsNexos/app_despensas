import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  DateTime? _selectedDate;
  int _quantity = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de producto'),
        backgroundColor: const Color(0xFFB0C4DE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón para tomar foto
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar foto'),
              onPressed: () {
                // Implementar funcionalidad de cámara
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.grey[300], // backgroundColor reemplaza primary
                foregroundColor:
                    Colors.black, // foregroundColor reemplaza onPrimary
              ),
            ),
            const SizedBox(height: 16),
            // Contenedor para tomar foto del código de barra
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 40, color: Colors.blue[800]),
                    const SizedBox(height: 8),
                    Text(
                      'Tomar foto código de barra',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Selección de fecha de vencimiento
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Fecha de vencimiento'
                          : 'Fecha: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Selección de cantidad con botones + y -
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ingresar cantidad'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (_quantity > 0) _quantity--;
                        });
                      },
                    ),
                    Text('$_quantity', style: const TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Botones de "Cancelar" y "Agregar"
            Row(
              children: [
                // Botón de "Cancelar"
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Regresa a la pantalla anterior
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFDFE8FB), // Botón gris para cancelar
                        foregroundColor: const Color(0xFF4A618D)),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                // Botón de "Agregar"
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Implementar lógica para agregar producto
                      // Validar la información
                      if (_quantity > 0 && _selectedDate != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Producto agregado')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Por favor completa todos los campos')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white // Color azul para agregar

                        ),
                    child: const Text('Agregar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
