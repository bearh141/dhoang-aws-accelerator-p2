#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export MINIKUBE_HOME=/root

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin conntrack
systemctl enable docker
systemctl start docker

curl -LO "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install -o root -g root -m 0755 minikube-linux-amd64 /usr/local/bin/minikube

mkdir -p /opt/w8-challenge/app /opt/w8-challenge/k8s

cat > /opt/w8-challenge/app/Dockerfile <<'APP_DOCKERFILE'
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
APP_DOCKERFILE

cat > /opt/w8-challenge/app/nginx.conf <<'APP_NGINX'
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
APP_NGINX

cat > /opt/w8-challenge/app/index.html <<'APP_HTML'
<!doctype html>
<html lang="vi">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>W8 Kubernetes Challenge</title>
    <style>
      body {
        margin: 0;
        min-height: 100vh;
        display: grid;
        place-items: center;
        font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        background: #f6f8fb;
        color: #172033;
      }
      main {
        width: min(900px, calc(100vw - 40px));
        padding: 40px;
        background: white;
        border: 1px solid #d9e1ee;
        border-radius: 8px;
        box-shadow: 0 18px 60px rgba(28, 43, 68, 0.12);
      }
      .status {
        display: inline-flex;
        gap: 10px;
        padding: 8px 12px;
        border-radius: 999px;
        background: #e8f7ef;
        color: #17633a;
        font-weight: 700;
      }
      .dot {
        width: 10px;
        height: 10px;
        border-radius: 999px;
        background: #20b15a;
        margin-top: 7px;
      }
      h1 {
        margin: 24px 0 12px;
        font-size: 52px;
        line-height: 1.05;
      }
      p {
        max-width: 720px;
        color: #4b5870;
        font-size: 18px;
        line-height: 1.7;
      }
    </style>
  </head>
  <body>
    <main>
      <span class="status"><span class="dot"></span>Running in Kubernetes</span>
      <h1>W8 K8s on AWS Challenge</h1>
      <p>
        This lightweight Nginx app is built as a Docker image, deployed into a
        Kubernetes cluster on EC2, and exposed through an AWS Application Load Balancer.
      </p>
    </main>
  </body>
</html>
APP_HTML

cat > /opt/w8-challenge/k8s/deployment.yaml <<'APP_DEPLOYMENT'
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
APP_DEPLOYMENT

cat > /opt/w8-challenge/k8s/service.yaml <<APP_SERVICE
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
      nodePort: ${node_port}
APP_SERVICE

cat > /opt/w8-challenge/k8s/hpa.yaml <<'APP_HPA'
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
APP_HPA

docker build -t w8-k8s-challenge-web:local /opt/w8-challenge/app

minikube start --driver=docker --force --cpus=2 --memory=1800mb --ports=${node_port}:${node_port}
minikube image load w8-k8s-challenge-web:local
minikube addons enable metrics-server || true

kubectl apply -f /opt/w8-challenge/k8s/deployment.yaml
kubectl apply -f /opt/w8-challenge/k8s/service.yaml
kubectl apply -f /opt/w8-challenge/k8s/hpa.yaml
kubectl rollout status deployment/restaurant-web --timeout=180s
curl --retry 20 --retry-delay 5 --retry-all-errors -fsS http://127.0.0.1:${node_port}/healthz

kubectl get deploy,rs,pods,svc,hpa -o wide > /opt/w8-challenge/evidence.txt
