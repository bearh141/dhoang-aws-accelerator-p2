# Terraform Backend Bootstrap

Folder này tạo S3 bucket và DynamoDB table để lưu Terraform state cho project chính.

Lý do tách riêng:

- Terraform backend phải tồn tại trước khi project chính chạy `terraform init`.
- S3 bucket dùng để lưu file `terraform.tfstate`.
- DynamoDB table dùng để khóa state, tránh hai người cùng `terraform apply` một lúc.

## Chạy

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\CDO_Terraform\backend-bootstrap
terraform init
terraform apply
terraform output
```

Sau đó copy output vào `../backend.tf`.
