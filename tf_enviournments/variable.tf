

variable "vpc_cidr" {
  description = "VPC CIDR Range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "github_repository" {
  description = "GitHub repo for OIDC trust, e.g. myorg/ci_cd_pipeline"
  type        = string
}

# variable "subnet_cidr" {
#     description = "Subnet CIDRS"
#     type = list(string)
# }