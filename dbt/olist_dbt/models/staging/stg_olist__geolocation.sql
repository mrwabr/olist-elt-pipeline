with source as (
    select * from {{ source('olist_raw', 'geolocation') }}
),
renamed as (
    select
        geolocation_zip_code_prefix as zip_code_prefix,
        geolocation_lat::float       as latitude,
        geolocation_lng::float       as longitude,
        geolocation_city,
        geolocation_state
    from source
),
deduped as (
    select
        zip_code_prefix,
        avg(latitude)  as latitude,
        avg(longitude) as longitude,
        max(geolocation_city)  as city,
        max(geolocation_state) as state
    from renamed
    group by zip_code_prefix
)
select * from deduped