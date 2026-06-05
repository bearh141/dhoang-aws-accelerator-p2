# Docker và Kubernetes - Tài Liệu Học Nền Tảng

## Mục tiêu

Tài liệu này giúp bạn học chắc nền tảng Docker và Kubernetes để làm tốt lab tuần W8.

Sau khi học xong, bạn cần hiểu:

- Docker là gì, image và container khác nhau như thế nào.
- Dockerfile dùng để làm gì.
- Cách chạy, xem, dừng, xóa container.
- Kubernetes là gì và vì sao cần Kubernetes.
- Pod, Deployment, Service, ConfigMap, Secret là gì.
- Cách dùng `kubectl` để thao tác với cluster.
- Cách dùng minikube để chạy Kubernetes local.
- Cách debug lỗi cơ bản khi làm lab.

---

## 1. Docker là gì?

Docker là công cụ dùng để đóng gói và chạy application trong container.

Container giúp application chạy nhất quán giữa nhiều môi trường:

- Máy cá nhân.
- Máy của teammate.
- Server test.
- Server production.
- CI/CD pipeline.

Vấn đề Docker giải quyết là:

```text
Máy em chạy được, máy anh lại lỗi.
```

Khi dùng Docker, app và dependency được đóng gói vào image. Ai chạy image đó cũng có môi trường giống nhau hơn.

### Docker dùng để làm gì?

Docker thường được dùng để:

- Chạy application trong môi trường cô lập.
- Đóng gói app cùng dependency để dễ chạy ở máy khác.
- Tạo môi trường dev giống nhau cho cả team.
- Chạy service phụ trong lúc dev, ví dụ database, Redis, Nginx.
- Build image để deploy lên Kubernetes, ECS, server hoặc CI/CD.
- Test app trong pipeline mà không cần cài dependency trực tiếp lên máy CI.

Ví dụ thực tế:

- Backend cần PostgreSQL để chạy local: dùng container PostgreSQL thay vì cài PostgreSQL vào Windows.
- App Node.js cần đúng version Node 20: đóng gói Node 20 trong image.
- Team 5 người cùng làm app: tất cả dùng cùng Docker image để tránh lệch môi trường.

### Đặc điểm chính của Docker

- **Portable**: image chạy được ở nhiều môi trường có Docker/container runtime.
- **Isolated**: container có process, filesystem, network riêng tương đối tách biệt.
- **Lightweight**: container nhẹ hơn máy ảo vì dùng chung kernel với host.
- **Fast startup**: container thường start nhanh hơn VM.
- **Immutable image**: image nên được build cố định, không sửa tay sau khi build.
- **Layered filesystem**: image gồm nhiều layer, giúp cache khi build.
- **Registry-based**: image có thể push/pull từ registry như Docker Hub, ECR, GHCR.

### Docker không phải là gì?

Docker không phải là máy ảo đầy đủ. Container không chứa toàn bộ operating system riêng như VM. Nó cô lập process tốt cho app, nhưng vẫn chia sẻ kernel với host.

Docker cũng không tự giải quyết toàn bộ bài toán production như scaling, service discovery, rolling update, self-healing. Những phần đó là lý do Kubernetes ra đời.

---

## 2. Image và container

### Image

Image là bản đóng gói read-only của application.

Image thường chứa:

- Application code.
- Runtime, ví dụ Node.js, Python, Java.
- Libraries/dependencies.
- File cấu hình.
- Lệnh start app.

Ví dụ image:

```text
nginx:1.27
redis:7
mysql:8
python:3.12
```

### Image dùng để làm gì?

Image dùng để tạo container. Bạn có thể xem image là artifact sau khi build app.

Trong pipeline thực tế:

```text
Code -> Build Docker image -> Push image lên registry -> Deploy image
```

Ví dụ:

- Build image `my-api:1.0.0`.
- Push lên Amazon ECR.
- Kubernetes Deployment dùng image đó để chạy Pod.

### Đặc điểm của image

- **Read-only**: image không thay đổi khi container chạy.
- **Có tag**: ví dụ `nginx:1.27`, `my-api:v1.0.0`.
- **Có digest**: định danh nội dung chính xác của image.
- **Gồm nhiều layer**: mỗi lệnh trong Dockerfile có thể tạo layer.
- **Có thể tái sử dụng**: nhiều container có thể chạy từ cùng một image.
- **Có thể lưu ở registry**: Docker Hub, AWS ECR, GitHub Container Registry.

### Tag image nên hiểu thế nào?

Ví dụ:

```text
nginx:1.27
```

Trong đó:

- `nginx`: tên image.
- `1.27`: tag.

Không nên phụ thuộc quá nhiều vào tag `latest` trong production, vì `latest` có thể thay đổi theo thời gian.

### Container

Container là instance đang chạy từ image.

Ví dụ:

```powershell
docker run nginx:1.27
```

Lệnh này tạo một container chạy từ image `nginx:1.27`.

### Container dùng để làm gì?

Container dùng để chạy app thật sự.

Ví dụ:

- Một container chạy API backend.
- Một container chạy PostgreSQL.
- Một container chạy Redis.
- Một container chạy Nginx reverse proxy.

Trong Kubernetes, container thường chạy bên trong Pod.

### Đặc điểm của container

- **Runtime instance**: container là image đang chạy.
- **Có lifecycle**: create, start, stop, restart, remove.
- **Có filesystem riêng**: thay đổi bên trong container thường mất khi container bị xóa nếu không dùng volume.
- **Có network riêng**: container có IP/network namespace riêng.
- **Có log riêng**: xem bằng `docker logs`.
- **Có resource limit**: có thể giới hạn CPU/RAM.

### Khi nào container mất dữ liệu?

Nếu bạn ghi dữ liệu vào filesystem bên trong container rồi xóa container, dữ liệu có thể mất.

