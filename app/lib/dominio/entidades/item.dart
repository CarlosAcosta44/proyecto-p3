class Item {
  final String id;
  final String codigoBarras;
  final String nombre;
  final int cantidad;
  final String estado;
  final int version;
  final int sucio;
  final String? fotoRuta;
  final String? modificadoEn;

  Item({
    required this.id,
    required this.codigoBarras,
    required this.nombre,
    required this.cantidad,
    required this.estado,
    required this.version,
    this.sucio = 0,
    this.fotoRuta,
    this.modificadoEn,
  });

  factory Item.desdeMapa(Map<String, dynamic> mapa) {
    return Item(
      id: mapa['id'] as String,
      codigoBarras: mapa['codigo_barras'] as String,
      nombre: mapa['nombre'] as String,
      cantidad: mapa['cantidad'] as int,
      estado: mapa['estado'] as String,
      version: mapa['version'] as int,
      sucio: mapa['sucio'] as int,
      fotoRuta: mapa['foto_ruta'] as String?,
      modificadoEn: mapa['modificado_en'] as String?,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'codigo_barras': codigoBarras,
      'nombre': nombre,
      'cantidad': cantidad,
      'estado': estado,
      'version': version,
      'sucio': sucio,
      'foto_ruta': fotoRuta,
      'modificado_en': modificadoEn,
    };
  }

  Item copiarCon({
    String? id,
    String? codigoBarras,
    String? nombre,
    int? cantidad,
    String? estado,
    int? version,
    int? sucio,
    String? fotoRuta,
    String? modificadoEn,
  }) {
    return Item(
      id: id ?? this.id,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      estado: estado ?? this.estado,
      version: version ?? this.version,
      sucio: sucio ?? this.sucio,
      fotoRuta: fotoRuta ?? this.fotoRuta,
      modificadoEn: modificadoEn ?? this.modificadoEn,
    );
  }
}
