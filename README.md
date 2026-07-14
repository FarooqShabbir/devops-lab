# DevOps Lab — Full Lifecycle Deployment System

A single coherent system covering cloud infra, CI/CD, containerization,
orchestration, IaC, and observability — built to satisfy every item in the
lab brief with one architecture, not six disconnected demos.

## Architecture

```
                              Internet
                                 │
                    ┌────────────────────────┐
                    │   edge-nginx (edge)     │  :80 → redirect, :443 TLS, :8888 forward-proxy
                    │  reverse proxy + vhosts │
                    │  domain + SSL + routing │
                    └───────────┬─────────────┘
                 ┌──────────────┼──────────────┐
                 │              │              │
        /python/ │      /node/  │      /java/  │        (URL-based routing)
   python.lab.local│  node.lab.local│  java.lab.local    (vhost/subdomain routing)
                 ▼              ▼              ▼
         ┌───────────┐  ┌────────────┐  ┌─────────────┐
         │nginx-python│  │apache-node │  │tomcat-java  │  ← "one app per server" tier
         │(app server)│  │(app server)│  │(app server) │
         └─────┬─────┘  └──────┬─────┘  └──────┬──────┘
               │               │                │  (Tomcat runs the WAR natively —
               ▼               ▼                │   no extra hop needed)
        ┌────────────┐  ┌────────────┐          │
        │ python-app │  │  node-app  │          │
        │  (FastAPI) │  │ (Express)  │   [java-app IS tomcat-java's deployed WAR]
        └────────────┘  └────────────┘

   Observability sidecar to everything above:
   Prometheus (scrapes /metrics on all 3 apps + cAdvisor)
   → Grafana (dashboards)
   Promtail (tails container logs) → Loki (log storage) → Grafana (log explorer)
```

## How the lab checklist maps to this repo

