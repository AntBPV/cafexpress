package com.cafexpress.backend.alerta.dto;

import java.util.List;
import java.util.Map;

public record OpenMeteoResponse(
        double latitude,
        double longitude,
        double elevation,
        double generationtime_ms,
        int utc_offset_seconds,
        String timezone,
        String timezone_abbreviation,
        DailyWeather daily,
        Map<String, String> daily_units,
        CurrentWeather current,
        Map<String, String> current_units
) {
    public record DailyWeather(
            List<String> time,
            List<Double> temperature_2m_max,
            List<Double> temperature_2m_min,
            List<Double> rain_sum
    ) {
    }

    public record CurrentWeather(
            String time,
            int interval,
            Double relative_humidity_2m,
            Double temperature_2m
    ) {
    }
}
