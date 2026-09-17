{#
    Calcule, pour chaque commande LIVREE, les métriques de délai de livraison :
    délai réel (jours), délai estimé (jours), écart (retard positif = en retard).
#}
with orders as (
    select * from {{ ref('stg_olist__orders') }}
),

delivered as (
    select
        order_id,
        customer_id,
        order_status,
        order_purchase_at,
        order_estimated_delivery_at,
        order_delivered_customer_at,
        datediff('day', order_purchase_at, order_delivered_customer_at)        as actual_delivery_days,
        datediff('day', order_purchase_at, order_estimated_delivery_at)        as estimated_delivery_days,
        datediff('day', order_estimated_delivery_at, order_delivered_customer_at) as delay_days,
        case
            when order_delivered_customer_at > order_estimated_delivery_at then true
            else false
        end as is_late
    from orders
    where order_status = 'delivered'
      and order_delivered_customer_at is not null
)

select * from delivered