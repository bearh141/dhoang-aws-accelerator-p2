# Ngày 02 - Kubernetes Foundation

## Mục tiêu hôm nay

Hôm nay là ngày chuẩn bị nền tảng Kubernetes trước buổi onsite. Bạn cần học đủ để ngày mai hoặc ngày onsite nhìn manifest không bị ngợp, hiểu được Kubernetes đang quản lý container theo cách nào, và cài sẵn các công cụ cần thiết trên laptop.

Sau buổi học này, bạn cần nắm được:

- Container là gì và vì sao container phù hợp với DevOps.
- Orchestration là gì và vì sao cần Kubernetes.
- Kubernetes cluster gồm những thành phần chính nào.
- Pod là gì, vì sao Pod không phải là container đơn thuần.
- Service là gì và vì sao cần Service để truy cập Pod ổn định.
- Liveness probe và readiness probe khác nhau như thế nào.
- ConfigMap và Secret dùng để tách cấu hình khỏi image.
- NetworkPolicy là gì và vì sao liên quan đến bảo mật traffic trong cluster.
- Cài và kiểm tra được Docker Desktop, kubectl, minikube.

Thời lượng gợi ý: khoảng 6 giờ.

---

## 1. Container là gì?

Container là cách đóng gói application cùng với runtime, thư viện, dependency và cấu hình cần thiết để app chạy được nhất quán ở nhiều môi trường.

Nếu bạn từng gặp câu:

```text
Máy em chạy được mà máy anh không chạy được
```

thì container sinh ra để giảm kiểu vấn đề đó.

Một container thường chứa:

- Application code.
- Runtime, ví dụ Node.js, Python, Java runtime.
- Dependency/library.
- Biến môi trường hoặc cấu hình runtime.
- Lệnh khởi động app.

Container chạy dựa trên image. Image giống như bản thiết kế, còn container là instance đang chạy từ image đó.

Ví dụ:

```powershell
docker run nginx
```

Lệnh này tải image `nginx` nếu máy chưa có, sau đó chạy một container từ image đó.

### Image và container khác nhau thế nào?

Image:

- Là template/bản đóng gói.
- Không thay đổi khi chỉ dùng để chạy container.
- Có thể push/pull từ registry như Docker Hub, ECR, GHCR.

Container:

- Là tiến trình đang chạy từ image.
- Có trạng thái runtime.
- Có thể start, stop, restart, remove.

Ví dụ dễ nhớ:

```text
Image     = bản thiết kế hoặc file cài đặt
Container = app đang chạy từ bản thiết kế đó
```

---

## 2. Vì sao cần orchestration?

Nếu chỉ chạy một container trên laptop, Docker là đủ. Nhưng trong môi trường thật, bạn thường có nhiều vấn đề hơn:

- App cần chạy nhiều replicas để chịu tải.
- Container lỗi thì cần tự khởi động lại.
- Cần rolling update khi deploy version mới.
- Cần service discovery để các service gọi nhau.
- Cần scale up/scale down.
- Cần quản lý secret/config.
- Cần phân phối traffic.
- Cần giới hạn tài nguyên CPU/RAM.

Orchestration là việc điều phối nhiều container trên nhiều máy để hệ thống chạy ổn định.

Kubernetes là một container orchestration platform. Nó giúp bạn nói:

```text
Tôi muốn app này luôn có 3 bản chạy.
Tôi muốn app này expose qua Service.
Tôi muốn container lỗi thì tự restart.
Tôi muốn deploy version mới không làm sập toàn bộ app.
```

Sau đó Kubernetes cố gắng giữ cluster đúng với trạng thái mong muốn đó.

---

## 3. Kubernetes là gì?

Kubernetes, thường viết tắt là K8s, là nền tảng orchestration dùng để quản lý containerized applications.

Ý tưởng rất giống Terraform ở một điểm:

- Terraform quản lý desired state của hạ tầng cloud.
- Kubernetes quản lý desired state của workload/app trong cluster.

