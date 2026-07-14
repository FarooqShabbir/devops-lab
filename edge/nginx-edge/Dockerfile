# Edge Nginx: the "advanced configuration" layer for the lab.
# Responsibilities:
#   - Reverse proxy for all 3 app-server backends (context/URL-based routing)
#   - Virtual hosting (multiple server_name blocks)
#   - Domain + SSL termination
#   - Forward proxy (separate listener, separate config file)
FROM nginx:1.27-alpine
LABEL role="edge" purpose="reverse-proxy,forward-proxy,vhost,ssl,routing"

RUN apk add --no-cache openssl

# Remove default server block
RUN rm -f /etc/nginx/conf.d/default.conf

COPY edge/nginx-edge/nginx.conf /etc/nginx/nginx.conf
COPY edge/nginx-edge/conf.d/ /etc/nginx/conf.d/
COPY edge/nginx-edge/forward-proxy/forward-proxy.conf /etc/nginx/forward-proxy.conf
COPY edge/nginx-edge/gen-self-signed-cert.sh /usr/local/bin/gen-self-signed-cert.sh
RUN chmod +x /usr/local/bin/gen-self-signed-cert.sh

EXPOSE 80 443 8888
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:80/edge-health || exit 1

ENTRYPOINT ["/bin/sh", "-c", "/usr/local/bin/gen-self-signed-cert.sh && nginx -g 'daemon off;'"]
