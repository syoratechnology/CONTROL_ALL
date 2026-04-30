/// Representa un pago o movimiento de dinero dentro de un Proyecto.
/// El usuario puede registrar el monto, la fecha, el método de pago y notas libres.
class Pago {
  final int? id;
  final int proyectoId;       // A qué proyecto pertenece este pago
  final double monto;
  final DateTime fecha;
  final String metodoPago;    // Ej: "Efectivo", "Tarjeta BBVA", "Débito HSBC"
  final String notas;         // Texto libre para el usuario
  final DateTime creadoEn;

  const Pago({
    this.id,
    required this.proyectoId,
    required this.monto,
    required this.fecha,
    required this.metodoPago,
    this.notas = '',
    required this.creadoEn,
  });

  // ─── Serialización para SQLite ────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'proyecto_id': proyectoId,
      'monto':       monto,
      'fecha':       fecha.toIso8601String(),
      'metodo_pago': metodoPago,
      'notas':       notas,
      'creado_en':   creadoEn.toIso8601String(),
    };
  }

  factory Pago.fromMap(Map<String, dynamic> map) {
    return Pago(
      id:          map['id'] as int,
      proyectoId:  map['proyecto_id'] as int,
      monto:       (map['monto'] as num).toDouble(),
      fecha:       DateTime.parse(map['fecha'] as String),
      metodoPago:  map['metodo_pago'] as String,
      notas:       map['notas'] as String? ?? '',
      creadoEn:    DateTime.parse(map['creado_en'] as String),
    );
  }

  Pago copyWith({
    int? id,
    int? proyectoId,
    double? monto,
    DateTime? fecha,
    String? metodoPago,
    String? notas,
    DateTime? creadoEn,
  }) {
    return Pago(
      id:          id ?? this.id,
      proyectoId:  proyectoId ?? this.proyectoId,
      monto:       monto ?? this.monto,
      fecha:       fecha ?? this.fecha,
      metodoPago:  metodoPago ?? this.metodoPago,
      notas:       notas ?? this.notas,
      creadoEn:    creadoEn ?? this.creadoEn,
    );
  }

  @override
  String toString() =>
      'Pago(id: $id, proyectoId: $proyectoId, monto: $monto, fecha: $fecha)';
}