Vì vậy database container nên dùng volume:

```powershell
docker run -d -v pgdata:/var/lib/postgresql/data postgres:16
```

### So sánh nhanh

| Khái niệm | Ý nghĩa |
|---|---|
| Image | Bản đóng gói/template |
| Container | Tiến trình đang chạy từ image |
| Dockerfile | Công thức để build image |
| Registry | Nơi lưu image, ví dụ Docker Hub, ECR |

---

## 3. Docker CLI cơ bản

Kiểm tra Docker:

```powershell
docker --version
docker info
```

Chạy container Nginx:

```powershell
docker run nginx:1.27
```

Chạy container ở background:

```powershell
docker run -d nginx:1.27
```

Xem container đang chạy:

```powershell
docker ps
```

Xem tất cả container, kể cả container đã stop:

```powershell
docker ps -a
```

Dừng container:

```powershell
docker stop <container_id_or_name>
```

Xóa container:

```powershell
docker rm <container_id_or_name>
```

Xem image local:

```powershell
docker images
```

Xóa image:

```powershell
docker rmi <image_id_or_name>
```

### Docker CLI dùng để làm gì?

Docker CLI là công cụ dòng lệnh để nói chuyện với Docker daemon.

Bạn dùng Docker CLI để:

- Pull image.
- Build image.
- Run container.
- Xem logs.
- Debug container.
- Quản lý network/volume.
- Dọn container/image không dùng nữa.

### Docker client và Docker daemon

Khi chạy:

```powershell
docker ps
```

Docker CLI không tự chạy container. Nó gửi request tới Docker daemon. Docker daemon mới là service thật sự quản lý container.

Vì vậy nếu Docker Desktop chưa chạy, bạn sẽ gặp lỗi kiểu:

```text
failed to connect to the docker API
```

Khi đó cần mở Docker Desktop trước.

---

## 4. Port mapping trong Docker

Container có network riêng. Nếu muốn truy cập app từ máy host, cần map port.

Ví dụ chạy Nginx:

```powershell
docker run -d -p 8080:80 nginx:1.27
```

Ý nghĩa:

```text
8080:80
host_port:container_port
```

Bạn truy cập:

```text
http://localhost:8080
```

Traffic sẽ đi vào port 8080 trên máy bạn, rồi được chuyển vào port 80 trong container.

### Port mapping dùng để làm gì?

Port mapping dùng để truy cập app chạy trong container từ máy host.

Không có port mapping:

- App vẫn chạy trong container.
- Nhưng trình duyệt trên máy bạn chưa chắc truy cập được.

Có port mapping:

```text
localhost:8080 -> container:80
```

### Đặc điểm

- Bên trái là port trên máy host.
- Bên phải là port trong container.
- Một host port chỉ nên được một container dùng tại một thời điểm.
- Nếu host port bị trùng, Docker sẽ báo lỗi.

Ví dụ lỗi thường gặp:

```text
Bind for 0.0.0.0:8080 failed: port is already allocated
```

Cách xử lý: đổi host port.

```powershell
docker run -d -p 8081:80 nginx:1.27
```

---

## 5. Dockerfile

Dockerfile là file mô tả cách build image.

Ví dụ đơn giản:

```dockerfile
FROM nginx:1.27
COPY index.html /usr/share/nginx/html/index.html
```

Giải thích:

- `FROM`: image nền.
- `COPY`: copy file từ máy local vào image.

Build image:

```powershell
docker build -t my-nginx:1.0 .
```

Chạy image vừa build:

```powershell
docker run -d -p 8080:80 my-nginx:1.0
```

### Dockerfile dùng để làm gì?

Dockerfile dùng để định nghĩa cách build image một cách lặp lại được.

Không có Dockerfile:

- Bạn phải nhớ từng bước cài dependency.
- Người khác khó tái tạo môi trường.
- CI/CD khó build app tự động.

Có Dockerfile:

- Mọi bước build nằm trong code.
- Team review được thay đổi môi trường.
- CI/CD có thể tự build image.

### Các instruction hay gặp

```dockerfile
FROM
```

Chọn image nền.

```dockerfile
WORKDIR
```

Đặt thư mục làm việc trong image.

```dockerfile
COPY
```

Copy file từ máy build vào image.

```dockerfile
RUN
```

Chạy lệnh trong lúc build image, ví dụ cài package.

```dockerfile
ENV
```

Khai báo biến môi trường.

```dockerfile
EXPOSE
```

Ghi chú app lắng nghe port nào. `EXPOSE` không tự mở port ra host.

```dockerfile
CMD
```

Lệnh mặc định khi container start.

### Đặc điểm của Dockerfile tốt

- Dùng base image rõ version, hạn chế `latest`.
- Copy dependency file trước để tận dụng cache.
- Không copy secret vào image.
- Image càng nhỏ càng tốt nếu phục vụ production.
- Có `.dockerignore` để tránh copy file thừa.

---

## 6. Docker Compose là gì?

Docker Compose dùng để chạy nhiều container bằng một file YAML.

Ví dụ `compose.yaml`:

```yaml
services:
  web:
    image: nginx:1.27
    ports:
      - "8080:80"
```

Chạy:

```powershell
docker compose up -d
```

Dừng:

```powershell
docker compose down
```

Trong W8, Docker Compose không phải trọng tâm chính, nhưng hiểu Compose sẽ giúp bạn dễ hình dung nhiều service chạy cùng nhau.

### Docker Compose dùng để làm gì?

Docker Compose dùng để chạy nhiều container có liên quan với nhau bằng một file YAML.

Ví dụ một app thực tế có thể cần:

- Backend API.
- Database PostgreSQL.
- Redis cache.
- Nginx reverse proxy.

Thay vì chạy nhiều lệnh `docker run`, bạn viết một file `compose.yaml` và chạy:

```powershell
docker compose up -d
```

### Đặc điểm của Docker Compose

- Phù hợp cho local development.
- Dễ định nghĩa nhiều service.
- Có network mặc định giữa các service.
- Có thể khai báo volume để lưu data.
- Có thể khai báo environment variables.
- Không thay thế Kubernetes trong production cluster lớn.

### Khi nào dùng Compose?

Nên dùng:

- Dev local nhiều service.
- Demo app nhỏ.
- Test integration đơn giản.

Không nên dùng làm giải pháp chính nếu bạn cần:

- Multi-node cluster.
- Auto-healing nâng cao.
- Rolling update chuẩn production.
- Service discovery và autoscaling phức tạp.

---

## 7. Kubernetes là gì?

Kubernetes, viết tắt là K8s, là nền tảng quản lý container.

Nếu Docker giúp bạn chạy container, Kubernetes giúp bạn quản lý nhiều container ở quy mô lớn hơn.

Kubernetes giúp:

- Chạy nhiều replicas của app.
- Tự restart container khi lỗi.
- Rolling update khi deploy version mới.
- Service discovery.
- Load balancing nội bộ.
- Quản lý config và secret.
- Scale app.
- Quản lý network policy.

Ý tưởng quan trọng:

```text
Bạn khai báo trạng thái mong muốn.
Kubernetes cố gắng giữ hệ thống đúng trạng thái đó.
```

### Kubernetes dùng để làm gì?

Kubernetes dùng để vận hành containerized applications ở quy mô lớn hơn Docker đơn lẻ.

Trong thực tế, Kubernetes dùng để:

- Deploy microservices.
- Chạy nhiều replicas cho app.
- Rolling update app mà giảm downtime.
- Rollback nếu version mới lỗi.
- Tự restart Pod khi container lỗi.
- Expose service nội bộ hoặc ra ngoài.
- Quản lý config/secret.
- Quản lý resource CPU/RAM.
- Tổ chức workload theo namespace.
- Làm nền cho GitOps, CI/CD, observability, service mesh.

### Đặc điểm chính của Kubernetes

- **Declarative**: bạn khai báo desired state bằng YAML.
- **Self-healing**: Pod lỗi có thể được tạo lại.
- **Scalable**: scale replicas dễ dàng.
- **Extensible**: có CRD/operator để mở rộng API.
- **Portable**: chạy được local, on-prem, cloud.
- **API-driven**: mọi thao tác đi qua Kubernetes API.
- **Controller-based**: controller liên tục reconcile actual state về desired state.

### Desired state và control loop

Tư tưởng quan trọng nhất của Kubernetes là **desired state**.

Bạn không nói từng bước:

```text
Chạy container A, nếu chết thì chạy lại, nếu traffic tăng thì tự tạo thêm...
```

Bạn khai báo:

```text
Tôi muốn luôn có 3 bản app web chạy.
```

Kubernetes sẽ liên tục chạy vòng lặp:

```text
Declare -> Observe -> Diff -> Reconcile
```

Giải thích:

- **Declare**: bạn khai báo trạng thái mong muốn bằng YAML hoặc command.
- **Observe**: Kubernetes quan sát trạng thái thật trong cluster.
- **Diff**: so sánh trạng thái thật với trạng thái mong muốn.
- **Reconcile**: nếu lệch, Kubernetes hành động để kéo về đúng.

Ví dụ self-healing:

```text
Desired state: 3 Pod
Actual state: 2 Pod vì bạn xóa 1 Pod
Kubernetes thấy thiếu 1 Pod
ReplicaSet tạo Pod mới
Actual state trở lại 3 Pod
```

Đây là lý do Kubernetes mạnh hơn cách chạy script thủ công.

### Kubernetes không thay Docker theo nghĩa nào?

Docker giúp build và chạy container. Kubernetes quản lý container ở cấp cluster.

Bạn vẫn cần image container để Kubernetes chạy workload. Kubernetes không tự thay thế bước build image.

---

## 8. Cluster, node và control plane

### Cluster

Cluster là một cụm Kubernetes.

Một cluster gồm:

- Control plane.
- Worker node.

### Control plane

Control plane là bộ não của cluster.

Nó chịu trách nhiệm:

- Nhận request qua API server.
- Lưu trạng thái cluster.
- Lên lịch Pod chạy trên node nào.
- Theo dõi và sửa trạng thái nếu lệch desired state.

### Worker node

Worker node là nơi Pod/container thật sự chạy.

Với minikube, máy bạn thường có một node tên:

```text
minikube
```

### Cluster dùng để làm gì?

Cluster là môi trường nơi application Kubernetes chạy.

Một cluster giúp:

- Gom nhiều node thành một hệ thống chung.
- Lên lịch workload lên node phù hợp.
- Quản lý network giữa các Pod.
- Quản lý storage, secret, config.
- Cung cấp API chung cho team/CI/CD.

### Đặc điểm của control plane

- Không nên chạy workload app thông thường trên control plane trong production, trừ khi cluster được thiết kế cho việc đó.
- Lưu trạng thái cluster trong `etcd`.
- Nhận mọi request qua API server.
- Ra quyết định scheduling và reconciliation.

### Đặc điểm của worker node

- Chạy Pod thật.
- Có kubelet để nhận lệnh từ control plane.
- Có container runtime để chạy container.
- Nếu node lỗi, Pod trên node đó có thể được schedule lại sang node khác nếu workload được quản lý bởi controller như Deployment.

---

## 9. minikube là gì?

minikube giúp chạy Kubernetes cluster local trên laptop.

Kiểm tra minikube:

```powershell
minikube version
```

Start cluster bằng Docker driver:

```powershell
minikube start --driver=docker
```

Kiểm tra:

