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
                "nombre", "Café Sprint Dos", "cantidadUnitaria", 1,
                "unidadCantidad", "KILOGRAMOS", "cantidadDisponible", 10,
                "lugarOrigen", "Pasto", "precioUnitario", 25000, "disponible", true)), 201);
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
}
