import 'marketplace_models.dart';

class ClimateRules {
  const ClimateRules({
    this.minimumTemperature = 18,
    this.maximumTemperature = 24,
    this.minimumRain = 2,
    this.maximumRain = 10,
  });
  final double minimumTemperature, maximumTemperature, minimumRain, maximumRain;
  bool falling(double temperature, double meanTemperature, double rain) =>
      temperature >= minimumTemperature &&
      temperature <= maximumTemperature &&
      meanTemperature >= minimumTemperature &&
      meanTemperature <= maximumTemperature &&
      rain >= minimumRain &&
      rain <= maximumRain;
}

class ClimateReading {
  const ClimateReading({
    required this.origin,
    required this.products,
    required this.temperature,
    required this.meanTemperature,
    required this.rain,
    required this.falling,
    required this.checkedAt,
  });
  final String origin;
  final List<Product> products;
  final double temperature, meanTemperature, rain;
  final bool falling;
  final DateTime checkedAt;
  String get title => falling ? 'Precios bajando' : 'Precios subiendo';
}

class ClimateSnapshot {
  const ClimateSnapshot({this.readings = const [], this.notices = const []});
  final List<ClimateReading> readings;
  final List<String> notices;
}
