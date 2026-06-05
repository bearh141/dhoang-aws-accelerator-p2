# W8 Kubernetes trên AWS - Terraform 1-Click Deploy

Triển khai một ứng dụng web Nginx nhẹ lên Kubernetes cluster chạy trên EC2 instance, sau đó public ứng dụng ra Internet thông qua AWS Application Load Balancer.

Mục tiêu của project này là mô phỏng một quy trình DevOps end-to-end đơn giản:

```text
Terraform -> AWS infrastructure -> EC2 bootstrap -> Docker image -> Kubernetes workload -> ALB public access
```

## Kiến trúc

```text
User Browser
  -> Application Load Balancer HTTP :80
  -> Target Group
  -> EC2 :30080
  -> minikube Service NodePort
  -> Deployment
  -> Nginx Pods :80
```

Các thành phần chính:

* `Terraform`: tạo và quản lý hạ tầng AWS.
* `EC2`: chạy Docker và minikube.
* `Docker`: build local web image.
* `minikube`: chạy một Kubernetes cluster single-node trên EC2.
* `Deployment`: đảm bảo web app luôn chạy với 2 replicas.
* `Service`: expose app thông qua NodePort `30080`.
* `HPA`: tự động scale Deployment từ 2 đến 5 Pods dựa trên CPU.
* `ALB`: expose app ra Internet thông qua public DNS name.

Các sơ đồ kiến trúc:

* `aws-k8s-challenge.drawio`
* `aws-k8s-challenge-aws-style.drawio`

## Cấu trúc Repository

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

## Những tài nguyên được tạo

Terraform sẽ tạo:

* EC2 instance
* Application Load Balancer
* ALB Listener trên HTTP port `80`
* Target Group trỏ đến EC2 port `30080`
* Security Groups
* AWS Key Pair
* File SSH private key ở local

Script EC2 `user_data` sẽ cài đặt và cấu hình:

* Docker Engine
* kubectl
* minikube
* Nginx static web app
* Kubernetes Deployment, Service và HPA

## Điều kiện cần có

Cài đặt và cấu hình:

* Terraform `>= 1.6`
* AWS CLI
* AWS account có quyền tạo EC2, ALB, Security Groups và Key Pairs

Cấu hình AWS credentials:

```powershell
aws configure
```

Kiểm tra account AWS đang sử dụng:

```powershell
aws sts get-caller-identity
```

## Chạy nhanh

Đi đến thư mục Terraform:

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\lab\challenge\terraform
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Lấy URL của ứng dụng:

```powershell
terraform output alb_dns_name
```

Mở URL output trên trình duyệt.

## Cấu hình

Các biến chính được định nghĩa trong file `terraform/variables.tf`.

| Variable        | Default            | Mô tả                                 |
| --------------- | ------------------ | ------------------------------------- |
| `aws_region`    | `ap-southeast-1`   | AWS region dùng để deploy             |
| `project_name`  | `w8-k8s-challenge` | Prefix cho tên các AWS resource       |
| `instance_type` | `t3.small`         | Loại EC2 instance                     |
| `ssh_cidr`      | `0.0.0.0/0`        | CIDR được phép SSH vào EC2            |
| `node_port`     | `30080`            | Kubernetes NodePort mà ALB sẽ trỏ tới |

Khuyến nghị cải thiện bảo mật:

```hcl
ssh_cidr = "YOUR_PUBLIC_IP/32"
```

Trong môi trường lab, `0.0.0.0/0` tiện hơn nhưng kém an toàn hơn.

## Cách hoạt động

1. Terraform lấy default VPC, default subnets và Ubuntu 22.04 AMI mới nhất.
2. Terraform tạo ALB, Target Group, Listener, Security Groups, Key Pair và EC2 instance.
3. EC2 chạy script `terraform/user-data.sh` trong lần boot đầu tiên.
4. `user-data.sh` cài Docker, kubectl và minikube.
5. Script ghi các file app và Kubernetes manifests vào `/opt/w8-challenge`.
6. Docker build image `w8-k8s-challenge-web:local`.
7. minikube khởi động với Docker driver và publish port `30080`.
8. Image được load vào minikube.
9. Kubernetes apply Deployment, Service và HPA.
10. ALB forward public HTTP traffic đến EC2 port `30080`.

