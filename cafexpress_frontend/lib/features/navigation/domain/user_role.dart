import 'package:flutter/material.dart';

/// Roles definidos en el alcance del MVP v2 (Marketplace bilateral).
enum UserRole {
  comprador(
    label: 'Comprador',
    subtitle: 'Minorista o mayorista',
    icon: Icons.storefront_outlined,
  ),
  vendedor(
    label: 'Vendedor',
    subtitle: 'Productor o distribuidor',
    icon: Icons.agriculture_outlined,
  );

  const UserRole({
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final IconData icon;

  static UserRole? tryParse(String? raw) {
    if (raw == null) return null;
    return switch (raw.trim().toUpperCase()) {
      'VENDEDOR' => UserRole.vendedor,
      'COMPRADOR' => UserRole.comprador,
      _ => null,
    };
  }
}
