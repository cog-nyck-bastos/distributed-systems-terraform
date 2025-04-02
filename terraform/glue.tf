resource "aws_glue_catalog_database" "database" {
  name = "distributed_systems_terraform"
}

resource "aws_glue_catalog_table" "table" {
  name          = "terraform_data_table"
  database_name = aws_glue_catalog_database.database.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "parquet"
  }

  storage_descriptor {
    location      = "s3://distributed-systems-terraform/source/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
  }
}

resource "aws_glue_crawler" "crawler" {
  database_name = aws_glue_catalog_database.database.name
  name          = "crawler-desafio-terraform"
  role          = aws_iam_role.accessGlue.arn

  s3_target {
    path = "s3://distributed-systems-terraform/source/"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }
}