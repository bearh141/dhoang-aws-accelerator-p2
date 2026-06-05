# Challenge - K8s on AWS bằng Terraform 1-Click

## 1. Challenge yêu cầu gì?

Đề bài mentor đưa:

```text
Dựng 1 EC2 bằng Terraform, bật minikube hoặc kind trong đó,
deploy một app nhỏ trong Kubernetes, expose app ra Internet qua ALB.
Toàn bộ phải là 1-click automation từ Terraform và dùng >=2 providers.
```

Acceptance:

- Một flow từ repo sạch có thể dựng app chạy được.
- App thật sự chạy trong Kubernetes, không cài thẳng lên EC2.
- App truy cập được từ Internet qua ALB.
- Có dùng ít nhất 2 Terraform providers.
- Có README giải thích kiến trúc, lệnh chạy, cách wire provider.
- Có evidence URL ALB mở được app.
- `terraform destroy` dọn được sạch.

### Cách hiểu đề bằng lời của mình

Đề không chỉ yêu cầu “chạy được một web trên EC2”. Nếu chỉ SSH vào EC2 rồi cài Nginx trực tiếp thì **không đạt**, vì app phải chạy trong Kubernetes.

Điều cần chứng minh là:

```text
Terraform tạo hạ tầng AWS
EC2 chạy một Kubernetes cluster local
App chạy dưới dạng Pod trong Kubernetes
Service expose Pod qua NodePort
ALB route traffic Internet vào NodePort đó
```

Nói ngắn gọn khi vấn đáp:

```text
Em dùng Terraform để dựng AWS infrastructure, dùng EC2 làm host chạy minikube,
deploy một Nginx static app vào Kubernetes, expose bằng NodePort Service,
rồi dùng ALB forward traffic vào NodePort trên EC2.
```

---

## 2. App dùng cho challenge

Dùng một static HTML app tự tạo, chạy bằng Nginx.

Lý do chọn app nhỏ:

- Đúng yêu cầu đề: app đơn giản, nhỏ nhẹ.
- Không phụ thuộc database, secret, payment, email hoặc service bên ngoài.
- Dễ build Docker image.
- Dễ deploy vào Kubernetes.
- Dễ expose qua NodePort và ALB.
- Có endpoint `/healthz` để ALB health check.

App nằm ở:

```text
cloud/w8/lab/challenge/app/
```

File chính:

- `Dockerfile`
- `nginx.conf`
- `index.html`

---

## 3. Kiến trúc đề xuất

Kiến trúc tối giản:

```text
Internet
  |
  v
AWS ALB
  |
  v
Target Group -> EC2 instance:NodePort
  |
  v
minikube/kind on EC2
  |
  v
Kubernetes Service -> Deployment -> Pod nginx serving a lightweight static challenge app
```

### Luồng request từ browser đến Pod

Khi người dùng mở URL ALB:

```text
Browser
  -> ALB DNS port 80
  -> ALB Listener :80
  -> Target Group
  -> EC2 private IP port 30080
  -> Kubernetes NodePort Service restaurant-web
  -> Pod label app=restaurant-web
  -> Nginx container port 80
  -> index.html
```

Giải thích từng tầng:

- **ALB** nhận traffic HTTP từ Internet.
- **Listener** là rule trên ALB, nghe port 80.
- **Target Group** chứa EC2 instance và port app cần forward tới.
- **EC2** là máy chạy Docker + minikube.
- **NodePort Service** mở một port cố định trên node, ví dụ `30080`.
- **Deployment** đảm bảo luôn có số Pod mong muốn.
- **Pod** chạy container Nginx serve static HTML.

### Vì sao cần ALB?

Đề yêu cầu app truy cập được từ Internet qua ALB. ALB giúp:

- Có endpoint public ổn định hơn public IP EC2.
- Health check target.
- Forward traffic theo listener/rule.
- Gần với kiến trúc production hơn so với mở thẳng EC2 port ra Internet.

### Vì sao dùng NodePort?

