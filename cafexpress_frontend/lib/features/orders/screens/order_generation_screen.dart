import 'package:flutter/material.dart';
import '../models/order_request.dart';
import '../services/order_service.dart';

class OrderGenerationScreen extends StatefulWidget {
  // En el futuro, estos datos deberían venir desde la pantalla del Catálogo
  final String productId = 'cafe-001';
  final String productName = 'Café de Origen Huila 500g';
  final double productPrice = 25000.0;
  final int maxStock = 10; 

  const OrderGenerationScreen({Key? key}) : super(key: key);

  @override
  State<OrderGenerationScreen> createState() => _OrderGenerationScreenState();
}

class _OrderGenerationScreenState extends State<OrderGenerationScreen> {
  int _cantidad = 1;
  bool _isLoading = false;
  final OrderService _orderService = OrderService();

  void _incrementarCantidad() {
    if (_cantidad < widget.maxStock) {
      setState(() => _cantidad++);
    } else {
      _mostrarError('No puedes pedir más de lo disponible en stock (${widget.maxStock})');
    }
  }

  void _decrementarCantidad() {
    if (_cantidad > 1) {
      setState(() => _cantidad--);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enviarOrden() async {
    setState(() => _isLoading = true);

    final nuevaOrden = OrderRequest(
      productId: widget.productId,
      cantidad: _cantidad,
      precioUnitario: widget.productPrice,
    );

    try {
      // TODO: Cuando el equipo implemente el Login, aquí deberás obtener el token real.
      // Por ahora lo dejamos en null para que el código no falle.
      final String? tokenSimulado = null; 

      // Le pasamos el token al servicio
      await _orderService.createOrder(nuevaOrden, token: tokenSimulado);
      
      if (!mounted) return;
      
      // Si el backend responde 201 (Created), mostramos éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Orden generada con éxito!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Opcional: Podrías regresar a la pantalla anterior o ir al historial
      // Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      // Aquí se capturan los errores del backend (ej. Stock insuficiente de Java)
      _mostrarError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _cantidad * widget.productPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Orden'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productName,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Precio unitario: \$${widget.productPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cantidad:', style: theme.textTheme.titleMedium),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _isLoading ? null : _decrementarCantidad,
                                icon: const Icon(Icons.remove),
                              ),
                              Text('$_cantidad', style: theme.textTheme.titleLarge),
                              IconButton(
                                onPressed: _isLoading ? null : _incrementarCantidad,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total a pagar:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _enviarOrden,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Confirmar y Enviar Orden',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}