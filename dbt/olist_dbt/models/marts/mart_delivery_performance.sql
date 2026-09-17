{#
    Délais de livraison réels vs estimés, taux de retard, par mois et par région.
    Grain : 1 ligne par (mois, état client).
#}
with delivery as (
    select * from {{ ref('int_orders__delivery_metrics') }}
),

customers as (
    select * from {{ ref('int_customers__location') }}
),

joined as (
    select
        date_trunc('month', d.order_purchase_at)::date as order_month,
        c.customer_state,
        d.order_id,
        d.actual_delivery_days,
        d.estimated_delivery_days,
        d.delay_days,
        d.is_late
    from delivery d
    left join customers c
        on d.customer_id = c.customer_id
),

aggregated as (
    select
        order_month,
        customer_state,
        count(*)                                                     as n_delivered_orders,
        round(avg(actual_delivery_days), 1)                          as avg_actual_delivery_days,
        round(avg(estimated_delivery_days), 1)                       as avg_estimated_delivery_days,
        round(avg(delay_days), 1)                                    as avg_delay_days,
        sum(case when is_late then 1 else 0 end)                     as n_late_orders,
        round(100.0 * sum(case when is_late then 1 else 0 end) / nullif(count(*), 0), 2) as late_rate_pct
    from joined
    group by order_month, customer_state
)

select * from aggregated
order by order_month, late_rate_pct desc