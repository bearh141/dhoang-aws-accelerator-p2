# W8 Challenge - Terraform 1-click deploy Kubernetes app on AWS

## Mục tiêu

Dự án này triển khai một web app Nginx nhỏ lên Kubernetes chạy trên EC2, sau đó expose ra Internet bằng AWS Application Load Balancer.

Chỉ cần chạy Terraform:

```powershell
terraform apply
```

Terraform sẽ tạo hạ tầng AWS, còn EC2 `user_data` sẽ tự cài Docker, kubectl, minikube, build image và deploy app vào Kubernetes.

## Kiến trúc

```text
User Browser
  -> ALB HTTP :80
  -> Target Group
  -> EC2 :30080
  -> minikube Service NodePort
  -> Deployment
  -> Pod Nginx :80
```

Thành phần chính:

- `Terraform`: tạo AWS infrastructure bằng code.
- `EC2`: máy chạy Docker và minikube.
- `minikube`: Kubernetes cluster nhỏ dùng cho lab.
- `Docker`: build image web app.
- `Deployment`: giữ 2 Pod web luôn chạy.
- `Service NodePort`: expose app ở port `30080`.
- `HPA`: autoscale Deployment từ 2 đến 5 Pod khi CPU cao.
- `ALB`: public endpoint cho người dùng truy cập web.

## Cấu trúc thư mục

```text
cloud/w8/lab/challenge/
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

## Vì sao chọn các công nghệ này?

`Terraform`: phù hợp yêu cầu 1-click deploy vì mô tả hạ tầng bằng code, dễ tạo lại và dễ destroy.

`EC2 + minikube`: đơn giản cho lab, không cần tạo EKS phức tạp nhưng vẫn dùng Kubernetes object thật.

`t3.small`: `t3.micro` không đủ RAM/CPU để chạy minikube ổn định. `t3.small` có 2 vCPU và 2GB RAM, phù hợp hơn cho bài này.

`ALB`: cung cấp DNS public, listener HTTP :80, health check và forward request vào backend.

`NodePort 30080`: cho phép ALB forward request vào Kubernetes Service chạy trên EC2.

`Nginx Alpine`: nhẹ, nhanh, phù hợp serve static HTML và endpoint `/healthz`.

## Luồng triển khai

1. Terraform đọc provider và variable.
2. Terraform lấy default VPC, subnet và Ubuntu AMI.
3. Terraform tạo Security Group cho ALB và EC2.
4. Terraform tạo SSH key pair.
5. Terraform tạo EC2 `t3.small`.
6. EC2 chạy `user-data.sh`:
   - cài Docker, kubectl, minikube;
   - tạo file app và Kubernetes manifest trong `/opt/w8-challenge`;
   - build Docker image;
   - start minikube;
   - load image vào minikube;
   - apply Deployment, Service, HPA;
   - kiểm tra `/healthz`.
7. Terraform tạo ALB, Target Group và Listener.
8. ALB forward request HTTP :80 vào EC2 port `30080`.

## Giải thích code chính

### app/Dockerfile

```dockerfile
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

Image dùng Nginx Alpine để serve `index.html`. File `nginx.conf` tạo route `/` và `/healthz`.

### app/nginx.conf

```nginx
location /healthz {
    access_log off;
    return 200 "ok\n";
    add_header Content-Type text/plain;
}
```

`/healthz` trả HTTP 200 để ALB và Kubernetes probe biết app còn khỏe.

### k8s/deployment.yaml

Điểm chính:

- `replicas: 2`: chạy 2 Pod.
- `selector.matchLabels`: Deployment quản lý Pod có label `app=restaurant-web`.
- `imagePullPolicy: IfNotPresent`: dùng image local đã load vào minikube.
- `resources.requests.cpu`: cần cho HPA tính CPU utilization.
- `readinessProbe`: Pod chỉ nhận traffic khi ready.
- `livenessProbe`: container lỗi sẽ được restart.

### k8s/service.yaml

```yaml
type: NodePort
nodePort: 30080
```

Service expose app ra port `30080` trên Kubernetes node. ALB Target Group trỏ vào port này.

### k8s/hpa.yaml

```yaml
minReplicas: 2
maxReplicas: 5
averageUtilization: 70
```

HPA scale Deployment từ 2 đến 5 Pod nếu CPU trung bình vượt 70%.

### terraform/versions.tf

Khai báo Terraform version và provider:

- `aws`: tạo AWS resource.
- `tls`: tạo SSH key.
- `local`: ghi private key `.pem` ra máy local.

### terraform/main.tf

