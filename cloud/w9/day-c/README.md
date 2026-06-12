# W9 Day C - CloudWatch Agent and CPU Alarm Email Alert

Bài lab này triển khai đúng yêu cầu:

1. Cài CloudWatch Agent trên EC2.
2. Tạo SNS Topic và Email Subscription.
3. Tạo CloudWatch Alarm theo CPU EC2.
4. Khi CPU vượt ngưỡng, CloudWatch gửi cảnh báo qua SNS về email.

## Kiến Trúc

```text
EC2 Instance
  -> CloudWatch Agent
  -> CloudWatch Metrics
  -> CloudWatch Alarm: CPUUtilization > threshold
  -> SNS Topic
  -> Email Subscription
  -> User Email
```

## Thư Mục

```text
day-c/
  README.md
  EVIDENCE.md
  terraform/
    versions.tf
    variables.tf
    main.tf
    iam.tf
    security-groups.tf
    ec2.tf
    sns.tf
    cloudwatch.tf
    outputs.tf
    user-data.sh
```

## Điều Kiện Cần Có

- AWS CLI đã cấu hình bằng `aws configure`.
- Terraform đã cài.
- AWS account có quyền tạo EC2, IAM Role, SNS, CloudWatch Alarm.
- Một email thật để nhận SNS alert.

Kiểm tra account:

```powershell
aws sts get-caller-identity
```

## Cách Chạy

Đi vào thư mục Terraform:

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w9\day-c\terraform
```

Tạo file `terraform.tfvars`:

```hcl
aws_region          = "ap-southeast-1"
project_name        = "w9-cloudwatch-alarm"
notification_email  = "your-email@example.com"
cpu_alarm_threshold = 80
```

Chạy Terraform:

```powershell
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Sau khi apply xong, mở email và bấm **Confirm subscription** từ AWS SNS.

Nếu chưa confirm subscription, SNS sẽ không gửi alert về email.

## Test CPU Alarm

SSH vào EC2:

```powershell
ssh -i .\w9-cloudwatch-alarm.pem ubuntu@<ec2_public_ip>
```

Chạy stress CPU:

```bash
stress-ng --cpu 2 --timeout 8m --metrics-brief
```

Chờ khoảng vài phút rồi kiểm tra:

- CloudWatch Alarm chuyển từ `OK` sang `In alarm`.
- Email nhận được alert từ SNS.

## Kiểm Tra CloudWatch Agent

SSH vào EC2 rồi chạy:

```bash
sudo systemctl status amazon-cloudwatch-agent --no-pager
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

CloudWatch Agent được dùng để gửi thêm metric hệ thống như memory và disk usage. CPU alarm trong bài dùng metric mặc định `AWS/EC2 CPUUtilization`.

## Kiểm Tra Bằng AWS CLI

Xem SNS topic:

```powershell
aws sns list-topics --region ap-southeast-1
```

Xem subscription:

```powershell
aws sns list-subscriptions-by-topic `
  --topic-arn <sns_topic_arn> `
  --region ap-southeast-1
```

Xem alarm:

```powershell
aws cloudwatch describe-alarms `
  --alarm-names w9-cloudwatch-alarm-high-cpu `
  --region ap-southeast-1
```

## Cleanup

Sau khi chụp evidence xong, destroy để tránh tốn phí:

```powershell
terraform destroy
```

## Ghi Chú

- SNS email subscription phải được confirm thủ công qua email.
- Alarm dùng điều kiện mặc định: CPU lớn hơn threshold trong 5 phút.
- Để test nhanh hơn, có thể giảm `cpu_alarm_period` hoặc `cpu_alarm_evaluation_periods` trong `terraform.tfvars`.
- Không commit `.pem`, `.tfstate`, `.tfvars`, `.terraform/`, hoặc `tfplan`.