Vì cluster minikube/kind chạy bên trong một EC2 đơn lẻ. Để ALB bên ngoài cluster gọi được app, cần có một port mở trên EC2 host.

NodePort làm việc này:

```text
EC2:30080 -> Service -> Pod:80
```

Trong challenge này, NodePort cố định là `30080` để Terraform Target Group biết forward vào port nào.

Terraform sẽ tạo:

- VPC hoặc dùng default VPC.
- Security Group cho ALB.
- Security Group cho EC2.
- EC2 instance.
- ALB.
- Target Group.
- Listener port 80.
- User data script để cài Docker, kubectl, minikube/kind.
- Build/pull image và apply Kubernetes manifest.

---

## 4. Providers nên dùng

Để đạt yêu cầu `>=2 providers`, dùng:

1. `hashicorp/aws`
   - Tạo EC2, Security Group, ALB, Target Group.

2. Một provider thứ hai, chọn một trong các hướng:

### Hướng A - `hashicorp/local`

Dùng để render file local như kube manifest hoặc helper script.

Ưu điểm:

- Dễ làm.
- Ít rủi ro.
- Chứng minh được wire nhiều providers.

Nhược điểm:

- Provider thứ hai chưa trực tiếp deploy vào Kubernetes.

### Hướng B - `hashicorp/null`

Dùng `null_resource` + provisioner để chạy script remote/local.

Ưu điểm:

- Dễ orchestration demo.
- Hay dùng trong lab.

Nhược điểm:

- Không phải pattern production đẹp.

### Hướng C - `hashicorp/kubernetes`

Dùng Kubernetes provider để tạo Deployment/Service sau khi EC2/minikube sẵn sàng.

Ưu điểm:

- Đúng tinh thần wire provider khác.
- Terraform quản lý cả AWS infra và K8s resources.

Nhược điểm:

- Khó hơn vì phải lấy kubeconfig từ EC2/minikube.
- Dễ phát sinh ordering/networking issue.

Khuyến nghị cho bản đầu:

```text
aws + local/null
```

Sau khi chạy ổn, nếu còn thời gian thì nâng cấp sang:

```text
aws + kubernetes
```

### Vì sao đề yêu cầu >=2 providers?

Terraform provider là plugin để Terraform nói chuyện với một hệ thống/API.

Nếu chỉ dùng provider `aws`, Terraform chỉ chứng minh được phần AWS infrastructure.

Khi dùng thêm provider khác, bạn chứng minh được khả năng “wire provider”:

- AWS provider tạo hạ tầng.
- Local/null/kubernetes provider xử lý phần ngoài AWS API.

Trong vấn đáp có thể nói:

```text
Provider aws dùng để tạo EC2, SG, ALB, Target Group.
Provider local hoặc null dùng để render/copy/bootstrap file phục vụ triển khai app.
Nếu nâng cấp, có thể dùng Kubernetes provider để quản lý Deployment/Service trực tiếp.
```

### Vì sao chưa chọn Kubernetes provider ngay?

Kubernetes provider cần kubeconfig/API endpoint của cluster. Với minikube chạy bên trong EC2, kubeconfig nằm trên EC2 và API server không tự nhiên expose an toàn ra máy chạy Terraform.

Vì vậy bản đầu dùng user data hoặc provisioner để bootstrap app trong EC2 sẽ đơn giản và ổn định hơn cho challenge.

Nếu mentor hỏi “production có làm vậy không?”, trả lời:

```text
Không hẳn. Đây là lab để chứng minh concept. Production nên dùng EKS hoặc cluster chuẩn,
kết hợp Kubernetes provider/Helm/GitOps thay vì minikube trên EC2.
```

---

## 5. Cấu trúc thư mục nên tạo

Đề xuất tạo trong repo học:

```text
cloud/w8/lab/challenge/
  README.md
  terraform/
    versions.tf
    variables.tf
    main.tf
    security-groups.tf
    alb.tf
    ec2.tf
    outputs.tf
    user-data.sh
  app/
    Dockerfile
    nginx.conf
    index.html
  k8s/
    deployment.yaml
    service.yaml
    hpa.yaml
```

