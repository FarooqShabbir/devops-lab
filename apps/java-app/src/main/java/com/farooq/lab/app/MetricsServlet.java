package com.farooq.lab.app;

import io.prometheus.client.exporter.common.TextFormat;
import io.prometheus.client.hotspot.DefaultExports;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.Writer;

@WebServlet(urlPatterns = {"/metrics"})
public class MetricsServlet extends HttpServlet {

    static {
        DefaultExports.initialize();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType(TextFormat.CONTENT_TYPE_004);
        try (Writer writer = resp.getWriter()) {
            TextFormat.write004(writer, io.prometheus.client.CollectorRegistry.defaultRegistry.metricFamilySamples());
        }
    }
}
