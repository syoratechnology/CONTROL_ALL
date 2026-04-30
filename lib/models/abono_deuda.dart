import 'dart:convert';

class AbonoDeuda {
  final int? id;
  final int deudaId;
  final double monto;
  final DateTime fecha;
  final String nota;

  AbonoDeuda({
    this.id,
    required this.deudaId,
    required this.monto,
    required this.fecha,
    this.nota = '',
  });

  AbonoDeuda copyWith({
    int? id,
    int? deudaId,
    double? monto,
    DateTime? fecha,
    String? nota,
  }) {
    return AbonoDeuda(
      id: id ?? this.id,
      deudaId: deudaId ?? this.deudaId,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deuda_id': deudaId,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'nota': nota,
    };
  }

  factory AbonoDeuda.fromMap(Map<String, dynamic> map) {
    return AbonoDeuda(
      id: map['id'],
      deudaId: map['deuda_id'] ?? 0,
      monto: map['monto']?.toDouble() ?? 0.0,
      fecha: DateTime.parse(map['fecha']),
      nota: map['nota'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AbonoDeuda.fromJson(String source) => AbonoDeuda.fromMap(json.decode(source));
}
