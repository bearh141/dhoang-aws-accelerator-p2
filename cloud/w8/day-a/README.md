# Day A - Terraform Basics

## Mục tiêu

Học nền tảng Terraform: tổng quan IaC, cú pháp HCL và workflow cơ bản.

Tài liệu học:

- `../00-study-materials/day-01-terraform-basics.md`
- `../00-study-materials/day-03-terraform-state-modules-best-practices.md`

## Việc cần làm

- [ ] Đọc `../00-study-materials/day-01-terraform-basics.md`.
- [ ] Đọc `../00-study-materials/day-03-terraform-state-modules-best-practices.md`.
- [ ] Kiểm tra Terraform đã được cài chưa.
- [ ] Cài hoặc kiểm tra extension HashiCorp Terraform trong VS Code.
- [ ] Mở Terraform Registry và xem docs provider `hashicorp/aws`.
- [ ] Tạo một ví dụ Terraform nhỏ.
- [ ] Chạy `terraform init`.
- [ ] Chạy `terraform fmt`.
- [ ] Chạy `terraform validate`.
- [ ] Chạy `terraform plan`.
- [ ] Đọc được ý nghĩa các ký hiệu plan: `+`, `~`, `-`, `-/+`.
- [ ] Hiểu provider version pinning trong `required_providers`.
- [ ] Hiểu state safety: không commit `terraform.tfstate`.
- [ ] Hiểu module dùng để tái sử dụng code Terraform.
- [ ] Hiểu remote state với S3 + DynamoDB lock.
- [ ] Viết hoặc đọc được một ADR ngắn.
- [ ] Chuẩn bị 2-3 câu hỏi cho mentor Minh.
- [ ] Lưu evidence và cập nhật `../reflection.md`.

## Evidence

```text
terraform -version:
Terraform v1.15.5
on windows_amd64

aws sts get-caller-identity:
UserId: AIDA5YT6S7YFWSBYYMXN6
Account: 946232032779
Arn: arn:aws:iam::946232032779:user/Hoang

terraform init:

terraform validate:

terraform plan summary:
```

## Câu hỏi chuẩn bị cho mentor Minh

- 
- 
- 

## Lab: Install Terraform & Set Up Environment

- [x] Install Terraform CLI.
- [x] Verify Terraform CLI.
- [x] Install/check VS Code extension: HashiCorp Terraform.
- [x] Configure/check AWS CLI credentials.
- [x] Explore/check Terraform Registry.

### Setup results

```text
Terraform CLI:
Terraform v1.15.5 on windows_amd64

AWS CLI:
aws-cli/2.34.44 Python/3.14.4 Windows/11 exe/AMD64

AWS identity:
arn:aws:iam::946232032779:user/Hoang

VS Code:
1.122.1

VS Code extension:
hashicorp.terraform installed

Terraform Registry:
https://registry.terraform.io -> 200 OK
```

### Ghi chú PATH

Terraform đã được cài qua winget tại:

```text
C:\Users\NITRO\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform.exe
```

winget đã cập nhật PATH, nhưng terminal hiện tại có thể chưa nhận PATH mới. Nếu chạy `terraform -version` chưa được, hãy mở terminal mới trong VS Code rồi chạy lại.

## Ghi chú

Thêm ghi chú học tập và tóm tắt output lệnh tại đây.