Bạn viết manifest YAML mô tả trạng thái mong muốn, ví dụ:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
```

Kubernetes sẽ cố gắng làm cho trạng thái thật trong cluster khớp với manifest đó.

---

## 4. Cluster là gì?

Kubernetes cluster là tập hợp các máy cùng chạy Kubernetes.

Một cluster gồm:

- Control plane: bộ não điều khiển cluster.
- Worker nodes: nơi workload/container thật sự chạy.

Với production, cluster thường có nhiều node. Với tuần này, bạn dùng **minikube**, tức một Kubernetes cluster local chạy trên laptop.

### Control plane

Control plane chịu trách nhiệm quản lý trạng thái cluster.

Các thành phần quan trọng:

- `kube-apiserver`: cổng giao tiếp chính của Kubernetes.
- `etcd`: nơi lưu trạng thái cluster.
- `scheduler`: quyết định Pod sẽ chạy trên node nào.
- `controller-manager`: chạy các controller để giữ desired state.

Bạn chưa cần thuộc sâu từng component ngay hôm nay, nhưng cần hiểu:

```text
Control plane = phần điều khiển
Worker node   = nơi chạy workload
```

### Worker node

Worker node là máy chạy Pod/container.

Các thành phần thường gặp:

- `kubelet`: agent chạy trên node, nói chuyện với control plane.
- `container runtime`: chạy container, ví dụ containerd.
- `kube-proxy`: hỗ trợ networking/service routing.

---

## 5. kubectl là gì?

`kubectl` là command-line tool để bạn nói chuyện với Kubernetes cluster.

Bạn dùng `kubectl` để:

- Xem cluster.
- Tạo resource.
- Apply manifest.
- Xem Pod/Service/Deployment.
- Xem log.
- Debug app.

Các lệnh cơ bản:

```powershell
kubectl version --client
kubectl cluster-info
kubectl get nodes
kubectl get pods
kubectl get svc
kubectl get deployments
```

Mẫu chung:

```powershell
kubectl get <resource_type>
```

Ví dụ:

```powershell
kubectl get pods
kubectl get services
kubectl get deployments
```

Lệnh xem chi tiết:

```powershell
kubectl describe pod <pod-name>
```

Lệnh xem log:

```powershell
kubectl logs <pod-name>
```

---

## 6. minikube là gì?

minikube là công cụ tạo Kubernetes cluster local trên laptop.

Tuần này bạn dùng minikube để thực hành mà không cần tạo cluster thật trên AWS.

Kiểm tra minikube:

```powershell
minikube version
```

Khởi động cluster:

```powershell
minikube start
```

Kiểm tra trạng thái:

```powershell
minikube status
kubectl get nodes
```

Dừng cluster:

```powershell
minikube stop
```

Xóa cluster local:

```powershell
minikube delete
```

Lưu ý: `minikube delete` xóa cluster local và resource trong cluster đó. Chỉ dùng khi bạn muốn dọn sạch để làm lại.

---

## 7. Kubernetes manifest YAML

Kubernetes resource thường được khai báo bằng YAML.

Một manifest cơ bản có các phần chính:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
    - name: nginx
      image: nginx:1.27
```

Giải thích:

- `apiVersion`: version API của resource.
- `kind`: loại resource, ví dụ Pod, Service, Deployment.
- `metadata`: thông tin định danh như name, labels, annotations.
- `spec`: trạng thái mong muốn của resource.

Hãy nhớ công thức:

```text
apiVersion + kind + metadata + spec
```

Đây là khung bạn sẽ gặp liên tục trong Kubernetes.

---

## 8. Pod là gì?

Pod là đơn vị nhỏ nhất mà Kubernetes trực tiếp chạy và quản lý.

Một Pod có thể chứa một hoặc nhiều container, nhưng trường hợp phổ biến nhất là một Pod chứa một container app chính.

