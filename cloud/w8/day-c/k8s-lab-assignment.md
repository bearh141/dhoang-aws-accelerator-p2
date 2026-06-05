# W8 Day C - Kubernetes Lab Assignment

## Mục tiêu bài tập

Bạn cần hoàn thành một chuỗi lab Kubernetes từ nền tảng đến thực hành:

1. Dựng cluster local bằng minikube.
2. Tạo Pod trần để hiểu Pod là ephemeral.
3. Tạo Deployment bằng YAML.
4. Quan sát Deployment -> ReplicaSet -> Pod.
5. Kiểm tra labels/selectors.
6. Thử self-healing bằng cách xóa Pod thuộc Deployment.
7. Tạo ConfigMap và Secret, inject vào Deployment.
8. Expose app bằng Service.
9. Scale app.
10. Rollout version mới và rollback.
11. Cố tình làm lỗi image để debug bằng `get -> describe -> logs`.
12. Ghi evidence vào README/reflection.

Tài liệu này dùng cú pháp **PowerShell trên Windows**, không dùng cú pháp bash như `\`, `head`, `grep`.

---

## 0. Kiểm tra môi trường

Chạy:

```powershell
docker info
kubectl version --client
minikube version
```

Nếu `docker info` lỗi, mở Docker Desktop và chờ Docker Engine chạy xong.

Start cluster:

```powershell
minikube start --driver=docker
```

Kiểm tra:

```powershell
kubectl get nodes
kubectl cluster-info
minikube status
```

Kết quả đạt:

```text
Node minikube ở trạng thái Ready
```

Evidence cần lưu:

```powershell
kubectl get nodes
kubectl cluster-info
```

---

## 1. Lab Pod trần

Tạo một Pod Nginx:

```powershell
kubectl run hello --image=nginx:1.27 --port=80
```

Xem Pod:

```powershell
kubectl get pods -o wide
kubectl describe pod hello
```

Chạy lệnh trong Pod:

```powershell
kubectl exec -it hello -- sh -c "hostname; nginx -v"
```

Xóa Pod:

```powershell
kubectl delete pod hello
kubectl get pods
```

Bạn cần hiểu:

- Pod trần bị xóa là mất hẳn.
- Không có controller nào tạo lại Pod này.
- Đây là lý do production thường không tạo Pod trực tiếp.

Evidence:

```powershell
kubectl get pods -o wide
kubectl describe pod hello
```

---

## 2. Lab Deployment bằng YAML

File của bạn đang ở:

```text
cloud/w8/day-c/web.yaml
```

Nếu terminal đang đứng ở root repo:

```powershell
kubectl apply -f .\cloud\w8\day-c\web.yaml
```

Nếu đã `cd` vào `cloud/w8/day-c`:

```powershell
kubectl apply -f web.yaml
```

Kiểm tra phả hệ:

```powershell
kubectl get deploy,rs,pods
kubectl get pods -o wide
```

Kết quả đạt:

```text
Deployment web tồn tại
ReplicaSet của web tồn tại
Pod của web Running
```

Bạn cần hiểu:

```text
Deployment -> ReplicaSet -> Pod
```

Deployment là object bạn quản lý trực tiếp. ReplicaSet giữ số Pod đúng với `replicas`. Pod là workload thật.

---

## 3. Lab Labels và Selectors

Xem labels:

```powershell
kubectl get pods --show-labels
```

Lọc Pod theo label:

```powershell
kubectl get pods -l app=web
```

Xem logs theo label:

```powershell
kubectl logs -l app=web --tail=3
```

Bạn cần hiểu:

- Labels là metadata dạng key-value.
- Selector dùng labels để tìm Pod.
- Deployment và Service đều dựa rất nhiều vào labels/selectors.

---

## 4. Lab Self-Healing

Lấy tên một Pod thuộc app `web`:

```powershell
$pod = kubectl get pod -l app=web -o jsonpath="{.items[0].metadata.name}"
```

Xóa Pod đó:

```powershell
kubectl delete pod $pod
```

Watch Pod mọc lại:

```powershell
kubectl get pods -w
```

Thoát watch bằng:

```text
Ctrl + C
```

Bạn cần quan sát:

- Pod cũ chuyển `Terminating`.
- Pod mới chuyển `ContainerCreating`.
- Sau đó Pod mới `Running`.
- Tổng số Pod quay về đúng số replicas.

Bạn cần giải thích được:

```text
ReplicaSet thấy actual state thiếu Pod so với desired state, nên tạo Pod mới.
```

---

## 5. Lab ConfigMap và Secret

Tạo ConfigMap:

```powershell
kubectl create configmap app-cfg --from-literal=APP_ENV=production
```

Tạo Secret:

```powershell
kubectl create secret generic app-sec --from-literal=DB_PASSWORD=s3cr3t
```

Inject vào Deployment:

```powershell
kubectl set env deploy/web --from=configmap/app-cfg
kubectl set env deploy/web --from=secret/app-sec
```

Chờ rollout:

```powershell
kubectl rollout status deploy/web
```

Kiểm tra env trong Pod:

```powershell
kubectl exec deploy/web -- env | Select-String "APP_ENV|DB_PASSWORD"
```

Kết quả mong đợi:

```text
APP_ENV=production
DB_PASSWORD=s3cr3t
```

Bạn cần hiểu:

- ConfigMap chứa config không nhạy cảm.
- Secret chứa dữ liệu nhạy cảm.
- `kubectl set env` làm Deployment rollout lại Pod.
- Trong lab có thể dùng secret đơn giản, nhưng thực tế không đưa password thật vào command history/Git.

Nếu resource đã tồn tại và lệnh create báo lỗi, có thể xóa để tạo lại:

```powershell
kubectl delete configmap app-cfg
kubectl delete secret app-sec
```

---

## 6. Lab Service và truy cập app

Expose Deployment:

```powershell
kubectl expose deployment web --type=NodePort --port=80
```

Kiểm tra Service:

```powershell
kubectl get svc web
kubectl get endpoints web
```

Lấy URL bằng minikube:

```powershell
minikube service web --url
```

Hoặc dùng port-forward:

```powershell
kubectl port-forward svc/web 8080:80
```

Sau đó mở:

```text
http://localhost:8080
```

Bạn cần hiểu:

- Service đứng trước Pod.
- Service dùng selector `app=web` để tìm Pod.
- Client không gọi Pod IP trực tiếp.
- Service route traffic tới Pod matching label.

---

## 7. Lab Scale

Scale lên 5 replicas:

```powershell
kubectl scale deploy/web --replicas=5
```

Kiểm tra:

```powershell
kubectl get deploy,rs,pods
kubectl get pods -l app=web
```

Bạn cần hiểu:

- Scale thay đổi desired replicas của Deployment.
- ReplicaSet tạo thêm Pod để đạt số lượng mong muốn.

---

## 8. Lab Rollout và Rollback

Cập nhật image:

```powershell
kubectl set image deploy/web web=nginx:1.28
```

Theo dõi rollout:

```powershell
kubectl rollout status deploy/web
```

Xem lịch sử:

```powershell
kubectl rollout history deploy/web
```

Rollback:

```powershell
kubectl rollout undo deploy/web
```

Kiểm tra lại:

```powershell
kubectl rollout status deploy/web
kubectl get pods
```

Bạn cần hiểu:

- Deployment rolling update bằng cách tạo ReplicaSet mới.
- Pod cũ giảm dần, Pod mới tăng dần.
- Rollback đưa Deployment về revision trước.

---

## 9. Lab Break -> Debug -> Recover

Cố tình set image sai:

```powershell
kubectl set image deploy/web web=nginx:khong-co-tag
```

Kiểm tra trạng thái:

```powershell
kubectl get pods
```

Tìm Pod lỗi:

```powershell
kubectl get pods
```

Describe Pod lỗi:

```powershell
kubectl describe pod <pod-name>
```

Bạn sẽ thấy lỗi kiểu:

```text
ImagePullBackOff
Failed to pull image
```

Recover bằng rollback:

```powershell
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
kubectl get pods
```

Bạn cần nhớ quy trình debug:

```text
kubectl get -> kubectl describe -> kubectl logs
```

---

## 10. Cleanup sau lab

Xóa resource app:

```powershell
kubectl delete deploy/web svc/web
kubectl delete configmap app-cfg
kubectl delete secret app-sec
```

Nếu muốn giữ cluster để học tiếp:

```powershell
minikube stop
```

Nếu muốn xóa cluster hoàn toàn:

```powershell
minikube delete
```

---

## 11. Evidence cần nộp/ghi lại

Ghi vào `cloud/w8/day-c/README.md` hoặc `cloud/w8/reflection.md`:

```text
1. docker info chạy được.
2. kubectl get nodes: node Ready.
3. kubectl get deploy,rs,pods sau khi apply web.yaml.
4. kubectl get pods --show-labels.
5. Evidence self-healing: xóa 1 Pod và Pod mới mọc lại.
6. Evidence ConfigMap/Secret: APP_ENV và DB_PASSWORD xuất hiện trong env.
7. kubectl get svc web và URL từ minikube service hoặc port-forward.
8. Evidence scale lên 5 replicas.
9. Evidence rollout image mới.
10. Evidence rollback thành công.
11. Debug note về ImagePullBackOff.
```

---

## 12. Challenge lớn sau lab

Đề challenge trong tài liệu mentor:

```text
K8s on AWS - Terraform 1-Click
```

Yêu cầu cấp cao:

- Dựng EC2 bằng Terraform.
- Chạy minikube hoặc kind trên EC2.
- Deploy app nhỏ trong Kubernetes.
- Expose app ra Internet qua ALB.
- Tất cả dựng được bằng một lệnh hoặc một flow automation rõ ràng.
- Có dùng ít nhất 2 Terraform providers.
- Có README giải thích kiến trúc, lệnh chạy và cách wire provider.
- Có evidence URL ALB mở được app.
- Destroy sạch sau khi xong.

Hiện tại W8 lab local là nền tảng để chuẩn bị cho challenge này. Bạn chưa cần giải ngay toàn bộ challenge nếu mentor chưa yêu cầu, nhưng nên hiểu hướng đi:

```text
Terraform tạo hạ tầng AWS -> EC2 chạy K8s local -> app chạy trong K8s -> ALB route traffic vào app
```

---

## 13. Checklist hoàn thành

- [ ] Start được minikube.
- [ ] `kubectl get nodes` thấy Ready.
- [ ] Tạo và xóa Pod trần `hello`.
- [ ] Apply `web.yaml`.
- [ ] Thấy Deployment, ReplicaSet, Pod.
- [ ] Lọc Pod bằng label `app=web`.
- [ ] Xóa 1 Pod và thấy Pod mới mọc lại.
- [ ] Tạo ConfigMap `app-cfg`.
- [ ] Tạo Secret `app-sec`.
- [ ] Inject env vào Deployment.
- [ ] Kiểm tra env trong Pod.
- [ ] Expose Deployment bằng Service.
- [ ] Truy cập Nginx qua URL/port-forward.
- [ ] Scale lên 5 replicas.
- [ ] Rollout image mới.
- [ ] Rollback thành công.
- [ ] Cố tình gây lỗi image và debug được.
- [ ] Ghi evidence.
