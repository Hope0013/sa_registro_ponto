class PunchModel {
  final int? id;
  final String userNif;
  final String userName;
  final String punchType; // Ex: "Entrada", "Intervalo", "Retorno", "Saída"
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final bool isValidLocation;
  final String authenticationType; // "Senha" ou "Biometria"

  PunchModel({
    this.id,
    required this.userNif,
    required this.userName,
    required this.punchType,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.isValidLocation,
    required this.authenticationType,
  });

  // Converte o registro de ponto para insercao na tabela SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userNif': userNif,
      'userName': userName,
      'punchType': punchType,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'distanceMeters': distanceMeters,
      'isValidLocation': isValidLocation ? 1 : 0,
      'authenticationType': authenticationType,
    };
  }

  // Converte a linha retornada do SQLite de volta para o modelo Dart
  factory PunchModel.fromMap(Map<String, dynamic> map) {
    return PunchModel(
      id: map['id'] as int?,
      userNif: map['userNif'] as String,
      userName: map['userName'] as String,
      punchType: map['punchType'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      isValidLocation: (map['isValidLocation'] as int) == 1,
      authenticationType: map['authenticationType'] as String,
    );
  }
}