---

## 6. App Dockerfile

Tạo:

```text
cloud/w8/lab/challenge/app/Dockerfile
```

Nội dung:

```dockerfile
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

### Giải thích Dockerfile

```dockerfile
FROM nginx:1.27-alpine
```

Dùng Nginx làm base image vì app chỉ là static HTML. Bản `alpine` nhẹ hơn image Linux đầy đủ, phù hợp app demo.

```dockerfile
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

Copy cấu hình Nginx của mình vào vị trí default server config. Cấu hình này có route `/` và `/healthz`.

```dockerfile
COPY index.html /usr/share/nginx/html/index.html
```

Copy trang HTML vào thư mục Nginx serve static file.

```dockerfile
EXPOSE 80
```

Ghi chú container lắng nghe port 80. `EXPOSE` không tự mở port ra host; nó chỉ là metadata. Khi chạy Docker local cần `-p`, khi chạy Kubernetes cần Service.

Tạo:

```text
cloud/w8/lab/challenge/app/nginx.conf
```

Nội dung:

```nginx
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /healthz {
        access_log off;
        return 200 "ok\n";
        add_header Content-Type text/plain;
    }
}
```

### Giải thích nginx.conf

```nginx
listen 80;
```

Nginx lắng nghe HTTP port 80 trong container.

```nginx
root /usr/share/nginx/html;
index index.html;
```

Nginx serve file static từ thư mục đã copy `index.html`.

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

Nếu user truy cập một path không có file thật, Nginx trả về `index.html`. Cách này phù hợp với single-page app và cũng không hại cho static demo.

```nginx
location /healthz {
    return 200 "ok\n";
}
```

Endpoint health check cho Kubernetes probes và ALB Target Group. ALB gọi `/healthz`, nếu nhận HTTP 200 thì xem target healthy.

Build image local để test:

```powershell
cd .\cloud\w8\lab\challenge\app
docker build -t w8-k8s-challenge-web:local .
docker run -d --name w8-web-test -p 8088:80 w8-k8s-challenge-web:local
```

### Giải thích lệnh Docker local

```powershell
docker build -t w8-k8s-challenge-web:local .
```

Build Docker image từ Dockerfile trong thư mục hiện tại.

- `-t`: đặt tag cho image.
- `w8-k8s-challenge-web`: tên image.
- `local`: tag version local.
- `.`: build context là thư mục hiện tại.

```powershell
docker run -d --name w8-web-test -p 8088:80 w8-k8s-challenge-web:local
```

Chạy container test.

- `-d`: chạy background.
- `--name w8-web-test`: đặt tên container để dễ xóa.
- `-p 8088:80`: map port máy host 8088 vào port container 80.
- `w8-k8s-challenge-web:local`: image cần chạy.

Nếu mở `http://localhost:8088` thấy trang app, nghĩa là image hoạt động trước khi đưa vào Kubernetes.

Mở:

```text
http://localhost:8088
```

Dọn test:

```powershell
docker rm -f w8-web-test
```

---

## 7. Kubernetes manifests

### `deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: restaurant-web
  labels:
    app: restaurant-web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: restaurant-web
  template:
    metadata:
      labels:
        app: restaurant-web
    spec:
      containers:
        - name: web
          image: w8-k8s-challenge-web:local
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "256Mi"
          readinessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
```

### Giải thích Deployment

```yaml
kind: Deployment
```

Deployment dùng để quản lý Pod replicas, rollout và self-healing. Ta không tạo Pod trần vì Pod trần bị xóa là mất luôn.

```yaml
replicas: 2
```

Mong muốn luôn có 2 Pod chạy. Nếu một Pod chết, ReplicaSet tạo Pod mới.

```yaml
selector:
  matchLabels:
    app: restaurant-web
```

Deployment dùng selector này để biết Pod nào thuộc quyền quản lý của nó.

```yaml
template:
  metadata:
    labels:
      app: restaurant-web
