import 'dart:convert';

class Deuda {
  final int? id;
  final String persona;
  final double montoTotal;
  final double montoPagado;
  final int tipo; // 0: Debo, 1: Me deben
  final DateTime fecha;
  final DateTime? fechaLimite;
  final String notas;
  final int estatus; // 0: Pendiente, 1: Liquidada
  final int totalCuotas;

  Deuda({
    this.id,
    required this.persona,
    required this.montoTotal,
    this.montoPagado = 0.0,
    required this.tipo,
    required this.fecha,
    this.fechaLimite,
    this.notas = '',
    this.estatus = 0,
    this.totalCuotas = 1,
  });

  bool get isLiquidada => estatus == 1 || montoPagado >= montoTotal;
  bool get meDeben => tipo == 1;

  Deuda copyWith({
    int? id,
    String? persona,
    double? montoTotal,
    double? montoPagado,
    int? tipo,
    DateTime? fecha,
    DateTime? fechaLimite,
    String? notas,
    int? estatus,
    int? totalCuotas,
  }) {
    return Deuda(
      id: id ?? this.id,
      persona: persona ?? this.persona,
      montoTotal: montoTotal ?? this.montoTotal,
      montoPagado: montoPagado ?? this.montoPagado,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      notas: notas ?? this.notas,
      estatus: estatus ?? this.estatus,
      totalCuotas: totalCuotas ?? this.totalCuotas,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'persona': persona,
      'monto_total': montoTotal,
      'monto_pagado': montoPagado,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'fecha_limite': fechaLimite?.toIso8601String(),
      'notas': notas,
      'estatus': estatus,
      'total_cuotas': totalCuotas,
    };
  }

  factory Deuda.fromMap(Map<String, dynamic> map) {
    return Deuda(
      id: map['id'],
      persona: map['persona'] ?? '',
      montoTotal: map['monto_total']?.toDouble() ?? 0.0,
      montoPagado: map['monto_pagado']?.toDouble() ?? 0.0,
      tipo: map['tipo'] ?? 0,
      fecha: DateTime.parse(map['fecha']),
      fechaLimite: map['fecha_limite'] != null ? DateTime.parse(map['fecha_limite']) : null,
      notas: map['notas'] ?? '',
      estatus: map['estatus'] ?? 0,
      totalCuotas: map['total_cuotas'] ?? 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory Deuda.fromJson(String source) => Deuda.fromMap(json.decode(source));
}
