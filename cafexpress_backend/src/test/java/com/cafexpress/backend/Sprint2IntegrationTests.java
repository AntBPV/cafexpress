package com.cafexpress.backend;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import tools.jackson.databind.ObjectMapper;
import java.net.*;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "server.address=127.0.0.1")
class Sprint2IntegrationTests {
    @LocalServerPort int port;
    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient client = HttpClient.newHttpClient();
    private record Account(String token, Map<String, Object> user) {}
    private static final HttpServer weather = stub();

    private static HttpServer stub() {
        try {
            var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
            server.createContext("/search", exchange -> {
                byte[] body = """
                    {"results":[{"name":"Pasto","country":"Colombia","latitude":1.21,"longitude":-77.28},
                    {"name":"Pasto / Airport","country":"Colombia","latitude":1.40,"longitude":-77.29}]}
                    """.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().add("Content-Type", "application/json");
                exchange.sendResponseHeaders(200, body.length);
                try (var output = exchange.getResponseBody()) { output.write(body); }
            });
            server.createContext("/forecast", exchange -> {
                byte[] body = """
                    {"latitude":1.21,"longitude":-77.28,"elevation":2500,"generationtime_ms":1,
                    "utc_offset_seconds":0,"timezone":"UTC","timezone_abbreviation":"UTC",
                    "current":{"time":"2026-11-07T12:00","interval":900,"temperature_2m":22,"relative_humidity_2m":70},
                    "current_units":{"temperature_2m":"°C","relative_humidity_2m":"%"},
                    "daily_units":{"rain_sum":"mm","temperature_2m_max":"°C","temperature_2m_min":"°C"},
                    "daily":{"time":["2026-11-07","2026-11-08"],"temperature_2m_max":[24,24],
                    "temperature_2m_min":[20,20],"rain_sum":[4,4]}}
                    """.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().add("Content-Type", "application/json");
                exchange.sendResponseHeaders(200, body.length);
                try (var output = exchange.getResponseBody()) { output.write(body); }
            });
            server.start();
            Runtime.getRuntime().addShutdownHook(new Thread(() -> server.stop(0)));
            return server;
        } catch (Exception ex) { throw new IllegalStateException(ex); }
    }

    @DynamicPropertySource
    static void urls(DynamicPropertyRegistry registry) {
        String url = "http://127.0.0.1:" + weather.getAddress().getPort();
        registry.add("app.geocoding.base-url", () -> url);
        registry.add("app.open-meteo.base-url", () -> url);
    }

