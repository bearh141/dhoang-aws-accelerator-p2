# Ngày 01 - Terraform Cơ Bản

## Mục tiêu hôm nay

Sau buổi học này, bạn cần nắm được:

- Infrastructure as Code là gì và vì sao Cloud/DevOps cần IaC.
- Terraform dùng để làm gì, khác gì so với thao tác thủ công trên AWS Console.
- Cú pháp HCL cơ bản: block, argument, expression, variable, output.
- Workflow chính của Terraform: `init`, `fmt`, `validate`, `plan`, `apply`, `destroy`.
- Cách đọc Terraform plan trước khi apply.
- Cách tổ chức một Terraform project nhỏ, dễ đọc, dễ commit.

Thời lượng gợi ý: khoảng 6 giờ.

---

## 1. Infrastructure as Code là gì?

Infrastructure as Code, viết tắt là IaC, là cách quản lý hạ tầng bằng file cấu hình thay vì thao tác thủ công trên giao diện web.

Ví dụ, thay vì vào AWS Console và bấm từng bước để tạo VPC, subnet, security group, EC2, bạn viết các file Terraform mô tả:

- Cần tạo tài nguyên nào.
- Cấu hình của từng tài nguyên là gì.
- Tài nguyên nào phụ thuộc tài nguyên nào.
- Output nào cần lấy sau khi tạo xong.

Terraform sẽ đọc các file cấu hình đó và gọi API của cloud provider, ví dụ AWS, để tạo/sửa/xóa hạ tầng theo đúng trạng thái mong muốn.

### Lợi ích của IaC

- Lưu được lịch sử thay đổi bằng Git.
- Review hạ tầng giống như review code.
- Tạo lại môi trường nhanh hơn và đồng nhất hơn.
- Giảm thao tác tay lặp lại.
- Dễ rollback về cấu hình cũ nếu có lỗi.
- Dễ chia sẻ tri thức trong team vì mọi thứ nằm trong repo.

### Vấn đề nếu không dùng IaC

- Khó biết ai đã tạo hoặc sửa gì trên cloud.
- Môi trường dev, staging, production dễ bị lệch nhau.
- Khó tái tạo hạ tầng khi cần disaster recovery.
- Dễ cấu hình thiếu hoặc sai do thao tác tay.
- Không có bằng chứng rõ ràng để mentor hoặc reviewer kiểm tra.

---

## 2. Terraform là gì?

Terraform là công cụ IaC của HashiCorp. Terraform dùng ngôn ngữ cấu hình HCL để mô tả hạ tầng.

Terraform làm việc theo ý tưởng:

1. Bạn viết desired state trong file `.tf`.
2. Terraform đọc current state của hạ tầng.
3. Terraform so sánh desired state với current state.
4. Terraform tạo execution plan.
5. Nếu bạn đồng ý, Terraform thực thi plan đó.

### Khái niệm quan trọng

Provider:
Provider là plugin giúp Terraform nói chuyện với một nền tảng cụ thể, ví dụ AWS, Azure, Google Cloud, Kubernetes, GitHub.

Resource:
Resource là một đối tượng hạ tầng Terraform quản lý, ví dụ `aws_vpc`, `aws_subnet`, `aws_instance`.

Data source:
Data source dùng để đọc thông tin có sẵn, không trực tiếp tạo tài nguyên mới. Ví dụ: đọc AMI Ubuntu mới nhất.

State:
State là file Terraform dùng để ghi nhớ tài nguyên nào đang được quản lý và mapping giữa code với hạ tầng thật.

Module:
Module là cách đóng gói Terraform code để tái sử dụng. Một folder Terraform cũng có thể xem là root module.

### Terraform khác gì so với các công cụ khác?

Trong Cloud/DevOps, bạn sẽ nghe nhiều công cụ khác nhau. Chúng không hoàn toàn thay thế nhau, vì mỗi công cụ giải quyết một nhóm vấn đề hơi khác.

| Công cụ | Điểm mạnh | Thường dùng cho |
|---|---|---|
| Terraform | Cloud-agnostic, dùng được với AWS/Azure/GCP/Kubernetes/GitHub..., có state và plan rõ ràng | Provisioning hạ tầng cloud |
| AWS CloudFormation | Native của AWS, dùng JSON/YAML | Provisioning hạ tầng riêng trên AWS |
| Ansible | Agentless, mạnh về cấu hình server và automation | Configuration management |
| Pulumi | Dùng ngôn ngữ lập trình như Python/TypeScript/Go | IaC dạng code-first |
| AWS CDK | Code-first, sinh ra CloudFormation | Hạ tầng AWS bằng ngôn ngữ lập trình |

Với track Cloud/DevOps này, Terraform phù hợp vì:

- Dễ review bằng `terraform plan`.
- Có hệ sinh thái provider lớn.
- Có thể dùng cho nhiều nền tảng, không chỉ AWS.
- Có module để tái sử dụng hạ tầng.
- Phù hợp với GitOps/CI/CD sau này.

### Terraform hoạt động như thế nào?

Terraform có thể hiểu theo luồng sau:

```text
File .tf -> Terraform Core -> Provider -> Cloud API
                 |
              State file
```

Giải thích:

- Bạn viết file `.tf` để mô tả desired state.
- Terraform Core đọc cấu hình, đọc state và tính toán thay đổi.
- Provider, ví dụ `hashicorp/aws`, biết cách gọi AWS API.
- State file ghi nhớ Terraform đã tạo gì ngoài cloud.
- Cloud API thực sự tạo/sửa/xóa resource.

Điểm cần nhớ:

- Terraform Core không tự biết AWS là gì.
- AWS provider mới là thành phần biết cách nói chuyện với AWS.
- `terraform init` sẽ tải provider từ Terraform Registry.
- Provider có version riêng, độc lập với Terraform CLI.

---

## 3. Công cụ cần có

Hôm nay bạn nên kiểm tra các tool sau:

```powershell
terraform -version
git --version
aws --version
```

Nếu chưa cài Terraform, dùng tài liệu chính thống:

- https://developer.hashicorp.com/terraform/install

