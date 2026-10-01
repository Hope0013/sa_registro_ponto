class WorkplaceModel {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  WorkplaceModel({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
  });

  // Converte a empresa/posto de trabalho para o formato do banco SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    };
  }

  // Cria a empresa a partir do mapa do banco de dados
  factory WorkplaceModel.fromMap(Map<String, dynamic> map) {
    return WorkplaceModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 100.0,
    );
  }
}
