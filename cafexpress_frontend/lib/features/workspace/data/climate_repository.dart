import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_exception.dart';
import '../domain/climate_trend.dart';
import '../domain/marketplace_models.dart';
import 'marketplace_repository.dart';

class ClimateRepository {
  ClimateRepository(
    this.marketplace, {
    http.Client? client,
    this.rules = const ClimateRules(),
  }) : _client = client ?? http.Client();
  final MarketplaceRepository marketplace;
  final http.Client _client;
  final ClimateRules rules;
  bool _closed = false;
  final Map<String, (double, double)> _locations = {};

  static String _normalize(String value) {
    const accented = 'áéíóúüñ';
    const plain = 'aeiouun';
    var result = value.trim().toLowerCase();
    for (var i = 0; i < accented.length; i++) {
      result = result.replaceAll(accented[i], plain[i]);
    }
    return result;
  }

  Future<Json> _get(Uri uri) async {
    if (_closed) throw const ApiException('Consulta cancelada.');
    try {
      // This client is separate from the authenticated backend client.
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ApiException('El servicio de clima no está disponible.');
      }
      return object(jsonDecode(utf8.decode(response.bodyBytes)));
    } on TimeoutException {
      throw const ApiException('La consulta del clima tardó demasiado.');
    } on http.ClientException {
      throw const ApiException('No pudimos conectar con el servicio de clima.');
    } on FormatException {
      throw const ApiException(
        'El servicio de clima devolvió datos incompletos.',
      );
    }
  }

  Future<(double, double)> _location(Product product, String origin) async {
    if (_locations[origin] case final cached?) return cached;
    final data = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': origin,
        'count': '10',
        'language': 'es',
      }),
    );
    final city = _normalize(product.origin.split(',').first);
    final country = _normalize(product.seller.country ?? '');
    var matches =
        objects({...data, 'results': data['results'] ?? []}, 'results')
            .where(
              (place) => _normalize(place['name'] as String? ?? '') == city,
            )
            .where(
              (place) =>
                  country.isEmpty ||
                  _normalize(place['country'] as String? ?? '') == country ||
                  _normalize(place['country_code'] as String? ?? '') == country,
            )
            .toList();
    final parts = product.origin.split(',');
    if (matches.length > 1 && parts.length > 1) {
      final region = _normalize(parts[1]);
      matches = matches
          .where(
            (place) => _normalize(place['admin1'] as String? ?? '') == region,
          )
          .toList();
    }
    if (matches.length != 1) {
      throw const ApiException(
        'Indica un origen con ciudad, departamento y país.',
      );
    }
    final latitude = _number(matches.single['latitude']);
    final longitude = _number(matches.single['longitude']);
    if (latitude.abs() > 90 || longitude.abs() > 180) {
      throw const FormatException('Coordenadas inválidas.');
    }
    final result = (latitude, longitude);
    _locations[origin] = result;
    return result;
  }

  static double _number(Object? value) {
    if (value is! num || !value.isFinite) {
      throw const FormatException('Dato climático inválido.');
    }
    return value.toDouble();
  }

  Future<ClimateReading> _reading(String origin, List<Product> products) async {
    final (latitude, longitude) = await _location(products.first, origin);
    final data = await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m',
        'daily': 'temperature_2m_max,temperature_2m_min,rain_sum',
        'forecast_days': '1',
        'timezone': 'auto',
      }),
    );
    final current = object(data['current']);
    final daily = object(data['daily']);
    double first(String key) {
      final values = daily[key];
      if (values is! List || values.isEmpty) {
        throw const FormatException('Pronóstico incompleto.');
      }
      return _number(values.first);
    }

    final temperature = _number(current['temperature_2m']);
    final mean =
        (first('temperature_2m_max') + first('temperature_2m_min')) / 2;
    final rain = first('rain_sum');
    if (rain < 0) throw const FormatException('Lluvia inválida.');
    return ClimateReading(
      origin: origin,
      products: products,
      temperature: temperature,
      meanTemperature: mean,
      rain: rain,
      falling: rules.falling(temperature, mean, rain),
      checkedAt: DateTime.now(),
    );
  }

  Future<ClimateSnapshot> fetch() async {
    final products = await marketplace.climateProducts();
    final groups = <String, List<Product>>{};
    for (final product in products) {
      final country = product.seller.country?.trim();
      final origin =
          country == null ||
              country.isEmpty ||
              _normalize(product.origin).contains(_normalize(country))
          ? product.origin
          : '${product.origin}, $country';
      groups.putIfAbsent(origin, () => []).add(product);
    }
    final entries = groups.entries.toList();
    final readings = <String, ClimateReading>{};
    final notices = <String, String>{};
    var next = 0;
    Future<void> worker() async {
      while (!_closed && next < entries.length) {
        final entry = entries[next++];
        try {
          readings[entry.key] = await _reading(entry.key, entry.value);
        } on ApiException catch (error) {
          notices[entry.key] = '${entry.key}: ${error.message}';
        } catch (_) {
          notices[entry.key] =
              '${entry.key}: no pudimos interpretar el clima. Reintenta.';
        }
      }
    }

    await Future.wait(
      List.generate(entries.length.clamp(0, 4), (_) => worker()),
    );
    return ClimateSnapshot(
      readings: [for (final entry in entries) ?readings[entry.key]],
      notices: [for (final entry in entries) ?notices[entry.key]],
    );
  }

  void close() {
    _closed = true;
    _client.close();
  }
}
