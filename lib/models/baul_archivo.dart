class BaulArchivo {
  final int? id;
  final int itemId;
  final String nombre;
  final String rutaLocal;
  final String extension;
  final int tamano;

  BaulArchivo({
    this.id,
    required this.itemId,
    required this.nombre,
    required this.rutaLocal,
    required this.extension,
    required this.tamano,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'nombre': nombre,
      'ruta_local': rutaLocal,
      'extension': extension,
      'tamano': tamano,
    };
  }

  factory BaulArchivo.fromMap(Map<String, dynamic> map) {
    return BaulArchivo(
      id: map['id'],
      itemId: map['item_id'],
      nombre: map['nombre'],
      rutaLocal: map['ruta_local'],
      extension: map['extension'],
      tamano: map['tamano'],
    );
  }
}
