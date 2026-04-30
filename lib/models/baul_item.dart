class BaulItem {
  final int? id;
  final String titulo;
  final String tipo; // 'nota', 'password', 'cuenta'
  final DateTime fechaCreacion;

  BaulItem({
    this.id,
    required this.titulo,
    required this.tipo,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'tipo': tipo,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory BaulItem.fromMap(Map<String, dynamic> map) {
    return BaulItem(
      id: map['id'],
      titulo: map['titulo'],
      tipo: map['tipo'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }

  BaulItem copyWith({
    int? id,
    String? titulo,
    String? tipo,
    DateTime? fechaCreacion,
  }) {
    return BaulItem(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

class BaulCampo {
  final int? id;
  final int itemId;
  final String etiqueta;
  final String valor;
  final bool esSecreto;

  BaulCampo({
    this.id,
    required this.itemId,
    required this.etiqueta,
    required this.valor,
    required this.esSecreto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'etiqueta': etiqueta,
      'valor': valor,
      'es_secreto': esSecreto ? 1 : 0,
    };
  }

  factory BaulCampo.fromMap(Map<String, dynamic> map) {
    return BaulCampo(
      id: map['id'],
      itemId: map['item_id'],
      etiqueta: map['etiqueta'],
      valor: map['valor'],
      esSecreto: map['es_secreto'] == 1,
    );
  }

  BaulCampo copyWith({
    int? id,
    int? itemId,
    String? etiqueta,
    String? valor,
    bool? esSecreto,
  }) {
    return BaulCampo(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      etiqueta: etiqueta ?? this.etiqueta,
      valor: valor ?? this.valor,
      esSecreto: esSecreto ?? this.esSecreto,
    );
  }
}
