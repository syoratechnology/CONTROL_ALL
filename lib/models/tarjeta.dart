class Tarjeta {
  final int? id;
  final String nombre;
  final String tipo; // "Crédito" o "Débito"
  final int? diaCorte;
  final int? diaLimite;

  Tarjeta({
    this.id,
    required this.nombre,
    required this.tipo,
    this.diaCorte,
    this.diaLimite,
  });

  Tarjeta copyWith({
    int? id,
    String? nombre,
    String? tipo,
    int? diaCorte,
    int? diaLimite,
  }) {
    return Tarjeta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      diaCorte: diaCorte ?? this.diaCorte,
      diaLimite: diaLimite ?? this.diaLimite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'dia_corte': diaCorte,
      'dia_limite': diaLimite,
    };
  }

  factory Tarjeta.fromMap(Map<String, dynamic> map) {
    return Tarjeta(
      id: map['id']?.toInt(),
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] ?? '',
      diaCorte: map['dia_corte']?.toInt(),
      diaLimite: map['dia_limite']?.toInt(),
    );
  }
}
