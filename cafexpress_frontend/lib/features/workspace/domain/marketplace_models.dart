import 'package:intl/intl.dart';

typedef Json = Map<String, dynamic>;

Json object(Object? value) {
  if (value is! Json) throw const FormatException('Se esperaba un objeto.');
  return value;
}

String string(Json data, String key) {
  final value = data[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Falta $key.');
  }
  return value;
}

List<Json> objects(Json data, String key) {
  final value = data[key];
  if (value is! List) throw FormatException('Falta $key.');
  return value.map(object).toList();
}

String number(num value) => NumberFormat.decimalPattern('es_CO').format(value);
String date(DateTime value) =>
    DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
String statusLabel(String value) => switch (value) {
  'SOLICITADA' => 'Solicitada',
  'ACEPTADA' => 'Aceptada',
  'RECHAZADA' => 'Rechazada',
  'CONFIRMADA' => 'Confirmada',
  'EN_PREPARACION' => 'En preparación',
  'EN_TRÁNSITO' || 'EN_TRANSITO' => 'En tránsito',
  'ENVIADA' => 'Enviada',
  'ENTREGADA' => 'Entregada',
  _ => value.toLowerCase().replaceAll('_', ' '),
};

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.company,
    this.country,
    this.username,
  });
  factory Profile.fromJson(Json json) {
    final role = string(json, 'rol');
    if (!['VENDEDOR', 'COMPRADOR'].contains(role)) {
      throw const FormatException('Rol no válido.');
    }
    return Profile(
      id: string(json, 'id'),
      name: string(json, 'nombre'),
      email: string(json, 'email'),
      role: role,
      company: json['empresaProductor'] as String?,
      country: json['paisOrigen'] as String?,
      username: json['username'] as String?,
    );
  }
  final String id, name, email, role;
  final String? company, country, username;
  bool get isSeller => role == 'VENDEDOR';
  bool get isComplete =>
      (company?.trim().isNotEmpty ?? false) &&
      (country?.trim().isNotEmpty ?? false);
  String get roleLabel => isSeller ? 'Vendedor' : 'Comprador';
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unitAmount,
    required this.unit,
    required this.availableAmount,
    required this.origin,
    required this.price,
    required this.available,
    required this.seller,
    this.type = 'CAFE',
    this.variety,
  });
  factory Product.fromJson(Json json) => Product(
    id: string(json, 'id'),
    name: string(json, 'nombre'),
    type: json['tipo'] as String? ?? 'CAFE',
    variety: json['variedad'] as String?,
    unitAmount: json['cantidadUnitaria'] as num,
    unit: string(json, 'unidadCantidad'),
    availableAmount: json['cantidadDisponible'] as num,
    origin: string(json, 'lugarOrigen'),
    price: json['precioUnitario'] as num,
    available: json['disponible'] as bool,
    seller: Profile.fromJson(object(json['vendedor'])),
  );
  final String id, name, unit, origin;
  final num unitAmount, availableAmount, price;
  final bool available;
  final Profile seller;
  final String type;
  final String? variety;
  String get typeLabel => switch (type) {
    'CAFE' => 'Café',
    'CACAO' => 'Cacao',
    _ => 'Variedad',
  };
  String get unitLabel => unit == 'KILOGRAMOS' ? 'kg' : 'g';
  bool get canOrder => available && availableAmount > 0;
}

class ProductPage {
  ProductPage.fromJson(Json json)
    : items = objects(json, 'content').map(Product.fromJson).toList(),
      page = (json['page'] as num).toInt(),
      totalPages = (json['totalPages'] as num).toInt(),
      total = (json['totalElements'] as num).toInt();
  final List<Product> items;
  final int page, totalPages, total;
}

class OrderSummary {
  OrderSummary.fromJson(Json json)
    : id = string(json, 'id'),
      productId = string(json, 'productoId'),
      productName = string(json, 'productoNombre'),
      state = string(json, 'estado'),
      quantity = json['cantidad'] as num,
      unitPrice = json['precioUnitario'] as num?,
      total = json['precioTotal'] as num?,
      buyer = json['comprador'] == null
          ? null
          : Profile.fromJson(object(json['comprador'])),
      seller = json['vendedor'] == null
          ? null
          : Profile.fromJson(object(json['vendedor'])),
      created = DateTime.parse(string(json, 'creadoEn')),
      events = [
        ('Solicitada', DateTime.parse(string(json, 'creadoEn'))),
        for (final entry in const {
          'aceptadaEn': 'Aceptada',
          'enPreparacionEn': 'En preparación',
          'enviadaEn': 'Enviada',
          'entregadaEn': 'Entregada',
          'rechazadaEn': 'Rechazada',
        }.entries)
          if (json[entry.key] != null)
            (entry.value, DateTime.parse(json[entry.key] as String)),
      ];
  final String id, productId, productName, state;
  final num quantity;
  final num? unitPrice, total;
  final Profile? buyer, seller;
  final DateTime created;
  final List<(String, DateTime)> events;
  String? get nextAction => switch (state) {
    'SOLICITADA' => 'aceptar',
    'ACEPTADA' => 'preparar',
    'EN_PREPARACION' => 'enviar',
    'ENVIADA' => 'entregar',
    _ => null,
  };
  String? get nextActionLabel => switch (state) {
    'SOLICITADA' => 'Aceptar solicitud',
    'ACEPTADA' => 'Iniciar preparación',
    'EN_PREPARACION' => 'Marcar como enviada',
    'ENVIADA' => 'Confirmar entrega',
    _ => null,
  };
}

class OrderPage {
  OrderPage.fromJson(Json json)
    : items = objects(json, 'content').map(OrderSummary.fromJson).toList(),
      totalPages = (json['totalPages'] as num).toInt(),
      total = (json['totalElements'] as num).toInt();
  final List<OrderSummary> items;
  final int totalPages, total;
}

class DashboardData {
  DashboardData.fromJson(Json json)
    : profile = Profile.fromJson(object(json['usuario'])),
      activeProducts = (json['productosActivos'] as num).toInt(),
      activeOrders = (json['ordenesActivas'] as num).toInt(),
      byState = object(json['ordenesPorEstado'])
          .map((key, value) => MapEntry(key, (value as num).toInt())),
      orders = objects(
        json,
        'ordenesRecientes',
      ).map(OrderSummary.fromJson).toList(),
      updated = DateTime.parse(string(json, 'actualizadoEn'));
  final Profile profile;
  final int activeProducts, activeOrders;
  final Map<String, int> byState;
  final List<OrderSummary> orders;
  final DateTime updated;
}

class ClimateAlert {
  ClimateAlert.fromJson(Json json)
    : productId = string(json, 'productoId'),
      productName = string(json, 'productoNombre'),
      origin = string(json, 'origen'),
      message = string(json, 'mensaje'),
      favourable = json['condicionesOptimas'] as bool,
      temperature = json['temperaturaActual'] as num,
      observed = DateTime.parse(string(json, 'consultadoEn'));
  final String productId, productName, origin, message;
  final bool favourable;
  final num temperature;
  final DateTime observed;
}

class AlertsData {
  AlertsData.fromJson(Json json)
    : alerts = objects(json, 'alertas').map(ClimateAlert.fromJson).toList(),
      notices = (json['avisos'] as List).cast<String>();
  final List<ClimateAlert> alerts;
  final List<String> notices;
}
