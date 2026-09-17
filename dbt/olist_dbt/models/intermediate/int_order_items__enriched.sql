{#
    Une ligne par article commandé, enrichie avec le produit (catégorie EN) et
    le vendeur. Base réutilisée par le mart sales performance.
#}
with order_items as (
    select * from {{ ref('stg_olist__order_items') }}
),

products as (
    select * from {{ ref('stg_olist__products') }}
),

category_translation as (
    select * from {{ ref('stg_olist__category_translation') }}
),

sellers as (
    select * from {{ ref('stg_olist__sellers') }}
),

joined as (
    select
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        oi.price + oi.freight_value               as item_total_value,
        coalesce(ct.product_category_name_english, p.product_category_name, 'unknown') as product_category,
        s.seller_state,
        s.seller_city
    from order_items oi
    left join products p
        on oi.product_id = p.product_id
    left join category_translation ct
        on p.product_category_name = ct.product_category_name
    left join sellers s
        on oi.seller_id = s.seller_id
)

select * from joined