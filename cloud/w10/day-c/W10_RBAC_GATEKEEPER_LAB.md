# W10 Day C Lab - RBAC + Gatekeeper Admission Policy

Lab này được làm dựa trên repo:

```text
https://github.com/bearh141/dhoang-aws-accelerator-p2 (thư mục cloud/w10/day-c)
```

Mục tiêu là bổ sung lớp **Secure & Operate** vào platform GitOps đã có:

- App-of-Apps bằng ArgoCD.
- API canary bằng Argo Rollouts.
- Prometheus/Grafana/AlertManager.
- RBAC 3 vai trò.
- Gatekeeper admission policy để chặn manifest rủi ro.

## 1. Cấu Trúc Được Bổ Sung

```text
day-c/
  argocd/
    root.yaml
    apps/
      rbac.yaml
      gatekeeper.yaml
      gatekeeper-policies.yaml
  rbac/
    kustomization.yaml
    roles.yaml
    rolebindings.yaml
  gatekeeper/
    kustomization.yaml
    templates/
    constraints/
  policy-tests/
```

## 2. App-of-Apps

Root app:

```text
argocd/root.yaml
```

Root app đọc toàn bộ child apps trong:

```text
argocd/apps/
```

Các app mới được thêm:

| App | Vai trò | Sync wave |
| --- | --- | --- |
| `rbac` | Tạo 3 role và binding | `-1` |
| `gatekeeper` | Cài OPA Gatekeeper controller | `0` |
| `gatekeeper-policies` | Apply ConstraintTemplate và Constraint | `1` |

## 3. Lưu Ý Về repoURL

Các file hiện đang dùng repo:

```text
https://github.com/bearh141/dhoang-aws-accelerator-p2.git
```

Nếu em push lab này lên repo hoặc fork riêng, cần đổi `repoURL` trong các file sau:

```text
argocd/root.yaml
argocd/apps/*.yaml
```

Ví dụ nếu dùng repo cá nhân:

```yaml
repoURL: https://github.com/<username>/<repo>.git
```

Nếu không đổi `repoURL`, ArgoCD sẽ đọc repo gốc và không thấy phần em tự bổ sung.

## 4. Lab 1.1 - RBAC 3 Vai Trò

File:

```text
rbac/roles.yaml
rbac/rolebindings.yaml
```

Yêu cầu:

| User | Role | Quyền |
| --- | --- | --- |
| `alice` | `developer` | CRUD workload chỉ trong namespace `demo` |
| `bob` | `sre` | Xem và thao tác pod toàn cluster |
| `carol` | `viewer` | Chỉ đọc toàn cluster |

Kiểm tra:

```bash
kubectl auth can-i create deploy -n demo --as alice
kubectl auth can-i create deploy -n kube-system --as alice
kubectl auth can-i get pods -A --as bob
kubectl auth can-i delete nodes --as carol
```

Kết quả mong đợi:

```text
alice create deploy -n demo        -> yes
alice create deploy -n kube-system -> no
bob get pods -A                    -> yes
carol delete nodes                 -> no
```

## 5. Lab 1.2 - Gatekeeper 4 Constraints

File:

```text
gatekeeper/templates/
gatekeeper/constraints/
```

Các policy được enforce:

| Policy | Mục tiêu |
| --- | --- |
| `disallow-latest-tag` | Cấm image tag `:latest` |
| `require-resource-limits` | Bắt buộc có `resources.limits.cpu` và `resources.limits.memory` |
| `disallow-root-user` | Cấm `runAsUser: 0` |
| `disallow-host-network` | Cấm `hostNetwork: true` |

## 6. Lab 1.3 - Custom Policy

Custom policy đã chọn:

```text
Bắt buộc workload có label owner
```

File:

```text
gatekeeper/templates/k8srequiredownerlabel.yaml
gatekeeper/constraints/require-owner-label.yaml
```

Policy áp dụng cho:

- `Deployment`
- `Rollout`

App API đã được sửa để có label:

```yaml
metadata:
  labels:
    owner: platform
```

## 7. Chạy Lab

### 7.1. Start cluster

```bash
minikube start -p w10 --driver=docker
kubectl config use-context w10
```

### 7.2. Cài ArgoCD

```bash
kubectl create ns argocd
kubectl apply --server-side -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server
```

### 7.3. Apply root app

```bash
kubectl apply -f argocd/root.yaml
kubectl -n argocd get applications
```

Chờ các app chính `Synced/Healthy`:

```bash
kubectl -n argocd get applications
```

## 8. Nghiệm Thu RBAC

Chạy:

```bash
kubectl auth can-i create deploy -n demo --as alice
kubectl auth can-i create deploy -n kube-system --as alice
kubectl auth can-i get pods -A --as bob
kubectl auth can-i delete nodes --as carol
```

Nếu kết quả đúng `yes/no/yes/no`, phần RBAC đạt.

## 9. Nghiệm Thu Gatekeeper

Các manifest test nằm trong:

```text
policy-tests/
```

Test manifest vi phạm:

```bash
kubectl apply -f policy-tests/bad-latest.yaml
kubectl apply -f policy-tests/bad-no-limits.yaml
kubectl apply -f policy-tests/bad-root-user.yaml
kubectl apply -f policy-tests/bad-host-network.yaml
kubectl apply -f policy-tests/bad-no-owner-deployment.yaml
```

Kỳ vọng:

```text
Error from server (Forbidden)
admission webhook denied the request
```

Test manifest hợp lệ:

```bash
kubectl apply -f policy-tests/good-pod.yaml
kubectl -n demo get pod good-pod
```

Kỳ vọng:

```text
pod/good-pod created
```

Dọn pod test:

```bash
kubectl -n demo delete pod good-pod
```

## 10. Evidence Cần Chụp

Chụp các màn hình sau:

1. ArgoCD Applications có `rbac`, `gatekeeper`, `gatekeeper-policies`.
2. `kubectl auth can-i` trả đúng kết quả `yes/no/yes/no`.
3. Gatekeeper pods đang chạy:

```bash
kubectl -n gatekeeper-system get pods
```

4. ConstraintTemplate và Constraint đã tồn tại:

```bash
kubectl get constrainttemplates
kubectl get K8sDisallowLatestTag
kubectl get K8sRequiredResourceLimits
kubectl get K8sDisallowRootUser
kubectl get K8sDisallowHostNetwork
kubectl get K8sRequiredOwnerLabel
```

5. Manifest vi phạm bị reject.
6. Manifest hợp lệ được apply thành công.

## 11. Giải Thích Ngắn Khi Vấn Đáp

RBAC kiểm soát:

```text
Ai được làm gì?
```

Gatekeeper kiểm soát:

```text
Manifest có được phép vào cluster không?
```

Luồng admission:

```text
kubectl apply
-> API Server
-> Authentication
-> RBAC Authorization
-> Gatekeeper admission webhook
-> etcd
```

Nếu manifest vi phạm policy, Gatekeeper reject trước khi resource được lưu vào cluster.
