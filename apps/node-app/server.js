/**
 * Node.js stack app (Express).
 * Fronted by: Apache httpd (servers/apache-node) via mod_proxy -> proxied further by edge/nginx-edge.
 */
const express = require('express');
const os = require('os');
const client = require('prom-client');

const APP_NAME = 'node-app';
const START_TIME = Date.now();
const app = express();
const PORT = process.env.PORT || 3000;

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestCounter = new client.Counter({
  name: 'app_requests_total',
  help: 'Total requests',
  labelNames: ['path', 'method', 'status'],
  registers: [register],
});

const httpLatency = new client.Histogram({
  name: 'app_request_latency_seconds',
  help: 'Request latency',
  labelNames: ['path'],
  registers: [register],
});

app.use((req, res, next) => {
  const end = httpLatency.startTimer({ path: req.path });
  res.on('finish', () => {
    end();
    httpRequestCounter.inc({ path: req.path, method: req.method, status: res.statusCode });
  });
  next();
});

app.get('/', (req, res) => {
  res.json({
    app: APP_NAME,
    stack: 'node-express',
    hostname: os.hostname(),
    message: 'Hello from the Node.js stack, routed via Apache httpd.',
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime_seconds: (Date.now() - START_TIME) / 1000 });
});

app.get('/api/info', (req, res) => {
  res.json({
    app: APP_NAME,
    language: 'JavaScript (Node.js)',
    framework: 'Express',
    server: 'Node HTTP server behind Apache httpd (mod_proxy)',
    container_host: os.hostname(),
    env: process.env.APP_ENV || 'development',
  });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.listen(PORT, () => {
  console.log(`${APP_NAME} listening on port ${PORT}`);
});