| Lab requirement | Where it lives |
|---|---|
| Deploy one app per stack (Python/Node/Java) | `apps/python-app`, `apps/node-app`, `apps/java-app` |
| Deploy one app per server (Apache/Tomcat/Nginx) | Apache→Node (`servers/apache-node`), Tomcat→Java (`apps/java-app/Dockerfile`, native WAR), Nginx→Python (`servers/nginx-python`) |
| Nginx reverse proxy | `edge/nginx-edge/conf.d/*.conf` (every backend), also `servers/nginx-python/default.conf` |
| Nginx forward proxy | `edge/nginx-edge/forward-proxy/forward-proxy.conf` — see `docs/forward-proxy-notes.md` for the one honest caveat (HTTP-only on stock Nginx) |
| Nginx virtual hosting | `edge/nginx-edge/conf.d/20-virtual-hosts.conf` (python/node/java.lab.local) |
| Domain configured with app | `edge/nginx-edge/conf.d/10-main-domain.conf` (`lab.local`) |
| SSL certificate deployed | `edge/nginx-edge/gen-self-signed-cert.sh` + `ssl_certificate` directives (swap for Let's Encrypt in real deployment — see below) |
| Context/URL-based routing | `/python/`, `/node/`, `/java/` in `10-main-domain.conf`; K8s-native version in `k8s/base/30-ingress.yaml` |
| Cloud | `infra/terraform` — AWS EC2 t3.micro (free tier), VPC, SG, EIP |
| IaC | Terraform (`infra/terraform/`), bootstrap via `infra/ansible/bootstrap.sh` |
| Containerization | Every service has its own `Dockerfile`, multi-stage, non-root where practical |
| CI/CD | `.github/workflows/ci.yml` (build/test/push), `cd.yml` (deploy) |
| Orchestration | `docker-compose.yml` (local/full demo) + `k8s/base` (Minikube, real K8s API) |
| Observability | `observability/` — Prometheus, Grafana, Loki, Promtail, cAdvisor |

## Quick start — local (Docker Compose, full 13-container stack)

```bash
git clone <your-repo-url> devops-lab && cd devops-lab
docker compose up -d --build

# Map the lab domain locally (once):
echo "127.0.0.1 lab.local www.lab.local python.lab.local node.lab.local java.lab.local" | sudo tee -a /etc/hosts

curl -k https://lab.local/python/           # FastAPI, via Nginx
curl -k https://lab.local/node/             # Express, via Apache
curl -k https://lab.local/java/             # Servlet, via Tomcat
curl -k https://python.lab.local/           # same app, via virtual host instead of path
curl -x http://localhost:8888 http://example.com/   # forward proxy (HTTP only, see docs/)

open http://localhost:3001    # Grafana (admin/admin)
open http://localhost:9090    # Prometheus
```

## Quick start — AWS (Terraform + free tier)

```bash
cd infra/terraform
ssh-keygen -t ed25519 -f ~/.ssh/devops_lab_key -N ""
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set allowed_ssh_cidr to YOUR public IP (curl ifconfig.me)

terraform init
terraform plan
terraform apply

# SSH in once bootstrap finishes (~3-5 min, watch /var/log/lab-bootstrap.log)
ssh -i ~/.ssh/devops_lab_key ubuntu@$(terraform output -raw instance_public_ip)
git clone <your-repo-url> /opt/devops-lab && cd /opt/devops-lab
docker compose up -d --build
```

## Quick start — Kubernetes deliverable (Minikube on the same EC2 box)

```bash
minikube start --driver=docker --memory=1800mb --cpus=1
minikube addons enable ingress

# Build images into Minikube's own Docker daemon (no registry push needed for local grading)
eval $(minikube docker-env)
docker compose build

kubectl apply -k k8s/base/
kubectl get pods -n devops-lab -w

minikube service edge-nginx-svc -n devops-lab --url
```

**On RAM:** a `t3.micro` (1GB RAM) comfortably runs `k8s/base/` (apps +
servers + edge + Ingress, ~740Mi requested). Running the observability stack
*inside* K8s at the same time gets tight — see `k8s/overlays/README.md` for
the exact tradeoff and the one-line fix (`t3.small`, ~$0.02/hr) if you want
everything live in K8s simultaneously during grading.

## CI/CD

- **`ci.yml`**: on every push/PR to `main` — lints Terraform/K8s manifests,
  unit-checks each app, then builds and pushes all 6 images to GHCR
  (`ghcr.io/<you>/devops-lab/<service>:latest` and `:<short-sha>`).
- **`cd.yml`**: manually triggered (`workflow_dispatch`) — SSHes into the EC2
  box, pulls new images, rolls `docker compose up -d`, then smoke-tests all
  three routes. Kept manual rather than auto-deploy since this is a
  thesis/coursework box you don't want redeploying itself mid-demo.

Required repo secrets for CD: `LAB_SSH_PRIVATE_KEY`, `LAB_HOST_IP`.

## Going from self-signed to a real domain + real SSL

Everything here uses `lab.local` + a self-signed cert because a lab
environment has no real DNS-resolvable domain. To make this production-real
later, the swap is small and contained:

1. Point a real domain's A record at `terraform output instance_public_ip`.
2. Replace `gen-self-signed-cert.sh`'s call with `certbot --nginx -d
   yourdomain.com` (add the certbot package to the `edge-nginx` Dockerfile).
3. Change `server_name lab.local` → `server_name yourdomain.com` in
   `10-main-domain.conf` and `20-virtual-hosts.conf`.

Nothing else in the routing/proxy logic changes — the self-signed cert was
never load-bearing for the architecture, just for having *a* cert to
terminate TLS with in an environment without real DNS.

## Repo layout

```
apps/           Python (FastAPI), Node (Express), Java (Servlet/Tomcat) source + Dockerfiles
servers/        Nginx-fronting-Python, Apache-fronting-Node, Tomcat server.xml tuning
edge/           The advanced Nginx layer: reverse proxy, forward proxy, vhosts, SSL, routing
infra/          Terraform (AWS) + EC2 bootstrap script
k8s/            Kubernetes manifests (Minikube-targeted) + observability overlay
observability/  Prometheus, Grafana, Loki, Promtail configs
.github/        CI (build/test/push) and CD (deploy) workflows
docs/           Deep-dive notes (forward proxy limitation, etc.)
docker-compose.yml   Full local/demo stack, 13 services
```
