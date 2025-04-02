data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda/"
  output_path = "../lambda/lambda.zip"

}
resource "aws_lambda_function" "lambda" {
  function_name    = "transform-data-function-terrafom"
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10
  memory_size      = 128

  layers = [
    [for k, v in aws_serverlessapplicationrepository_cloudformation_stack.aws_sdk_pandas_layer.outputs : v][0]
  ]
}

resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"

  source_arn = aws_s3_bucket.example.arn
}

resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = aws_s3_bucket.example.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "source/"
    filter_suffix       = ".csv"
  }

  depends_on = [
    aws_lambda_function.lambda,     # Garante que a Lambda já existe
    aws_lambda_permission.s3_invoke # Garante que a permissão está ativa
  ]
}
