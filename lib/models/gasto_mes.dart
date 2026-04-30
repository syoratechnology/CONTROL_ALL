class GastoMes {
  final int? id;
  final int controlId; // Vinculado a ControlMensual
  final String nombre;
  final double monto;
  final DateTime fecha; // Fecha real en que se hizo o toca el cobro
  final String metodoPago;
  final String icono;
  final String notas;
  final int esFijo; // 1 = inyectado de suscripción, 0 = gasto extra
  final int pagado; // 1 = ya se pagó, 0 = pendiente (útil para fijos)

  GastoMes({
    this.id,
    required this.controlId,
    required this.nombre,
    required this.monto,
    required this.fecha,
    required this.metodoPago,
    required this.icono,
    this.notas = '',
    required this.esFijo,
    this.pagado = 1, // Por defecto al crear un gasto extra, se asume pagado
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'controlId': controlId,
      'nombre': nombre,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'metodoPago': metodoPago,
      'icono': icono,
      'notas': notas,
      'esFijo': esFijo,
      'pagado': pagado,
    };
  }

  factory GastoMes.fromMap(Map<String, dynamic> map) {
    return GastoMes(
      id: map['id'],
      controlId: map['controlId'],
      nombre: map['nombre'],
      monto: map['monto'],
      fecha: DateTime.parse(map['fecha']),
      metodoPago: map['metodoPago'],
      icono: map['icono'] ?? 'folder',
      notas: map['notas'] ?? '',
      esFijo: map['esFijo'] ?? 0,
      pagado: map['pagado'] ?? 1,
    );
  }

  GastoMes copyWith({
    int? id,
    int? controlId,
    String? nombre,
    double? monto,
    DateTime? fecha,
    String? metodoPago,
    String? icono,
    String? notas,
    int? esFijo,
    int? pagado,
  }) {
    return GastoMes(
      id: id ?? this.id,
      controlId: controlId ?? this.controlId,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      metodoPago: metodoPago ?? this.metodoPago,
      icono: icono ?? this.icono,
      notas: notas ?? this.notas,
      esFijo: esFijo ?? this.esFijo,
      pagado: pagado ?? this.pagado,
    );
  }
}
