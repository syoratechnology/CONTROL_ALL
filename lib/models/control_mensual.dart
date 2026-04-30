class ControlMensual {
  final int? id;
  final int mes; // 1-12
  final int anio; // 2026
  final String notas;
  final DateTime creadoEn;

  ControlMensual({
    this.id,
    required this.mes,
    required this.anio,
    this.notas = '',
    required this.creadoEn,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mes': mes,
      'anio': anio,
      'notas': notas,
      'creadoEn': creadoEn.toIso8601String(),
    };
  }

  factory ControlMensual.fromMap(Map<String, dynamic> map) {
    return ControlMensual(
      id: map['id'],
      mes: map['mes'],
      anio: map['anio'],
      notas: map['notas'] ?? '',
      creadoEn: DateTime.parse(map['creadoEn']),
    );
  }
  ControlMensual copyWith({
    int? id,
    int? mes,
    int? anio,
    String? notas,
    DateTime? creadoEn,
  }) {
    return ControlMensual(
      id: id ?? this.id,
      mes: mes ?? this.mes,
      anio: anio ?? this.anio,
      notas: notas ?? this.notas,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