Nếu học với AWS, bạn cũng cần AWS CLI và credential hợp lệ:

```powershell
aws configure
aws sts get-caller-identity
```

Lưu ý quan trọng: không commit access key, secret key, file `.tfstate`, hoặc file `.tfvars` có chứa thông tin nhạy cảm.

### VS Code extension nên cài

Nên cài extension:

```text
HashiCorp Terraform
```

Extension này giúp:

- Highlight cú pháp HCL.
- Format code dễ hơn.
- Gợi ý một số cấu trúc Terraform.
- Đọc file `.tf` dễ hơn khi học.

### Terraform Registry là gì?

Terraform Registry là nơi tra cứu provider và module:

- https://registry.terraform.io

Bạn nên dùng Registry để:

- Xem resource nào provider hỗ trợ.
- Xem argument nào bắt buộc.
- Xem attribute nào có thể reference.
- Tìm module có sẵn.

Ví dụ khi học AWS VPC, bạn nên tra:

```text
aws_vpc Terraform Registry
```

Tài liệu resource sẽ cho bạn biết `cidr_block`, `tags`, `enable_dns_support`, `enable_dns_hostnames`... dùng thế nào.

---

## 4. Cú pháp HCL cơ bản

Terraform dùng HCL. File Terraform thường có đuôi `.tf`.

HCL viết tắt của HashiCorp Configuration Language. Đây không phải là ngôn ngữ lập trình kiểu Python hoặc JavaScript, mà là ngôn ngữ cấu hình. Mục tiêu chính của HCL là mô tả trạng thái mong muốn của hạ tầng.

Bạn có thể hiểu đơn giản:

- Terraform code không nói "hãy bấm bước 1, bước 2, bước 3".
- Terraform code nói "tôi muốn hạ tầng cuối cùng trông như thế này".
- Terraform sẽ tự tính cần tạo, sửa hoặc xóa gì để đạt trạng thái đó.

Ví dụ:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

Câu này không phải là "chạy lệnh tạo VPC ngay lập tức". Nó có nghĩa là: trong hạ tầng mong muốn, tôi muốn có một VPC tên nội bộ là `main`, thuộc loại `aws_vpc`, với CIDR `10.0.0.0/16`.

### Block

Block là đơn vị cấu hình chính.

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

Trong ví dụ trên:

- `resource` là loại block.
- `aws_vpc` là loại resource.
- `main` là tên local trong Terraform.
- `cidr_block` là argument.

Một block thường có dạng:

```hcl
<block_type> "<label_1>" "<label_2>" {
  <argument_name> = <argument_value>
}
```

Không phải block nào cũng có 2 label. Số lượng label phụ thuộc vào loại block.

Ví dụ `terraform` block không có label:

```hcl
terraform {
  required_version = ">= 1.6.0"
}
```

Ví dụ `provider` block có 1 label:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Ví dụ `resource` block có 2 label:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

Giải thích kỹ:

- `resource`: nói với Terraform rằng bạn muốn quản lý một tài nguyên hạ tầng.
- `"aws_vpc"`: loại tài nguyên, đến từ AWS provider.
- `"main"`: tên bạn tự đặt trong code Terraform, dùng để tham chiếu sau này.
- `{ ... }`: phần thân block, chứa cấu hình chi tiết.

Tên `"main"` không nhất thiết là tên hiển thị trên AWS Console. Nó chỉ là tên trong Terraform. Nếu muốn đặt tên trên AWS Console, thường bạn dùng `tags`.

Ví dụ:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-first-vpc"
  }
}
```

Ở đây:

- `main` là tên nội bộ trong Terraform.
- `my-first-vpc` là tag `Name` sẽ thấy trên AWS Console.

### Argument

Argument là cặp `key = value`.

```hcl
instance_type = "t3.micro"
```

Argument nằm bên trong block để cấu hình chi tiết cho block đó.

Ví dụ:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-1234567890abcdef0"
  instance_type = "t3.micro"
}
```

Trong block trên:

- `ami` là argument.
- `instance_type` là argument.
- `"ami-1234567890abcdef0"` là value của `ami`.
- `"t3.micro"` là value của `instance_type`.

Điểm cần nhớ:

- Bên trái dấu `=` là tên argument.
- Bên phải dấu `=` là giá trị.
- Tên argument phải đúng theo tài liệu provider.
- Bạn không thể tự đặt bừa argument nếu provider không hỗ trợ.

Ví dụ sai:

```hcl
resource "aws_vpc" "main" {
  network_range = "10.0.0.0/16"
}
```

Sai vì `aws_vpc` không có argument tên `network_range`. Argument đúng là `cidr_block`.

Ví dụ đúng:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

### String, number, bool

```hcl
name        = "demo"
port        = 80
enable_logs = true
```

Terraform có nhiều kiểu dữ liệu. Ngày đầu bạn cần nắm chắc các kiểu cơ bản sau.

### String

String là chuỗi ký tự, đặt trong dấu nháy kép.

```hcl
name   = "demo"
region = "us-east-1"
```

String dùng cho tên, region, AMI ID, CIDR, tag value, environment...

Ví dụ:

```hcl
tags = {
  Name = "dev-vpc"
}
```

Lỗi thường gặp: quên dấu nháy kép.

```hcl
region = us-east-1
```

Terraform sẽ hiểu `us-east-1` như một expression hoặc reference, không phải string thường. Hãy viết:

```hcl
region = "us-east-1"
```

### Number

Number là số, không đặt trong dấu nháy kép.

```hcl
port          = 80
desired_count = 2
```

Nếu provider yêu cầu number, bạn nên để number thật:

```hcl
from_port = 80
to_port   = 80
```

Không nên viết:

```hcl
from_port = "80"
```

Dù đôi khi Terraform có thể tự convert, thói quen đúng là dùng đúng kiểu dữ liệu.

### Bool

Bool chỉ có 2 giá trị:

```hcl
true
false
```

Ví dụ:

```hcl
enable_dns_support   = true
enable_dns_hostnames = true
```

Bool cũng không đặt trong dấu nháy kép.

