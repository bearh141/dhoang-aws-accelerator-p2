# Architecture Diagram - W8 K8s on AWS Challenge

File này tách kiến trúc thành nhiều flow nhỏ để dễ học và dễ vấn đáp.

---

## 1. Big Picture

```mermaid
flowchart LR
    browser[User Browser]
    alb[AWS ALB]
    ec2[EC2 Instance]
    k8s[minikube Kubernetes]
    app[Static Nginx App]

    browser -->|HTTP :80| alb
    alb -->|Forward :30080| ec2
    ec2 -->|NodePort Service| k8s
    k8s -->|Route to Pod| app
```

Giải thích ngắn:

- User chỉ biết ALB DNS.
- ALB forward traffic vào EC2 port `30080`.
- Port `30080` là Kubernetes NodePort.
- Service route traffic tới Pod chạy Nginx app.

---

## 2. Request Flow

```mermaid
flowchart TB
    step1[1. Browser sends HTTP request]
    step2[2. ALB Listener receives request on port 80]
    step3[3. Target Group forwards to EC2 port 30080]
    step4[4. Kubernetes NodePort Service receives traffic]
    step5[5. Service selects Pods by label app=restaurant-web]
    step6[6. Nginx Pod returns index.html or /healthz]

    step1 --> step2 --> step3 --> step4 --> step5 --> step6
```

Câu nói vấn đáp:

```text
Request đi từ Browser vào ALB port 80, ALB listener forward sang Target Group,
Target Group gọi EC2 port 30080, đây là NodePort của Kubernetes Service,
rồi Service route tới Pod có label app=restaurant-web.
```

---

## 3. AWS Infrastructure Flow

```mermaid
flowchart LR
    tf[Terraform]
    vpc[Default VPC/Subnets]
    albsg[ALB Security Group]
    ec2sg[EC2 Security Group]
    alb[Application Load Balancer]
    tg[Target Group :30080]
    listener[Listener :80]
    ec2[EC2 Instance]

    tf --> vpc
    tf --> albsg
    tf --> ec2sg
    tf --> alb
    tf --> tg
    tf --> listener
    tf --> ec2

    listener --> tg
    tg --> ec2
    alb --> listener
```

Giải thích ngắn:

- Terraform không chỉ tạo EC2.
- Terraform tạo cả ALB, Target Group, Listener và Security Groups.
- Target Group dùng port `30080` vì app được expose bằng NodePort.

---

## 4. EC2 Bootstrap Flow

```mermaid
flowchart TB
    ec2[EC2 boots]
    userdata[user_data.sh runs]
    docker[Install Docker]
    kubectl[Install kubectl]
    minikube[Install minikube]
    swap[Create swap for small instance]
    start[Start minikube with Docker driver]
    build[Build Docker image]
    load[Load image into minikube]
    apply[Apply K8s manifests]

    ec2 --> userdata
    userdata --> swap
    userdata --> docker
    userdata --> kubectl
    userdata --> minikube
    docker --> start
    minikube --> start
    start --> build --> load --> apply
```

Câu nói vấn đáp:

```text
EC2 không được cấu hình thủ công. Terraform truyền user_data để EC2 tự cài Docker,
kubectl, minikube, build image, load image vào minikube và apply manifest.
```

---

## 5. Kubernetes Runtime Flow

```mermaid
flowchart LR
    deploy[Deployment restaurant-web]
    rs[ReplicaSet]
    pod1[Pod 1 Nginx]
    pod2[Pod 2 Nginx]
    svc[Service restaurant-web\nNodePort 30080]
    hpa[HPA\nmin 2 max 5]

    deploy --> rs
    rs --> pod1
    rs --> pod2
    svc -->|selector app=restaurant-web| pod1
    svc -->|selector app=restaurant-web| pod2
    hpa -->|scale target| deploy
```

Giải thích ngắn:

- Deployment quản lý ReplicaSet.
- ReplicaSet giữ đúng số Pod.
- Service không gọi Pod theo IP cố định, mà chọn Pod bằng label.
- HPA scale Deployment khi metrics vượt ngưỡng.

---

## 6. Health Check Flow

```mermaid
flowchart TB
    alb[ALB Target Group Health Check]
    nodeport[EC2 :30080]
    svc[K8s Service]
    pod[Nginx Pod]
    health[/healthz returns 200 OK/]

    alb -->|GET /healthz| nodeport
    nodeport --> svc
    svc --> pod
    pod --> health
```

Giải thích ngắn:

- ALB health check gọi `/healthz`.
- Nginx trả `200 OK`.
- Nếu health check fail, Target Group xem EC2 target unhealthy.

---

## 7. Security Group Flow

```mermaid
flowchart LR
    internet[Internet]
    albsg[ALB SG\nAllow :80 from 0.0.0.0/0]
    alb[ALB]
    ec2sg[EC2 SG\nAllow :30080 from ALB SG]
    ec2[EC2 NodePort :30080]
    admin[Your IP\nOptional SSH :22]

    internet --> albsg --> alb
    alb --> ec2sg --> ec2
    admin -->|SSH :22| ec2sg
```

Giải thích ngắn:

- Internet chỉ vào ALB port 80.
- EC2 NodePort `30080` chỉ nhận traffic từ ALB Security Group.
- SSH chỉ để debug, nên tốt nhất giới hạn bằng IP cá nhân `/32`.

---

## 8. Local Test Flow

```mermaid
flowchart LR
    browser[Browser localhost:18080]
    pf[kubectl port-forward\nsvc/restaurant-web 18080:80]
    svc[Service restaurant-web]
    pod1[Pod 1]
    pod2[Pod 2]

    browser --> pf
    pf --> svc
    svc --> pod1
    svc --> pod2
```

Giải thích ngắn:

- Local không có ALB.
- Dùng `kubectl port-forward` để test Service.
- Evidence local đã có: `/healthz` và `/` đều trả HTTP 200.

---

## 9. One-Minute Explanation

```text
Terraform tạo hạ tầng AWS gồm ALB, Target Group, Security Groups và EC2.
EC2 dùng user_data để tự cài Docker, kubectl, minikube và deploy app vào Kubernetes.
App không chạy trực tiếp trên EC2 mà chạy trong Pod do Deployment quản lý.
Service type NodePort expose app ra port 30080 trên EC2.
ALB nhận traffic Internet port 80 rồi forward vào EC2 port 30080.
Health check dùng /healthz để xác nhận app healthy.
```