Khai báo AWS provider, lấy default VPC/subnet và Ubuntu AMI mới nhất.

### terraform/security-groups.tf

- ALB SG: mở HTTP port 80 từ Internet.
- EC2 SG: chỉ cho ALB SG vào port `30080`, và mở SSH port 22 để debug.

Best practice cần nhớ: khi nộp thật nên giới hạn `ssh_cidr` về IP cá nhân `/32`, không nên để `0.0.0.0/0`.

### terraform/ec2.tf

Tạo EC2 và truyền `user-data.sh` vào máy:

```hcl
user_data = templatefile("${path.module}/user-data.sh", {
  node_port = var.node_port
})
```

`user_data_replace_on_change = true` giúp EC2 được tạo lại nếu bootstrap script thay đổi.

### terraform/alb.tf

Tạo ALB public, Target Group port `30080`, health check `/healthz`, và Listener HTTP :80 forward tới Target Group.

### terraform/user-data.sh

Script bootstrap chính. Dòng quan trọng:

```bash
minikube start --driver=docker --force --cpus=2 --memory=1800mb --ports=${node_port}:${node_port}
```

`--ports=30080:30080` rất quan trọng vì minikube chạy bằng Docker driver. Port này giúp ALB gọi vào EC2 port 30080 và đi được vào Kubernetes NodePort.

## Cách chạy

Yêu cầu:

- AWS CLI đã cấu hình bằng `aws configure`.
- Terraform đã cài.
- AWS account có quyền tạo EC2, ALB, Security Group, Key Pair.

Chạy:

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\lab\challenge\terraform
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Lấy URL:

```powershell
terraform output alb_dns_name
```

Mở URL đó trên browser.

## Cách kiểm tra

Kiểm tra Terraform output:

```powershell
terraform output
```

Kiểm tra ALB health:

```powershell
aws elbv2 describe-target-health `
  --target-group-arn <target-group-arn> `
  --region ap-southeast-1
```

SSH vào EC2:

```powershell
ssh -i .\w8-k8s-challenge.pem ubuntu@<ec2-public-ip>
```

Kiểm tra Kubernetes trên EC2:

```bash
sudo kubectl get nodes
sudo kubectl get deploy,rs,pods,svc,hpa -o wide
sudo curl http://127.0.0.1:30080/healthz
sudo cat /opt/w8-challenge/evidence.txt
```

Kiểm tra log bootstrap nếu lỗi:

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
```

## Evidence cần chụp

- Browser mở được web qua ALB DNS.
- Target Group hiển thị `healthy`.
- ALB Listener HTTP :80 forward tới Target Group.
- EC2 running, type `t3.small`.
- `terraform output`.
- `kubectl get deploy,rs,pods,svc,hpa -o wide`.
- `curl http://127.0.0.1:30080/healthz` trả `ok`.

## Câu hỏi vấn đáp cốt lõi

**Vì sao gọi là 1-click deploy?**

Vì chỉ cần chạy `terraform apply`, hạ tầng AWS và workload Kubernetes được tạo tự động. Không cần SSH vào EC2 để cài tay.

**Vì sao dùng ALB?**

ALB là public entrypoint, nhận HTTP request từ Internet và forward tới backend EC2. ALB cũng có health check để chỉ gửi traffic tới target healthy.

**Vì sao dùng NodePort?**

Vì app chạy trong Kubernetes, còn ALB cần forward vào một port trên EC2. NodePort `30080` là cầu nối từ EC2 vào Service trong cluster.

**Vì sao cần `/healthz`?**

`/healthz` cho phép ALB và Kubernetes kiểm tra app có đang sống không. Nếu trả 200 thì backend healthy.

**Vì sao t3.micro bị lỗi?**

Minikube cần khoảng 2 CPU và 1800MB RAM. `t3.micro` không đủ tài nguyên nên cluster không start ổn định, dẫn tới ALB 502.

**Nếu ALB trả 502 thì debug thế nào?**

Kiểm tra theo thứ tự: Target Group health, Security Group, EC2 port 30080, `minikube status`, `kubectl get pods`, `kubectl logs`, và `/var/log/cloud-init-output.log`.

**HPA hoạt động dựa vào gì?**

HPA đọc CPU metrics từ metrics-server và so sánh với CPU request của Pod. Nếu CPU trung bình vượt 70%, HPA tăng số replica.

## Dọn tài nguyên

Sau khi demo xong, chạy:

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\lab\challenge\terraform
terraform destroy
```

Lệnh này xóa các tài nguyên AWS để tránh phát sinh chi phí.
