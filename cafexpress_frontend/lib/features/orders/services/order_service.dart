import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_request.dart';

class OrderService {
  // 1. La URL real que descubrimos en el código de tus compañeros (Java)
  final String baseUrl = 'http://localhost:8080/api/v1/comprador/ordenes'; 

  // 2. Agregamos el parámetro opcional {String? token}
  Future<void> createOrder(OrderRequest order, {String? token}) async {
    try {
      // Preparamos los headers, incluyendo el token si es que lo tenemos
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(order.toJson()),
      );

      // 201 significa "Created" (Creado con éxito)
      if (response.statusCode == 201) {
        return; 
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        // Errores de validación o stock (409 Conflict)
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error de validación en la orden.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Error de seguridad (JWT)
        throw Exception('No autorizado. Necesitas iniciar sesión como comprador.');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
} 