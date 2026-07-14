package com.farooq.lab.app;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.net.InetAddress;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Java stack app (Jakarta Servlet), deployed natively into Apache Tomcat as a WAR.
 * Tomcat itself acts as the app server here (no extra reverse proxy in front,
 * other than the edge Nginx layer for routing/SSL/domain).
 */
@WebServlet(urlPatterns = {"/", "/health", "/api/info"})
public class AppServlet extends HttpServlet {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final long START_TIME = System.currentTimeMillis();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");

        // NOTE: when a servlet is mapped to "/", Tomcat treats it as the
        // default servlet and getServletPath() returns "" for the root
        // request (not "/"). getPathInfo() and getRequestURI() are also
        // inconsistent across containers for this exact-vs-default mapping
        // case, so match on the full request URI instead, which is stable
        // regardless of which urlPattern actually matched.
        String uri = req.getRequestURI();
        Map<String, Object> body = new LinkedHashMap<>();

        String hostname;
        try {
            hostname = InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            hostname = "unknown";
        }

        if (uri.endsWith("/health")) {
            body.put("status", "ok");
            body.put("uptime_seconds", (System.currentTimeMillis() - START_TIME) / 1000.0);
        } else if (uri.endsWith("/api/info")) {
            body.put("app", "java-app");
            body.put("language", "Java");
            body.put("framework", "Jakarta Servlet");
            body.put("server", "Apache Tomcat (native WAR deployment)");
            body.put("container_host", hostname);
            body.put("env", System.getenv().getOrDefault("APP_ENV", "development"));
        } else {
            body.put("app", "java-app");
            body.put("stack", "java-servlet");
            body.put("hostname", hostname);
            body.put("timestamp", Instant.now().toString());
            body.put("message", "Hello from the Java stack, running natively in Tomcat.");
        }

        resp.getWriter().write(MAPPER.writeValueAsString(body));
    }
}
