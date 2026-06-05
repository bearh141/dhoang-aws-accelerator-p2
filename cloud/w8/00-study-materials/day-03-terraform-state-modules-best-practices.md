# Ngày 03 - Terraform State, Modules, Best Practices và ADR

## Mục tiêu hôm nay

Hôm nay là ngày học sâu hơn về Terraform sau khi đã nắm được IaC, HCL syntax và workflow cơ bản.

Bạn cần tập trung vào 5 mảng:

- Terraform state hoạt động như thế nào.
- Vì sao team cần remote state với S3 và DynamoDB lock.
- Module là gì và cách dùng module để tái sử dụng code.
- Best practices khi viết Terraform trong team.
- ADR là gì và cách viết ADR ngắn gọn cho quyết định kỹ thuật.

Lịch quan trọng hôm nay:

- Sáng: self-study Terraform phần 2.
- 15h-17h: LIVE Terraform với mentor Minh.
- 17h-18h: Online Test 1, scope Terraform D1.

---

## 1. Ôn nhanh trước khi học tiếp

Trước khi vào state và module, bạn cần chắc các ý sau:

- Terraform là công cụ Infrastructure as Code.
- File `.tf` mô tả desired state.
- `terraform init` khởi tạo project và tải provider.
- `terraform plan` cho biết Terraform sẽ thay đổi gì.
- `terraform apply` thực thi thay đổi.
- `terraform destroy` xóa resource Terraform đang quản lý.
- Provider là plugin để Terraform nói chuyện với API như AWS.
- Resource là tài nguyên Terraform tạo/quản lý.
- State là bộ nhớ của Terraform.

Nếu còn mơ hồ phần nào, hãy đọc lại:

```text
cloud/w8/00-study-materials/day-01-terraform-basics.md
```

---

## 2. Terraform state là gì?

Terraform state là nơi Terraform ghi nhớ các resource mà nó đang quản lý.

Mặc định, state nằm trong file local:

```text
terraform.tfstate
```

State giúp Terraform biết:

- Resource nào trong code tương ứng với resource thật nào trên AWS.
- ID thật của resource là gì.
- Thuộc tính hiện tại của resource là gì.
- Lần chạy `plan` tiếp theo cần tạo, sửa hay xóa gì.

