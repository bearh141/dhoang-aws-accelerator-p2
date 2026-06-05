# Day B - Kubernetes Container and Orchestration

## Mục tiêu

Xây nền tảng Kubernetes trước buổi lab onsite.

Tài liệu chính hôm nay:

- `../00-study-materials/day-02-kubernetes-foundation.md`
- `../00-study-materials/docker-kubernetes-complete-guide.md`

## Chủ đề

- Container basics
- Orchestration
- Pod
- Service
- Liveness và readiness probes
- ConfigMap và Secret
- NetworkPolicy

## Công cụ cần cài

- Docker Desktop
- kubectl
- minikube

## Việc cần làm hôm nay

- [ ] Đọc tài liệu ngày 02.
- [ ] Kiểm tra Docker Desktop đã chạy.
- [ ] Kiểm tra `docker --version`.
- [ ] Kiểm tra `kubectl version --client`.
- [ ] Kiểm tra `minikube version`.
- [ ] Chạy `minikube start`.
- [ ] Chạy `minikube status`.
- [ ] Chạy `kubectl get nodes`.
- [ ] Tạo manifest Pod.
- [ ] Tạo manifest Deployment.
- [ ] Tạo manifest Service.
- [ ] Kiểm tra `kubectl get pods`.
- [ ] Kiểm tra `kubectl get svc`.
- [ ] Ghi evidence vào phần bên dưới.
- [ ] Cập nhật `../reflection.md`.

## Evidence

### Tool versions

```text
docker --version:

kubectl version --client:

minikube version:
```

### Cluster status

```text
minikube status:

kubectl get nodes:
```

### Workload status

```text
kubectl get pods:

kubectl get deployments:

kubectl get svc:

kubectl get endpoints:
```

### App URL

```text
minikube service nginx-service --url:
```

## Ghi chú

Thêm ghi chú học tập và evidence cài đặt tại đây.
