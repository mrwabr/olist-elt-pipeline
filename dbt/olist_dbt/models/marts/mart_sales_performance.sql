{#
    CA, nombre de commandes par mois / catégorie produit / région (état client).
    Grain : 1 ligne par (mois, catégorie, état).
#}
with orders as (
    select * from {{ ref('int_orders__joined') }}
    where order_status not in ('canceled', 'unavailable')
),

order_items as (
    select * from {{ ref('int_order_items__enriched') }}
),

joined as (
    select
        date_trunc('month', o.order_purchase_at)::date as order_month,
        oi.product_category,
        o.customer_state,
        o.order_id,
        oi.item_total_value
    from orders o
    inner join order_items oi
        on o.order_id = oi.order_id
),

aggregated as (
    select
        order_month,
        product_category,
        customer_state,
        count(distinct order_id)   as n_orders,
        sum(item_total_value)      as gross_merchandise_value,
        round(sum(item_total_value) / nullif(count(distinct order_id), 0), 2) as avg_order_value
    from joined
    group by order_month, product_category, customer_state
)

select * from aggregated
order by order_month, gross_merchandise_value desc