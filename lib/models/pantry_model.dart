class PantryModel {
  String id; // Esta es la ID del documento en Firestore
  String nombre;
  String categoria;
  String icono;

  PantryModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.icono,
  });

  // Para convertir de y hacia Firestore
  factory PantryModel.fromFirestore(String docId, Map<String, dynamic> data) {
    return PantryModel(
      id: docId, // ID del documento
      nombre: data['nombre'] ?? '',
      categoria: data['categoria'] ?? '',
      icono: data['icono'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'icono': icono,
    };
  }
}