```

Pod do Deployment tạo ra sẽ có label `app=restaurant-web`. Label này phải khớp selector.

```yaml
image: w8-k8s-challenge-web:local
```

Pod chạy image app mình build.

```yaml
imagePullPolicy: IfNotPresent
```

Nếu image đã có trên node thì dùng image local, không cố pull từ Docker Hub. Điều này quan trọng vì image `w8-k8s-challenge-web:local` là image local.

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

Requests giúp scheduler biết Pod cần tối thiểu bao nhiêu tài nguyên. Limits đặt trần để Pod không ăn quá nhiều CPU/RAM. HPA cũng cần CPU requests để tính phần trăm CPU utilization.

```yaml
readinessProbe:
```

Kiểm tra Pod đã sẵn sàng nhận traffic chưa. Nếu fail, Service không route traffic tới Pod đó.

```yaml
livenessProbe:
```

Kiểm tra container còn sống không. Nếu fail, Kubernetes restart container.

### `service.yaml`

Để ALB target vào EC2 NodePort, nên cố định NodePort:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: restaurant-web
spec:
  type: NodePort
  selector:
    app: restaurant-web
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30080
```

### Giải thích Service

```yaml
type: NodePort
```

Service mở một port trên node EC2. ALB sẽ forward traffic vào port này.

```yaml
selector:
  app: restaurant-web
```

Service tìm Pod có label `app=restaurant-web`.

```yaml
port: 80
targetPort: 80
nodePort: 30080
```

Ý nghĩa:

```text
Service port 80 -> Pod targetPort 80
Node EC2 port 30080 -> Service -> Pod 80
```

`nodePort: 30080` được cố định để Terraform Target Group trỏ đúng port.

### `hpa.yaml`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: restaurant-web
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: restaurant-web
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### Giải thích HPA

```yaml
kind: HorizontalPodAutoscaler
```

HPA tự động tăng/giảm số replicas theo metric.

```yaml
scaleTargetRef:
  kind: Deployment
  name: restaurant-web
```

HPA scale Deployment `restaurant-web`.

```yaml
minReplicas: 2
maxReplicas: 5
```

Số Pod thấp nhất là 2, cao nhất là 5.

```yaml
averageUtilization: 70
```

Khi CPU trung bình vượt khoảng 70% so với CPU requests, HPA có thể tăng replicas.

Điều kiện cần:

- Metrics server đang chạy.
- Pod có CPU requests.

---

## 8. Terraform AWS skeleton

### `versions.tf`

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
```

### Giải thích versions.tf

```hcl
required_version = ">= 1.6.0"
```

Đảm bảo Terraform CLI đủ mới.

```hcl
aws = {
  source  = "hashicorp/aws"
  version = "~> 5.0"
}
```

Khai báo AWS provider để tạo EC2, Security Group, ALB.

```hcl
local = {
  source  = "hashicorp/local"
  version = "~> 2.5"
}
```

Khai báo provider thứ hai để đạt yêu cầu multi-provider và có thể render/copy file local phục vụ bootstrap.

`~> 5.0` nghĩa là dùng provider AWS dòng 5.x, không tự nhảy lên 6.x. Việc pin version giúp tránh breaking changes.

### `variables.tf`

```hcl
variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "project_name" {
  type    = string
  default = "w8-k8s-challenge"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name for SSH"
}
```

### Giải thích variables.tf

```hcl
aws_region
```

Region AWS để tạo tài nguyên. Với Việt Nam, `ap-southeast-1` Singapore là lựa chọn gần và phổ biến.

```hcl
project_name
```

Dùng cho naming/tagging resource.

```hcl
instance_type
```

Loại EC2. Với Docker + minikube, nên dùng `t3.medium` nếu budget/lab cho phép. `t3.micro` có thể yếu.

```hcl
key_name
```

Tên EC2 key pair đã có sẵn, dùng để SSH vào EC2 nếu cần debug.

### `main.tf`

```hcl
provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

### Giải thích data sources

```hcl
data "aws_vpc" "default" {
  default = true
}
```

