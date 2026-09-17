{#
    Enrichit chaque client avec sa position géographique (via le préfixe de code
    postal). Utilisé par les marts sales & delivery pour l'analyse régionale.
#}
with customers as (
    select * from {{ ref('stg_olist__customers') }}
),

geolocation as (
    select * from {{ ref('stg_olist__geolocation') }}
),

joined as (
    select
        c.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        g.latitude,
        g.longitude
    from customers c
    left join geolocation g
        on c.customer_zip_code_prefix = g.zip_code_prefix
)

select * from joined