Không nên viết:

```hcl
enable_dns_support = "true"
```

Nên viết:

```hcl
enable_dns_support = true
```

### List

```hcl
availability_zones = ["us-east-1a", "us-east-1b"]
```

List là danh sách nhiều giá trị, đặt trong dấu `[]`.

Ví dụ:

```hcl
allowed_ports = [80, 443]
```

List string:

```hcl
availability_zones = ["us-east-1a", "us-east-1b"]
```

List thường dùng khi:

- Một argument nhận nhiều giá trị.
- Bạn muốn truyền nhiều subnet IDs.
- Bạn muốn khai báo nhiều port, nhiều CIDR, nhiều availability zone.

Ví dụ security group ingress có thể dùng list CIDR:

```hcl
cidr_blocks = ["0.0.0.0/0"]
```

Lỗi thường gặp: thiếu dấu phẩy.

```hcl
availability_zones = ["us-east-1a" "us-east-1b"]
```

Đúng:

```hcl
availability_zones = ["us-east-1a", "us-east-1b"]
```

### Map

```hcl
tags = {
  Project = "aws-accelerator-p2"
  Week    = "w8"
  Owner   = "your-name"
}
```

Map là tập hợp key-value, đặt trong dấu `{}`.

Map rất hay dùng cho `tags`.

```hcl
tags = {
  Name        = "dev-vpc"
  Environment = "dev"
  Project     = "aws-accelerator-p2"
}
```

Trong map:

- Bên trái là key.
- Bên phải là value.
- Mỗi dòng là một cặp key-value.

Map khác list ở chỗ:

- List chỉ là danh sách giá trị.
- Map có tên cho từng giá trị.

Ví dụ list:

```hcl
["dev", "staging", "prod"]
```

Ví dụ map:

```hcl
{
  dev     = "10.0.0.0/16"
  staging = "10.1.0.0/16"
  prod    = "10.2.0.0/16"
}
```

Map giúp bạn tra cứu theo key.

### Reference

Reference dùng để tham chiếu giá trị từ resource khác.

```hcl
subnet_id = aws_subnet.public.id
```

Mẫu chung:

```hcl
<resource_type>.<resource_name>.<attribute>
```

Reference là phần cực kỳ quan trọng trong Terraform. Đây là cách bạn nối các tài nguyên lại với nhau.