Đọc default VPC hiện có trong region. Dùng data source vì ta không tạo VPC mới ở bản đơn giản.

```hcl
data "aws_subnets" "default"
```

Đọc các subnet thuộc default VPC để ALB/EC2 dùng.

```hcl
data "aws_ami" "ubuntu"
```

Tìm Ubuntu AMI mới nhất. Không hard-code AMI ID vì AMI ID thay đổi theo region và thời gian.

Lưu ý khi vấn đáp:

```text
data source chỉ đọc resource/thông tin có sẵn, không tạo mới.
resource mới là thứ Terraform tạo/quản lý.
```

### Security Group idea

EC2 SG cần mở:

- SSH 22 từ IP của bạn.
- NodePort 30080 từ ALB SG.

ALB SG cần mở:

- HTTP 80 từ Internet.

### Vì sao tách SG cho ALB và EC2?

Tách Security Group giúp kiểm soát rõ luồng traffic:

```text
Internet -> ALB SG :80
ALB SG -> EC2 SG :30080
SSH IP của mình -> EC2 SG :22
```

EC2 không cần mở NodePort `30080` cho cả Internet. Chỉ ALB SG được gọi vào NodePort. Đây là nguyên tắc giảm bề mặt tấn công.

### Target Group idea

Target group:

- Protocol: HTTP.
- Port: `30080`.
- Target type: instance.
- Health check path: `/healthz`.

ALB listener:

- Port 80 -> forward target group.

### Vì sao Target Group port là 30080?

Vì Kubernetes Service dùng `type: NodePort` và cố định:

```yaml
nodePort: 30080
```

ALB không biết Pod IP bên trong minikube. ALB chỉ biết EC2 instance. Do đó ALB target vào:

```text
EC2 instance port 30080
```

Kubernetes NodePort nhận traffic ở đó và route tiếp vào Pod.

---

## 9. User data flow trên EC2

`user-data.sh` nên làm:

```bash
#!/usr/bin/env bash
set -euxo pipefail

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

# Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Start minikube with docker driver
minikube start --driver=docker --force

# Enable metrics for HPA
minikube addons enable metrics-server
```

### Giải thích user data

User data là script EC2 chạy khi instance boot lần đầu.

Mình dùng user data để tự động hóa:

- Cài Docker.
- Cài kubectl.
- Cài minikube.
- Start minikube.
- Bật metrics-server.
- Chuẩn bị app/K8s manifests.

Điểm này giúp challenge gần với “1-click”: sau `terraform apply`, EC2 tự bootstrap thay vì bạn SSH vào làm tay.

### Vì sao cài Docker trước?

minikube dùng Docker driver, nên Docker phải chạy trước:

```text
Docker -> minikube -> Kubernetes -> Pod
```

### Vì sao dùng `minikube start --driver=docker --force`?

Trên EC2, script chạy bằng root trong user data. minikube thường cảnh báo khi chạy root, nên `--force` cho phép tiếp tục trong lab.

Trong production không nên dùng minikube kiểu này; production nên dùng EKS hoặc cluster chuẩn.

### Vì sao bật metrics-server?

HPA cần metrics-server để đọc CPU/memory metrics.

Nếu không bật metrics-server:

```powershell
kubectl get hpa
```

có thể thấy target CPU là `<unknown>`.

Sau đó cần build/load image và apply manifest.

Có 2 hướng:

### Hướng đơn giản cho EC2

Copy source app lên EC2 bằng provisioner hoặc user data, rồi:

```bash
docker build -t w8-k8s-challenge-web:local /opt/restaurant-app
minikube image load w8-k8s-challenge-web:local
kubectl apply -f /opt/k8s/deployment.yaml
kubectl apply -f /opt/k8s/service.yaml
kubectl apply -f /opt/k8s/hpa.yaml
```

Giải thích:

```bash
docker build -t w8-k8s-challenge-web:local /opt/restaurant-app
```

Build image app trên EC2.

```bash
minikube image load w8-k8s-challenge-web:local
```

