# W9 Day C Evidence - CloudWatch CPU Alarm Email Alert

Tài liệu này ghi lại các ảnh cần chụp để nộp bài CloudWatch Agent và CPU Alarm gửi email qua SNS.

## Checklist Evidence

| Mục | Ảnh cần chụp | Mục tiêu |
| --- | --- | --- |
| 1 | `01-terraform-apply.png` | Terraform apply thành công |
| 2 | `02-ec2-running.png` | EC2 instance đang Running |
| 3 | `03-iam-role.png` | EC2 có IAM Role gắn CloudWatch Agent policy |
| 4 | `04-cloudwatch-agent-status.png` | CloudWatch Agent đang chạy trên EC2 |
| 5 | `05-sns-topic.png` | SNS topic đã tạo |
| 6 | `06-sns-email-confirmed.png` | Email subscription đã Confirmed |
| 7 | `07-cloudwatch-alarm-config.png` | CloudWatch Alarm cấu hình CPU threshold |
| 8 | `08-cpu-stress-running.png` | Đang chạy stress CPU trên EC2 |
| 9 | `09-alarm-in-alarm.png` | Alarm chuyển sang trạng thái In alarm |
| 10 | `10-email-alert-received.png` | Email alert nhận được từ SNS |

## 1. Terraform Apply

Chụp terminal sau khi chạy:

```powershell
terraform apply tfplan
terraform output
```

Cần thấy:

- EC2 instance ID.
- SNS topic ARN.
- Alarm name.
- Public IP.

## 2. EC2 Running

Vào AWS Console:

```text
EC2 -> Instances
```

Chụp instance đang Running.

## 3. IAM Role

Vào EC2 instance detail, chụp IAM Role đã gắn cho instance.

Role cần có policy:

```text
CloudWatchAgentServerPolicy
AmazonSSMManagedInstanceCore
```

## 4. CloudWatch Agent Status

SSH vào EC2:

```bash
sudo systemctl status amazon-cloudwatch-agent --no-pager
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

Chụp kết quả agent đang running.

## 5. SNS Topic

Vào AWS Console:

```text
SNS -> Topics
```

Chụp topic được tạo bởi Terraform.

## 6. SNS Email Subscription

Vào email nhận SNS, bấm **Confirm subscription**.

Sau đó vào:

```text
SNS -> Subscriptions
```

Chụp subscription có trạng thái:

```text
Confirmed
```

## 7. CloudWatch Alarm

Vào:

```text
CloudWatch -> Alarms
```

Chụp alarm CPU.

Cần thấy:

- Metric: `CPUUtilization`
- Namespace: `AWS/EC2`
- Threshold: lớn hơn 80% hoặc threshold bạn cấu hình
- Action: gửi tới SNS topic

## 8. CPU Stress Test

SSH vào EC2 và chạy:

```bash
stress-ng --cpu 2 --timeout 8m --metrics-brief
```

Chụp terminal đang chạy stress.

## 9. Alarm In Alarm

Sau vài phút, quay lại CloudWatch Alarm.

Chụp trạng thái:

```text
In alarm
```

## 10. Email Alert Received

Chụp email nhận được từ AWS Notification.

Email cần thể hiện:

- Alarm name.
- State change to `ALARM`.
- Region.
- Instance ID hoặc metric CPU.

## Cleanup Evidence

Sau khi chụp xong, chạy:

```powershell
terraform destroy
```

Chụp thêm nếu giảng viên yêu cầu chứng minh đã dọn tài nguyên.

