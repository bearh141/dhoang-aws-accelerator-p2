# W9 Day C - AWS Monitoring Alerts

Thư mục này triển khai 2 bài monitoring trên AWS:

1. **EC2 CPU Alarm -> Email Alert via SNS**
2. **AWS Root Account Login Alert -> Email Alert via SNS**

Cả hai bài đều dùng Terraform để tạo hạ tầng và cấu hình cảnh báo.

## Kiến trúc tổng quan

```text
CPU Alarm:
EC2 Instance
  -> CloudWatch Metric: CPUUtilization
  -> CloudWatch Alarm
  -> SNS Topic
  -> Email

Root Login Alarm:
AWS Account Events
  -> CloudTrail
  -> CloudWatch Logs
  -> Metric Filter: RootAccountLoginCount
  -> CloudWatch Alarm
  -> SNS Topic
  -> Email
```

## Cấu trúc thư mục

```text
day-c/
  README.md
  EVIDENCE.md
  evidence/
  terraform/
    versions.tf
    variables.tf
    main.tf
    iam.tf
    security-groups.tf
    ec2.tf
    sns.tf
    cloudwatch.tf
    cloudtrail-root-login.tf
    outputs.tf
    user-data.sh
```

## Thành phần được tạo

Terraform tạo các tài nguyên chính sau:

- EC2 instance để test CPU alarm.
- IAM Role cho EC2 chạy CloudWatch Agent.
- CloudWatch Agent trên EC2.
- SNS Topic và Email Subscription.
- CloudWatch Alarm cho `CPUUtilization`.
- S3 bucket lưu CloudTrail log.
- CloudTrail multi-region trail.
- CloudWatch Log Group nhận log từ CloudTrail.
- CloudWatch Logs Metric Filter bắt sự kiện root login.
- CloudWatch Alarm cho root account login.

## Điều kiện cần có

- AWS CLI đã cấu hình bằng `aws configure`.
- Terraform đã cài.
- AWS account có quyền tạo EC2, IAM, SNS, CloudWatch, CloudTrail, CloudWatch Logs và S3.
- Một email thật để nhận cảnh báo SNS.

Kiểm tra account:

```powershell
aws sts get-caller-identity
```

## Cách chạy Terraform

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

Nếu email subscription chưa được confirm, SNS sẽ không gửi cảnh báo.

## Bài 1: Test CPU Alarm

SSH vào EC2:

```powershell
ssh -i .\w9-cloudwatch-alarm.pem ubuntu@<ec2_public_ip>
```

Kiểm tra CloudWatch Agent:

```bash
sudo systemctl status amazon-cloudwatch-agent --no-pager
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

Chạy stress CPU:

```bash
./stress-cpu.sh
```

Hoặc:

```bash
stress-ng --cpu 2 --timeout 8m --metrics-brief
```

Kết quả cần thấy:

- CloudWatch Alarm `w9-cloudwatch-alarm-high-cpu` chuyển sang `In alarm`.
- Email nhận cảnh báo CPU từ SNS.

## Bài 2: Root Account Login Alert

File Terraform chính:

```text
terraform/cloudtrail-root-login.tf
```

Luồng hoạt động:

1. CloudTrail ghi lại sự kiện trong AWS account.
2. CloudTrail gửi log vào CloudWatch Logs.
3. Metric Filter tìm sự kiện có `userIdentity.type = Root`.
4. Metric Filter tạo metric `Security/RootAccountLoginCount`.
5. CloudWatch Alarm kích hoạt nếu metric lớn hơn hoặc bằng `1`.
6. Alarm gửi notification đến SNS Topic.
7. SNS gửi email cảnh báo.

Metric filter pattern:

```text
{ $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }
```

Ý nghĩa:

- `$.userIdentity.type = "Root"`: chỉ bắt sự kiện do root account thực hiện.
- `$.eventType != "AwsServiceEvent"`: bỏ qua các event nội bộ do AWS service tạo.

Alarm condition:

```text
RootAccountLoginCount >= 1 trong 5 phút
```

Điều này nghĩa là chỉ cần root account login một lần thì alarm sẽ kích hoạt.

## Kiểm tra bằng AWS CLI

Xem output Terraform:

```powershell
terraform output
```

Xem SNS subscription:

```powershell
aws sns list-subscriptions-by-topic `
  --topic-arn <sns_topic_arn> `
  --region ap-southeast-1
```

Xem CPU alarm:

```powershell
aws cloudwatch describe-alarms `
  --alarm-names w9-cloudwatch-alarm-high-cpu `
  --region ap-southeast-1
```

Xem Root Login alarm:

```powershell
aws cloudwatch describe-alarms `
  --alarm-names w9-cloudwatch-alarm-root-account-login `
  --region ap-southeast-1
```

Xem CloudTrail:

```powershell
aws cloudtrail describe-trails `
  --trail-name-list w9-cloudwatch-alarm-root-login-trail `
  --region ap-southeast-1
```

## Evidence cần chụp

Cho bài CPU Alarm:

- EC2 instance đang `Running`.
- IAM Role gắn vào EC2.
- CloudWatch Agent đang `running`.
- SNS Topic.
- Email subscription đã `Confirmed`.
- CPU Alarm config.
- Terminal chạy stress CPU.
- Alarm chuyển sang `In alarm`.
- Email alert nhận được.

Cho bài Root Login Alert:

- CloudTrail trail đã tạo và đang logging.
- CloudWatch Log Group `/aws/cloudtrail/w9-cloudwatch-alarm`.
- Metric Filter `w9-cloudwatch-alarm-root-account-login-filter`.
- Metric `Security/RootAccountLoginCount`.
- Alarm `w9-cloudwatch-alarm-root-account-login`.
- SNS action gắn vào alarm.

## Cleanup

Sau khi chụp evidence xong, destroy để tránh tốn phí:

```powershell
terraform destroy
```

## Ghi chú bảo mật

- Root account gần như không nên dùng trong vận hành hằng ngày.
- Nên bật MFA cho root account.
- Nên dùng IAM User hoặc IAM Role cho công việc thường ngày.
- Alert root login giúp phát hiện sớm hành vi rủi ro trong AWS account.
- Không commit `.pem`, `.tfstate`, `.tfvars`, `.terraform/` hoặc `tfplan`.
