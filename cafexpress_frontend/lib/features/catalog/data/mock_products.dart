// lib/features/catalog/data/mock_products.dart
import '../models/product_model.dart';

final List<ProductModel> mockProducts = [
  ProductModel(id: '1', name: 'Café Huila 500g', origin: 'Huila', price: 25000, stock: 10, createdAt: DateTime.now().subtract(const Duration(days: 1))),
  ProductModel(id: '2', name: 'Café Geisha 250g', origin: 'Nariño', price: 85000, stock: 5, createdAt: DateTime.now().subtract(const Duration(days: 5))),
  ProductModel(id: '3', name: 'Cacao Fino 1kg', origin: 'Santander', price: 35000, stock: 20, createdAt: DateTime.now().subtract(const Duration(days: 10))),
  ProductModel(id: '4', name: 'Café Orgánico 1kg', origin: 'Tolima', price: 45000, stock: 8, createdAt: DateTime.now()),
]; 