Ví dụ Pod chạy Nginx:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80
```

Giải thích từng phần:

- `kind: Pod`: khai báo đây là Pod.
- `metadata.name`: tên Pod.
- `metadata.labels`: nhãn để Service/selector tìm Pod.
- `spec.containers`: danh sách container trong Pod.
- `name`: tên container.
- `image`: image dùng để chạy container.
- `containerPort`: port app lắng nghe bên trong container.

Apply manifest:

```powershell
kubectl apply -f pod.yaml
```

Kiểm tra:

```powershell
kubectl get pods
kubectl describe pod nginx-pod
kubectl logs nginx-pod
```

Xóa:

```powershell
kubectl delete -f pod.yaml
```

### Vì sao không nên chỉ dùng Pod đơn lẻ?

Pod đơn lẻ không tự phục hồi tốt theo cách production mong muốn. Nếu Pod bị xóa, nó có thể mất luôn nếu không có controller quản lý.

Trong thực tế, bạn thường dùng Deployment để quản lý Pod.

---

## 9. Deployment là gì?

Deployment là resource dùng để quản lý nhiều Pod replicas và rollout version mới.

Ví dụ:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

Giải thích:

- `replicas: 2`: muốn luôn có 2 Pod chạy.
- `selector.matchLabels`: Deployment chọn Pod có label `app: nginx`.
- `template`: mẫu Pod mà Deployment sẽ tạo.
- `template.metadata.labels`: label gắn vào Pod được tạo.
- `template.spec.containers`: container trong Pod.

Điểm cực kỳ quan trọng:

```yaml
selector:
  matchLabels:
    app: nginx
```

phải khớp với:

```yaml
template:
  metadata:
    labels:
      app: nginx
```

Nếu selector và label không khớp, Deployment không quản lý đúng Pod.

Các lệnh cần biết:

```powershell
kubectl apply -f deployment.yaml
kubectl get deployments
kubectl get pods
kubectl describe deployment nginx-deployment
```

Scale:

```powershell
kubectl scale deployment nginx-deployment --replicas=3
```

Xem rollout:

```powershell
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
```

---

## 10. Service là gì?

Pod có IP riêng, nhưng Pod có thể bị xóa và tạo lại. Khi Pod tạo lại, IP có thể đổi. Vì vậy, không nên truy cập app bằng Pod IP.

Service cung cấp endpoint ổn định để truy cập nhóm Pod.

Ví dụ Service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

Giải thích:

- `kind: Service`: khai báo Service.
- `type: ClusterIP`: Service chỉ truy cập nội bộ trong cluster.
- `selector.app: nginx`: Service tìm các Pod có label `app=nginx`.
- `port: 80`: port của Service.
- `targetPort: 80`: port trong container/Pod.

Mối quan hệ:

```text
Client -> Service port -> Pod targetPort -> Container port
```

Kiểm tra:

```powershell
kubectl get svc
kubectl describe svc nginx-service
```

### Các loại Service phổ biến

ClusterIP:

- Mặc định.
- Chỉ truy cập trong cluster.
- Phù hợp cho internal service.

NodePort:

- Mở port trên node.
- Dễ test trên minikube.
- Không phải cách expose đẹp nhất cho production.

LoadBalancer:

- Tạo load balancer bên ngoài nếu cloud provider hỗ trợ.
- Hay dùng trên EKS/GKE/AKS.

Với minikube, nếu dùng NodePort, có thể lấy URL bằng:

```powershell
minikube service nginx-service --url
```

---

## 11. Labels và selectors

Labels là key-value gắn vào Kubernetes resources.

Ví dụ:

```yaml
metadata:
  labels:
    app: nginx
    environment: dev
```

Selector dùng để chọn resource theo label.

Ví dụ Service chọn Pod:

```yaml
selector:
  app: nginx
```

Nếu Pod có label:

```yaml
labels:
  app: nginx
```

thì Service có thể route traffic tới Pod đó.

Lỗi rất hay gặp:

```yaml
selector:
  app: web
```

nhưng Pod lại có:

```yaml
labels:
  app: nginx