Lệnh minikube quan trọng:

```bash
minikube start --driver=docker --force --cpus=2 --memory=1800mb --ports=${node_port}:${node_port}
```

Phần mapping `--ports=30080:30080` là bắt buộc vì minikube chạy bên trong Docker. Nó cho phép traffic từ ALB đi vào Kubernetes NodePort.

## Ứng dụng

App là một trang HTML tĩnh được serve bằng Nginx.

`app/Dockerfile`:

```dockerfile
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

`app/nginx.conf` có health check endpoint:

```nginx
location /healthz {
    access_log off;
    return 200 "ok\n";
    add_header Content-Type text/plain;
}
```

ALB Target Group và Kubernetes probes đều sử dụng `/healthz`.

## Kubernetes Resources

`k8s/deployment.yaml`

* Chạy `restaurant-web`.
* Sử dụng 2 replicas.
* Định nghĩa CPU và memory requests/limits.
* Sử dụng readiness probe và liveness probe tại `/healthz`.

`k8s/service.yaml`

* Expose app dưới dạng `NodePort`.
* Sử dụng `nodePort: 30080`.
* Route traffic đến container port `80`.

`k8s/hpa.yaml`

* Scale Deployment từ 2 đến 5 replicas.
* Sử dụng CPU target utilization là 70%.

## Kiểm tra

Kiểm tra Terraform outputs:

```powershell
terraform output
```

Kiểm tra ALB URL:

```powershell
terraform output alb_dns_name
```

Kiểm tra trạng thái Target Group:

```powershell
aws elbv2 describe-target-health `
  --target-group-arn <target-group-arn> `
  --region ap-southeast-1
```

SSH vào EC2:

```powershell
ssh -i .\w8-k8s-challenge.pem ubuntu@<ec2-public-ip>
```

Nếu Windows báo lỗi quyền của key:

```powershell
$me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
icacls .\w8-k8s-challenge.pem /inheritance:r
icacls .\w8-k8s-challenge.pem /grant:r "$($me):R"
```

Kiểm tra Kubernetes từ EC2:

```bash
sudo kubectl get nodes
sudo kubectl get deploy,rs,pods,svc,hpa -o wide
sudo curl http://127.0.0.1:30080/healthz
sudo cat /opt/w8-challenge/evidence.txt
```

Kết quả health check mong đợi:

```text
ok
```

## Xử lý lỗi

Xem log bootstrap của EC2:

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
```

Kiểm tra minikube:

```bash
sudo minikube status
```

Kiểm tra Kubernetes workload:

```bash
sudo kubectl get pods -o wide
sudo kubectl describe pod <pod-name>
sudo kubectl logs <pod-name>
sudo kubectl get svc
```

Nếu ALB trả về lỗi `502 Bad Gateway`, hãy kiểm tra:

1. Trạng thái health của Target Group.
2. Security Group của EC2 có cho phép traffic từ ALB SG vào port `30080` không.
3. minikube có đang chạy không.
4. Service `restaurant-web` có expose NodePort `30080` không.
5. Pods có ở trạng thái `Running` và readiness probes có pass không.
6. Lệnh `curl http://127.0.0.1:30080/healthz` có trả về `ok` không.

## Evidence Checklist

Cần chụp các ảnh sau để nộp bài:

* Browser mở được app thông qua ALB DNS.
* Target trong Target Group ở trạng thái `healthy`.
* ALB Listener `HTTP :80` forward đến Target Group.
* EC2 instance đang chạy với type `t3.small`.
* Kết quả `terraform output`.
* Kết quả `kubectl get deploy,rs,pods,svc,hpa -o wide`.
* Kết quả `curl http://127.0.0.1:30080/healthz` trả về `ok`.

## Cleanup

Xóa AWS resources sau khi demo để tránh phát sinh chi phí:

```powershell
terraform destroy
```

## Ghi chú

* Project này được thiết kế cho lab challenge, không phải môi trường production.
* Với production, nên dùng EKS, ECR, HTTPS với ACM, private subnets, giới hạn SSH chặt hơn, và remote Terraform state với S3/DynamoDB.
* Không commit các file `.pem`, `.tfstate`, `.tfvars`, `.terraform/`, hoặc `tfplan*`.
