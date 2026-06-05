# ADR-001: Dùng S3 và DynamoDB cho Terraform Remote State

## Trạng thái

Draft

## Bối cảnh

Khi làm việc với Terraform theo nhóm, local state không còn phù hợp vì mỗi người có thể có một bản state khác nhau. Nếu hai người cùng chạy `terraform apply`, state có thể bị conflict hoặc ghi đè.

## Quyết định

Sử dụng S3 bucket để lưu Terraform state và DynamoDB table để state locking.

## Hệ quả

- Team có một nguồn state thống nhất.
- DynamoDB lock giúp tránh nhiều người apply cùng lúc.
- S3 versioning giúp khôi phục state cũ khi cần.
- Cần bật encryption và quản lý IAM permission cẩn thận.
- State có thể chứa dữ liệu nhạy cảm nên không được public hoặc commit lên Git.

## Câu hỏi cần xác nhận

- Tên S3 bucket state theo convention nào?
- Dùng region nào cho state backend?
- Có dùng SSE-S3 hay SSE-KMS?
- IAM policy cho học viên cần quyền gì?