```

Kết quả: Service không tìm thấy endpoint.

Kiểm tra endpoint:

```powershell
kubectl get endpoints
```

Nếu Service không có endpoint, thường là selector và label đang không khớp.

---

## 12. Probes: liveness và readiness

Probe là cách Kubernetes kiểm tra tình trạng container.

Có 2 loại cần học hôm nay:

- Liveness probe.
- Readiness probe.

### Liveness probe

Liveness probe trả lời câu hỏi:

```text
Container còn sống không?
```

Nếu liveness probe fail, Kubernetes sẽ restart container.

Ví dụ:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 5
```

Giải thích:

- `httpGet`: kiểm tra bằng HTTP request.
- `path: /`: gọi endpoint `/`.
- `port: 80`: gọi port 80.
- `initialDelaySeconds`: đợi bao lâu sau khi container start rồi mới check.
- `periodSeconds`: check mỗi bao nhiêu giây.

### Readiness probe

Readiness probe trả lời câu hỏi:

```text
Container đã sẵn sàng nhận traffic chưa?
```

Nếu readiness probe fail, Pod sẽ bị loại khỏi Service endpoint, nhưng container không nhất thiết bị restart.

Ví dụ:

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
```

### So sánh nhanh

| Probe | Hỏi điều gì? | Nếu fail thì sao? |
|---|---|---|
| Liveness | App còn sống không? | Restart container |
| Readiness | App sẵn sàng nhận traffic chưa? | Ngừng gửi traffic tới Pod |

Nguyên tắc dễ nhớ:

```text
Liveness = có nên restart không?
Readiness = có nên nhận traffic không?
```

---

## 13. ConfigMap

ConfigMap dùng để lưu cấu hình không nhạy cảm, ví dụ:

- App mode.
- Feature flag.
- Log level.
- URL public không chứa secret.

Ví dụ ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "dev"
  LOG_LEVEL: "info"
```

Dùng ConfigMap trong Deployment:

```yaml
envFrom:
  - configMapRef:
      name: app-config
```

Ví dụ đầy đủ trong container:

```yaml
containers:
  - name: app
    image: nginx:1.27
    envFrom:
      - configMapRef:
          name: app-config
```

Kiểm tra:

```powershell
kubectl get configmaps
kubectl describe configmap app-config
```

---

## 14. Secret

Secret dùng để lưu cấu hình nhạy cảm, ví dụ:

- Password.
- Token.
- API key.
- Database connection string.

Ví dụ Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
stringData:
  DB_PASSWORD: "example-password"
```

Dùng Secret trong Deployment:

```yaml
envFrom:
  - secretRef:
      name: app-secret
```

Lưu ý quan trọng:

- Kubernetes Secret mặc định chỉ base64 encode, không phải tự động mã hóa mạnh theo cách bạn tưởng.
- Không commit secret thật lên GitHub.
- Với production, cần dùng thêm giải pháp như External Secrets, Sealed Secrets, AWS Secrets Manager, hoặc secret management phù hợp.

Kiểm tra:

```powershell
kubectl get secrets
kubectl describe secret app-secret
```

Không nên in secret thật ra terminal nếu không cần.

---

## 15. NetworkPolicy

NetworkPolicy dùng để kiểm soát traffic vào/ra Pod.

Mặc định trong nhiều cluster, các Pod có thể nói chuyện với nhau khá tự do. NetworkPolicy giúp bạn giới hạn:

- Pod nào được gọi Pod nào.
- Namespace nào được phép truy cập.
- Port nào được phép đi qua.

Ví dụ policy chỉ cho traffic vào Pod `app=backend` từ Pod `app=frontend`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 80
```

Giải thích:

- `podSelector`: chọn Pod mà policy áp dụng lên, ở đây là backend.
- `policyTypes: Ingress`: kiểm soát traffic đi vào.
- `from`: nguồn được phép gọi vào.
- `ports`: port được phép.

Lưu ý: NetworkPolicy chỉ hoạt động nếu networking plugin của cluster hỗ trợ NetworkPolicy. Với minikube, tùy driver/plugin, bạn có thể cần bật CNI phù hợp. Hôm nay mục tiêu chính là hiểu khái niệm và đọc được manifest.

---

