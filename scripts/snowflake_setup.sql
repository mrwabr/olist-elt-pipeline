-- ============================================================
-- Setup manuel de la zone RAW (bronze) : tables + chargement S3.
-- A lancer une fois après le déploiement Terraform (infra) et
-- l'upload des CSV vers S3 (scripts/upload_to_s3.py).
-- En production, ces étapes sont automatisées par le DAG Airflow.
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OLIST_WH;
USE DATABASE OLIST;
USE SCHEMA RAW;

-- Droit nécessaire pour que dbt (rôle OLIST_TRANSFORMER) puisse
-- créer les schémas STAGING custom si besoin.
GRANT CREATE SCHEMA ON DATABASE OLIST TO ROLE OLIST_TRANSFORMER;
GRANT ROLE OLIST_TRANSFORMER TO USER MRWABR;

-- ---- Tables RAW (bronze) : tout en STRING, cast fait par dbt ----
CREATE OR REPLACE TABLE orders (
    order_id                       STRING,
    customer_id                    STRING,
    order_status                   STRING,
    order_purchase_timestamp       STRING,
    order_approved_at               STRING,
    order_delivered_carrier_date    STRING,
    order_delivered_customer_date   STRING,
    order_estimated_delivery_date   STRING
);

CREATE OR REPLACE TABLE order_items (
    order_id            STRING,
    order_item_id        STRING,
    product_id          STRING,
    seller_id            STRING,
    shipping_limit_date   STRING,
    price                STRING,
    freight_value        STRING
);

CREATE OR REPLACE TABLE customers (
    customer_id               STRING,
    customer_unique_id         STRING,
    customer_zip_code_prefix   STRING,
    customer_city             STRING,
    customer_state            STRING
);

CREATE OR REPLACE TABLE products (
    product_id                     STRING,
    product_category_name           STRING,
    product_name_lenght              STRING,
    product_description_lenght       STRING,
    product_photos_qty              STRING,
    product_weight_g                STRING,
    product_length_cm               STRING,
    product_height_cm               STRING,
    product_width_cm                STRING
);

CREATE OR REPLACE TABLE payments (
    order_id               STRING,
    payment_sequential      STRING,
    payment_type            STRING,
    payment_installments     STRING,
    payment_value           STRING
);

CREATE OR REPLACE TABLE reviews (
    review_id                 STRING,
    order_id                  STRING,
    review_score               STRING,
    review_comment_title        STRING,
    review_comment_message      STRING,
    review_creation_date        STRING,
    review_answer_timestamp     STRING
);

CREATE OR REPLACE TABLE sellers (
    seller_id               STRING,
    seller_zip_code_prefix   STRING,
    seller_city             STRING,
    seller_state            STRING
);

CREATE OR REPLACE TABLE geolocation (
    geolocation_zip_code_prefix STRING,
    geolocation_lat             STRING,
    geolocation_lng             STRING,
    geolocation_city           STRING,
    geolocation_state          STRING
);

CREATE OR REPLACE TABLE category_translation (
    product_category_name           STRING,
    product_category_name_english    STRING
);

-- ---- Chargement depuis S3 (stage externe créé par Terraform) ----
COPY INTO orders FROM @OLIST_S3_STAGE/orders/olist_orders_dataset.csv
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO order_items FROM @OLIST_S3_STAGE/order_items/olist_order_items_dataset.csv
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO customers FROM @OLIST_S3_STAGE/customers/olist_customers_dataset.csv
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO products FROM @OLIST_S3_STAGE/products/olist_products_dataset.csv
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO payments FROM @OLIST_S3_STAGE/payments/olist_order_payments_dataset.csv
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO reviews FROM @OLIST_S3_STAGE/reviews/olist_order_reviews_dataset.csv
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO sellers FROM @OLIST_S3_STAGE/sellers/olist_sellers_dataset.csv
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO geolocation FROM @OLIST_S3_STAGE/geolocation/olist_geolocation_dataset.csv
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO category_translation FROM @OLIST_S3_STAGE/category_translation/product_category_name_translation.csv
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);