import 'package:flutter_test/flutter_test.dart';
import 'package:sa_registro_ponto/models/user_model.dart';
import 'package:sa_registro_ponto/models/workplace_model.dart';
import 'package:sa_registro_ponto/models/punch_model.dart';
import 'package:sa_registro_ponto/services/location_service.dart';

void main() {
  test('Teste do modelo de Usuario e conversao para SQLite', () {
    final user = UserModel(
      id: 1,
      nif: '123456',
      name: 'Carlos Teste',
      email: 'carlos@empresa.com',
      password: 'senha123',
    );

    final map = user.toMap();
    expect(map['nif'], '123456');
    expect(map['name'], 'Carlos Teste');

    final userFromMap = UserModel.fromMap(map);
    expect(userFromMap.email, 'carlos@empresa.com');
  });

  test('Teste do modelo de Workplace e raio', () {
    final workplace = WorkplaceModel(
      id: 1,
      name: 'Sede Teste',
      latitude: -23.561414,
      longitude: -46.655881,
      radiusMeters: 100.0,
    );

    final map = workplace.toMap();
    expect(map['name'], 'Sede Teste');
    expect(map['radiusMeters'], 100.0);

    final fromMap = WorkplaceModel.fromMap(map);
    expect(fromMap.radiusMeters, 100.0);
  });

  test('Teste do calculo de raio de 100 metros', () {
    final locationService = LocationService.instance;

    // Mesma posicao: distancia zero, dentro do raio
    final isInside = locationService.isWithinAllowedRadius(
      currentLatitude: -23.561414,
      currentLongitude: -46.655881,
      workLatitude: -23.561414,
      workLongitude: -46.655881,
      maxRadiusMeters: 100.0,
    );
    expect(isInside, true);

    // Posicao distante (ex: Rio de Janeiro): fora do raio
    final isOutside = locationService.isWithinAllowedRadius(
      currentLatitude: -22.9068,
      currentLongitude: -43.1729,
      workLatitude: -23.561414,
      workLongitude: -46.655881,
      maxRadiusMeters: 100.0,
    );
    expect(isOutside, false);
  });

  test('Teste de criacao e serializacao do Registro de Ponto', () {
    final punch = PunchModel(
      userNif: '123456',
      userName: 'Carlos Teste',
      punchType: 'Entrada',
      timestamp: DateTime.now(),
      latitude: -23.561414,
      longitude: -46.655881,
      distanceMeters: 15.5,
      isValidLocation: true,
      authenticationType: 'Biometria',
    );

    final map = punch.toMap();
    expect(map['punchType'], 'Entrada');
    expect(map['isValidLocation'], 1);
    expect(map['authenticationType'], 'Biometria');

    final restored = PunchModel.fromMap(map);
    expect(restored.userNif, '123456');
    expect(restored.isValidLocation, true);
  });
}
