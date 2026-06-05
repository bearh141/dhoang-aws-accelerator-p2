# W8 Kubernetes on AWS - Terraform 1-Click Deploy

Deploy a lightweight Nginx web app to a Kubernetes cluster running on an EC2 instance, then expose it publicly through an AWS Application Load Balancer.

The goal of this project is to demonstrate a simple end-to-end DevOps workflow:

```text
Terraform -> AWS infrastructure -> EC2 bootstrap -> Docker image -> Kubernetes workload -> ALB public access
```

## Architecture

```text
User Browser
  -> Application Load Balancer HTTP :80
  -> Target Group
  -> EC2 :30080
  -> minikube Service NodePort
  -> Deployment
  -> Nginx Pods :80
```

Main components:

- `Terraform`: provisions AWS infrastructure.
- `EC2`: runs Docker and minikube.
- `Docker`: builds the local web image.
- `minikube`: runs a single-node Kubernetes cluster on EC2.
- `Deployment`: keeps the web app running with 2 replicas.
- `Service`: exposes the app through NodePort `30080`.
- `HPA`: scales the Deployment from 2 to 5 Pods based on CPU.
- `ALB`: exposes the app to the Internet through a public DNS name.

Architecture diagrams:

- `aws-k8s-challenge.drawio`
- `aws-k8s-challenge-aws-style.drawio`

## Repository Structure

```text
challenge/
  app/
    Dockerfile
    index.html
    nginx.conf
  k8s/
    deployment.yaml
    service.yaml
    hpa.yaml
  terraform/
    versions.tf
    variables.tf
    main.tf
    security-groups.tf
    keypair.tf
    ec2.tf
    alb.tf
    outputs.tf
    user-data.sh
```

## What Gets Created

Terraform creates:

- EC2 instance
- Application Load Balancer
- ALB Listener on HTTP port `80`
- Target Group pointing to EC2 port `30080`
- Security Groups
- AWS Key Pair
- Local SSH private key file

The EC2 `user_data` script installs and configures:

- Docker Engine
- kubectl
- minikube
- Nginx static web app
- Kubernetes Deployment, Service, and HPA

## Prerequisites

Install and configure:

- Terraform `>= 1.6`
- AWS CLI
- An AWS account with permission to create EC2, ALB, Security Groups, and Key Pairs

Configure AWS credentials:

```powershell
aws configure
```

Verify the active account:

```powershell
aws sts get-caller-identity
```

## Quick Start

From the Terraform directory:

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\lab\challenge\terraform
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Get the application URL:

```powershell
terraform output alb_dns_name
```

Open the output URL in a browser.

## Configuration

Main variables are defined in `terraform/variables.tf`.

| Variable | Default | Description |
| --- | --- | --- |
| `aws_region` | `ap-southeast-1` | AWS region for the deployment |
| `project_name` | `w8-k8s-challenge` | Prefix for AWS resource names |
| `instance_type` | `t3.small` | EC2 instance type |
| `ssh_cidr` | `0.0.0.0/0` | CIDR allowed to SSH into EC2 |
| `node_port` | `30080` | Kubernetes NodePort targeted by ALB |

Recommended security improvement:

```hcl
ssh_cidr = "YOUR_PUBLIC_IP/32"
```

For a lab environment, `0.0.0.0/0` is convenient but less secure.

## How It Works

1. Terraform selects the default VPC, default subnets, and latest Ubuntu 22.04 AMI.
2. Terraform creates the ALB, Target Group, Listener, Security Groups, Key Pair, and EC2 instance.
3. EC2 runs `terraform/user-data.sh` on first boot.
4. `user-data.sh` installs Docker, kubectl, and minikube.
5. The script writes the app files and Kubernetes manifests into `/opt/w8-challenge`.
6. Docker builds the image `w8-k8s-challenge-web:local`.
7. minikube starts with Docker driver and publishes port `30080`.
8. The image is loaded into minikube.
9. Kubernetes applies Deployment, Service, and HPA.
10. ALB forwards public HTTP traffic to EC2 port `30080`.

Important minikube command:

```bash
minikube start --driver=docker --force --cpus=2 --memory=1800mb --ports=${node_port}:${node_port}
```

The `--ports=30080:30080` mapping is required because minikube runs inside Docker. It allows ALB traffic to reach the Kubernetes NodePort.

## Application

The app is a static HTML page served by Nginx.

`app/Dockerfile`:

```dockerfile
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

`app/nginx.conf` includes a health check endpoint:

```nginx
location /healthz {
    access_log off;
    return 200 "ok\n";
    add_header Content-Type text/plain;
}
```

The ALB Target Group and Kubernetes probes use `/healthz`.

## Kubernetes Resources

`k8s/deployment.yaml`

- Runs `restaurant-web`.
- Uses 2 replicas.
- Defines CPU and memory requests/limits.
- Uses readiness and liveness probes on `/healthz`.

`k8s/service.yaml`

- Exposes the app as `NodePort`.
- Uses `nodePort: 30080`.
- Routes traffic to container port `80`.

`k8s/hpa.yaml`

- Scales the Deployment from 2 to 5 replicas.
- Uses CPU target utilization of 70%.

## Verification

Check Terraform outputs:

```powershell
terraform output
```

Check the ALB URL:

```powershell
terraform output alb_dns_name
```

Check Target Group health:

```powershell
aws elbv2 describe-target-health `
  --target-group-arn <target-group-arn> `
  --region ap-southeast-1
```

SSH into EC2:

```powershell
ssh -i .\w8-k8s-challenge.pem ubuntu@<ec2-public-ip>
```

If Windows rejects the key permission:

```powershell
$me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
icacls .\w8-k8s-challenge.pem /inheritance:r
icacls .\w8-k8s-challenge.pem /grant:r "$($me):R"
```

Check Kubernetes from EC2:

```bash
sudo kubectl get nodes
sudo kubectl get deploy,rs,pods,svc,hpa -o wide
sudo curl http://127.0.0.1:30080/healthz
sudo cat /opt/w8-challenge/evidence.txt
```

Expected health check result:

```text
ok
```

## Troubleshooting

View EC2 bootstrap logs:

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
```

Check minikube:

```bash
sudo minikube status
```

Check Kubernetes workload:

```bash
sudo kubectl get pods -o wide
sudo kubectl describe pod <pod-name>
sudo kubectl logs <pod-name>
sudo kubectl get svc
```

If ALB returns `502 Bad Gateway`, check:

1. Target Group health status.
2. EC2 Security Group allows traffic from ALB SG to port `30080`.
3. minikube is running.
4. Service `restaurant-web` exposes NodePort `30080`.
5. Pods are `Running` and readiness probes pass.
6. `curl http://127.0.0.1:30080/healthz` returns `ok`.

## Evidence Checklist

Capture these screenshots for submission:

- Browser opens the app through ALB DNS.
- Target Group target is `healthy`.
- ALB Listener `HTTP :80` forwards to the Target Group.
- EC2 instance is running with type `t3.small`.
- `terraform output`.
- `kubectl get deploy,rs,pods,svc,hpa -o wide`.
- `curl http://127.0.0.1:30080/healthz` returns `ok`.

## Cleanup

Destroy AWS resources after the demo to avoid cost:

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\lab\challenge\terraform
terraform destroy
```

## Notes

- This project is designed for a lab challenge, not production.
- For production, prefer EKS, ECR, HTTPS with ACM, private subnets, stricter SSH access, and remote Terraform state with S3/DynamoDB.
- Do not commit `.pem`, `.tfstate`, `.tfvars`, `.terraform/`, or `tfplan*` files.
