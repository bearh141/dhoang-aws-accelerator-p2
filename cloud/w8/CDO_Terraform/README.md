# CDO Terraform - Deploy a Web App on AWS

Project này triển khai một web app đơn giản trên AWS bằng Terraform.

Kiến trúc theo yêu cầu:

```text
VPC
  Public Subnets
    EC2 web server
  Private Subnets
    RDS MySQL
  S3 bucket
    Static assets
```

## Thành phần chính

- `VPC`: mạng riêng cho project.
- `Public subnet`: nơi đặt EC2 web server vì cần nhận HTTP từ Internet.
- `Private subnet`: nơi đặt RDS MySQL để database không bị public ra Internet.
- `EC2`: chạy Nginx và phục vụ trang web.
- `RDS MySQL`: database managed service của AWS.
- `S3`: lưu static assets.
- `Security Groups`: chỉ mở traffic cần thiết.
- `S3 backend + DynamoDB locking`: lưu Terraform state tập trung và chống nhiều người apply cùng lúc.

## Cấu trúc thư mục

```text
CDO_Terraform/
  README.md
  .gitignore
  backend.tf.example
  versions.tf
  variables.tf
  main.tf
  security-groups.tf
  ec2.tf
  rds.tf
  s3.tf
  outputs.tf
  user-data.sh
  modules/
    vpc/
      variables.tf
      main.tf
      outputs.tf
  backend-bootstrap/
    README.md
    versions.tf
    variables.tf
    main.tf
    outputs.tf
```

## Cách chạy

### 1. Tạo backend state trước

Terraform backend S3 không thể tự tạo chính bucket đang dùng để lưu state của nó. Vì vậy chạy folder bootstrap trước:

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\CDO_Terraform\backend-bootstrap
terraform init
terraform apply
```

Sau khi chạy xong, lấy output:

```powershell
terraform output
```

### 2. Bật backend cho project chính

Copy nội dung từ `backend.tf.example` sang file `backend.tf`, sau đó sửa:

- `bucket`
- `dynamodb_table`
- `region`

Ví dụ:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-state-bucket"
    key            = "w8/cdo-terraform/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "your-lock-table"
    encrypt        = true
  }
}
```

### 3. Deploy project chính

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\CDO_Terraform
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Nếu muốn truyền password database bằng biến:

```powershell
terraform plan -out=tfplan -var="db_password=YourStrongPassword123!"
terraform apply tfplan
```

### 4. Xem web

Sau khi apply xong:

```powershell
terraform output web_url
```

Mở URL đó trên trình duyệt.

## Luồng hoạt động

1. Người dùng truy cập public IP của EC2 qua HTTP port `80`.
2. Security Group của EC2 cho phép HTTP từ Internet.
3. Nginx trên EC2 trả về trang HTML đơn giản.
4. EC2 có thể kết nối RDS MySQL qua port `3306`.
5. RDS chỉ nhận kết nối từ Security Group của EC2, không nhận từ Internet.
6. S3 bucket được tạo để lưu static assets, có versioning và encryption.

## Security Group

Web Security Group:

- Inbound HTTP `80` từ `0.0.0.0/0`.
- Inbound SSH `22` từ biến `ssh_cidr`.
- Outbound cho phép ra ngoài để cài package và kết nối AWS services.

RDS Security Group:

- Inbound MySQL `3306` chỉ từ Web Security Group.
- Không public database ra Internet.

## Cleanup

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\CDO_Terraform
terraform destroy
```

Sau đó nếu không cần backend nữa:

```powershell
cd D:\Download\AWS\Học\cloud\cloud\w8\CDO_Terraform\backend-bootstrap
terraform destroy
```

## Ghi chú

- Project này dùng default password biến `db_password` có giá trị mặc định để dễ học lab. Khi làm thật, nên truyền bằng `terraform.tfvars` local hoặc secret manager, không commit password.
- RDS có `skip_final_snapshot = true` để dễ cleanup trong lab. Production không nên dùng như vậy.
- S3 bucket có block public access, encryption, versioning để hợp best practice cơ bản.
