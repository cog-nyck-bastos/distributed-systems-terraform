variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}
variable "aws_profile" {
  description = "AWS profile"
  type        = string
  default     = "tfcog"
}