Ví dụ:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```

Dòng quan trọng:

```hcl
vpc_id = aws_vpc.main.id
```

Giải thích:

- `aws_vpc`: loại resource.
- `main`: tên resource trong Terraform.
- `id`: attribute được tạo ra sau khi VPC tồn tại.

Nghĩa là subnet này sẽ thuộc về VPC `main`.

Reference có 2 lợi ích lớn:

- Bạn không phải hard-code ID thật của resource.
- Terraform tự hiểu dependency, tức biết phải tạo VPC trước rồi mới tạo subnet.

Không nên làm thế này:

```hcl
vpc_id = "vpc-0123456789abcdef0"
```

Vì hard-code ID khiến code khó tái sử dụng, khó chạy lại ở môi trường khác.

Nên làm:

```hcl
vpc_id = aws_vpc.main.id
```

### Variable

Variable là input cho Terraform code. Dùng variable khi một giá trị có thể thay đổi giữa các môi trường hoặc giữa các lần chạy.

Khai báo variable:

```hcl
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
```

Giải thích:

- `variable`: loại block để khai báo biến.
- `"aws_region"`: tên biến.
- `description`: mô tả biến dùng để làm gì.
- `type`: kiểu dữ liệu của biến.
- `default`: giá trị mặc định nếu người dùng không truyền vào.

Dùng variable:

```hcl
provider "aws" {
  region = var.aws_region
}
```

Mẫu chung:

```hcl
var.<variable_name>
```

Ví dụ:

```hcl
var.aws_region
var.project_name
var.environment
```

Nếu variable không có `default`, Terraform sẽ yêu cầu bạn nhập giá trị khi chạy `plan` hoặc `apply`.

Ví dụ:

```hcl
variable "project_name" {
  description = "Project name"
  type        = string
}
```

Khi chạy:

```powershell
terraform plan
```

Terraform sẽ hỏi giá trị cho `project_name`.

Bạn cũng có thể truyền bằng command line:

```powershell
terraform plan -var="project_name=aws-accelerator-p2"
```

### Local values

Local values dùng để đặt tên cho một biểu thức hoặc giá trị dùng lại nhiều lần trong cùng module.

Ví dụ:

```hcl
locals {
  common_tags = {
    Project     = "aws-accelerator-p2"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

Dùng local:

```hcl
tags = local.common_tags
```

Mẫu chung:

```hcl
local.<local_name>
```

Khi nào dùng variable, khi nào dùng local?

- Dùng `variable` khi giá trị đến từ bên ngoài module, ví dụ region, environment, project name.
- Dùng `local` khi giá trị được tính hoặc chuẩn hóa bên trong module, ví dụ common tags, name prefix.

Ví dụ kết hợp:

```hcl
variable "project_name" {
  type    = string
  default = "aws-accelerator-p2"
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}
```

Ở đây:

- `var.project_name` lấy từ variable.
- `var.environment` lấy từ variable.
- `local.name_prefix` là giá trị được ghép lại từ 2 variable.

### Output

Output dùng để in giá trị quan trọng sau khi Terraform apply xong.

Ví dụ:

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
```

Giải thích:

- `output`: loại block khai báo output.
- `"vpc_id"`: tên output.
- `description`: mô tả output.
- `value`: giá trị cần in ra.

Sau khi `terraform apply`, bạn sẽ thấy output ở cuối.

Bạn cũng có thể xem lại bằng:

```powershell
terraform output
```

Hoặc lấy một output cụ thể:

```powershell
terraform output vpc_id
```

Output thường dùng cho:

- VPC ID.
- Subnet IDs.
- Load balancer DNS name.
- Public IP.
- Cluster endpoint.

Không nên output secret nếu không thật sự cần.

### Expression

Expression là phần bên phải dấu `=` dùng để tạo ra một giá trị.

Ví dụ string đơn giản:

```hcl
name = "demo"
```

Ví dụ reference:

```hcl
vpc_id = aws_vpc.main.id
```

Ví dụ nối chuỗi:

```hcl
name = "${var.project_name}-${var.environment}-vpc"
```

Terraform hiện đại cũng cho phép viết gọn trong nhiều trường hợp, nhưng với người mới học, cú pháp `"${...}"` giúp bạn nhìn rõ đâu là phần Terraform cần tính.

Ví dụ:

```hcl
tags = {
  Name = "${var.project_name}-vpc"
}
```

Nếu chỉ gán trực tiếp một variable, không cần `"${...}"`:

```hcl
region = var.aws_region
```

Không nên viết:

```hcl
region = "${var.aws_region}"
```

Dù vẫn có thể chạy, cách viết này không cần thiết.

### Comment

Terraform hỗ trợ comment để ghi chú.

Comment một dòng:

```hcl
# Đây là comment
```

Hoặc:

```hcl
// Đây cũng là comment
```

Comment nhiều dòng:

```hcl
/*
Đây là comment
nhiều dòng
*/
```

Chỉ nên comment khi cần giải thích lý do. Không cần comment những thứ quá hiển nhiên.

Ví dụ comment tốt:

```hcl
# Lab dùng CIDR riêng để tránh trùng với VPC mặc định.
cidr_block = "10.10.0.0/16"
```

Ví dụ comment không cần thiết:

```hcl
# Set instance type
instance_type = "t3.micro"
```

### Provider block

Provider block cấu hình provider mà Terraform sẽ dùng.

Ví dụ AWS:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Nếu dùng variable:

```hcl
provider "aws" {
  region = var.aws_region
}
```

Provider block trả lời câu hỏi: Terraform sẽ nói chuyện với nền tảng nào, ở đâu, bằng cấu hình gì?

Credential AWS thường không viết trực tiếp trong provider block. Nên dùng AWS CLI profile, environment variables, hoặc IAM role.

Không nên viết:

```hcl
provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA..."
  secret_key = "..."
}
```

Vì rất dễ lộ secret khi commit lên GitHub.

### Terraform block

Terraform block dùng để cấu hình chính Terraform, ví dụ version và provider cần dùng.

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

Giải thích:

- `required_version`: yêu cầu version Terraform CLI.
- `required_providers`: khai báo provider cần dùng.
- `source`: nơi lấy provider.
- `version`: version constraint của provider.

`~> 5.0` nghĩa là cho phép dùng các bản `5.x`, nhưng không tự nhảy lên `6.x`.

Việc ghim version giúp project ổn định hơn, tránh lỗi do provider nâng major version.

### Resource block

Resource block là nơi bạn khai báo tài nguyên Terraform sẽ quản lý.

Mẫu:

```hcl
resource "<resource_type>" "<resource_name>" {
  argument = value
}
```

Ví dụ:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

Điểm quan trọng:

- `resource_type` do provider định nghĩa.
- `resource_name` do bạn đặt.
- Cặp `resource_type.resource_name` phải là duy nhất trong cùng module.

Ví dụ không được khai báo trùng:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
}
```

Terraform sẽ báo lỗi vì có 2 resource cùng địa chỉ `aws_vpc.main`.

### Data source block

Data source dùng để đọc tài nguyên hoặc thông tin đã có sẵn, không tạo mới.

Mẫu:

```hcl
data "<data_source_type>" "<name>" {
  argument = value
}
```

Ví dụ đọc AMI Amazon Linux 2 mới nhất:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

Dùng data source:

```hcl
ami = data.aws_ami.amazon_linux.id
```

Mẫu reference data source:

```hcl
data.<data_source_type>.<name>.<attribute>
```

So sánh:

- `resource`: Terraform tạo và quản lý tài nguyên.
- `data`: Terraform chỉ đọc thông tin có sẵn.

### Nested block

Một số resource có block lồng bên trong.

Ví dụ security group:

```hcl
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

Ở đây:

- `ingress` là nested block.
- `egress` là nested block.
- Các argument bên trong `ingress` chỉ thuộc block `ingress`.

Không phải nested block nào cũng giống nhau. Bạn cần đọc docs của từng resource để biết nó hỗ trợ nested block nào.

### Object

Object là một cấu trúc có nhiều field được đặt tên. Bạn sẽ gặp object khi khai báo variable phức tạp.

Ví dụ:

```hcl
variable "vpc_config" {
  type = object({
    cidr_block = string
    name       = string
  })

  default = {
    cidr_block = "10.0.0.0/16"
    name       = "dev-vpc"
  }
}
```

Dùng object:

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_config.cidr_block

  tags = {
    Name = var.vpc_config.name
  }
}
```

Mẫu truy cập field:

```hcl
var.<variable_name>.<field_name>
```

Object giúp gom các cấu hình liên quan lại với nhau.

### Tuple

Tuple là một danh sách có số lượng phần tử và kiểu dữ liệu cố định theo từng vị trí.

Ví dụ khai báo type:

```hcl
variable "server_info" {
  type = tuple([string, number, bool])

  default = ["web", 80, true]
}
```

Ở đây:

- Phần tử thứ nhất phải là `string`.
- Phần tử thứ hai phải là `number`.
- Phần tử thứ ba phải là `bool`.

Truy cập tuple theo index:

```hcl
var.server_info[0]
var.server_info[1]
var.server_info[2]
```

Ngày đầu bạn chưa cần dùng tuple nhiều. Trong Terraform thực tế, `object` và `map` thường dễ đọc hơn tuple vì mỗi field có tên rõ ràng.

### Splat expression

Splat dùng để lấy một attribute từ nhiều resource hoặc nhiều object.

Ví dụ sau này khi có nhiều subnet:

```hcl
aws_subnet.public[*].id
```

Nghĩa là: lấy `id` của tất cả `aws_subnet.public`.

Ngày đầu bạn chưa cần dùng nhiều, nhưng nên nhận ra cú pháp `[*]` khi đọc code Terraform.

### `count`

`count` dùng để tạo nhiều bản sao của cùng một resource.

Ví dụ:

```hcl
resource "aws_subnet" "public" {
  count = 2

  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"
}
```

Ở đây:

- `count = 2` tạo 2 subnet.
- `count.index` là số thứ tự, bắt đầu từ 0.

Kết quả:

- Resource thứ nhất có `count.index = 0`.
- Resource thứ hai có `count.index = 1`.

Reference khi dùng count:

```hcl
aws_subnet.public[0].id
aws_subnet.public[1].id
```

Ngày đầu chỉ cần hiểu ý tưởng, chưa cần dùng thành thạo.

### `for_each`

`for_each` cũng dùng để tạo nhiều resource, nhưng theo key rõ ràng hơn `count`.

Ví dụ:

```hcl
variable "subnets" {
  type = map(string)

  default = {
    public_a = "10.0.1.0/24"
    public_b = "10.0.2.0/24"
  }
}

resource "aws_subnet" "public" {
  for_each = var.subnets

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value

  tags = {
    Name = each.key
  }
}
```

Ở đây:

- `each.key` là key trong map, ví dụ `public_a`.
- `each.value` là value trong map, ví dụ `10.0.1.0/24`.

Reference khi dùng `for_each`:

```hcl
aws_subnet.public["public_a"].id
```

Khi resource có danh tính rõ ràng theo tên, `for_each` thường dễ quản lý hơn `count`.

### Tổng kết nhanh cú pháp

| Cú pháp | Ý nghĩa | Ví dụ |
|---|---|---|
| `resource` | Tạo/quản lý tài nguyên | `resource "aws_vpc" "main"` |
| `provider` | Cấu hình provider | `provider "aws"` |
| `variable` | Khai báo input | `variable "aws_region"` |
| `var.name` | Dùng variable | `var.aws_region` |
| `locals` | Khai báo giá trị nội bộ | `locals { name = "demo" }` |
| `local.name` | Dùng local | `local.name_prefix` |
| `output` | In giá trị sau apply | `output "vpc_id"` |
| `aws_vpc.main.id` | Reference resource | Lấy ID của VPC |
| `data.aws_ami.ubuntu.id` | Reference data source | Lấy ID AMI |
| `[]` | List | `["a", "b"]` |
| `{}` | Map/object hoặc thân block | `{ Name = "demo" }` |
| `tuple` | Danh sách có kiểu cố định theo vị trí | `tuple([string, number])` |
| `"${...}"` | String interpolation | `"${var.name}-vpc"` |

### Bài tập nhỏ về cú pháp

Hãy đọc đoạn sau và tự giải thích từng dòng:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

locals {
  project_name = "aws-accelerator-p2"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name    = "${local.project_name}-vpc"
    Managed = "terraform"
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}
```

Bạn nên tự trả lời:

1. Có bao nhiêu block chính?
2. Block nào cấu hình provider?
3. Block nào tạo resource?
4. `var.aws_region` lấy từ đâu?
5. `local.project_name` lấy từ đâu?
6. `aws_vpc.main.id` có giá trị khi nào?
7. Vì sao `Name` dùng `"${local.project_name}-vpc"`?

---

## 5. Cấu trúc project Terraform nhỏ

Với bài học đầu tiên, bạn có thể dùng cấu trúc:

```text
day-a/
  main.tf
  variables.tf
  outputs.tf
  versions.tf
  README.md
```

Ý nghĩa từng file:

- `versions.tf`: khai báo Terraform version và provider version.
- `main.tf`: khai báo provider và resource chính.
- `variables.tf`: khai báo input variables.
- `outputs.tf`: khai báo output sau khi apply.
- `README.md`: ghi mục tiêu, cách chạy, bằng chứng kết quả.

Không bắt buộc phải tách file ngay từ đầu, nhưng tách như trên giúp repo dễ đọc và dễ review hơn.

---

## 6. Workflow Terraform cần thuộc

### Bước 1: `terraform init`

```powershell
terraform init
```

Lệnh này khởi tạo working directory:

- Tải provider plugin.
- Khởi tạo backend lưu state.
- Tạo hoặc cập nhật `.terraform.lock.hcl`.

Chạy khi:

- Mới clone project.
- Mới thêm hoặc sửa provider.
- Mới đổi backend.
- Mới thêm module.

Ví dụ provider pinning tốt:

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

`~> 5.0` nghĩa là cho phép các bản `5.x`, nhưng không tự nâng lên `6.x`. Đây là best practice để tránh breaking changes trong CI/CD hoặc khi teammate chạy lại project sau này.

### Bước 2: `terraform fmt`

```powershell
terraform fmt
```

Lệnh này format file `.tf` theo style chuẩn. Nên chạy trước khi commit.

### Bước 3: `terraform validate`

```powershell
terraform validate
```

Lệnh này kiểm tra cấu hình có hợp lệ về cú pháp và logic Terraform cơ bản không.

Lưu ý: `validate` không đảm bảo `apply` sẽ thành công trên AWS, vì vẫn có thể sai permission, quota, region, hoặc tên resource bị trùng.

### Bước 4: `terraform plan`

```powershell
terraform plan
```

Lệnh này cho bạn xem Terraform sẽ làm gì trước khi thay đổi hạ tầng.

Ký hiệu cần đọc:

- `+`: tạo resource mới.
- `~`: sửa resource.
- `-`: xóa resource.
- `-/+`: thay thế resource, tức xóa cái cũ và tạo cái mới.

Khi thấy `-/+`, cần đọc thật kỹ vì có thể gây downtime hoặc mất dữ liệu.

### Bước 5: `terraform apply`

```powershell
terraform apply
```

Lệnh này thực thi thay đổi. Terraform sẽ hỏi xác nhận `yes`.

Trong lab, bạn có thể dùng:

```powershell
terraform apply -auto-approve
```

Nhưng trong môi trường thật, nên tránh `-auto-approve` nếu chưa có quy trình CI/CD và review rõ ràng.

### Bước 6: `terraform destroy`

```powershell
terraform destroy
```

Lệnh này xóa các resource Terraform đang quản lý trong state.

Với lab AWS, nên destroy sau khi học xong để tránh tốn chi phí.

---

## 7. Ví dụ Terraform AWS đơn giản

Ví dụ dưới đây tạo một VPC có tags. Nếu chưa sẵn sàng tạo resource thật trên AWS, bạn chỉ cần đọc và hiểu workflow trước.

### `versions.tf`

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

### `variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region for this lab"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
  default     = "aws-accelerator-p2"
}
```

### `main.tf`

```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-w8-vpc"
    Project = var.project_name
    Week    = "w8"
    Day     = "day-01"
  }
}
```

### `outputs.tf`

```hcl
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}
```

### Lệnh chạy

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

Checkpoint evidence nên lưu:

- Kết quả `terraform version`.
- Kết quả `terraform init` thành công.
- Kết quả `terraform validate` thành công.
- Một phần `terraform plan` cho thấy resource sẽ được tạo.
- Output sau `terraform apply`.
- Xác nhận `terraform destroy` để tránh tốn chi phí.

### Gợi ý region cho học viên ở Việt Nam

Nếu mentor/lab không yêu cầu region cụ thể, bạn có thể dùng:

```hcl
provider "aws" {
  region  = "ap-southeast-1"
  profile = "default"
}
```

`ap-southeast-1` là Singapore, thường gần Việt Nam hơn `us-east-1`. Tuy nhiên, trong bài lab hoặc dự án team, hãy theo region được mentor chỉ định để tránh lệch môi trường.

### Ví dụ EC2 Free Tier để hiểu workflow

PDF có gợi ý lab deploy EC2 Free Tier. Nếu bạn được phép tạo tài nguyên AWS, flow học sẽ là:

```text
Tạo folder lab -> viết main.tf -> terraform init -> terraform plan -> terraform apply -> kiểm tra AWS Console -> terraform destroy
```

Nên dùng instance nhỏ như:

```hcl
instance_type = "t2.micro"
```

hoặc:

```hcl
instance_type = "t3.micro"
```

Lưu ý:

- Kiểm tra Free Tier trước khi tạo EC2.
- Luôn `terraform destroy` sau khi lab xong.
- Đừng tạo RDS, NAT Gateway, hoặc resource tính phí cao nếu chưa được yêu cầu.

---

## 8. State là gì và vì sao phải cẩn thận?

Terraform state mặc định nằm trong file:

```text
terraform.tfstate
```

State giúp Terraform biết:

- Resource nào trong cloud đang thuộc về project này.
- ID thật của resource trên provider.
- Attribute nào đang có giá trị gì.
- Lần sau plan/apply cần thay đổi gì.

### Không nên commit state

Không commit:

```text
terraform.tfstate
terraform.tfstate.backup
.terraform/
*.tfvars
```

Lý do:

- State có thể chứa thông tin nhạy cảm.
- Nhiều người cùng sửa local state dễ gây conflict.
- Production nên dùng remote backend như S3 + DynamoDB lock.

Hôm nay chỉ cần hiểu khái niệm. Phần remote state S3 + DynamoDB lock sẽ học kỹ hơn ở Terraform phần 2.

### Không sửa state thủ công

Không mở `terraform.tfstate` rồi tự sửa bằng tay.

State là bộ nhớ của Terraform. Nếu sửa sai, Terraform có thể hiểu nhầm resource đang tồn tại hoặc cần xóa/tạo lại resource không mong muốn.

Nếu cần thao tác với state, dùng lệnh Terraform chính thống.

### Các lệnh state cần biết

```powershell
terraform state list
```

Liệt kê các resource Terraform đang quản lý trong state.

```powershell
terraform state show <address>
```

Xem chi tiết một resource trong state.

Ví dụ:

```powershell
terraform state show aws_vpc.main
```

```powershell
terraform state mv <old_address> <new_address>
```

Đổi địa chỉ resource trong state, thường dùng khi refactor code.

```powershell
terraform state rm <address>
```

Xóa resource khỏi state, nhưng **không xóa resource thật trên cloud**.

```powershell
terraform import <address> <real_resource_id>
```

Đưa resource đã tồn tại ngoài cloud vào Terraform state.

Ví dụ:

```powershell
terraform import aws_s3_bucket.data my-existing-bucket-name
```

Ngày đầu bạn chỉ cần hiểu ý nghĩa. Không nên dùng `state mv`, `state rm`, `import` nếu chưa biết rõ hậu quả.

### Remote state với S3 và DynamoDB

Khi làm một mình ở local, Terraform thường lưu state ở:

```text
terraform.tfstate
```

Khi làm team, nên dùng remote state. Với AWS, pattern phổ biến là:

- S3 bucket để lưu state.
- DynamoDB table để lock state.
- Bật encryption cho state.
- Bật versioning cho S3 bucket.

Ví dụ backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "prod/vpc/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

State locking giúp tránh việc hai người cùng chạy `terraform apply` một lúc. Nếu không lock, state có thể bị ghi đè hoặc hỏng.

### State drift là gì?

State drift xảy ra khi hạ tầng thật khác với state/code Terraform.

Ví dụ:

- Terraform tạo EC2.
- Sau đó ai đó vào AWS Console sửa security group thủ công.
- Terraform code không biết thay đổi này.

Khi chạy:

```powershell
terraform plan
```

Terraform có thể phát hiện drift và đề xuất thay đổi để đưa hạ tầng về lại desired state.

Nguyên tắc làm việc tốt:

- Hạn chế sửa resource thủ công trên Console.
- Nếu bắt buộc sửa thủ công, cần cập nhật Terraform code hoặc import/refresh phù hợp.
- Luôn đọc kỹ `terraform plan`.

---

## 9. Variable và output

### Variable

Variable giúp code linh hoạt hơn.

```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
```

Dùng variable:

```hcl
tags = {
  Environment = var.environment
}
```

### Truyền giá trị variable

Cách 1: dùng default trong `variables.tf`.

Cách 2: dùng command line.

```powershell
terraform plan -var="environment=dev"
```

Cách 3: dùng file `.tfvars`.

```hcl
environment = "dev"
```

Chạy:

```powershell
terraform plan -var-file="dev.tfvars"
```

Lưu ý: chỉ commit `.tfvars` nếu không có secret và team đồng ý. Nếu chưa chắc, đưa `*.tfvars` vào `.gitignore`.

### `sensitive = true`

Với biến nhạy cảm, có thể khai báo:

```hcl
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

