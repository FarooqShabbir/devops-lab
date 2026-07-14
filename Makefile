.PHONY: up down build logs ps clean k8s-apply k8s-delete tf-plan tf-apply tf-destroy

## --- Docker Compose (local/full demo) ---
up:
	docker compose up -d --build

down:
	docker compose down

build:
	docker compose build

logs:
	docker compose logs -f

ps:
	docker compose ps

clean:
	docker compose down -v --remove-orphans
	docker system prune -f

## --- Kubernetes (Minikube) ---
k8s-apply:
	kubectl apply -k k8s/base/

k8s-delete:
	kubectl delete -k k8s/base/

k8s-status:
	kubectl get all -n devops-lab

## --- Terraform ---
tf-plan:
	cd infra/terraform && terraform plan

tf-apply:
	cd infra/terraform && terraform apply

tf-destroy:
	cd infra/terraform && terraform destroy

## --- Smoke test all routes (requires lab.local in /etc/hosts) ---
smoke:
	curl -fsk https://lab.local/python/health && echo " -> python OK"
	curl -fsk https://lab.local/node/health && echo " -> node OK"
	curl -fsk https://lab.local/java/health && echo " -> java OK"