```powershell
minikube status
kubectl get nodes
```

Dừng cluster:

```powershell
minikube stop
```

Xóa cluster:

```powershell
minikube delete
```

Lưu ý: trước khi chạy minikube bằng Docker driver, **Docker Desktop phải đang chạy**.

### minikube dùng để làm gì?

minikube dùng để học và test Kubernetes local.

Nó phù hợp cho:

- Học Pod, Deployment, Service.
- Test manifest trước khi đưa lên cluster thật.
- Làm lab cá nhân.
- Demo app nhỏ.

### Đặc điểm của minikube

- Chạy Kubernetes trên máy cá nhân.
- Thường chỉ có một node.
- Có thể dùng nhiều driver: Docker, Hyper-V, VirtualBox...
- Dễ tạo/xóa cluster.
- Không đại diện đầy đủ cho production cluster nhiều node.

### Khi nào không nên dùng minikube?

Không nên dùng minikube cho production. Nó là công cụ học/test local, không phải nền tảng vận hành thật.

---

## 10. kubectl là gì?

`kubectl` là CLI để thao tác với Kubernetes cluster.

Kiểm tra client:

```powershell
kubectl version --client
```

Kiểm tra cluster:

```powershell
kubectl cluster-info
kubectl get nodes
```

Các lệnh cơ bản:

```powershell
kubectl get pods
kubectl get pods -A
kubectl get deployments
kubectl get services
kubectl get configmaps
kubectl get secrets
```

Xem chi tiết resource:

```powershell
kubectl describe pod <pod-name>
```

Xem log:

```powershell
kubectl logs <pod-name>
```

Apply file YAML:

```powershell
kubectl apply -f file.yaml
```

Xóa resource từ file YAML:

```powershell
kubectl delete -f file.yaml
```

### kubectl dùng để làm gì?

`kubectl` là công cụ chính để thao tác với Kubernetes cluster.

Bạn dùng `kubectl` để:

- Tạo resource.
- Xem resource.
- Sửa resource.
- Xóa resource.
- Xem logs.
- Debug lỗi.
- Apply manifest YAML.
- Kiểm tra rollout.

### Đặc điểm của kubectl

- Là client, không phải cluster.
- Cần kubeconfig để biết kết nối tới cluster nào.
- Có thể quản lý nhiều cluster/context.
- Gửi request tới Kubernetes API server.
- Không chạy được đúng nếu cluster chưa start hoặc kubeconfig sai.

### Quy trình debug bằng kubectl

Khi Pod không chạy, đi theo thứ tự này:

