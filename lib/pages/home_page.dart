import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    // Dividimos las palabras en una lista
    List<String> wordList = words.split(' ');

    List<Map<String, dynamic>> filteredProducts = [];
    String currentProduct = '';
    int? currentQuantity;

    // Recorremos todas las palabras una por una
    for (int i = 0; i < wordList.length; i++) {
      String word = wordList[i];

      // Primero intentamos convertir la palabra a un número directamente
      int? quantity = _tryParseNumber(word);

      if (quantity != null) {
        // Si encontramos un número y ya tenemos un producto actual, lo guardamos
        if (currentProduct.isNotEmpty) {
          filteredProducts.add(
              {'quantity': currentQuantity, 'product': currentProduct.trim()});
        }

        // Guardamos la nueva cantidad y reiniciamos el producto
        currentQuantity = quantity;
        currentProduct = '';
      } else {
        // Si no es un número, asumimos que es parte del nombre del producto
        currentProduct += word + ' ';
      }
    }

    // Guardamos el último producto si quedó alguno sin agregar
    if (currentProduct.isNotEmpty && currentQuantity != null) {
      filteredProducts
          .add({'quantity': currentQuantity, 'product': currentProduct.trim()});
    }

    // Actualizamos la lista de productos filtrados
    setState(() {
      _products = filteredProducts;
    });
  }

// Método que intenta interpretar un número como string o como palabra
  int? _tryParseNumber(String word) {
    // Primero intentamos convertir el string directamente a número
    try {
      return int.parse(word); // Si es "23", "15", etc.
    } catch (e) {
      // Si no es un número directo, intentamos mapear la palabra
      return palabrasANumeroExtendido(word);
    }
  }

  int? palabrasANumeroExtendido(String palabra) {
    // Mapeo de unidades y decenas
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
      'nueve': 9,
    };

    Map<String, int> decenas = {
      'diez': 10,
      'veinte': 20,
      'treinta': 30,
      'cuarenta': 40,
      'cincuenta': 50,
      'sesenta': 60,
      'setenta': 70,
      'ochenta': 80,
      'noventa': 90,
    };

    Map<String, int> excepciones = {
      'once': 11,
      'doce': 12,
      'trece': 13,
      'catorce': 14,
      'quince': 15,
      'dieciséis': 16,
      'diecisiete': 17,
      'dieciocho': 18,
      'diecinueve': 19,
    };

    // División del input en palabras
    List<String> palabras = palabra.split(' ');

    int total = 0;
    bool foundDecena = false;

    for (var palabra in palabras) {
      if (unidades.containsKey(palabra)) {
        total += unidades[palabra]!;
      } else if (decenas.containsKey(palabra)) {
        total += decenas[palabra]!;
        foundDecena = true;
      } else if (excepciones.containsKey(palabra)) {
        return excepciones[palabra];
      } else {
        return null; // Si no reconoce la palabra, devuelve null
      }
    }

    // Si encuentra una decena (20, 30, etc.), devolvemos el número.
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          'Demo de voz',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                _speechToText.isListening
                    ? "Escuchando..."
                    : _speechEnabled
                        ? "Presiona el botón para comenzar a hablar..."
                        : "Reconocimiento de voz no disponible",
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: _products.isNotEmpty
                    ? ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ListTile(
                            title: Text(
                              "${product['quantity']} x ${product['product']}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      )
                    : Text(
                        "No se ha reconocido ningún producto.",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
              ),
            ),
            // Mostrar el texto completo reconocido abajo de la lista de productos
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Texto completo: $_wordsSpoken",
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_speechToText.isNotListening && _confidenceLevel > 0)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 100,
                ),
                child: Text(
                  "Confianza: ${(_confidenceLevel * 100).toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechToText.isListening ? _stopListening : _startListening,
        tooltip: 'Escuchar',
        child: Icon(
          _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}