Đưa image local vào image store của minikube để Pod dùng được.

```bash
kubectl apply -f /opt/k8s/deployment.yaml
```

Tạo Deployment.

```bash
kubectl apply -f /opt/k8s/service.yaml
```

Tạo NodePort Service port `30080`.

```bash
kubectl apply -f /opt/k8s/hpa.yaml
```

Tạo autoscaler.

### Hướng sạch hơn

Build image local/CI, push lên ECR, sau đó Deployment dùng ECR image.

Hướng này production hơn nhưng mất thêm thời gian:

```text
Docker build -> ECR push -> EC2/minikube pull image from ECR
```

Với challenge nhanh, có thể dùng hướng đơn giản.

---

## 10. Các bước làm khuyến nghị

### Phase 1 - Chạy local trước

1. Tạo static app trong `challenge/app/index.html`.
2. Tạo Dockerfile Nginx.
3. Build image local.
4. Test bằng `docker run`.
5. Load image vào minikube local.
6. Apply Deployment/Service/HPA.
7. Truy cập bằng `minikube service` hoặc `port-forward`.

Lệnh local:

```powershell
cd .\cloud\w8\lab\challenge\app
docker build -t w8-k8s-challenge-web:local .
minikube image load w8-k8s-challenge-web:local
kubectl apply -f ..\k8s\deployment.yaml
kubectl apply -f ..\k8s\service.yaml
kubectl apply -f ..\k8s\hpa.yaml
kubectl get deploy,svc,hpa,pods
```

### Vì sao phải test local trước?

Nếu app chưa chạy được local thì đưa lên AWS sẽ khó debug hơn nhiều.

Test local giúp tách vấn đề:

- Docker image có build được không?
- Nginx có serve app không?
- `/healthz` có trả 200 không?
- Kubernetes manifest có đúng không?
- Service có route vào Pod không?

Khi local đã ổn, lỗi trên AWS thường nằm ở:

- Security Group.
- ALB Target Group.
- User data.
- EC2 bootstrap.

### Phase 2 - Terraform dựng AWS infra

1. Viết Terraform tạo EC2 + ALB.
2. User data cài Docker/kubectl/minikube.
3. Deploy app vào K8s trên EC2.
4. ALB target vào EC2 port `30080`.
5. Output ALB DNS.

### Phase 3 - Evidence

Ghi lại:

```powershell
terraform apply
terraform output alb_dns_name
```

Mở:

```text
http://<alb_dns_name>
```

Evidence cần có:

- Screenshot ALB URL mở được static challenge app.
- `kubectl get pods` trên EC2.
- `kubectl get svc`.
- `kubectl get hpa`.
- README giải thích kiến trúc.

---

## 11. README cần nộp

README challenge nên có:

```markdown
# K8s on AWS - Terraform 1-Click

## Architecture

Internet -> ALB -> EC2 NodePort 30080 -> minikube Service -> Deployment -> Pod

## App

Lightweight static HTML app served by Nginx.

## Providers

- aws: create EC2, Security Groups, ALB, Target Group, Listener
- local/null: render/copy helper files and orchestrate bootstrap

## How to run

terraform init
terraform plan -var="key_name=<your-key>"
terraform apply -var="key_name=<your-key>"

## Outputs

alb_dns_name = ...

## Evidence

- ALB URL screenshot
- kubectl get pods
- kubectl get svc
- kubectl get hpa

## Cleanup

terraform destroy -var="key_name=<your-key>"
```

### Khi vấn đáp nên giải thích README thế nào?

README là tài liệu để trainer có thể dựng lại app từ repo sạch.

Nếu README thiếu lệnh chạy hoặc thiếu biến cần truyền, trainer không reproduce được thì bài bị yếu.

README nên trả lời:

- Kiến trúc là gì?
- App chạy ở đâu?
- Terraform tạo những gì?
- Providers nào được dùng?
- Chạy lệnh nào?
- Output nào là URL app?
- Dọn tài nguyên bằng lệnh nào?

---

## 12. Rủi ro cần để ý

