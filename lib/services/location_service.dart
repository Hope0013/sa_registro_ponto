import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  // Verifica se o GPS esta ativado e se as permissoes foram concedidas
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Testa se o servico de localizacao do dispositivo esta ligado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('O serviço de GPS está desativado. Ative a localização nas configurações do aparelho.');
    }

    // Verifica a permissao de localizacao
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada pelo usuário.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('A permissão de localização foi negada permanentemente. Habilite nas configurações do app.');
    }

    // Obtem a coordenada atual com alta precisao
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // Calcula a distancia em metros entre o ponto atual do funcionario e a empresa
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Verifica se a distancia do funcionario esta dentro do limite maximo (padrao 100 metros)
  bool isWithinAllowedRadius({
    required double currentLatitude,
    required double currentLongitude,
    required double workLatitude,
    required double workLongitude,
    double maxRadiusMeters = 100.0,
  }) {
    final distance = calculateDistance(
      startLatitude: currentLatitude,
      startLongitude: currentLongitude,
      endLatitude: workLatitude,
      endLongitude: workLongitude,
    );

    return distance <= maxRadiusMeters;
  }
}
