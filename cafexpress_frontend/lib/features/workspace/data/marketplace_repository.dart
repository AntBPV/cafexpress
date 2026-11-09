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

  Future<List<Product>> climateProducts() => _read(
    'dashboard/productos-relevantes',
    (json) => objects(json, 'productos').map(Product.fromJson).toList(),
  );

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

  bool ownsProduct(Product product) =>
      isSeller && product.seller.id == session.userId;

  Future<ProductPage> products({
    int page = 0,
    String? type,
    String? origin,
    String? country,
    num? minimumPrice,
    num? maximumPrice,
    String? sort, // <--- PARÁMETRO AGREGADO
  }) {
    final query = Uri(
      queryParameters: <String, String>{
        'page': '$page',
        'size': '12',
        'tipo': ?type,
        if (origin?.trim().isNotEmpty == true) 'lugarOrigen': origin!.trim(),
        if (country?.trim().isNotEmpty == true) 'paisOrigen': country!.trim(),
        if (minimumPrice != null) 'precioMin': '$minimumPrice',
        if (maximumPrice != null) 'precioMax': '$maximumPrice',
        if (sort != null) 'sort': sort, // <--- AGREGADO A LA URL
      },
    ).query;
    return _read(
      '${isSeller ? "vendedor/" : ""}productos?$query',
      ProductPage.fromJson,
    );
  }

  Future<Product> saveProduct(Map<String, dynamic> body, {String? id}) async {
    final path =
        '/api/v1/vendedor/productos${id == null ? "" : "/${Uri.encodeComponent(id)}"}';
    final json = id == null
        ? await api.postJson(
            path,
            authorization: _authorization,
            body: body,
            errorMessages: const {
              409: 'Completa tu perfil de vendedor antes de publicar.',
            },
          )
        : await api.putJson(path, authorization: _authorization, body: body);
    try {
      return Product.fromJson(json);
    } catch (_) {
      throw const ApiException(
        'No pudimos confirmar los cambios. Actualiza tus productos antes de reintentar.',
      );
    }
  }

  Future<void> deleteProduct(String id) async {
    await api.deleteJson(
      '/api/v1/vendedor/productos/${Uri.encodeComponent(id)}',
      authorization: _authorization,
      errorMessages: const {
        409: 'Este producto tiene órdenes. Desactívalo desde Editar producto para conservar el historial.',
      },
    );
  }

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

  Future<OrderPage> orderPage({int page = 0, bool history = false}) => _read(
    '${isSeller ? "vendedor" : "comprador"}/ordenes${history ? "/historial" : ""}?page=$page&size=20',
    OrderPage.fromJson,
  );

  Future<List<OrderSummary>> orders({int page = 0}) async =>
      (await orderPage(page: page)).items;
  Future<OrderSummary> order(String id) =>
      _read('ordenes/${Uri.encodeComponent(id)}', OrderSummary.fromJson);

  Future<OrderSummary> advanceOrder(String id, String action) async {
    if (!isSeller ||
        !{
          'aceptar',
          'rechazar',
          'preparar',
          'enviar',
          'entregar',
        }.contains(action)) {
      throw const ApiException('No puedes realizar esta acción.');
    }
    final json = await api.patchJson(
      '/api/v1/vendedor/ordenes/${Uri.encodeComponent(id)}/$action',
      authorization: _authorization,
      errorMessages: const {
        409: 'La orden cambió de estado o ya no hay disponibilidad. Actualiza los datos antes de continuar.',
      },
    );
    try {
      return OrderSummary.fromJson(json);
    } catch (_) {
      throw const ApiException(
        'No pudimos confirmar el nuevo estado. Actualiza la orden antes de reintentar.',
      );
    }
  }

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