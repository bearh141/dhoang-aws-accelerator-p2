# Evidence - W9 Day C: CloudWatch CPU Alarm gửi Email qua SNS

File này tổng hợp bằng chứng cho bài lab **CPU Alarm -> Email Alert via SNS** và **Installing the CloudWatch Agent on EC2**.

Các ảnh bằng chứng được lưu tại:

```text
cloud/w9/day-c/evidence/
```

## 1. EC2 Instance đang chạy

![EC2 running](evidence/ec2-running.png)

Ảnh này chứng minh Terraform đã tạo EC2 instance thành công và instance đang ở trạng thái `Running`.

Thông tin cần thấy:

- Instance name: `w9-cloudwatch-alarm-ec2`
- Instance state: `Running`
- Instance type: `t3.micro`
- Public IPv4 address dùng để SSH vào EC2

## 2. IAM Role gắn cho EC2

![IAM role](evidence/iam-role.png)

Ảnh này chứng minh EC2 có IAM Role để CloudWatch Agent có quyền gửi metric về CloudWatch.

Role cần có các policy chính:

- `CloudWatchAgentServerPolicy`
- `AmazonSSMManagedInstanceCore`

Lý do cần IAM Role: EC2 không nên dùng access key hard-code. CloudWatch Agent lấy quyền tạm thời thông qua IAM Role để push metric an toàn hơn.

## 3. CloudWatch Agent đang chạy trên EC2

![CloudWatch Agent status](evidence/cloudwatch-agent-status.png)

Ảnh này chứng minh CloudWatch Agent đã được cài và đang chạy trên EC2.

Các lệnh kiểm tra:

```bash
sudo systemctl status amazon-cloudwatch-agent --no-pager
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

Kết quả cần thấy:

- Service `amazon-cloudwatch-agent` ở trạng thái `active` hoặc `running`
- Agent status là `running`
- Config status là `configured`

## 4. SNS Topic đã được tạo

![SNS topic](evidence/sns-topic.png)

Ảnh này chứng minh SNS Topic đã được tạo để nhận notification từ CloudWatch Alarm.

Topic dùng trong bài:

```text
w9-cloudwatch-alarm-cpu-alarm-topic
```

Luồng hoạt động:

```text
CloudWatch Alarm -> SNS Topic -> Email Subscription -> Gmail
```

## 5. Email Subscription đã Confirmed

![SNS email confirmed](evidence/sns-email-confirmed.png)

Ảnh này chứng minh email đã xác nhận đăng ký nhận cảnh báo từ SNS.

Trạng thái cần thấy:

```text
Confirmed
```

Nếu subscription còn `PendingConfirmation`, CloudWatch Alarm có chuyển sang `ALARM` thì email vẫn chưa nhận được.

## 6. CloudWatch Alarm được cấu hình đúng

![CloudWatch alarm config](evidence/cloudwatch-alarm-config.png)

Ảnh này chứng minh alarm đã được cấu hình theo yêu cầu đề bài.

Cấu hình chính:

- Metric: `CPUUtilization`
- Namespace: `AWS/EC2`
- Condition: CPU lớn hơn `80%`
- Period: `5 minutes`
- Action: gửi notification đến SNS Topic

Ý nghĩa: Khi CPU của EC2 vượt ngưỡng 80%, CloudWatch sẽ đổi trạng thái alarm và kích hoạt SNS gửi email.

## 7. Chạy CPU Stress Test trên EC2

![CPU stress running](evidence/cpu-stress-running.png)

Ảnh này chứng minh đã tạo tải CPU để test alarm.

Script chạy trên EC2:

```bash
./stress-cpu.sh
```

Nội dung chính của script:

```bash
stress-ng --cpu 2 --timeout 8m --metrics-brief
```

Lý do dùng `stress-ng`: tạo tải CPU cao trong vài phút để metric `CPUUtilization` vượt ngưỡng alarm.

## 8. CloudWatch Alarm chuyển sang In alarm

![Alarm in alarm](evidence/alarm-in-alarm.png)

Ảnh này là bằng chứng quan trọng nhất cho phần CloudWatch Alarm.

Trạng thái cần thấy:

```text
In alarm
```

Kết quả đã kiểm tra bằng CLI:

```text
State: ALARM
Reason: CPU datapoint 99.41% greater than threshold 80%
```

Điều này chứng minh alarm hoạt động đúng sau khi EC2 bị stress CPU.

## 9. Email Alert đã nhận được

![Email alert received](evidence/email-alert-received.png)

Ảnh này chứng minh SNS đã gửi email cảnh báo thành công.

Email cần thể hiện:

- Alarm name: `w9-cloudwatch-alarm-high-cpu`
- State change: `OK` hoặc `INSUFFICIENT_DATA` sang `ALARM`
- Region: `ap-southeast-1`
- Metric: `CPUUtilization`

## Kết luận

Bài lab đã đáp ứng đúng yêu cầu:

- Tạo EC2 instance để làm máy cần monitoring.
- Cài và chạy CloudWatch Agent trên EC2.
- Tạo SNS Topic và email subscription.
- Tạo CloudWatch Alarm theo metric CPU.
- Stress CPU để alarm chuyển sang `ALARM`.
- Nhận email cảnh báo từ SNS.

## Evidence bổ sung - Root Account Login Alert

Phần này dùng cho bài **Alert on AWS Root Account Login**.

Ảnh cần chụp thêm:

| Mục | Ảnh gợi ý | Nội dung cần thấy |
| --- | --- | --- |
| 1 | `root-cloudtrail-trail.png` | CloudTrail trail `w9-cloudwatch-alarm-root-login-trail` đang bật logging |
| 2 | `root-cloudwatch-log-group.png` | Log Group `/aws/cloudtrail/w9-cloudwatch-alarm` nhận log từ CloudTrail |
| 3 | `root-metric-filter.png` | Metric Filter `w9-cloudwatch-alarm-root-account-login-filter` |
| 4 | `root-security-metric.png` | Metric `Security/RootAccountLoginCount` |
| 5 | `root-login-alarm-config.png` | Alarm `w9-cloudwatch-alarm-root-account-login` với threshold `>= 1` |
| 6 | `root-login-alarm-sns-action.png` | Alarm action gửi đến SNS Topic |

Luồng cần giải thích khi vấn đáp:

```text
Root account login
  -> CloudTrail ghi event
  -> CloudWatch Logs nhận event
  -> Metric Filter bắt userIdentity.type = Root
  -> Tạo metric RootAccountLoginCount
  -> CloudWatch Alarm chuyển ALARM
  -> SNS gửi email cảnh báo
```

Filter pattern:

```text
{ $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }
```

Ý nghĩa:

- `userIdentity.type = "Root"`: chỉ bắt sự kiện từ root account.
- `eventType != "AwsServiceEvent"`: bỏ qua event do AWS service tự tạo.
- Metric value là `1`: mỗi lần root login tạo ra một điểm metric.
- Alarm threshold `>= 1`: chỉ cần root login một lần là đủ kích hoạt cảnh báo.

## Cleanup

Sau khi nộp bài, chạy lệnh sau để xóa tài nguyên AWS và tránh phát sinh chi phí:

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w9\day-c\terraform
terraform destroy
```
