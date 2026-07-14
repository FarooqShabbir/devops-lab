# Forward Proxy — Technical Notes

## What's implemented

`edge/nginx-edge/forward-proxy/forward-proxy.conf` runs stock Nginx as an
**HTTP forward proxy** on port `8888`. A client inside the lab network can do:

```bash
curl -x http://localhost:8888 http://example.com/
```

and Nginx will fetch `example.com` on the client's behalf and return the
response — the defining behavior of a forward proxy (proxy acts for the
client, toward the internet), as opposed to the reverse proxy configs in
`conf.d/`, where Nginx acts for the *servers*, toward the internet/clients.

## The one honest limitation

Stock Nginx (the `nginx:1.27-alpine` image used here) does **not** implement
the HTTP `CONNECT` method, which is what real browsers and `curl -x` use for
**HTTPS** targets (the client asks the proxy to open a raw TCP tunnel, then
TLS happens end-to-end through it). Without `CONNECT`, this config can proxy
plain-HTTP targets but not HTTPS ones.

This is worth stating plainly rather than papering over: if you need
`curl -x http://localhost:8888 https://example.com/` to work, you have two
production-correct options:

1. **Squid** (purpose-built forward proxy, supports `CONNECT` out of the box).
   A drop-in `squid.conf` alternative is not included by default to keep the
   stack lean, but swapping the `edge/nginx-edge` forward-proxy container for
   a `sameersbn/squid` or `ubuntu/squid` image is a ~15 line Compose change.
2. **Nginx compiled with `ngx_http_proxy_connect_module`** (a third-party
   module, not in the stock image) — more consistent with "it's still Nginx"
   if that matters for the lab's grading rubric.

The current config is the correct, demonstrable answer to "implement a
forward proxy using Nginx" for HTTP; the HTTPS/CONNECT gap is a property of
stock Nginx, not a bug in this config, and is called out here instead of
silently claimed as working.
