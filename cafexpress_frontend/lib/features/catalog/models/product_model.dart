// lib/features/catalog/models/product_model.dart

class ProductModel {
  final String id;
  final String name;
  final String origin;
  final double price;
  final int stock;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.origin,
    required this.price,
    required this.stock,
    required this.createdAt,
  });
}

// Enum para el ordenamiento (Mapeado exactamente a lo que espera Spring Boot)
enum CatalogSort {
  recent('Recientes', 'creadoEn,desc'),
  priceAsc('Menor precio', 'precio,asc'),
  priceDesc('Mayor precio', 'precio,desc');

  final String label;
  final String apiValue; // Esto es lo que enviaremos al backend después

  const CatalogSort(this.label, this.apiValue);
} 