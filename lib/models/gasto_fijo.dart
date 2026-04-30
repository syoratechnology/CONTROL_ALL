class GastoFijo {
  final int? id;
  final String nombre;
  final double monto;
  final int diaCobro; // 1-31
  final String metodoPago; // Efectivo, Tarjeta, etc.
  final String icono; // Icono representativo
  final int activo; // 1 = si, 0 = no (para pausar suscripciones)

  GastoFijo({
    this.id,
    required this.nombre,
    required this.monto,
    required this.diaCobro,
    required this.metodoPago,
    required this.icono,
    this.activo = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto': monto,
      'diaCobro': diaCobro,
      'metodoPago': metodoPago,
      'icono': icono,
      'activo': activo,
    };
  }

  factory GastoFijo.fromMap(Map<String, dynamic> map) {
    return GastoFijo(
      id: map['id'],
      nombre: map['nombre'],
      monto: map['monto'],
      diaCobro: map['diaCobro'],
      metodoPago: map['metodoPago'],
      icono: map['icono'],
      activo: map['activo'] ?? 1,
    );
  }

  GastoFijo copyWith({
    int? id,
    String? nombre,
    double? monto,
    int? diaCobro,
    String? metodoPago,
    String? icono,
    int? activo,
  }) {
    return GastoFijo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      diaCobro: diaCobro ?? this.diaCobro,
      metodoPago: metodoPago ?? this.metodoPago,
      icono: icono ?? this.icono,
      activo: activo ?? this.activo,
    );
  }
}