```powershell
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

Ý nghĩa:

- `get`: xem trạng thái tổng quan, ví dụ `Running`, `Pending`, `ImagePullBackOff`, `CrashLoopBackOff`.
- `describe`: xem chi tiết và phần `Events`, thường chỉ ra lỗi pull image, thiếu resource, probe fail.
- `logs`: xem log app/container.

Mẹo nhớ:

```text
get -> describe -> logs
```

Khoảng 90% lỗi lab cơ bản sẽ lộ ra trong 3 bước này.

### kubeconfig là gì?

kubeconfig là file cấu hình để `kubectl` biết:

- Cluster endpoint ở đâu.
- Dùng credential nào.
- Context hiện tại là gì.

Kiểm tra context:

```powershell
kubectl config current-context
kubectl config get-contexts
```

Với minikube, context thường là:

```text
minikube
```

---

## 11. Kubernetes manifest YAML

Kubernetes resource thường được viết bằng YAML.

Khung cơ bản:

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
- `metadata`: thông tin định danh như name, labels.
- `spec`: trạng thái mong muốn.

Công thức cần nhớ:

```text
apiVersion + kind + metadata + spec
```

### Manifest dùng để làm gì?

Manifest là file khai báo resource Kubernetes.

Thay vì tạo resource bằng lệnh thủ công, bạn viết YAML để:

- Lưu vào Git.
- Review được thay đổi.
- Apply lại được nhiều lần.
- Dùng trong CI/CD hoặc GitOps.

### Đặc điểm của manifest tốt

- Có `metadata.name` rõ ràng.
- Có `labels` nhất quán.
- Có `resources requests/limits` khi đi xa hơn lab.
- Có probe nếu app cần health check.
- Không chứa secret thật dạng plain text.
- Tách file theo resource hoặc theo app tùy quy mô.

---

## 12. Pod

Pod là đơn vị nhỏ nhất Kubernetes trực tiếp quản lý.

Một Pod thường chứa một container chính.

Ví dụ `pod.yaml`:

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

Trong thực tế, ít khi chạy Pod đơn lẻ trong production. Thường bạn dùng Deployment để quản lý Pod.

### Pod dùng để làm gì?

Pod là nơi container chạy trong Kubernetes.

Kubernetes không chạy container trực tiếp như Docker CLI. Kubernetes chạy container thông qua Pod.

Pod dùng để:

- Chạy một hoặc nhiều container có liên quan chặt chẽ.
- Chia sẻ network namespace giữa các container trong cùng Pod.
- Chia sẻ volume giữa các container trong cùng Pod.

### Đặc điểm của Pod

- Là đơn vị nhỏ nhất Kubernetes schedule lên node.
- Mỗi Pod có IP riêng.
- Container trong cùng Pod có thể gọi nhau qua `localhost`.
- Pod có thể chết và được tạo lại.
- IP Pod không ổn định, không nên dùng làm endpoint lâu dài.
- Pod thường được quản lý bởi Deployment, StatefulSet, DaemonSet hoặc Job.

### Pod trần khác Pod thuộc Deployment thế nào?

Pod trần là Pod bạn tạo trực tiếp:

```powershell
kubectl run hello --image=nginx:1.27 --port=80
```

Nếu xóa Pod này:

```powershell
kubectl delete pod hello
```

Pod sẽ mất hẳn, vì không có controller nào tạo lại nó.

Pod thuộc Deployment thì khác. Nếu bạn xóa một Pod thuộc Deployment, ReplicaSet sẽ tạo Pod mới để giữ đúng số replicas mong muốn.

Đây là bài học rất quan trọng:

```text
Production thường không chạy Pod trần.
Production thường dùng Deployment/StatefulSet/DaemonSet/Job để quản lý Pod.
```

### Khi nào dùng Pod nhiều container?

Thường dùng khi có sidecar container, ví dụ:

- App container + log collector.
- App container + proxy sidecar.
- App container + config reloader.

Nếu hai container có lifecycle độc lập, thường nên tách thành hai Deployment khác nhau.

---

## 13. Deployment

Deployment quản lý Pod replicas và rollout version mới.

Ví dụ `deployment.yaml`:

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

Điểm quan trọng:

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

Apply:

```powershell
kubectl apply -f deployment.yaml
```

Kiểm tra:

```powershell
kubectl get deployments
kubectl get pods
kubectl rollout status deployment/nginx-deployment
```

Scale:

```powershell
kubectl scale deployment nginx-deployment --replicas=3
```

### Deployment dùng để làm gì?

Deployment dùng để quản lý stateless application.

Nó giúp:

- Luôn duy trì số Pod replicas mong muốn.
- Tự tạo Pod mới nếu Pod cũ chết.
- Rolling update khi đổi image/config.
- Rollback về version trước.
- Scale app lên/xuống.

### Đặc điểm của Deployment

- Quản lý ReplicaSet.
- ReplicaSet quản lý Pod.
- Phù hợp cho app stateless như API, web frontend, worker không giữ state local.
- Dựa vào selector/label để biết Pod nào thuộc Deployment.
- Có rollout history.

### Khi nào dùng Deployment?

Dùng Deployment cho:

- Web app.
- REST API.
- Background worker stateless.
- Service có thể chạy nhiều bản giống nhau.

Không lý tưởng cho database stateful. Database thường cần StatefulSet hoặc dịch vụ managed như RDS.

### Lệnh rollout hữu ích

```powershell
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment
```

---

## 14. Service

Pod có IP riêng, nhưng IP Pod có thể đổi khi Pod bị tạo lại. Service cung cấp địa chỉ ổn định để truy cập nhóm Pod.

Ví dụ `service.yaml`:

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

Giải thích:

- `selector`: chọn Pod có label `app=nginx`.
- `port`: port của Service.
- `targetPort`: port trong Pod/container.
- `nodePort`: port mở ra trên node.

Apply:

```powershell
kubectl apply -f service.yaml
```

Kiểm tra:

```powershell
kubectl get svc
kubectl get endpoints
```

Lấy URL với minikube:

```powershell
minikube service nginx-service --url
```

### Service dùng để làm gì?

Service cung cấp endpoint ổn định để truy cập Pod.

Vì Pod có thể bị xóa/tạo lại và đổi IP, client không nên gọi trực tiếp Pod IP. Service đứng giữa để route traffic tới các Pod phù hợp.

Service dùng để:

- Cho các Pod gọi nhau ổn định.
- Expose app ra ngoài cluster.
- Load balance traffic tới nhiều Pod.
- Tách client khỏi lifecycle của Pod.

### Đặc điểm của Service

- Chọn Pod bằng selector.
- Có IP/DNS ổn định trong cluster.
- Route traffic tới endpoint là Pod matching label.
- Nếu selector sai, Service không có endpoint.

### Các loại Service

`ClusterIP`:

- Mặc định.
- Chỉ truy cập trong cluster.
- Dùng cho internal service.

`NodePort`:

- Mở port trên node.
- Dễ dùng với minikube.
- Không phải lựa chọn đẹp nhất cho production.

`LoadBalancer`:

- Tạo cloud load balancer nếu cloud provider hỗ trợ.
- Hay dùng trên EKS/GKE/AKS.

`ExternalName`:

- Map Service tới DNS name bên ngoài.

### Service discovery và DNS nội bộ

Mỗi Service có DNS name nội bộ trong cluster.

Nếu cùng namespace, app có thể gọi:

```text
http://web
```

Tên đầy đủ:

```text
http://web.default.svc.cluster.local
```

Điều này giúp app không cần biết IP của Pod. Pod có chết, scale, đổi IP thì tên Service vẫn ổn định.

### Ingress là gì?

Ingress là resource định tuyến HTTP/HTTPS ở layer 7.

Service chủ yếu route theo IP/port. Ingress hiểu HTTP host/path.

Ví dụ:

```text
shop.com/api -> api-service
shop.com/web -> web-service
```

Ingress dùng khi:

- Nhiều service cùng dùng một entrypoint.
- Cần route theo domain/path.
- Cần TLS termination.

Lưu ý: Ingress object chỉ là luật. Muốn Ingress hoạt động, cluster cần Ingress Controller như NGINX Ingress hoặc Traefik.

---

## 15. Labels và selectors

Labels là key-value gắn vào resource.

Ví dụ:

```yaml
metadata:
  labels:
    app: nginx
    environment: dev
```

Selector dùng để chọn resource theo labels.

Ví dụ Service chọn Pod:

```yaml
selector:
  app: nginx
```

Nếu Service không route được tới Pod, kiểm tra:

```powershell
kubectl get pods --show-labels
kubectl get endpoints
kubectl describe svc nginx-service
```

Lỗi thường gặp nhất là label và selector không khớp.

### Labels/selectors dùng để làm gì?

Labels và selectors là cơ chế liên kết resource trong Kubernetes.

Chúng dùng để:

- Service tìm Pod.
- Deployment quản lý Pod.
- Lọc resource khi debug.
- Tổ chức resource theo app/environment/version.

### Đặc điểm

- Label là metadata, không phải tên resource.
- Một resource có thể có nhiều label.
- Selector phải khớp label thì mới chọn được resource.
- Label nên nhất quán trong toàn project.

Ví dụ label tốt:

```yaml
labels:
  app: nginx
  environment: dev
  tier: frontend
