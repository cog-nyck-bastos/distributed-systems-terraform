resource "aws_s3_bucket" "example" {
  bucket = "distributed-systems-terraform"

  tags = {
    Name        = "distributed-systems-terraform"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}
resource "aws_s3_object" "source_directory" {
  bucket = aws_s3_bucket.example.bucket
  key    = "source/"
}

resource "aws_s3_object" "destination_directory" {
  bucket = aws_s3_bucket.example.bucket
  key    = "destination/"
}

resource "aws_s3_object" "upload_file" {
  bucket = aws_s3_bucket.example.bucket
  key    = "source/data.csv"
  source = "../data/anime.csv"
  etag   = filemd5("../data/anime.csv")
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::yourID:root"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]
  }
}