package com.cafexpress.backend.dashboard.service;

import com.cafexpress.backend.alerta.dto.AlertaClimaticaResponse;
import com.cafexpress.backend.alerta.service.OpenMeteoService;
import com.cafexpress.backend.dashboard.dto.DashboardAlertasResponse;
import com.cafexpress.backend.producto.dto.ProductoResponse;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import java.text.Normalizer;

@Service
public class DashboardAlertasService {
    private final DashboardService dashboard;
    private final OpenMeteoService clima;
    private final RestClient geocoding;
    private final ExecutorService executor;
    private final ConcurrentMap<String, Observacion> cache = new ConcurrentHashMap<>();
    private record Observacion(AlertaClimaticaResponse alerta, Instant fecha, String aviso) {}
    public record Lugar(double latitude, double longitude, String name, String country) {}
    public record Busqueda(List<Lugar> results) {}

    public DashboardAlertasService(DashboardService dashboard, OpenMeteoService clima,
            @Qualifier("geocodingRestClient") RestClient geocoding,
            @Qualifier("dashboardWeatherExecutor") ExecutorService executor) {
        this.dashboard = dashboard; this.clima = clima; this.geocoding = geocoding; this.executor = executor;
    }

    private String origen(ProductoResponse producto) {
        String lugar = producto.lugarOrigen();
        String pais = producto.vendedor().paisOrigen();
        return pais == null || pais.isBlank() || normalizar(lugar).contains(normalizar(pais))
                ? lugar : lugar + ", " + pais;
    }

    private static String normalizar(String value) {
        return Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").strip().toLowerCase(Locale.ROOT);
    }

    private static String codigoPais(String pais) {
        if (pais == null || pais.isBlank()) return null;
        for (String codigo : Locale.getISOCountries()) {
            var locale = Locale.of("", codigo);
            if (normalizar(pais).equals(normalizar(locale.getDisplayCountry(Locale.forLanguageTag("es"))))
                    || normalizar(pais).equals(normalizar(locale.getDisplayCountry(Locale.ENGLISH)))
                    || pais.equalsIgnoreCase(codigo)) return codigo;
        }
        return null;
    }

    private Observacion consultar(String origen, String pais) {
        var anterior = cache.get(origen);
        if (anterior != null && anterior.fecha().isAfter(Instant.now().minus(Duration.ofMinutes(15)))) {
            return anterior;
        }
        try {
            String codigo = codigoPais(pais);
            var respuesta = geocoding.get().uri(b -> {
                if (codigo != null) b.queryParam("countryCode", codigo);
                return b.path("/search").queryParam("name", origen).queryParam("count", 2)
                        .queryParam("language", "es").build();
            }).retrieve().body(Busqueda.class);
            if (respuesta == null || respuesta.results() == null || respuesta.results().isEmpty()) {
                return new Observacion(null, Instant.now(), "No encontramos la ubicación de " + origen + ".");
            }
            String nombreBuscado = normalizar(origen.split(",")[0]);
            var exactas = respuesta.results().stream()
                    .filter(lugar -> lugar.name() != null && normalizar(lugar.name()).equals(nombreBuscado))
                    .toList();
            // Una coincidencia exacta distingue la ciudad de aeropuertos y lugares de nombre parecido.
            if (exactas.size() != 1 && respuesta.results().size() > 1) {
                return new Observacion(null, Instant.now(),
                        "El origen " + origen + " es ambiguo. Indica ciudad, departamento y país para consultar su clima.");
            }
            Lugar lugar = exactas.size() == 1 ? exactas.getFirst() : respuesta.results().getFirst();
            var observacion = new Observacion(clima.consultarAlerta(lugar.latitude(), lugar.longitude()),
                    Instant.now(), null);
            if (cache.size() >= 500) cache.clear();
            cache.put(origen, observacion);
            return observacion;
        } catch (RuntimeException ex) {
            return new Observacion(null, Instant.now(), "El clima de " + origen + " no está disponible. Puedes reintentar.");
        }
    }

    public DashboardAlertasResponse recientes(UUID usuarioId) {
        var productos = dashboard.relevantes(usuarioId);
        var porOrigen = new LinkedHashMap<String, ProductoResponse>();
        productos.forEach(p -> porOrigen.putIfAbsent(origen(p), p));
        var seleccion = porOrigen.entrySet().stream().limit(5).toList();
        var futuras = seleccion.stream().map(entry -> CompletableFuture.supplyAsync(
                () -> consultar(entry.getKey(), entry.getValue().vendedor().paisOrigen()), executor).completeOnTimeout(
                new Observacion(null, Instant.now(), "La consulta de " + entry.getKey() + " tardó demasiado."),
                7, TimeUnit.SECONDS)).toList();
        List<DashboardAlertasResponse.Alerta> alertas = new ArrayList<>();
        List<String> avisos = new ArrayList<>();
        for (int i = 0; i < seleccion.size(); i++) {
            var entry = seleccion.get(i);
            var observacion = futuras.get(i).join();
            if (observacion.aviso() != null) {
                avisos.add(observacion.aviso());
                continue;
            }
            var dato = observacion.alerta();
            // Cada alerta conserva su producto para que el comprador reconozca su relevancia.
            for (var p : productos.stream().filter(p -> origen(p).equals(entry.getKey())).limit(5).toList()) {
                String mensaje = dato.condicionesOptimas()
                        ? "Condiciones favorables para el café. Revisa la disponibilidad y el precio."
                        : "Las condiciones del clima sugieren revisar el precio del café.";
                alertas.add(new DashboardAlertasResponse.Alerta(p.id(), p.nombre(), entry.getKey(),
                        mensaje, dato.condicionesOptimas(), dato.temperaturaActual(), observacion.fecha()));
            }
        }
        if (porOrigen.size() > 5) avisos.add("Se muestran los cinco primeros orígenes relevantes.");
        return new DashboardAlertasResponse(alertas, avisos, Instant.now());
    }
}
