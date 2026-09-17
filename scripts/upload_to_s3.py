"""
Upload des 9 CSV Olist vers la zone bronze S3 (raw/<table>/).
Mapping nom de fichier Kaggle -> préfixe S3 (aligné avec les sources dbt).
"""
import os
import sys
import boto3
from pathlib import Path

BUCKET_NAME = os.environ.get("S3_BUCKET_NAME", "olist-datalake-mrwabr")
RAW_PREFIX = "raw"
LOCAL_DATA_DIR = Path(__file__).parent.parent / "data" / "raw"

FILE_TO_TABLE_MAPPING = {
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_customers_dataset.csv": "customers",
    "olist_products_dataset.csv": "products",
    "olist_order_payments_dataset.csv": "payments",
    "olist_order_reviews_dataset.csv": "reviews",
    "olist_sellers_dataset.csv": "sellers",
    "olist_geolocation_dataset.csv": "geolocation",
    "product_category_name_translation.csv": "category_translation",
}


def upload_all():
    s3 = boto3.client("s3")
    uploaded = []
    missing = []

    for filename, table in FILE_TO_TABLE_MAPPING.items():
        local_path = LOCAL_DATA_DIR / filename
        if not local_path.exists():
            missing.append(filename)
            continue

        s3_key = f"{RAW_PREFIX}/{table}/{filename}"
        print(f"Uploading {filename} -> s3://{BUCKET_NAME}/{s3_key}")
        s3.upload_file(str(local_path), BUCKET_NAME, s3_key)
        uploaded.append(s3_key)

    print(f"\n{len(uploaded)}/{len(FILE_TO_TABLE_MAPPING)} fichiers uploadés.")
    if missing:
        print(f"⚠️  Fichiers manquants dans {LOCAL_DATA_DIR} :")
        for f in missing:
            print(f"   - {f}")
        sys.exit(1)


if __name__ == "__main__":
    upload_all()