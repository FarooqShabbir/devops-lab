# k8s/overlays

`k8s/base/` deploys the core deployment/orchestration story: 3 apps, their 3
app-servers, the edge Nginx (reverse proxy/vhost/SSL/routing), and an
Ingress. That's ~740Mi of memory requests — it fits a `minikube start
--memory=1800mb` node with room to spare.

Prometheus + Grafana + Loki + Promtail add roughly another 500-700Mi of
requests on top of that, which is where a `t3.micro` (1GB RAM total, minus
what the host OS and Docker/Minikube's own control plane need) gets
genuinely tight and prone to evictions or OOM-kills — not a "might be slow"
problem, a "pods get killed" problem.

**What to actually do, by scenario:**

- **Grading a live K8s demo, budget allows a few dollars:** bump
  `instance_type` to `t3.small` in `terraform.tfvars` (2GB RAM, ~$0.02/hr in
  eu-north-1), run `minikube start --memory=3500mb --cpus=2`, then `kubectl
  apply -k k8s/base/ -k k8s/overlays/observability/`. Full stack, live, in
  K8s.
- **Strict free tier, K8s deliverable only:** stay on `t3.micro`, apply only
  `k8s/base/`. Observability is demonstrated via Docker Compose instead
  (`docker compose up -d prometheus grafana loki promtail`) — same configs,
  same dashboards, just not orchestrated by K8s simultaneously with the app
  layer.

The `observability/` manifests below are real and correct either way; which
environment runs them is a resource decision, not a capability gap.
