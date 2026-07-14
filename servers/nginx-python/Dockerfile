# Nginx as the app server for the Python stack.
# Reverse-proxies to the FastAPI/Gunicorn container.
FROM nginx:1.27-alpine
LABEL role="app-server" server="nginx" stack="python-frontend"

COPY servers/nginx-python/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:80/health || exit 1