```

Lọc Pod theo label:

```powershell
kubectl get pods -l app=nginx
```

---

## 16. ConfigMap

ConfigMap lưu cấu hình không nhạy cảm.

Ví dụ:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "dev"
  LOG_LEVEL: "info"
```

Dùng trong Deployment:

```yaml
envFrom:
  - configMapRef:
      name: app-config
```

ConfigMap phù hợp cho:

- Environment name.
- Log level.
- Feature flag không nhạy cảm.
- Public URL không chứa secret.

### ConfigMap dùng để làm gì?

ConfigMap dùng để tách cấu hình khỏi image.

Nếu không dùng ConfigMap, bạn có thể phải build lại image chỉ vì đổi `LOG_LEVEL` từ `debug` sang `info`. Điều này không tốt.

Với ConfigMap:

- Image giữ nguyên.
- Cấu hình thay đổi theo môi trường.
- Dev/staging/prod có config khác nhau.

### Đặc điểm của ConfigMap

- Lưu key-value dạng text.
- Không dùng cho dữ liệu nhạy cảm.
- Có thể mount thành environment variables.
- Có thể mount thành file trong container.
- Thay đổi ConfigMap không phải lúc nào cũng tự restart Pod.

### Khi nào dùng ConfigMap?

Dùng cho:

- `APP_ENV`
- `LOG_LEVEL`
- `FEATURE_FLAG`
- URL nội bộ không chứa secret

Không dùng cho:

- Password.
- API key.
- Token.
- Private key.

---

## 17. Secret

Secret lưu dữ liệu nhạy cảm.

Ví dụ:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
stringData:
  DB_PASSWORD: "example-password"
```

Dùng trong Deployment:

```yaml
envFrom:
  - secretRef:
      name: app-secret
```

Lưu ý:

- Không commit secret thật lên Git.
- Kubernetes Secret mặc định không phải giải pháp bảo mật hoàn chỉnh.
- Production nên dùng secret manager như AWS Secrets Manager, External Secrets, Sealed Secrets.

### Secret dùng để làm gì?

Secret dùng để truyền dữ liệu nhạy cảm vào Pod mà không hard-code trong image.

Secret thường dùng cho:

- Database password.
- API token.
- TLS certificate.
- Docker registry credential.

### Đặc điểm của Secret

- Kubernetes lưu Secret dạng base64 encoded trong manifest/output.
- Base64 không phải mã hóa bảo mật.
- Secret có thể xuất hiện trong etcd nếu cluster không bật encryption at rest.
- Secret có thể được inject qua environment variable hoặc mount thành file.
- Cần RBAC để giới hạn ai được đọc Secret.

### Khi nào cần cẩn thận?

Không nên commit Secret thật vào Git:

```yaml
stringData:
  DB_PASSWORD: "real-production-password"
```

Trong production, nên dùng:

- External Secrets Operator.
- AWS Secrets Manager.
- HashiCorp Vault.
- Sealed Secrets.

---

## 18. Probes

Probe giúp Kubernetes kiểm tra tình trạng container.

### Liveness probe

Trả lời câu hỏi:

```text
App còn sống không?
```

Nếu fail, Kubernetes restart container.

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 10
```

### Readiness probe

Trả lời câu hỏi:

```text
App đã sẵn sàng nhận traffic chưa?
```

Nếu fail, Service không gửi traffic tới Pod đó.

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
```

Dễ nhớ:

```text
Liveness = có nên restart không?
Readiness = có nên nhận traffic không?
```

### Probes dùng để làm gì?

Probes giúp Kubernetes biết tình trạng app thay vì chỉ biết container process còn chạy.

Một process có thể vẫn chạy nhưng app bị treo, không trả lời request. Probe giúp phát hiện chuyện đó.

### Đặc điểm

- `livenessProbe` quyết định restart container.
- `readinessProbe` quyết định Pod có nhận traffic từ Service không.
- `startupProbe` dùng cho app khởi động lâu.
- Probe có thể dùng HTTP, TCP hoặc command.

### Running không có nghĩa là Ready

Một Pod có thể ở trạng thái `Running` nhưng app bên trong chưa sẵn sàng nhận traffic.

Ví dụ:

- App đang warm up.
- App đang connect database.
- App đang load config/model.
- Process chạy nhưng endpoint chưa trả lời được.

Nếu không có readiness probe, Service có thể gửi traffic vào Pod quá sớm và gây lỗi timeout/502.

Vì vậy với app thật, readiness probe thường quan trọng hơn bạn tưởng.

### Khi nào dùng startupProbe?

Nếu app cần nhiều thời gian để start, ví dụ Java app hoặc service load model AI, liveness probe có thể restart app quá sớm.

Khi đó dùng:

```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

Khi startup probe pass, Kubernetes mới bắt đầu dùng liveness/readiness probe.

---

## 19. NetworkPolicy

NetworkPolicy kiểm soát traffic vào/ra Pod.

Ví dụ chỉ cho frontend gọi backend:

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

Trong minikube, NetworkPolicy có thể cần CNI hỗ trợ. Hôm nay bạn chỉ cần đọc hiểu manifest và nắm mục đích bảo mật.

### NetworkPolicy dùng để làm gì?

NetworkPolicy dùng để giới hạn traffic giữa các Pod.

Nếu không có NetworkPolicy, nhiều cluster cho phép Pod nói chuyện với nhau khá tự do. Điều này tiện khi học nhưng không tốt về bảo mật.

NetworkPolicy giúp:

