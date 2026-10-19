# Caféxpress

<!-- impeccable:product-schema 1 -->

## Platform

android

Aplicación móvil Flutter. Android se toma como plataforma inicial de referencia;
el repositorio también incluye los proyectos generados para otras plataformas.

## Users

Compradores y vendedores de café y cacao con destino a la Unión Europea.

## Product Purpose

Organizar compras, ventas y exportaciones: requisitos, documentos, incidencias,
avance e historial desde la publicación hasta la entrega, según el PDF aportado.

## Capabilities and Constraints

- El módulo de interfaz de autenticación corresponde a F2-32.
- El alcance actual es solo inicio de sesión con usuario o correo y contraseña.
- Registro y selección de comprador/vendedor se incorporarán en pasos posteriores.
- El backend será una API REST Spring Boot. Su contrato aún no está definido.
- Los endpoints y JSON documentados en el frontend son propuestas, no APIs existentes.

## Brand Commitments

Nombre Caféxpress y texto de interfaz en español. El PDF proporcionado es la
referencia visual disponible; se conservan sus tonos café, crema, verde y dorado.

## Evidence on Hand

PDF Caféxpress y capturas de Jira proporcionados por el usuario. El repositorio
inicial contiene las plantillas de Flutter y Spring Boot, sin autenticación.

## Product Principles

- Mantener separadas la interfaz y la comunicación con el backend.
- Mostrar errores reales y recuperables, sin simular cuentas autenticadas.
- Mantener las credenciales fuera de registros y del almacenamiento persistente.