Ví dụ trong code:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
}
```

Sau khi apply, AWS tạo VPC thật, ví dụ:

```text
vpc-0123456789abcdef0
```

Terraform state sẽ ghi nhớ rằng:

```text
aws_vpc.main -> vpc-0123456789abcdef0
```

Nhờ vậy, lần sau khi bạn sửa `cidr_block`, tags hoặc thêm subnet, Terraform biết resource nào cần xử lý.

---

## 3. Vì sao state quan trọng?

Không có state, Terraform không biết hạ tầng thật đang ở trạng thái nào.

State quan trọng vì:

- Terraform cần state để so sánh code với hạ tầng thật.
- State giúp Terraform tạo plan chính xác.
- State giữ mapping giữa Terraform address và cloud resource ID.
- State có thể chứa dữ liệu nhạy cảm.
- State bị mất hoặc hỏng có thể làm project rất khó quản lý.

Ví dụ Terraform address:

```text
aws_vpc.main
aws_subnet.public
aws_security_group.web
```

Cloud resource ID thật:

```text
vpc-abc123
subnet-def456
sg-ghi789
```

State chính là lớp nối giữa hai bên này.

---

## 4. Không commit state lên Git

Không commit các file sau:

```text
terraform.tfstate
terraform.tfstate.backup
*.tfstate
*.tfstate.*
.terraform/
*.tfvars
*.tfplan
```

Lý do:

- State có thể chứa secret hoặc dữ liệu nhạy cảm.
- State local không phù hợp khi nhiều người cùng làm.
- State thay đổi sau mỗi apply, rất dễ conflict.
- Nếu state bị lộ, người khác có thể biết cấu trúc hạ tầng của bạn.

Repo của bạn đã có `.gitignore` để giảm rủi ro commit nhầm.

Nên kiểm tra trước khi commit:

```powershell
git status
```

Nếu thấy `terraform.tfstate`, `.terraform/`, hoặc file secret xuất hiện trong staged changes thì phải dừng lại.

---

## 5. State drift là gì?

State drift xảy ra khi hạ tầng thật khác với Terraform code hoặc Terraform state.

Ví dụ:

1. Terraform tạo Security Group cho phép port 80.
2. Ai đó vào AWS Console mở thêm port 22 thủ công.
3. Terraform code vẫn chỉ khai báo port 80.
4. Hạ tầng thật đã bị lệch khỏi desired state.

Khi chạy:

```powershell
terraform plan
```

Terraform có thể phát hiện drift và đề xuất đưa resource về đúng code.

Nguyên tắc:

- Không sửa resource thủ công trên AWS Console nếu resource đang được Terraform quản lý.
- Nếu bắt buộc sửa thủ công, cần cập nhật lại code Terraform.
- Luôn đọc kỹ plan trước khi apply.

---

## 6. Terraform state commands

Các lệnh này giúp bạn xem hoặc thao tác với state.

### `terraform state list`

Liệt kê resource Terraform đang quản lý:

```powershell
terraform state list
```

Ví dụ output:

```text
aws_vpc.main
aws_subnet.public
aws_security_group.web
```

### `terraform state show`

Xem chi tiết một resource trong state:

```powershell
terraform state show aws_vpc.main
```

Lệnh này hữu ích khi bạn muốn xem attribute Terraform đang ghi nhận.

### `terraform state mv`

Đổi địa chỉ resource trong state:

```powershell
terraform state mv aws_vpc.old aws_vpc.main
```

Dùng khi refactor code, ví dụ đổi tên resource trong Terraform.

Cẩn thận: dùng sai có thể làm Terraform hiểu nhầm mapping resource.

### `terraform state rm`

Xóa resource khỏi state nhưng không xóa resource thật trên cloud:

```powershell
terraform state rm aws_s3_bucket.logs
```

Sau lệnh này, Terraform không còn quản lý resource đó nữa.

### `terraform import`

Đưa resource có sẵn ngoài AWS vào Terraform state:

```powershell
terraform import aws_s3_bucket.data my-existing-bucket-name
```

Import không tự viết code `.tf` đầy đủ cho bạn. Bạn vẫn cần viết resource block tương ứng.

Ngày hôm nay bạn chỉ cần hiểu ý nghĩa các lệnh này. Không nên chạy `state mv`, `state rm`, hoặc `import` nếu chưa chắc chắn.

---

## 7. Remote state là gì?

Remote state là việc lưu Terraform state ở nơi dùng chung thay vì lưu trên máy cá nhân.

Với AWS, pattern phổ biến là:

- S3 bucket để lưu file state.
- DynamoDB table để lock state.
- Encryption để bảo vệ state.
- S3 versioning để có lịch sử state.

Mục tiêu:

- Team cùng dùng một state thống nhất.
- Tránh conflict state local.
- Tránh hai người cùng apply một lúc.
- Có backup/version history.
- Dễ dùng trong CI/CD.

---

## 8. S3 backend

Backend là nơi Terraform lưu state.

Ví dụ backend S3:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "w8/day-a/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
```

Giải thích:

- `bucket`: tên S3 bucket lưu state.
- `key`: đường dẫn file state trong bucket.
- `region`: region của bucket.

Ví dụ key nên có cấu trúc rõ:

```text
dev/vpc/terraform.tfstate
staging/vpc/terraform.tfstate
prod/vpc/terraform.tfstate
```

Hoặc với repo học:

```text
w8/day-a/terraform.tfstate
```

---

## 9. DynamoDB state locking

State locking giúp ngăn nhiều người cùng apply một state tại cùng thời điểm.

Nếu không lock:

- Người A chạy `terraform apply`.
- Người B cũng chạy `terraform apply`.
- Cả hai cùng ghi state.
- State có thể bị hỏng hoặc ghi đè.

Với AWS, Terraform thường dùng DynamoDB table để lock.

Ví dụ backend có lock:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/vpc/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Giải thích:

- `encrypt = true`: bật encryption cho state trong S3.
- `dynamodb_table`: tên bảng DynamoDB dùng để lock.

DynamoDB table thường cần partition key:

```text
LockID
```

Kiểu:

```text
String
```

Trong production, nên bật:

- S3 versioning.
- S3 encryption, tốt hơn là SSE-KMS.
- IAM policy giới hạn quyền đọc/ghi state.
- DynamoDB lock table.

---

## 10. Quy trình chuyển từ local state sang remote state

Flow thường gặp:

