with source as (
    select * from {{ source('olist_raw', 'payments') }}
),
renamed as (
    select
        order_id,
        payment_sequential::number    as payment_sequential,
        payment_type,
        payment_installments::number as payment_installments,
        payment_value::number(10,2)  as payment_value
    from source
)
select * from renamed