- Chỉ cho frontend gọi backend.
- Chỉ cho backend gọi database.
- Chặn namespace không liên quan.
- Giảm blast radius nếu một Pod bị compromise.

### Đặc điểm

- Áp dụng lên Pod thông qua `podSelector`.
- Có thể kiểm soát ingress, egress hoặc cả hai.
- Cần CNI hỗ trợ NetworkPolicy.
- Khi một Pod bị chọn bởi NetworkPolicy ingress, traffic không match policy sẽ bị chặn.

### Khi nào dùng NetworkPolicy?

Dùng khi bạn muốn áp dụng nguyên tắc:

```text
Default deny, only allow what is needed.
```

Trong production, NetworkPolicy là một phần quan trọng của Kubernetes security.

---

## 20. Autoscale với HPA

Autoscale là cơ chế tự tăng/giảm số Pod replicas theo tải thực tế.

Trong Kubernetes, autoscale phổ biến nhất ở mức cơ bản là **Horizontal Pod Autoscaler**, viết tắt là HPA.

### HPA dùng để làm gì?

HPA dùng để tự động scale Deployment/ReplicaSet/StatefulSet dựa trên metric.

Ví dụ:

```text
Nếu CPU trung bình > 70%, tăng số replicas.
Nếu tải giảm, giảm số replicas.
```

HPA giúp:

- App chịu tải tốt hơn khi traffic tăng.
- Giảm lãng phí khi traffic thấp.
- Không phải scale tay liên tục.

### Điều kiện để HPA hoạt động

HPA thường cần:

- `metrics-server` trong cluster.
- Pod có `resources.requests`.
- Deployment đang chạy ổn định.

Nếu không có `resources.requests`, HPA khó tính phần trăm CPU vì không biết baseline là gì.

### Công thức resources cho Pod

Ví dụ trong Deployment:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

Giải thích:

- `requests.cpu`: lượng CPU tối thiểu Pod cần, scheduler dùng để chọn node.
- `limits.cpu`: trần CPU Pod được dùng, vượt quá có thể bị throttle.
- `requests.memory`: lượng RAM tối thiểu Pod cần.
- `limits.memory`: trần RAM, vượt quá có thể bị `OOMKilled`.

`100m` nghĩa là 0.1 CPU core.

### Bật metrics-server trên minikube

```powershell
minikube addons enable metrics-server
```

Đợi một chút rồi kiểm tra:

```powershell
kubectl top nodes
kubectl top pods
```

Nếu mới bật xong mà chưa có metric, đợi 1-2 phút rồi chạy lại.

### Tạo HPA bằng command

```powershell
kubectl autoscale deployment web --min=2 --max=10 --cpu-percent=70
```

Kiểm tra:

```powershell
kubectl get hpa
kubectl describe hpa web
```

Ý nghĩa:

- Min replicas: 2.
- Max replicas: 10.
- Nếu CPU trung bình vượt 70%, HPA tăng replicas.

### HPA bằng YAML

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### HPA dùng khi nào?

Dùng HPA khi:

- App stateless.
- App có thể chạy nhiều replicas độc lập.
- Có metric đáng tin cậy.
- Đã đặt requests/limits.

Không nên kỳ vọng HPA giải quyết mọi thứ nếu:

- App bị bottleneck ở database.
- App stateful khó scale ngang.
- Cluster không còn đủ node/resource.
- Startup app quá chậm nhưng chưa cấu hình readiness/startup probe.

---

## 21. Taints và Tolerations

Taints và tolerations là cơ chế điều khiển Pod có được schedule lên node nào hay không.

Nói ngắn:

```text
Taint nằm trên Node.
Toleration nằm trên Pod.
Pod chỉ được lên node bị taint nếu nó tolerates taint đó.
```

### Taints/tolerations dùng để làm gì?

Dùng để:

- Chặn workload thường chạy lên node đặc biệt.
- Dành node riêng cho workload quan trọng.
- Tách workload GPU, database, monitoring, ingress.
- Tránh Pod thường chạy lên control-plane node.
- Điều phối workload theo mục đích node.

### Taint là gì?

Taint là dấu gắn lên node để nói:

```text
Node này không nhận Pod bình thường.
```

Ví dụ taint node:

```powershell
kubectl taint nodes <node-name> dedicated=web:NoSchedule
```

Ý nghĩa:

- Key: `dedicated`
- Value: `web`
- Effect: `NoSchedule`

Effect `NoSchedule` nghĩa là Pod mới sẽ không được schedule lên node này nếu không có toleration phù hợp.

### Toleration là gì?

Toleration là khai báo trong Pod/Deployment cho phép Pod chịu được taint trên node.

Ví dụ trong Deployment:

```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "web"
    effect: "NoSchedule"
```

Nếu Pod có toleration này, nó có thể được schedule lên node có taint:

```text
dedicated=web:NoSchedule
```

### Các effect phổ biến

| Effect | Ý nghĩa |
|---|---|
| `NoSchedule` | Không schedule Pod mới lên node nếu Pod không tolerates taint |
| `PreferNoSchedule` | Cố gắng tránh schedule, nhưng không tuyệt đối |
| `NoExecute` | Pod đang chạy cũng có thể bị evict nếu không tolerates |

### Toleration không ép Pod chạy lên node

Điểm rất dễ nhầm:

```text
Toleration chỉ cho phép Pod chạy lên node bị taint.
Nó không bắt buộc Pod phải chạy lên node đó.
```

Nếu muốn ép/chọn node, cần kết hợp:

- `nodeSelector`
- `nodeAffinity`
- taints/tolerations

Ví dụ:

```yaml
nodeSelector:
  workload: web
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "web"
    effect: "NoSchedule"
```

### Lab nhỏ với minikube