1. Tạo S3 bucket để lưu state.
2. Bật versioning/encryption cho bucket.
3. Tạo DynamoDB table để lock.
4. Thêm backend block vào Terraform code.
5. Chạy `terraform init`.
6. Terraform hỏi có migrate state không.
7. Xác nhận migrate nếu bạn hiểu rõ.

Ví dụ backend block:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "dev/app/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Lưu ý:

- Backend block không dùng được `var.bucket_name`.
- Backend được Terraform đọc rất sớm khi `init`.
- Vì vậy backend config thường hard-code hoặc truyền qua backend config file.

Ví dụ dùng backend config file:

```powershell
terraform init -backend-config="backend-dev.hcl"
```

---

## 11. Module là gì?

Module là cách đóng gói Terraform code để tái sử dụng.

Một folder Terraform có file `.tf` có thể xem là một module.

Có 2 loại hay gặp:

- Root module: folder bạn đang chạy `terraform init/plan/apply`.
- Child module: module được root module gọi bằng block `module`.

Ví dụ:

```text
infra/
  main.tf          # root module
  modules/
    vpc/           # child module
      main.tf
      variables.tf
      outputs.tf
```

---

## 12. Vì sao cần module?

Không dùng module, bạn dễ copy-paste:

```text
dev-vpc code
staging-vpc code
prod-vpc code
```

Khi cần sửa logic VPC, bạn phải sửa ở nhiều nơi. Rất dễ quên hoặc sửa lệch.

Dùng module:

```text
Viết VPC module một lần
Gọi cho dev với biến dev
Gọi cho staging với biến staging
Gọi cho prod với biến prod
```

Lợi ích:

- Giảm duplication.
- Code dễ review.
- Dễ chuẩn hóa hạ tầng.
- Dễ dùng lại giữa project.
- Dễ tách trách nhiệm trong team.

---

## 13. Cấu trúc module chuẩn

Một module nên có:

```text
modules/
  vpc/
    main.tf
    variables.tf
    outputs.tf
    README.md
```

Ý nghĩa:

- `main.tf`: khai báo resource chính.
- `variables.tf`: input module nhận vào.
- `outputs.tf`: output module trả ra.
- `README.md`: mô tả cách dùng module.

Ví dụ `variables.tf` trong module:

```hcl
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
```

Ví dụ `main.tf`:

```hcl
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

Ví dụ `outputs.tf`:

```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}
```

---

## 14. Gọi module

Ví dụ root module gọi VPC module:

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr    = "10.0.0.0/16"
  environment = "dev"
}
```

Giải thích:

- `module`: block gọi module.
- `"vpc"`: tên module trong root module.
- `source`: đường dẫn tới module.
- `vpc_cidr`: input truyền vào module.
- `environment`: input truyền vào module.

Reference output của module:

```hcl
module.vpc.vpc_id
```

Mẫu chung:

```hcl
module.<module_name>.<output_name>
```

Ví dụ dùng VPC ID từ module để tạo subnet:

```hcl
resource "aws_subnet" "public" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.0.1.0/24"
}
```

---

## 15. Project structure thực tế

Một project Terraform thực tế thường tách module và environment:

```text
infra/
  modules/
    vpc/
    ec2/
    rds/
  environments/
    dev/
      main.tf
      variables.tf
      dev.tfvars
    staging/
      main.tf
      variables.tf
      staging.tfvars
    prod/
      main.tf
      variables.tf
      prod.tfvars
```

Ý tưởng:

- Module chứa logic tái sử dụng.
- Environment chứa cấu hình cụ thể.
- Dev/staging/prod gọi cùng module nhưng truyền biến khác nhau.

Ví dụ:

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}
```

Chạy theo môi trường:

```powershell
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

---

## 16. Best practices khi viết Terraform

### Luôn format code

```powershell
terraform fmt
```

Chạy trước khi commit.

### Luôn validate

```powershell
terraform validate
```

Bắt lỗi cú pháp và cấu trúc cơ bản sớm.

### Luôn đọc plan

```powershell
terraform plan
```

Không apply khi chưa hiểu plan.

Đặc biệt cẩn thận với:

```text
-
-/+
```

Vì đây là dấu hiệu xóa hoặc replace resource.

### Pin provider version

Ví dụ:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Không pin version có thể khiến project bị lỗi khi provider ra major version mới.

### Không hard-code secret

Không viết:

```hcl
variable "db_password" {
  default = "MyPassword123"
}
```

Không viết access key trong provider:

