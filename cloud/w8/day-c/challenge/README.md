# K8s on AWS - Terraform 1-Click Challenge

## App Choice

Use a custom lightweight static HTML app served by Nginx.

This keeps the challenge focused on the required platform work:

- Build a Docker image.
- Run the app in Kubernetes.
- Expose it through a Service.
- Later expose it through an AWS ALB.
- Prove health checks through `/healthz`.

## Local Test Flow

Build and test Docker image:

```powershell
cd .\cloud\w8\day-c\challenge\app
docker build -t w8-k8s-challenge-web:local .
docker run -d --name w8-web-test -p 8088:80 w8-k8s-challenge-web:local
```

Open:

```text
http://localhost:8088
```

Cleanup local Docker test:

```powershell
docker rm -f w8-web-test
```

Load into minikube and deploy:

```powershell
minikube image load w8-k8s-challenge-web:local
kubectl apply -f ..\k8s\deployment.yaml
kubectl apply -f ..\k8s\service.yaml
minikube addons enable metrics-server
kubectl apply -f ..\k8s\hpa.yaml
kubectl get deploy,svc,hpa,pods
```

Access app:

```powershell
minikube service restaurant-web --url
```

Or:

```powershell
kubectl port-forward svc/restaurant-web 8080:80
```

Open:

```text
http://localhost:8080
```

## AWS Challenge Target Architecture

```text
Internet -> ALB -> EC2:30080 -> minikube Service -> Deployment -> Pod
```

Architecture diagrams:

- `architecture-diagram.md`
- `aws-k8s-challenge.drawio`

## Evidence

- Docker image builds successfully.
- App opens locally through Docker.
- App opens through minikube Service or port-forward.
- `kubectl get deploy,svc,hpa,pods`.
- Later: ALB DNS opens the app from Internet.

### Current Local Evidence

```text
docker build -t w8-k8s-challenge-web:local .
Result: success

kubectl get deploy,rs,pods,svc,hpa -o wide
Deployment: restaurant-web 2/2
Pods: 2 Running
Service: restaurant-web NodePort 80:30080
HPA: restaurant-web min 2 max 5

GET http://localhost:8088/healthz
Status: 200

GET http://localhost:8088
Status: 200

kubectl port-forward svc/restaurant-web 18080:80
GET http://localhost:18080/healthz
Status: 200

GET http://localhost:18080
Status: 200
Title found: W8 K8s on AWS Challenge
```

## Terraform Status

Terraform scaffold is ready in:

```text
cloud/w8/day-c/challenge/terraform/
```

Validated commands:

```text
terraform fmt
terraform init
terraform validate
terraform plan
```

Result:

```text
terraform validate: success
terraform plan: success
```

AWS apply status:

```text
First apply attempted with t3.medium:
Blocked by AWS because the instance type is not Free Tier eligible.

Second apply attempted with t3.micro:
Blocked by AWS account verification/account block.

Terraform destroy:
success, 8 partially-created resources destroyed.

terraform state list:
empty
```

Conclusion:

```text
Local Kubernetes challenge is complete.
AWS 1-click deployment code is ready, but cannot be completed until the AWS account block is resolved.
```