- ALB health check phải trỏ đúng path `/healthz`.
- EC2 SG phải cho ALB SG vào port `30080`.
- Docker/minikube cài lâu, EC2 cần vài phút mới healthy.
- `t3.micro` có thể yếu cho Docker + minikube; nên dùng `t3.medium` nếu lab cho phép.
- Nhớ destroy để tránh tốn tiền.
- Nếu dùng default VPC, phải chắc region có default subnets.

---

## 13. Việc bạn nên làm ngay

1. Tạo folder `cloud/w8/lab/challenge`.
2. Tạo Dockerfile + nginx.conf.
3. Test Docker local.
4. Tạo Deployment/Service/HPA YAML.
5. Test trên minikube local.
6. Sau khi local ổn mới viết Terraform AWS.

Đừng bắt đầu bằng ALB ngay. Hãy chứng minh app chạy trong K8s local trước, rồi mới đưa lên AWS.

---

## 14. Câu hỏi vấn đáp mẫu

### Câu 1: Vì sao không cài Nginx trực tiếp trên EC2?

Vì đề yêu cầu app chạy trong Kubernetes. Nếu cài Nginx trực tiếp trên EC2 thì chỉ chứng minh được EC2 web server, không chứng minh được Kubernetes workload, Service, Deployment, self-healing.

### Câu 2: Vì sao dùng Deployment thay vì Pod?

Pod trần bị xóa là mất. Deployment quản lý ReplicaSet để giữ số Pod đúng với desired state, hỗ trợ self-healing, rolling update và rollback.

### Câu 3: Vì sao dùng NodePort?

Vì ALB bên ngoài cluster cần một port trên EC2 để forward traffic vào. NodePort mở port `30080` trên node, sau đó Service route traffic vào Pod.

### Câu 4: Vì sao ALB Target Group trỏ tới port 30080?

Vì Kubernetes Service được cấu hình:

```yaml
type: NodePort
nodePort: 30080
```

ALB không target trực tiếp Pod IP trong minikube, mà target EC2 instance port `30080`.

### Câu 5: Vì sao cần `/healthz`?

`/healthz` là endpoint health check đơn giản. Kubernetes readiness/liveness probe và ALB Target Group có thể gọi endpoint này. Nếu trả HTTP 200 thì app được xem là healthy.

### Câu 6: HPA trong bài này cần gì?

HPA cần:

- Metrics server.
- Deployment target.
- Pod có CPU requests.
- Metric CPU/memory có thể đọc được.

Trong manifest, Pod có:

```yaml
resources:
  requests:
    cpu: "100m"
```

Và user data bật:

```bash
minikube addons enable metrics-server
```

### Câu 7: Vì sao chọn app static nhỏ?

Vì challenge kiểm tra năng lực dựng hạ tầng, Kubernetes deploy, expose qua ALB và automation bằng Terraform. App nhỏ giúp giảm phụ thuộc DB/secret/payment, tập trung vào mục tiêu chính.

### Câu 8: Có phải đây là kiến trúc production không?

Không hoàn toàn. minikube trên EC2 là phù hợp cho lab/challenge. Production nên dùng EKS hoặc cluster Kubernetes chuẩn, image trong ECR, Ingress Controller hoặc AWS Load Balancer Controller, remote state và CI/CD/GitOps.

### Câu 9: Terraform destroy có xóa Kubernetes resource không?

Nếu Kubernetes resource được tạo bởi user data bên trong EC2, khi `terraform destroy` xóa EC2 thì cluster và resource trong minikube cũng mất theo. ALB, Target Group, Security Group cũng bị Terraform destroy nếu được quản lý trong Terraform state.

### Câu 10: Điểm yếu của cách dùng user data là gì?

User data khó quản lý trạng thái Kubernetes chi tiết bằng Terraform. Nếu muốn production hơn, nên dùng EKS + Kubernetes provider/Helm/GitOps. Nhưng với challenge một EC2 chạy minikube, user data là cách đơn giản để đạt 1-click bootstrap.