```hcl
provider "aws" {
  access_key = "..."
  secret_key = "..."
}
```

Nên dùng:

- AWS CLI profile.
- Environment variables.
- IAM Role.
- AWS Secrets Manager.
- Secret manager của CI/CD.

### Tags đầy đủ

Nên tag resource:

```hcl
tags = {
  Name        = "dev-vpc-main"
  Environment = "dev"
  Project     = "aws-accelerator-p2"
  Owner       = "your-name"
  ManagedBy   = "Terraform"
}
```

Tags giúp tìm resource, phân loại cost và biết resource được quản lý bởi ai.

### Naming convention

Gợi ý:

```text
<environment>-<resource>-<purpose>
```

Ví dụ:

```text
dev-vpc-main
dev-subnet-public-a
prod-rds-main
```

### Không sửa resource bằng Console

Nếu resource đã do Terraform quản lý, hạn chế sửa tay trên AWS Console.

Nếu sửa tay, Terraform có thể phát hiện drift và đưa resource về lại cấu hình trong code ở lần apply sau.

---

## 17. ADR là gì?

ADR là viết tắt của Architecture Decision Record.

ADR là một tài liệu ngắn ghi lại một quyết định kỹ thuật quan trọng:

- Bối cảnh là gì?
- Vấn đề cần quyết định là gì?
- Các lựa chọn là gì?
- Quyết định cuối cùng là gì?
- Hệ quả của quyết định là gì?

ADR không cần dài. Mục tiêu là để sau này người khác hiểu vì sao team chọn cách đó.

Ví dụ quyết định cần ADR:

- Chọn S3 + DynamoDB để lưu Terraform remote state.
- Chọn module structure theo `modules/` và `environments/`.
- Chọn `ap-southeast-1` làm region lab.
- Chọn không commit `.tfvars` chứa secret.

---

## 18. Template ADR

Bạn có thể tạo file:

```text
cloud/w8/day-a/adr-001-terraform-remote-state.md
```

Nội dung mẫu:

```markdown
# ADR-001: Use S3 and DynamoDB for Terraform Remote State

## Status

Accepted

## Context

The team needs a shared and reliable place to store Terraform state. Local state is not suitable for teamwork because it can be lost, conflicted, or overwritten.

## Decision

We will use an S3 bucket to store Terraform state and a DynamoDB table for state locking.

## Consequences

- Team members share one source of truth for Terraform state.
- State locking prevents concurrent apply operations.
- S3 versioning helps recover previous state versions.
- IAM permissions must be managed carefully.
- State may contain sensitive data, so encryption and access control are required.
```

Nếu muốn viết tiếng Việt:

```markdown
# ADR-001: Dùng S3 và DynamoDB cho Terraform Remote State

## Trạng thái

Accepted

## Bối cảnh

Team cần một nơi lưu Terraform state dùng chung. Local state không phù hợp khi làm việc nhóm vì dễ mất, conflict hoặc bị ghi đè.

## Quyết định

Sử dụng S3 bucket để lưu Terraform state và DynamoDB table để state locking.

## Hệ quả

- Team có một nguồn state thống nhất.
- State locking giúp tránh nhiều người apply cùng lúc.
- S3 versioning giúp khôi phục state cũ khi cần.
- Cần quản lý IAM permission cẩn thận.
- State có thể chứa dữ liệu nhạy cảm nên cần encryption và access control.
```

---

## 19. Chuẩn bị câu hỏi cho mentor Minh

Bạn nên chuẩn bị 2-3 câu hỏi thật cụ thể. Gợi ý:

1. Khi nào nên tách Terraform code thành module, khi nào chỉ cần giữ trong root module?
2. Với team nhỏ, lúc nào bắt buộc phải dùng remote state S3 + DynamoDB lock?
3. Nếu một resource đã được tạo thủ công trên AWS Console, nên dùng `terraform import` hay tạo resource mới bằng Terraform?
4. Có nên commit `.tfvars` không nếu file đó chỉ chứa giá trị không nhạy cảm?
5. Khi `terraform plan` hiện `-/+`, cách đánh giá rủi ro trước khi apply là gì?

Nên chọn 2-3 câu bạn thật sự muốn hiểu sâu.

---

## 20. Ôn cho Online Test 1

Scope test là Terraform D1, nhưng hôm nay học thêm D2 nên bạn nên ôn theo nhóm.

### Nhóm 1: IaC

