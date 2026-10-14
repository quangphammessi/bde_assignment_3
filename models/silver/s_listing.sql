/*
    Silver: listing entity (decomposed from the listings table)
    Grain : one row per listing = the listing's most recent state
    Feeds : snapshots/listing_snapshot.sql  ->  gold.dim_listing

    Holds the descriptive attributes of a listing. They do change over time:
    Airbnb renamed its property types during the period ("Apartment" became
    "Entire apartment"), and listings switch availability on and off.

    updated_at is the first month of the listing's current run of unchanged
    attributes (see s_host.sql for the reasoning and a worked example).
*/

with listing_month as (

    select
        listing_id,
        month_start,
        listing_neighbourhood,
        property_type,
        room_type,
        accommodates,
        has_availability
    from {{ ref('s_listings_monthly') }}

),

fingerprinted as (

    -- One value that changes whenever any tracked attribute changes.
    select
        *,
        md5(concat_ws('|',
            coalesce(listing_neighbourhood, '<null>'),
            coalesce(property_type, '<null>'),
            coalesce(room_type, '<null>'),
            coalesce(accommodates::text, '<null>'),
            coalesce(has_availability::text, '<null>')
        )) as attribute_hash
    from listing_month

),

change_flagged as (

    select
        *,
        case
            when attribute_hash is distinct from
                 lag(attribute_hash) over (partition by listing_id order by month_start)
            then 1 else 0
        end as is_change
    from fingerprinted

),

runs as (

    -- Running count of changes = number of the run of unchanged months.
    select
        *,
        sum(is_change) over (partition by listing_id order by month_start) as run_number
    from change_flagged

),

latest as (

    select
        *,
        min(month_start) over (partition by listing_id, run_number)             as run_start,
        row_number() over (partition by listing_id order by month_start desc)   as recency
    from runs

)

select
    listing_id,
    listing_neighbourhood,
    property_type,
    room_type,
    accommodates,
    has_availability,
    run_start::timestamp as updated_at
from latest
where recency = 1
