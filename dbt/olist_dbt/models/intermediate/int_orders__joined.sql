{#
    Table pivot au niveau commande : agrège les articles (montant, nb d'articles),
    le paiement total et la note de review moyenne. Base commune des 3 marts.
#}
with orders as (
    select * from {{ ref('stg_olist__orders') }}
),

order_items as (
    select * from {{ ref('int_order_items__enriched') }}
),

payments as (
    select * from {{ ref('stg_olist__payments') }}
),

reviews as (
    select * from {{ ref('stg_olist__reviews') }}
),

customers as (
    select * from {{ ref('int_customers__location') }}
),

items_agg as (
    select
        order_id,
        count(distinct order_item_id)  as n_items,
        sum(price)                     as gross_merchandise_value,
        sum(freight_value)             as total_freight_value,
        sum(item_total_value)          as order_total_value,
        mode(product_category)         as main_product_category
    from order_items
    group by order_id
),

payments_agg as (
    select
        order_id,
        sum(payment_value)             as total_payment_value,
        max(payment_type)              as primary_payment_type,
        max(payment_installments)      as max_installments
    from payments
    group by order_id
),

reviews_agg as (
    select
        order_id,
        avg(review_score)              as avg_review_score,
        count(review_id)               as n_reviews
    from reviews
    group by order_id
),

final as (
    select
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_at,
        o.order_approved_at,
        o.order_delivered_carrier_at,
        o.order_delivered_customer_at,
        o.order_estimated_delivery_at,
        c.customer_state,
        c.customer_city,
        i.n_items,
        i.gross_merchandise_value,
        i.total_freight_value,
        i.order_total_value,
        i.main_product_category,
        p.total_payment_value,
        p.primary_payment_type,
        p.max_installments,
        r.avg_review_score,
        r.n_reviews
    from orders o
    left join customers c      on o.customer_id = c.customer_id
    left join items_agg i      on o.order_id = i.order_id
    left join payments_agg p   on o.order_id = p.order_id
    left join reviews_agg r    on o.order_id = r.order_id
)

select * from final