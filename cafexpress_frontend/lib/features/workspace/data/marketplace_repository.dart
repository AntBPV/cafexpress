import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/marketplace_models.dart';

class MarketplaceRepository {
  MarketplaceRepository(this.api, this.session);
  final ApiClient api;
  final AuthSession session;
  String get _authorization => session.authorizationHeader;
  bool get isSeller => session.role == 'VENDEDOR';

  Future<T> _read<T>(String path, T Function(Json) parse) async {
    final json = await api.getJson(
      '/api/v1/$path',
      authorization: _authorization,
    );
    try {
      return parse(json);
    } on FormatException {
      throw const ApiException(
        'Los datos recibidos no son válidos. Inténtalo de nuevo.',
      );
    } on TypeError {
      throw const ApiException(
        'Los datos recibidos no son válidos. Inténtalo de nuevo.',
      );
    }
  }

  Future<Profile> profile() => _read('perfil', Profile.fromJson);
  Future<DashboardData> dashboard() =>
      _read('dashboard', DashboardData.fromJson);
  Future<AlertsData> alerts() =>
      _read('dashboard/alertas', AlertsData.fromJson);

  Future<Profile> saveSellerProfile({
    required String name,
    required String company,
    required String country,
  }) async {
    final json = await api.putJson(
      '/api/v1/vendedor/perfil',
      authorization: _authorization,
      body: {
        'nombre': name.trim(),
        'empresaProductor': company.trim(),
        'paisOrigen': country.trim(),
      },
    );
    try {
      return Profile.fromJson(json);
    } on FormatException {
      throw const ApiException(
        'No pudimos confirmar los datos guardados. Actualiza tu perfil.',
      );
    } on TypeError {
      throw const ApiException(
        'No pudimos confirmar los datos guardados. Actualiza tu perfil.',
      );
    }
  }

  Future<ProductPage> products({int page = 0}) => _read(
    '${isSeller ? "vendedor/" : ""}productos?page=$page&size=12',
    ProductPage.fromJson,
  );

  Future<Product> product(String id) async {
    final item = await _read(
      'productos/${Uri.encodeComponent(id)}',
      Product.fromJson,
    );
    if (!isSeller) {
      await api.postJson(
        '/api/v1/productos/${Uri.encodeComponent(id)}/consulta',
        body: const {},
        authorization: _authorization,
      );
    }
    return item;
  }

  Future<List<OrderSummary>> orders({int page = 0}) => _read(
    '${isSeller ? "vendedor" : "comprador"}/ordenes?page=$page&size=20',
    (json) => objects(json, 'content').map(OrderSummary.fromJson).toList(),
  );

  Future<OrderSummary> startOrder(String productId, num quantity) async {
    final json = await api.postJson(
      '/api/v1/comprador/ordenes',
      authorization: _authorization,
      body: {'productoId': productId, 'cantidad': quantity},
      errorMessages: const {
        409: 'La cantidad disponible cambió. Actualiza el producto.',
      },
    );
    try {
      return OrderSummary.fromJson(json);
    } on FormatException {
      throw const ApiException(
        'No pudimos confirmar la solicitud. Revisa tus órdenes antes de reintentar.',
      );
    } on TypeError {
      throw const ApiException(
        'No pudimos confirmar la solicitud. Revisa tus órdenes antes de reintentar.',
      );
    }
  }
}
