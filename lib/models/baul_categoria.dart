class BaulCategoria {
  final int? id;
  final String nombre;
  final int color;
  final String icono;

  BaulCategoria({
    this.id,
    required this.nombre,
    required this.color,
    required this.icono,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'color': color,
      'icono': icono,
    };
  }

  factory BaulCategoria.fromMap(Map<String, dynamic> map) {
    return BaulCategoria(
      id: map['id'],
      nombre: map['nombre'],
      color: map['color'],
      icono: map['icono'],
    );
  }
}
