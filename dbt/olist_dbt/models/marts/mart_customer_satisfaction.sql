{#
    Notes moyennes clients et corrélation retard de livraison / satisfaction.
    Grain : 1 ligne par mois, avec ventilation "à l'heure" vs "en retard".
#}
with orders as (
    select * from {{ ref('int_orders__joined') }}
    where order_status = 'delivered'
),

delivery as (
    select * from {{ ref('int_orders__delivery_metrics') }}
),

joined as (
    select
        date_trunc('month', o.order_purchase_at)::date as order_month,
        o.order_id,
        o.avg_review_score,
        d.is_late,
        d.delay_days
    from orders o
    inner join delivery d
        on o.order_id = d.order_id
    where o.avg_review_score is not null
),

aggregated as (
    select
        order_month,
        count(*)                                                          as n_reviewed_orders,
        round(avg(avg_review_score), 2)                                    as avg_review_score,
        round(avg(case when is_late then avg_review_score end), 2)         as avg_score_when_late,
        round(avg(case when not is_late then avg_review_score end), 2)     as avg_score_when_on_time,
        round(avg(delay_days), 1)                                          as avg_delay_days
    from joined
    group by order_month
)

select * from aggregated
order by order_month