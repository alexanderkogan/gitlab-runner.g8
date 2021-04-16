variable "name" {
  type        = string
  description = "Name of the bucket. It must be globally unique. Use the prefix for buckets defined in the locals. Will also be used for the Name tag."
}

variable "acl" {
  default     = "private"
  description = "Set the ACL of the bucket. Default: private"
}

variable "owner_tag" {
  type        = string
  description = "Required owner tag"
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags for the bucket. Default: {}"
  default     = {}
}

variable "policy" {
  type        = string
  description = "Set the policy of the bucket. Empty by default"
  default     = ""
}

variable "index_document" {
  description = "Set the index_document of the bucket, for static websites. Empty by default"
  type        = string
  default     = ""
}

variable "error_document" {
  description = "Set the error_document of the bucket, for static websites. Empty by default"
  type        = string
  default     = ""
}

resource "aws_s3_bucket" "this" {
  bucket = var.name
  acl    = var.acl
  lifecycle {
    prevent_destroy = true
  }
  tags = merge(var.additional_tags, { Name = var.name, Owner = var.owner_tag })

  policy = var.policy
  dynamic "website" {
    for_each = var.index_document != "" ? [1] : []
    content {
      index_document = var.index_document
      error_document = var.error_document
    }
  }
}

output "bucket" {
  value = aws_s3_bucket.this
}