    private HttpResponse<String> call(String method, String path, String token, Map<String, ?> body) throws Exception {
        var builder = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + "/api/v1/" + path))
                .header("Content-Type", "application/json");
        if (token != null) builder.header("Authorization", "Bearer " + token);
        builder.method(method, body == null ? HttpRequest.BodyPublishers.noBody()
                : HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body)));
        return client.send(builder.build(), HttpResponse.BodyHandlers.ofString());
    }
    @SuppressWarnings("unchecked")
    private Map<String, Object> json(HttpResponse<String> response, int status) throws Exception {
        assertEquals(status, response.statusCode(), response.body());
        return mapper.readValue(response.body(), Map.class);
    }
    @SuppressWarnings("unchecked")
    private Map<String, Object> object(Object value) { return (Map<String, Object>) value; }
    private Account account(String role) throws Exception {
        var json = json(call("POST", "auth/register", null, Map.of(
                "nombre", "Cuenta Sprint Dos", "email", UUID.randomUUID() + "@example.test",
                "password", "SprintDos2026!", "rol", role)), 201);
        return new Account((String) json.get("accessToken"), object(json.get("usuario")));
    }
    private Map<String, Object> profile(Account account, String company) throws Exception {
        return json(call("PUT", "vendedor/perfil", account.token(), Map.of(
                "nombre", " Ana Sprint Dos ", "empresaProductor", " " + company + " ",
                "paisOrigen", " Colombia ")), 200);
    }
    private Map<String, Object> product(Account seller) throws Exception {
        return json(call("POST", "vendedor/productos", seller.token(), Map.of(
                "nombre", "Café Sprint Dos", "tipo", "CAFE", "cantidadUnitaria", 1,
                "unidadCantidad", "KILOGRAMOS", "cantidadDisponible", 10,
                "lugarOrigen", "Pasto", "precioUnitario", 25000, "disponible", true)), 201);
    }

    @Test
    void accesoPorUsuarioOCorreoYProductosRelevantesRespetanLaCuenta() throws Exception {
        String username = "local." + UUID.randomUUID().toString().substring(0, 8);
        String email = UUID.randomUUID() + "@example.test";
        var registered = json(call("POST", "auth/register", null, Map.of(
                "nombre", "Cuenta con usuario", "username", username.toUpperCase(Locale.ROOT),
                "email", email, "password", "SprintDos2026!", "rol", "VENDEDOR")), 201);
        assertEquals(username, object(registered.get("usuario")).get("username"));
        for (String identifier : List.of(username.toUpperCase(Locale.ROOT), email)) {
            var signedIn = json(call("POST", "auth/login", null, Map.of(
                    "email", identifier, "password", "SprintDos2026!")), 200);
            assertEquals(object(registered.get("usuario")).get("id"), object(signedIn.get("usuario")).get("id"));
        }
        assertEquals(409, call("POST", "auth/register", null, Map.of(
                "nombre", "Duplicado", "username", username, "email", UUID.randomUUID() + "@example.test",
                "password", "SprintDos2026!", "rol", "COMPRADOR")).statusCode());
        assertEquals(400, call("POST", "auth/register", null, Map.of(
                "nombre", "Inválido", "username", "usuario con espacios", "email", UUID.randomUUID() + "@example.test",
                "password", "SprintDos2026!", "rol", "COMPRADOR")).statusCode());
        assertEquals(401, call("POST", "auth/login", null, Map.of(
                "email", username, "password", "OtraClave2026!")).statusCode());
        var seller = new Account((String) registered.get("accessToken"), object(registered.get("usuario")));
        profile(seller, "Finca relevante");
        var product = product(seller);
        var buyer = account("COMPRADOR");
        var outsider = account("COMPRADOR");
        assertEquals(401, call("GET", "dashboard/productos-relevantes", null, null).statusCode());
        assertEquals(1, ((List<?>) json(call("GET", "dashboard/productos-relevantes", seller.token(), null), 200).get("productos")).size());
        assertEquals(0, ((List<?>) json(call("GET", "dashboard/productos-relevantes", buyer.token(), null), 200).get("productos")).size());
        json(call("POST", "productos/" + product.get("id") + "/consulta", buyer.token(), Map.of()), 200);
        assertEquals(1, ((List<?>) json(call("GET", "dashboard/productos-relevantes", buyer.token(), null), 200).get("productos")).size());
        assertEquals(0, ((List<?>) json(call("GET", "dashboard/productos-relevantes", outsider.token(), null), 200).get("productos")).size());
    }

    @Test
    void perfilesPersistenSinCambiarCorreoNiRolYNoSeCompartenEntreCuentas() throws Exception {
        var seller = account("VENDEDOR");
        var other = account("VENDEDOR");
        var buyer = account("COMPRADOR");
        var saved = profile(seller, "Finca de prueba");
        assertEquals("Ana Sprint Dos", saved.get("nombre"));
        assertEquals("Finca de prueba", saved.get("empresaProductor"));
        assertEquals("Colombia", saved.get("paisOrigen"));
        var reloaded = json(call("GET", "perfil", seller.token(), null), 200);
        assertEquals(saved, reloaded);
        assertEquals(seller.user().get("email"), reloaded.get("email"));
        assertEquals("VENDEDOR", reloaded.get("rol"));
        assertFalse(reloaded.containsKey("passwordHash"));
        assertNull(json(call("GET", "perfil", other.token(), null), 200).get("empresaProductor"));
        assertEquals(403, call("PUT", "vendedor/perfil", buyer.token(), Map.of(
                "nombre", "Comprador", "empresaProductor", "No autorizado", "paisOrigen", "Colombia")).statusCode());
        assertEquals(400, call("PUT", "vendedor/perfil", seller.token(), Map.of(
                "nombre", " ", "empresaProductor", "x", "paisOrigen", "x")).statusCode());
        assertEquals(400, call("PUT", "vendedor/perfil", seller.token(), Map.of(
                "nombre", "x", "empresaProductor", "x".repeat(121), "paisOrigen", "x")).statusCode());
        assertEquals("Finca de prueba", json(call("GET", "perfil", seller.token(), null), 200).get("empresaProductor"));
    }

    @Test
    void detalleDashboardYAlertasEstanConectadosYSeparadosPorCuenta() throws Exception {
        var seller = account("VENDEDOR");
        var buyer = account("COMPRADOR");
        var outsider = account("COMPRADOR");
        profile(seller, "Cooperativa de prueba");
        var product = product(seller);
        String id = (String) product.get("id");
        var detail = json(call("GET", "productos/" + id, buyer.token(), null), 200);
        assertEquals("Cooperativa de prueba", object(detail.get("vendedor")).get("empresaProductor"));
        assertEquals("Colombia", object(detail.get("vendedor")).get("paisOrigen"));
        assertEquals(404, call("GET", "productos/" + UUID.randomUUID(), buyer.token(), null).statusCode());
        assertEquals(401, call("GET", "productos/" + id, null, null).statusCode());
        var noAlerts = json(call("GET", "dashboard/alertas", outsider.token(), null), 200);
        assertEquals(List.of(), noAlerts.get("alertas"));
        for (int i = 0; i < 2; i++) json(call("POST", "productos/" + id + "/consulta", buyer.token(), Map.of()), 200);
        var alerts = json(call("GET", "dashboard/alertas", buyer.token(), null), 200);
        assertEquals(1, ((List<?>) alerts.get("alertas")).size(), alerts.toString());
        assertEquals(id, object(((List<?>) alerts.get("alertas")).getFirst()).get("productoId"));
        assertEquals(List.of(), json(call("GET", "dashboard/alertas", outsider.token(), null), 200).get("alertas"));
        var order = json(call("POST", "comprador/ordenes", buyer.token(),
                Map.of("productoId", id, "cantidad", 2)), 201);
        var sellerDashboard = json(call("GET", "dashboard", seller.token(), null), 200);
        assertEquals(1, ((Number) sellerDashboard.get("productosActivos")).intValue());
        assertEquals(1, ((Number) sellerDashboard.get("ordenesActivas")).intValue());
        var buyerDashboard = json(call("GET", "dashboard", buyer.token(), null), 200);
        assertEquals(1, ((Number) object(buyerDashboard.get("ordenesPorEstado")).get("SOLICITADA")).intValue());
        var isolated = json(call("GET", "dashboard", outsider.token(), null), 200);
        assertEquals(0, ((Number) isolated.get("ordenesActivas")).intValue());
        assertEquals(List.of(), isolated.get("ordenesRecientes"));
        json(call("PATCH", "vendedor/ordenes/" + order.get("id") + "/aceptar", seller.token(), Map.of()), 200);
        var updated = json(call("GET", "dashboard", buyer.token(), null), 200);
        assertEquals(1, ((Number) object(updated.get("ordenesPorEstado")).get("ACEPTADA")).intValue());
        assertEquals(0, ((Number) object(updated.get("ordenesPorEstado")).get("SOLICITADA")).intValue());
        assertEquals(401, call("GET", "dashboard", null, null).statusCode());
        assertEquals(401, call("GET", "perfil", null, null).statusCode());
    }
    @Test
    void integracionDeFiltrosImportesYEstadosMantieneLosPanelesConsistentes() throws Exception {
        var seller = account("VENDEDOR");
        var buyer = account("COMPRADOR");
        profile(seller, "Finca de integración");
        var product = product(seller);
        String id = (String) product.get("id");
        assertEquals("CAFE", product.get("tipo"));
        json(call("GET", "productos", buyer.token(), null), 200);
        var filtered = json(call("GET", "productos?tipo=CAFE&lugarOrigen=Pasto&precioMin=25000&precioMax=25000", buyer.token(), null), 200);
        assertTrue(((List<?>) filtered.get("content")).stream().anyMatch(item -> id.equals(object(item).get("id"))));
        assertEquals(400, call("GET", "productos?precioMin=30000&precioMax=10000", buyer.token(), null).statusCode());
        var order = json(call("POST", "comprador/ordenes", buyer.token(), Map.of("productoId", id, "cantidad", 2)), 201);
        assertEquals(25000, ((Number) order.get("precioUnitario")).doubleValue());
        assertEquals(50000, ((Number) order.get("precioTotal")).doubleValue());
        json(call("PUT", "vendedor/productos/" + id, seller.token(), Map.of("precioUnitario", 30000)), 200);
        String path = "vendedor/ordenes/" + order.get("id");
        assertEquals(409, call("PATCH", path + "/entregar", seller.token(), Map.of()).statusCode());
        assertEquals(403, call("PATCH", path + "/aceptar", buyer.token(), Map.of()).statusCode());
        var accepted = json(call("PATCH", path + "/aceptar", seller.token(), Map.of()), 200);
        assertEquals(50000, ((Number) accepted.get("precioTotal")).doubleValue());
        assertNotNull(accepted.get("aceptadaEn"));
        json(call("PATCH", path + "/preparar", seller.token(), Map.of()), 200);
        var preparing = json(call("GET", "dashboard", seller.token(), null), 200);
        assertEquals(1, ((Number) preparing.get("ordenesActivas")).intValue());
        assertEquals(1, ((Number) object(preparing.get("ordenesPorEstado")).get("EN_PREPARACION")).intValue());
        json(call("PATCH", path + "/enviar", seller.token(), Map.of()), 200);
        var sent = json(call("GET", "dashboard", buyer.token(), null), 200);
        assertEquals(1, ((Number) sent.get("ordenesActivas")).intValue());
        assertEquals(1, ((Number) object(sent.get("ordenesPorEstado")).get("ENVIADA")).intValue());
        var delivered = json(call("PATCH", path + "/entregar", seller.token(), Map.of()), 200);
        assertNotNull(delivered.get("entregadaEn"));
        assertNotNull(delivered.get("enPreparacionEn"));
        assertNotNull(delivered.get("enviadaEn"));
        assertEquals("ENTREGADA", delivered.get("estado"));
        var completed = json(call("GET", "dashboard", buyer.token(), null), 200);
        assertEquals(0, ((Number) completed.get("ordenesActivas")).intValue());
        var history = json(call("GET", "comprador/ordenes/historial", buyer.token(), null), 200);
        assertTrue(((List<?>) history.get("content")).stream().anyMatch(item -> order.get("id").equals(object(item).get("id"))));
        assertEquals(409, call("PATCH", path + "/preparar", seller.token(), Map.of()).statusCode());
    }

    @Test
    void catalogoGuardaVariedadFiltraPaisYProtegeProductosConOrdenes() throws Exception {
        var seller = account("VENDEDOR"); var buyer = account("COMPRADOR"); var other = account("VENDEDOR");
        profile(seller, "Productor integral");
        var product = json(call("POST", "vendedor/productos", seller.token(), Map.of(
                "nombre", "Cacao integrado", "tipo", "CACAO", "variedad", "Criollo", "cantidadUnitaria", 1,
                "unidadCantidad", "KILOGRAMOS", "cantidadDisponible", 8, "lugarOrigen", "Pasto",
                "precioUnitario", 25000, "disponible", true)), 201);
        String id = (String) product.get("id");
        assertEquals("Criollo", product.get("variedad"));
        var matches = json(call("GET", "productos?tipo=CACAO&paisOrigen=colombia&precioMin=25000&precioMax=25000", buyer.token(), null), 200);
        assertTrue(((List<?>) matches.get("content")).stream().anyMatch(v -> id.equals(object(v).get("id"))));
        var noMatches = json(call("GET", "productos?paisOrigen=Ecuador", buyer.token(), null), 200);
        assertFalse(((List<?>) noMatches.get("content")).stream().anyMatch(v -> id.equals(object(v).get("id"))));
        assertEquals(403, call("PUT", "vendedor/productos/" + id, buyer.token(), Map.of("precioUnitario", 26000)).statusCode());
        assertEquals(404, call("PUT", "vendedor/productos/" + id, other.token(), Map.of("precioUnitario", 26000)).statusCode());
        var order = json(call("POST", "comprador/ordenes", buyer.token(), Map.of("productoId", id, "cantidad", 1)), 201);
        assertEquals(409, call("DELETE", "vendedor/productos/" + id, seller.token(), null).statusCode());
        json(call("PUT", "vendedor/productos/" + id, seller.token(), Map.of("disponible", false)), 200);
        var unavailable = json(call("GET", "productos?tipo=CACAO", buyer.token(), null), 200);
        assertFalse(((List<?>) unavailable.get("content")).stream().anyMatch(v -> id.equals(object(v).get("id"))));
        json(call("GET", "ordenes/" + order.get("id"), buyer.token(), null), 200);
    }

    @Test
    void solicitudEsActivaYDetalleSoloSeComparteConSusParticipantes() throws Exception {
        var seller = account("VENDEDOR"); var buyer = account("COMPRADOR"); var other = account("COMPRADOR");
        profile(seller, "Finca privada"); var product = product(seller);
        var order = json(call("POST", "comprador/ordenes", buyer.token(), Map.of("productoId", product.get("id"), "cantidad", 1)), 201);
        assertEquals(true, order.get("activo"));
        assertEquals(1, ((Number) json(call("GET", "comprador/ordenes", buyer.token(), null), 200).get("totalElements")).intValue());
        assertEquals(0, ((Number) json(call("GET", "comprador/ordenes/historial", buyer.token(), null), 200).get("totalElements")).intValue());
        String path = "ordenes/" + order.get("id");
        json(call("GET", path, buyer.token(), null), 200); json(call("GET", path, seller.token(), null), 200);
        assertEquals(404, call("GET", path, other.token(), null).statusCode());
        assertEquals(401, call("GET", path, null, null).statusCode());
        json(call("PATCH", "vendedor/ordenes/" + order.get("id") + "/rechazar", seller.token(), Map.of()), 200);
        assertEquals(0, ((Number) json(call("GET", "comprador/ordenes", buyer.token(), null), 200).get("totalElements")).intValue());
        assertEquals(1, ((Number) json(call("GET", "comprador/ordenes/historial", buyer.token(), null), 200).get("totalElements")).intValue());
    }

    @Test
    void aceptarDosVecesEnParaleloSoloDescuentaStockUnaVez() throws Exception {
        var seller = account("VENDEDOR"); var buyer = account("COMPRADOR");
        profile(seller, "Finca concurrente"); var product = product(seller);
        var order = json(call("POST", "comprador/ordenes", buyer.token(), Map.of("productoId", product.get("id"), "cantidad", 2)), 201);
        var start = new java.util.concurrent.CountDownLatch(1);
        try (var executor = java.util.concurrent.Executors.newFixedThreadPool(2)) {
            java.util.concurrent.Callable<Integer> accept = () -> {
                start.await(); return call("PATCH", "vendedor/ordenes/" + order.get("id") + "/aceptar", seller.token(), Map.of()).statusCode();
            };
            var first = executor.submit(accept); var second = executor.submit(accept); start.countDown();
            var statuses = new ArrayList<>(List.of(first.get(), second.get())); Collections.sort(statuses);
            assertEquals(List.of(200,409), statuses);
        }
        var current = json(call("GET", "productos/" + product.get("id"), seller.token(), null), 200);
        assertEquals(8, ((Number) current.get("cantidadDisponible")).doubleValue());
    }

}