## 16. Bài thực hành nhỏ hôm nay

Tạo folder trong repo:

```text
cloud/w8/day-b/
  manifests/
    pod.yaml
    deployment.yaml
    service.yaml
    configmap.yaml
```

### Bước 1: Kiểm tra tool

```powershell
docker --version
kubectl version --client
minikube version
```

### Bước 2: Start minikube

```powershell
minikube start
minikube status
kubectl get nodes
```

### Bước 3: Tạo Pod Nginx

Tạo file `pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80
```

Apply:

```powershell
kubectl apply -f manifests/pod.yaml
kubectl get pods
kubectl describe pod nginx-pod
```

Xóa Pod sau khi hiểu:

```powershell
kubectl delete -f manifests/pod.yaml
```

### Bước 4: Tạo Deployment

Tạo file `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
```

Apply:

```powershell
kubectl apply -f manifests/deployment.yaml
kubectl get deployments
kubectl get pods
kubectl rollout status deployment/nginx-deployment
```

### Bước 5: Tạo Service

Tạo file `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

Apply:

```powershell
kubectl apply -f manifests/service.yaml
kubectl get svc
kubectl get endpoints
```

Lấy URL trên minikube:

```powershell
minikube service nginx-service --url
```

### Bước 6: Ghi evidence

Ghi vào `cloud/w8/day-b/README.md`:

- Output `docker --version`.
- Output `kubectl version --client`.
- Output `minikube version`.
- Output `kubectl get nodes`.
- Output `kubectl get pods`.
- Output `kubectl get svc`.
- URL app nếu lấy được bằng `minikube service`.

---

## 17. Checklist hôm nay

- [ ] Hiểu image và container khác nhau thế nào.
- [ ] Hiểu orchestration là gì.
- [ ] Hiểu Kubernetes cluster gồm control plane và worker node.
- [ ] Biết `kubectl` dùng để làm gì.
- [ ] Cài Docker Desktop.
- [ ] Cài kubectl.
- [ ] Cài minikube.
- [ ] Chạy được `minikube start`.
- [ ] Chạy được `kubectl get nodes`.
- [ ] Hiểu Pod manifest cơ bản.
- [ ] Hiểu Deployment manifest cơ bản.
- [ ] Hiểu Service và selector.
- [ ] Hiểu liveness/readiness probe.
- [ ] Hiểu ConfigMap và Secret khác nhau thế nào.
- [ ] Hiểu NetworkPolicy ở mức khái niệm.
- [ ] Ghi evidence vào `day-b/README.md`.
- [ ] Cập nhật `reflection.md`.
- [ ] Commit với message dạng `[W8-D2] kubernetes foundation`.

---

## 18. Câu hỏi tự kiểm tra

1. Container khác image như thế nào?
2. Vì sao cần Kubernetes nếu đã có Docker?
3. Pod là gì?
4. Vì sao production thường dùng Deployment thay vì Pod đơn lẻ?
5. Service giải quyết vấn đề gì?
6. Selector và label liên quan với nhau thế nào?
7. Nếu Service không route được traffic tới Pod, bạn sẽ kiểm tra gì đầu tiên?
8. Liveness probe khác readiness probe như thế nào?
9. ConfigMap khác Secret như thế nào?
10. NetworkPolicy dùng để làm gì?

---

## 19. Tài liệu nên đọc

Ưu tiên đọc theo thứ tự:

1. Kubernetes Concepts:
   https://kubernetes.io/docs/concepts/
2. Kubernetes Basics:
   https://kubernetes.io/docs/tutorials/kubernetes-basics/
3. minikube start:
   https://minikube.sigs.k8s.io/docs/start/
4. kubectl Cheat Sheet:
   https://kubernetes.io/docs/reference/kubectl/cheatsheet/
5. Docker overview:
   https://docs.docker.com/get-started/docker-overview/

Mục tiêu hôm nay không phải học hết Kubernetes, mà là đọc được manifest cơ bản, hiểu Pod/Deployment/Service, và chuẩn bị laptop sẵn sàng cho lab.
