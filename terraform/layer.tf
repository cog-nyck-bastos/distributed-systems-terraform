
resource "aws_serverlessapplicationrepository_cloudformation_stack" "aws_sdk_pandas_layer" {
  name           = "aws-sdk-pandas-layer-py3-11"
  application_id = "arn:aws:serverlessrepo:us-east-1:336392948345:applications/aws-sdk-pandas-layer-py3-11"
  capabilities = [
    "CAPABILITY_IAM"
  ]
}
