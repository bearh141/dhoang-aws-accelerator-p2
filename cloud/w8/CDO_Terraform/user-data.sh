#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx

cat >/var/www/html/index.html <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${project_name}</title>
  <style>
    body {
      margin: 0;
      font-family: Arial, sans-serif;
      background: #f6f8fb;
      color: #122033;
    }
    main {
      max-width: 920px;
      margin: 56px auto;
      padding: 32px;
      background: white;
      border: 1px solid #d9e2ef;
    }
    h1 {
      margin-top: 0;
      color: #0f3b66;
    }
    code {
      background: #eef3f8;
      padding: 2px 6px;
    }
    ul {
      line-height: 1.8;
    }
  </style>
</head>
<body>
  <main>
    <h1>${project_name}</h1>
    <p>This web app is deployed by Terraform on AWS.</p>
    <ul>
      <li>Compute: EC2 public subnet</li>
      <li>Database: RDS MySQL private subnet</li>
      <li>Static assets bucket: <code>${s3_bucket}</code></li>
      <li>Database endpoint: <code>${db_endpoint}</code></li>
      <li>Database name: <code>${db_name}</code></li>
    </ul>
  </main>
</body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
