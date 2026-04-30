/// Representa una categoría o "bolsillo" de gastos.
/// Ejemplos: "Coche", "Casa", "Tarjeta BBVA", "Vacaciones"
class Proyecto {
  final int? id;
  final String nombre;
  final String descripcion;
  final int colorHex;       // Color.value (int) — se convierte a Color en UI
  final String icono;       // Nombre del icono de Material Icons como String
  final int estatus;        // 1 = Activo, 0 = Finalizado
  final DateTime creadoEn;

  const Proyecto({
    this.id,
    required this.nombre,
    this.descripcion = '',
    required this.colorHex,
    required this.icono,
    this.estatus = 1, // Por defecto Activo
    required this.creadoEn,
  });

  bool get isActivo => estatus == 1;

  // ─── Serialización para SQLite ────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre':      nombre,
      'descripcion': descripcion,
      'color_hex':   colorHex,
      'icono':       icono,
      'estatus':     estatus,
      'creado_en':   creadoEn.toIso8601String(),
    };
  }

  factory Proyecto.fromMap(Map<String, dynamic> map) {
    return Proyecto(
      id:          map['id'] as int,
      nombre:      map['nombre'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      colorHex:    map['color_hex'] as int,
      icono:       map['icono'] as String,
      estatus:     map['estatus'] as int? ?? 1,
      creadoEn:    DateTime.parse(map['creado_en'] as String),
    );
  }

  Proyecto copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    int? colorHex,
    String? icono,
    int? estatus,
    DateTime? creadoEn,
  }) {
    return Proyecto(
      id:          id ?? this.id,
      nombre:      nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      colorHex:    colorHex ?? this.colorHex,
      icono:       icono ?? this.icono,
      estatus:     estatus ?? this.estatus,
      creadoEn:    creadoEn ?? this.creadoEn,
    );
  }

  @override
  String toString() => 'Proyecto(id: $id, nombre: $nombre)';
}