Vì minikube thường chỉ có một node, taint node có thể làm Pod không schedule được nếu bạn chưa hiểu rõ. Nếu thử, nhớ xóa taint sau lab.

Xem node:

```powershell
kubectl get nodes
```

Taint node:

```powershell
kubectl taint nodes minikube dedicated=web:NoSchedule
```

Xóa taint:

```powershell
kubectl taint nodes minikube dedicated=web:NoSchedule-
```

Dấu `-` cuối lệnh nghĩa là remove taint.

---

## 22. Lab cơ bản: chạy Nginx trên Kubernetes

### Bước 1: kiểm tra Docker

```powershell
docker info
```

Nếu lỗi, mở Docker Desktop trước.

### Bước 2: start minikube

```powershell
minikube start --driver=docker
kubectl get nodes
```

### Bước 3: tạo Deployment

```powershell
kubectl create deployment nginx --image=nginx:1.27
```

Kiểm tra:

```powershell
kubectl get deployments
kubectl get pods
```

### Bước 4: expose app bằng Service

```powershell
kubectl expose deployment nginx --type=NodePort --port=80
```

Kiểm tra:

```powershell
kubectl get svc
```

Lấy URL:

```powershell
minikube service nginx --url
```

### Bước 5: scale app

```powershell
kubectl scale deployment nginx --replicas=3
kubectl get pods
```

### Bước 6: cleanup

```powershell
kubectl delete service nginx
kubectl delete deployment nginx
```

---

## 23. Debug lỗi thường gặp

### Docker CLI có nhưng Docker daemon chưa chạy

Triệu chứng:

```text
failed to connect to the docker API
```

Cách xử lý:

- Mở Docker Desktop.
- Chờ Docker Engine chạy xong.
- Chạy lại:

```powershell
docker info
```

### minikube không chọn được driver

Triệu chứng:

```text
Unable to pick a default driver
```

Cách xử lý:

```powershell
minikube start --driver=docker
```

Nếu vẫn lỗi, kiểm tra Docker Desktop trước.

### kubectl báo localhost:8080 refused

Triệu chứng:

```text
Unable to connect to the server: dial tcp [::1]:8080
```

Nguyên nhân thường là chưa có cluster hoặc kubeconfig chưa đúng.

Cách xử lý:

```powershell
minikube status
minikube start --driver=docker
kubectl get nodes
```

### Pod bị Pending

Kiểm tra:

```powershell
kubectl describe pod <pod-name>
```

Nguyên nhân có thể:

- Thiếu resource CPU/RAM.
- Image pull lỗi.
- Node chưa Ready.

### Pod bị ImagePullBackOff

Kiểm tra image name/tag:

```powershell
kubectl describe pod <pod-name>
```

Nguyên nhân thường gặp:

- Sai tên image.
- Sai tag.
- Registry private nhưng chưa có secret.
- Không có internet.

---

## 24. Checklist học

- [ ] Hiểu Docker image.
- [ ] Hiểu Docker container.
- [ ] Chạy được `docker info`.
- [ ] Chạy thử container Nginx bằng Docker.
- [ ] Hiểu Kubernetes cluster/node/control plane.
- [ ] Start được minikube.
- [ ] Chạy được `kubectl get nodes`.
- [ ] Tạo được Deployment Nginx.
- [ ] Expose Deployment bằng Service.
- [ ] Lấy được URL bằng `minikube service`.
- [ ] Scale Deployment lên 3 replicas.
- [ ] Hiểu HPA/autoscale cần metrics-server và resources requests.
- [ ] Hiểu taints nằm trên node, tolerations nằm trên Pod.
- [ ] Cleanup resource sau lab.
- [ ] Ghi evidence vào `cloud/w8/day-b/README.md`.

---

## 25. Câu hỏi tự kiểm tra

1. Image khác container như thế nào?
2. Dockerfile dùng để làm gì?
3. Vì sao cần map port khi chạy Docker container?
4. Kubernetes giải quyết vấn đề gì mà Docker đơn lẻ chưa đủ?
5. Pod là gì?
6. Deployment khác Pod đơn lẻ như thế nào?
7. Service giải quyết vấn đề gì?
8. Label và selector liên quan với nhau thế nào?
9. Liveness probe khác readiness probe thế nào?
10. Khi `kubectl get nodes` lỗi localhost:8080 refused, bạn sẽ kiểm tra gì?
11. HPA cần điều kiện gì để hoạt động?
12. `requests` khác `limits` như thế nào?
13. Taint khác toleration như thế nào?
14. Toleration có ép Pod chạy lên node bị taint không?

---

## 26. Lệnh nhớ nhanh

Docker:

```powershell
docker --version
docker info
docker ps
docker images
docker run -d -p 8080:80 nginx:1.27
docker stop <container>
docker rm <container>
```

minikube:

```powershell
minikube version
minikube start --driver=docker
minikube status
minikube service <service-name> --url
minikube stop
```

kubectl:

```powershell
kubectl version --client
kubectl cluster-info
kubectl get nodes
kubectl get pods
kubectl get pods -A
kubectl get svc
kubectl get deployments
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl apply -f file.yaml
kubectl delete -f file.yaml
kubectl autoscale deployment web --min=2 --max=10 --cpu-percent=70
kubectl get hpa
kubectl taint nodes minikube dedicated=web:NoSchedule
kubectl taint nodes minikube dedicated=web:NoSchedule-
```

---

## 27. Tài liệu nên đọc

- Docker overview: https://docs.docker.com/get-started/docker-overview/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Kubernetes concepts: https://kubernetes.io/docs/concepts/
- Kubernetes basics: https://kubernetes.io/docs/tutorials/kubernetes-basics/
- kubectl cheat sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- minikube start: https://minikube.sigs.k8s.io/docs/start/
- HPA: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- Taints and tolerations: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
