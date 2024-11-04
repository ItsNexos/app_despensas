import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VoicePage extends StatefulWidget {
  final String despensaId;

  const VoicePage({super.key, required this.despensaId});

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  User? user = FirebaseAuth.instance.currentUser;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'es_ES', // Cambia esto si quieres otro dialecto
    );
    setState(() {
      _confidenceLevel = 0;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
      _confidenceLevel = result.confidence;
    });
    _filterSpokenWords(_wordsSpoken);
  }

  void _filterSpokenWords(String words) {
    List<String> wordList = words.split(' ');
    List<Map<String, dynamic>> filteredProducts = [];
    String currentProduct = '';
    int? currentQuantity;

    for (int i = 0; i < wordList.length; i++) {
      String word = wordList[i];
      int? quantity = _tryParseNumber(word);

      if (quantity != null) {
        if (currentProduct.isNotEmpty) {
          filteredProducts.add({
            'quantity': currentQuantity,
            'product': currentProduct.trim(),
            'date': DateTime.now().toString(),
            'expiryDate': ""
          });
        }
        currentQuantity = quantity;
        currentProduct = '';
      } else {
        currentProduct += word + ' ';
      }
    }

    if (currentProduct.isNotEmpty && currentQuantity != null) {
      filteredProducts.add({
        'quantity': currentQuantity,
        'product': currentProduct.trim(),
        'date': DateTime.now().toString(),
        'expiryDate': ""
      });
    }

    setState(() {
      _products = filteredProducts;
    });
  }

  int? _tryParseNumber(String word) {
    try {
      return int.parse(word);
    } catch (e) {
      return palabrasANumeroExtendido(word);
    }
  }

  int? palabrasANumeroExtendido(String palabra) {
    Map<String, int> unidades = {
      'cero': 0,
      'un': 1,
      'una': 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9
    };
    Map<String, int> decenas = {'diez': 10, 'veinte': 20, 'treinta': 30};
    Map<String, int> excepciones = {
      'once': 11,
      'doce': 12,
      'trece': 13,
      'catorce': 14,
      'quince': 15
    };

    if (unidades.containsKey(palabra)) return unidades[palabra];
    if (decenas.containsKey(palabra)) return decenas[palabra];
    if (excepciones.containsKey(palabra)) return excepciones[palabra];
    return null;
  }

  void _agregarProductosADespensa() async {
    // Referencia a la colección 'despensas' y al documento con la ID de la despensa
    CollectionReference despensasRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('despensas');

    try {
      // Recorremos cada producto en la lista _products
      for (var product in _products) {
        int cantidad = product['quantity'];
        String nombre = product['product'];

        // Referencia al documento del producto en la colección 'productos'
        DocumentReference productoDocRef = despensasRef
            .doc(widget.despensaId)
            .collection('productos')
            .doc(nombre);

        // Verificamos si el producto ya existe y obtenemos el valor de stockMinimo si es el caso
        int stockMinimo = 0; // Valor predeterminado
        DocumentSnapshot productoSnapshot = await productoDocRef.get();
        if (productoSnapshot.exists) {
          stockMinimo = productoSnapshot.get('stockMinimo') ?? 0;
        }

        // Establecemos el documento del producto en la colección 'productos'
        await productoDocRef.set({
          'nombre': nombre,
          'stockMinimo': stockMinimo,
        });

        // Añadimos la cantidad como unidades individuales en 'unidades_productos'
        for (int i = 0; i < cantidad; i++) {
          await productoDocRef.collection('unidades_productos').add({
            'fechaIngreso': DateFormat('dd/MM/yyyy').format(DateTime.now()),
            'fechaVencimiento': '',
          });
        }

        // Agregar a 'lista_productos' de 'usuarios' con nombre único
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user!.uid)
            .collection('lista_productos')
            .doc(nombre)
            .set({'nombre': nombre}, SetOptions(merge: true));
      }

      // Confirmación en consola y feedback visual
      print('Productos añadidos a la despensa con ID: ${widget.despensaId}');
      print(_products);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Productos añadidos a la despensa exitosamente')),
      );
    } catch (e) {
      print('Error al agregar productos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir productos: $e')),
      );
    }
  }

  void _editarProducto(int index) {
    showDialog(
      context: context,
      builder: (context) {
        String nombre = _products[index]['product'];
        int cantidad = _products[index]['quantity'];
        return AlertDialog(
          title: Text('Editar producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: nombre),
                onChanged: (value) {
                  nombre = value;
                },
                decoration: InputDecoration(labelText: 'Nombre del producto'),
              ),
              TextField(
                controller: TextEditingController(text: cantidad.toString()),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  cantidad = int.tryParse(value) ?? 0;
                },
                decoration: InputDecoration(labelText: 'Cantidad'),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _products[index]['product'] = nombre;
                  _products[index]['quantity'] = cantidad;
                });
                Navigator.pop(context);
              },
              child: Text('Guardar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarProducto(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Dictar productos',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              _speechToText.isListening
                  ? "Escuchando..."
                  : _speechEnabled
                      ? "Presiona el botón para comenzar a hablar..."
                      : "Reconocimiento de voz no disponible",
              style: const TextStyle(fontSize: 20.0),
            ),
          ),
          Expanded(
            child: _products.isNotEmpty
                ? ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return ListTile(
                        title: Text(
                          "${product['quantity']} x ${product['product']}",
                          style: const TextStyle(fontSize: 22),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editarProducto(index),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _eliminarProducto(index),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const Text(
                    "No se ha reconocido ningún producto.",
                    style: TextStyle(fontSize: 22),
                  ),
          ),
          ElevatedButton(
            onPressed: _agregarProductosADespensa,
            child: const Text("Agregar productos a la despensa"),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed:
            _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: 'Escuchar',
        child: Icon(
          _speechToText.isNotListening ? Icons.mic : Icons.mic_off,
        ),
      ),
    );
  }
}
