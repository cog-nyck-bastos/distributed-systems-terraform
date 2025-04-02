# Define a política de assunção para a role da Lambda
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Define as permissões para a Lambda (logs + acesso ao S3)
data "aws_iam_policy_document" "lambda_permissions" {
  # Permissões básicas de execução Lambda (logs)
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  # Permissões para o S3 (leitura no bucket específico)
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::distributed-systems-terraform",
      "arn:aws:s3:::distributed-systems-terraform/*"
    ]
  }

  # Permissão para o S3 escrever no bucket de destino
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::distributed-systems-terraform/destination/*"]
  }
}

# Cria a role do IAM para a Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_transform_data_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Anexa as permissões à role da Lambda
resource "aws_iam_role_policy" "lambda_execution_policy" {
  name   = "lambda_execution_policy"
  role   = aws_iam_role.lambda_role.name
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

# Permissão para o S3 invocar a Lambda
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.example.arn
}
resource "aws_iam_role" "accessGlue" {
  name = "terraform-accessGlue-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "glue_logs_policy" {
  name        = "terraform-glue-logs-policy"
  description = "Permissão para o Glue registrar logs no CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:us-east-1:476114135520:log-group:/aws-glue/crawlers",
          "arn:aws:logs:us-east-1:476114135520:log-group:/aws-glue/crawlers:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:CreateDatabase",
          "glue:DeleteDatabase",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:UpdateDatabase",
          "glue:CreateTable",
          "glue:DeleteTable",
          "glue:BatchDeleteTable",
          "glue:UpdateTable",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetTableVersions",
          "glue:CreatePartition",
          "glue:BatchCreatePartition",
          "glue:DeletePartition",
          "glue:BatchDeletePartition",
          "glue:UpdatePartition",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchGetPartition",
          "glue:StartCrawler",
          "glue:StopCrawler",
          "glue:GetCrawler",
          "glue:GetCrawlers",
          "glue:UpdateCrawler",
          "glue:CreateCrawler",
          "glue:DeleteCrawler"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "glue_logs" {
  role       = aws_iam_role.accessGlue.name
  policy_arn = aws_iam_policy.glue_logs_policy.arn
}

resource "aws_iam_policy" "S3policy" {
  name        = "terraform-S3-policy"
  description = "Permissão para o Glue acessar S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ]
      Resource = [
        "arn:aws:s3:::distributed-systems-terraform",
        "arn:aws:s3:::distributed-systems-terraform/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  role       = aws_iam_role.accessGlue.name
  policy_arn = aws_iam_policy.S3policy.arn
}

resource "aws_iam_role" "athena_role" {
  name = "terraform-athena-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "athena.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "athena_s3_policy" {
  name        = "terraform-athena-s3-policy"
  description = "Permite Athena acessar S3 e Glue"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::distributed-systems-terraform",
          "arn:aws:s3:::distributed-systems-terraform/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:BatchGetPartition"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "athena_s3_glue" {
  role       = aws_iam_role.athena_role.name
  policy_arn = aws_iam_policy.athena_s3_policy.arn
}

# Adicionar a política para o Glue que permite acesso ao S3 e a Glue.
resource "aws_iam_role_policy_attachment" "glue_s3_permissions" {
  role       = aws_iam_role.accessGlue.name
  policy_arn = aws_iam_policy.S3policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.accessGlue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}