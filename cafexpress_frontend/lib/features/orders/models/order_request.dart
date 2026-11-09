class OrderRequest {
  final String productId;
  final int cantidad;
  final double precioUnitario;

  OrderRequest({
    required this.productId,
    required this.cantidad,
    required this.precioUnitario,
  });

  // Cálculo automático del total
  double get total => cantidad * precioUnitario;

  // Convertir a JSON para el backend de Spring Boot
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'total': total,
    };
  }
}