`sensitive = true` giúp Terraform ẩn giá trị trong plan/output ở nhiều tình huống.

Nhưng cần nhớ:

- `sensitive = true` không có nghĩa là secret biến mất khỏi state.
- State vẫn có thể chứa secret.
- Vì vậy vẫn phải bảo vệ state và không commit state lên Git.

### Dùng tfvars theo môi trường

Bạn có thể dùng nhiều file `.tfvars` để tách cấu hình theo môi trường.

Ví dụ `dev.tfvars`:

```hcl
environment   = "development"
instance_type = "t2.micro"
```

Ví dụ `prod.tfvars`:

```hcl
environment   = "production"
instance_type = "t3.medium"
```

Chạy với file cụ thể:

```powershell
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

Hoặc:

```powershell
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

Nguyên tắc:

- Có thể commit `.tfvars` nếu chỉ chứa giá trị không nhạy cảm.
- Không commit `.tfvars` chứa password, token, secret key.
- Secret nên đến từ environment variable, secret manager, hoặc hệ thống CI/CD.

### Output

Output giúp in ra thông tin quan trọng sau khi apply.

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```

---

## 10. Dependency trong Terraform

Terraform tự suy ra thứ tự tạo resource dựa trên reference.

Ví dụ:

```hcl
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.10.1.0/24"
}
```

Vì `aws_subnet.public` tham chiếu `aws_vpc.main.id`, Terraform biết phải tạo VPC trước subnet.

Chỉ dùng `depends_on` khi dependency không thể hiện rõ qua reference.

```hcl
depends_on = [aws_vpc.main]
```

Dùng `depends_on` quá nhiều có thể làm code khó hiểu hơn, nên ưu tiên reference tự nhiên.

---

## 10.1. Modules và tái sử dụng code

Module giúp bạn đóng gói Terraform code để tái sử dụng. Có thể hiểu module giống như function trong lập trình: viết một lần, gọi nhiều lần với input khác nhau.

### Vì sao cần module?

Nếu không dùng module, bạn dễ copy-paste cấu hình VPC cho dev, staging, prod. Copy-paste nhiều sẽ dẫn tới:

- Khó sửa đồng bộ.
- Dễ lệch cấu hình giữa môi trường.
- Khó review.
- Dễ tạo lỗi nhỏ nhưng khó phát hiện.

Với module, bạn có thể:

- Viết module VPC một lần.
- Gọi module đó cho dev/staging/prod.
- Truyền biến khác nhau cho từng môi trường.

### Cấu trúc module chuẩn

```text
modules/
  vpc/
    main.tf
    variables.tf
    outputs.tf
    README.md