Cần trả lời được:

- IaC là gì?
- IaC khác thao tác thủ công trên Console thế nào?
- Vì sao IaC giúp repeatable, version-controlled, reviewable?

### Nhóm 2: Terraform workflow

Cần nhớ:

```text
init -> fmt -> validate -> plan -> apply -> destroy
```

Ý nghĩa:

- `init`: tải provider/module, khởi tạo backend.
- `fmt`: format code.
- `validate`: kiểm tra syntax.
- `plan`: xem thay đổi.
- `apply`: thực thi thay đổi.
- `destroy`: xóa resource được quản lý.

### Nhóm 3: HCL syntax

Cần phân biệt:

- Block.
- Argument.
- Resource.
- Provider.
- Variable.
- Output.
- Data source.
- Locals.
- Map/list/object.

### Nhóm 4: State

Cần nhớ:

- State là bộ nhớ của Terraform.
- Không commit state.
- Remote state dùng cho teamwork.
- DynamoDB lock tránh concurrent apply.

### Nhóm 5: Plan output

Cần đọc được:

```text
+    create
~    update in-place
-    destroy
-/+  destroy and recreate
```

Nếu thấy `-/+`, phải đọc kỹ vì có thể gây downtime hoặc mất dữ liệu.

---

## 21. Bài tập nhỏ hôm nay

Trong folder:

```text
cloud/w8/day-a/
```

Bạn nên làm:

1. Cập nhật hoặc tạo `main.tf` có provider AWS.
2. Tạo `versions.tf` có `required_version` và `required_providers`.
3. Tạo `variables.tf` có `aws_region`, `project_name`, `environment`.
4. Tạo `outputs.tf` nếu có resource để output.
5. Tạo ADR đầu tiên về remote state hoặc module structure.
6. Chạy:

```powershell
terraform fmt
terraform validate
terraform plan
```

Nếu chưa muốn tạo resource thật trên AWS, bạn có thể chỉ viết code và chạy `terraform validate`.

---

## 22. Checklist hôm nay

- [ ] Đọc hiểu Terraform state.
- [ ] Biết vì sao không commit state.
- [ ] Hiểu state drift.
- [ ] Biết ý nghĩa `terraform state list/show/mv/rm`.
- [ ] Hiểu `terraform import` dùng để làm gì.
- [ ] Hiểu remote state.
- [ ] Hiểu S3 backend.
- [ ] Hiểu DynamoDB state locking.
- [ ] Hiểu module/root module/child module.
- [ ] Biết cấu trúc module chuẩn.
- [ ] Biết cách gọi module.
- [ ] Biết project structure dev/staging/prod.
- [ ] Nắm best practices: fmt, validate, plan, pin provider, no secrets, tags.
- [ ] Viết hoặc đọc được một ADR đơn giản.
- [ ] Chuẩn bị 2-3 câu hỏi cho mentor Minh.
- [ ] Ôn Terraform D1 trước Online Test 1.
- [ ] Cập nhật evidence vào `cloud/w8/day-a/README.md`.
- [ ] Cập nhật reflection.

---

## 23. Câu hỏi tự kiểm tra

1. Terraform state dùng để làm gì?
2. Vì sao không nên commit `terraform.tfstate`?
3. Remote state giải quyết vấn đề gì khi làm team?
4. S3 dùng để làm gì trong remote state?
5. DynamoDB lock dùng để làm gì?
6. State drift là gì?
7. `terraform state rm` có xóa resource thật trên AWS không?
8. `terraform import` dùng trong tình huống nào?
9. Root module khác child module như thế nào?
10. Vì sao module giúp tránh copy-paste?
11. Vì sao cần pin provider version?
12. ADR ghi lại điều gì?

---

## 24. Tài liệu nên đọc

Ưu tiên đọc:

1. Terraform State:
   https://developer.hashicorp.com/terraform/language/state
2. Terraform S3 Backend:
   https://developer.hashicorp.com/terraform/language/backend/s3
3. Terraform Modules:
   https://developer.hashicorp.com/terraform/language/modules
4. Terraform Best Practices:
   https://www.terraform-best-practices.com
5. Terraform Registry:
   https://registry.terraform.io

Mục tiêu hôm nay không phải thuộc hết mọi lệnh state nâng cao, mà là hiểu vì sao state/module quan trọng khi Terraform chuyển từ lab cá nhân sang teamwork và production.
