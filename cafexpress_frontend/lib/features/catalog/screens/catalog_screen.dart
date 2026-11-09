// lib/features/catalog/screens/catalog_screen.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../data/mock_products.dart';
import '../../orders/screens/order_generation_screen.dart'; // Para el botón de comprar

class CatalogScreen extends StatefulWidget {
  final bool isSeller; // <-- Preparado para los dos roles

  const CatalogScreen({Key? key, required this.isSeller}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

// AUTOMATIC KEEP ALIVE: Esto hace que los filtros y el scroll no se pierdan
class _CatalogScreenState extends State<CatalogScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Mantiene el estado vivo

  CatalogSort _currentSort = CatalogSort.recent;
  List<ProductModel> _products = [];
  final Set<String> _activeFilters = {'Huila', 'Nariño'}; // Ejemplo de filtros aplicados

  @override
  void initState() {
    super.initState();
    _loadAndSortProducts();
  }

  // Simulamos la llamada a la API con el ordenamiento
  void _loadAndSortProducts() {
    List<ProductModel> sorted = List.from(mockProducts);

    // Aplicamos el ordenamiento igual que lo haría el backend
    switch (_currentSort) {
      case CatalogSort.recent:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CatalogSort.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case CatalogSort.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    // Aquí luego iría la lógica de filtrar por origen, etc.
    setState(() {
      _products = sorted;
    });
  }

  void _removeFilter(String filter) {
    setState(() => _activeFilters.remove(filter));
    _loadAndSortProducts();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSeller ? 'Mis Lotes (Vendedor)' : 'Catálogo (Comprador)'),
        // El botón de ordenamiento
        actions: [
          PopupMenuButton<CatalogSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar por',
            initialValue: _currentSort,
            onSelected: (CatalogSort newSort) {
              setState(() => _currentSort = newSort);
              _loadAndSortProducts();
            },
            itemBuilder: (context) => CatalogSort.values.map((sort) {
              return PopupMenuItem(
                value: sort,
                child: Text(sort.label),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sección de filtros aplicados (Etiquetas removibles)
          if (_activeFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                children: _activeFilters.map((filter) {
                  return InputChip(
                    label: Text('Región: $filter'),
                    onDeleted: () => _removeFilter(filter),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
            ),
            
          // Lista de Productos
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 350,
                mainAxisExtent: 220, // Altura de la tarjeta
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(label: Text(product.origin), visualDensity: VisualDensity.compact),
                            if (widget.isSeller) // Solo el vendedor ve esto
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Edición rápida de precio',
                                onPressed: () {
                                  // Aquí iría el diálogo de edición rápida
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Próximamente: Edición rápida')),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(product.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('\$${product.price.toStringAsFixed(0)}', 
                              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)
                            ),
                            if (!widget.isSeller) // Solo el comprador ve esto
                              FilledButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderGenerationScreen()));
                                },
                                child: const Text('Comprar'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 