```

Ý nghĩa:

- `main.tf`: resource chính.
- `variables.tf`: input của module.
- `outputs.tf`: giá trị module trả ra.
- `README.md`: cách dùng module.

### Gọi local module

Ví dụ:

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  environment         = "production"
}
```

Reference output của module:

```hcl
module.vpc.public_subnet_ids[0]
```

Mẫu chung:

```hcl
module.<module_name>.<output_name>
```

### Project structure thực tế

Một project Terraform thực tế thường tách module và environment:

```text
infra/
  modules/
    vpc/
    ec2/
  environments/
    dev/
      main.tf
    staging/
      main.tf
    prod/
      main.tf
```

Mỗi environment gọi cùng module nhưng truyền giá trị khác nhau.

Ví dụ:

- Dev dùng instance nhỏ.
- Staging giống production hơn.
- Production bật cấu hình bảo mật, backup, monitoring chặt hơn.

Ngày đầu bạn chưa cần tự viết module phức tạp. Nhưng bạn cần hiểu module là hướng đi để code Terraform không bị copy-paste.

---

## 11. Các lỗi hay gặp ngày đầu

### Lỗi chưa init

Triệu chứng thường gặp:

```text
Error: Inconsistent dependency lock file
```

Hoặc provider chưa được cài.

Cách xử lý:

```powershell
terraform init
```

### Lỗi sai credential AWS

Triệu chứng:

```text
NoCredentialProviders
```

Hoặc `AccessDenied`.

Cách kiểm tra:

```powershell
aws sts get-caller-identity
```

### Lỗi region

Nếu resource không có ở region đang dùng, kiểm tra:

```powershell
aws configure get region
```

Hoặc kiểm tra provider:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

### Plan có xóa resource

Nếu thấy ký hiệu `-` hoặc `-/+`, dừng apply và đọc kỹ. Hỏi mentor nếu resource quan trọng.

### Dependency cycle

Triệu chứng: Terraform báo có vòng phụ thuộc giữa các resource.

Nguyên nhân thường gặp:

- Resource A tham chiếu B.
- Resource B lại tham chiếu A.

Cách xử lý:

- Xem lại reference.
- Tách resource hoặc sửa thiết kế dependency.
- Chỉ dùng `depends_on` khi thật sự cần.

### Provider version conflict

Triệu chứng: Terraform báo version provider không tương thích.

Cách xử lý:

```powershell
terraform init -upgrade
```

và kiểm tra lại `required_providers`.

Không nên nâng version bừa trong production. Hãy đọc changelog nếu nâng major version.

### Resource already exists

Triệu chứng: apply thất bại vì resource đã tồn tại ngoài cloud.

Cách xử lý tùy tình huống:

- Nếu resource chỉ cần đọc: dùng `data source`.
- Nếu muốn Terraform quản lý resource đó: dùng `terraform import`.
- Nếu resource là lab dư thừa: xóa resource cũ sau khi chắc chắn không ảnh hưởng.

### Permission denied

Triệu chứng: AWS trả lỗi `AccessDenied` hoặc thiếu permission.

Cách kiểm tra:

```powershell
aws sts get-caller-identity
```

Sau đó kiểm tra IAM user/role/policy đang dùng.

---

## 11.1. Best practices và làm việc nhóm

### Quản lý secret an toàn

Không nên:

- Hard-code access key trong file `.tf`.
- Commit `*.tfstate`.
- Commit `.tfvars` có secret.
- Đặt password trong `default` của variable.

Nên:

- Dùng AWS CLI profile hoặc environment variables.
- Dùng IAM Role khi chạy trên EC2/ECS/Lambda/CI phù hợp.
- Dùng AWS Secrets Manager, HashiCorp Vault, hoặc secret manager tương đương.
- Dùng encrypted remote state, ví dụ S3 SSE-KMS.

### `.gitignore` tối thiểu cho Terraform

Repo Terraform nên có `.gitignore` để tránh commit file nguy hiểm hoặc file local.

Nội dung tối thiểu:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
crash.log
crash.*.log
*.tfplan
```

Lưu ý:

- `.terraform.lock.hcl` thường nên commit để khóa provider version.
- `.terraform/` không commit vì là folder plugin/module tải về local.
- `*.tfplan` không commit vì plan có thể chứa dữ liệu nhạy cảm.

### Naming convention

Nên đặt tên resource dễ hiểu theo mẫu:

```text
<environment>-<resource>-<purpose>
```

Ví dụ:

```text
dev-vpc-main
prod-rds-main
staging-ec2-web
```

Tags nên có:

```hcl
tags = {
  Environment = var.environment
  Project     = var.project_name
  Owner       = "your-name"
  ManagedBy   = "Terraform"
}
```

Tags giúp:

- Tìm resource trên AWS Console.
- Theo dõi cost.
- Biết resource thuộc project nào.
- Biết resource có được quản lý bởi Terraform hay không.

### Format và validate trước khi commit

Trước mỗi commit, nên chạy:

```powershell
terraform fmt
terraform validate
terraform plan
```

Ý nghĩa:

- `fmt`: giữ format đồng nhất.
- `validate`: bắt lỗi cú pháp sớm.
- `plan`: kiểm tra thay đổi thực tế trước khi đưa lên review.

Sau này bạn có thể học thêm:

```text
tflint
```

`tflint` là linter giúp phát hiện nhiều vấn đề best practice trong Terraform.

### Terraform trong CI/CD

Một workflow team phổ biến:

```text
Mở Pull Request -> CI chạy terraform fmt/validate/plan -> team review plan -> merge -> apply
```

Công cụ thường gặp:

- GitHub Actions.
- GitLab CI.
- Terraform Cloud.
- Atlantis.

Mục tiêu là không để hạ tầng thay đổi âm thầm. Mọi thay đổi nên có plan, review và log.

---

## 12. Checklist học hôm nay

- [ ] Đọc và hiểu IaC là gì.
- [ ] Đọc và hiểu Terraform provider, resource, state, module.
- [ ] Hiểu Terraform khác gì Ansible, CloudFormation, Pulumi, CDK.
- [ ] Hiểu Terraform Core, Provider, Cloud API và State phối hợp như thế nào.
- [ ] Cài hoặc kiểm tra Terraform CLI.
- [ ] Cài extension HashiCorp Terraform cho VS Code.
- [ ] Biết cách tra Terraform Registry.
- [ ] Tạo folder `cloud/w8/day-a`.
- [ ] Viết ít nhất một ví dụ Terraform nhỏ.
- [ ] Chạy `terraform init`.
- [ ] Chạy `terraform fmt`.
- [ ] Chạy `terraform validate`.
- [ ] Chạy `terraform plan`.
- [ ] Nếu có AWS credential và được phép tạo resource, chạy `terraform apply`, sau đó `terraform destroy`.
- [ ] Hiểu vì sao không commit state, secret, `.terraform/`, `*.tfvars` nhạy cảm.
- [ ] Hiểu remote state S3 + DynamoDB lock ở mức khái niệm.
- [ ] Hiểu module dùng để tránh copy-paste.
- [ ] Ghi lại evidence vào README hoặc reflection.
- [ ] Commit cuối ngày với message dạng `[W8-D1] terraform basics`.

---

## 13. Câu hỏi nên tự trả lời trước khi kết thúc ngày

1. IaC giải quyết vấn đề gì trong vận hành cloud?
2. Terraform `plan` khác `apply` như thế nào?
3. Vì sao phải cẩn thận với file `terraform.tfstate`?
4. Khi nào cần chạy `terraform init`?
5. Ký hiệu `+`, `~`, `-`, `-/+` trong plan có nghĩa gì?
6. Provider và resource khác nhau như thế nào?
7. Vì sao nên dùng Git để quản lý Terraform code?
8. Terraform Core và provider khác nhau thế nào?
9. Vì sao nên pin provider version?
10. State drift là gì?
11. Khi nào dùng data source thay vì resource?
12. Vì sao module giúp code dễ bảo trì hơn?

---

## 14. Gợi ý ghi reflection cuối ngày

Bạn có thể ghi vào `cloud/w8/reflection.md`:

```markdown
## W8-D1 Terraform Basics

### Hôm nay tôi đã học

- ...

### Lệnh tôi đã chạy

- `terraform init`
- `terraform fmt`
- `terraform validate`
- `terraform plan`

### Evidence

- ...

### Lỗi gặp phải và cách xử lý

- ...

### Câu hỏi cho mentor

- ...
```

---

## 15. Tài liệu nên đọc

Ưu tiên đọc theo thứ tự:

1. HashiCorp Learn - Get Started with Terraform on AWS:
   https://developer.hashicorp.com/terraform/tutorials/aws-get-started
2. Terraform Language Documentation:
   https://developer.hashicorp.com/terraform/language
3. Terraform CLI Documentation:
   https://developer.hashicorp.com/terraform/cli
4. Terraform Best Practices:
   https://www.terraform-best-practices.com

Mục tiêu của ngày đầu không phải học hết Terraform, mà là nắm workflow và tự tin đọc/tạo một project Terraform nhỏ.
