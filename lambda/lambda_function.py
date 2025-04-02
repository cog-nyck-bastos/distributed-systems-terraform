import boto3
import pandas as pd
import os

s3 = boto3.client('s3')

def handler(event, context):
    bucket_name = "distributed-systems-terraform"
    csv_key = "source/data.csv"
    parquet_key = "destination/data.parquet"

    csv_path = f"/tmp/{os.path.basename(csv_key)}"
    parquet_path = f"/tmp/{os.path.basename(parquet_key)}"

    try:
        s3.download_file(bucket_name, csv_key, csv_path)

        df = pd.read_csv(csv_path)
        df.to_parquet(parquet_path, index=False)

        s3.upload_file(parquet_path, bucket_name, parquet_key)

        return {
            "statusCode": 200,
            "body": f"Arquivo {csv_key} convertido para {parquet_key} com sucesso!"
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Erro ao processar o arquivo: {str(e)}"
        }