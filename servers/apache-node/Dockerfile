# Apache httpd as the app server for the Node.js stack.
# Node runs as a sidecar process; Apache reverse-proxies to it via mod_proxy.
# This satisfies "deploy one application on the Apache server" using the
# standard production pattern (Apache almost never runs Node code directly).
FROM httpd:2.4-alpine
LABEL role="app-server" server="apache" stack="node-frontend"

RUN sed -i \
    -e '/LoadModule proxy_module/s/^#//' \
    -e '/LoadModule proxy_http_module/s/^#//' \
    -e '/LoadModule headers_module/s/^#//' \
    -e '/LoadModule rewrite_module/s/^#//' \
    -e '/LoadModule remoteip_module/s/^#//' \
    /usr/local/apache2/conf/httpd.conf

COPY servers/apache-node/httpd.conf /usr/local/apache2/conf/extra/node-proxy.conf
RUN echo "Include conf/extra/node-proxy.conf" >> /usr/local/apache2/conf/httpd.conf

EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:80/health || exit 1
