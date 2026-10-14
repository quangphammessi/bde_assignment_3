/*
    Silver: suburbs and the LGA each one belongs to (from NSW_LGA_SUBURB.csv)
    Grain : one row per suburb
    Feeds : snapshots/suburb_snapshot.sql  ->  gold.dim_suburb

    Fixes the LGA / suburb naming issues:
      - the file is UPPER CASE while Airbnb uses Title Case, so suburb_key
        (upper case, trimmed) is the value to join on and suburb_name is a
        display version;
      - the file has no LGA code, so it is looked up from s_lga by name,
        ignoring case. One name has no code ('GUNDAGAI', which the code file
        calls something else); its lga_code stays NULL.
      - suburb_id is a stable surrogate key (md5 of suburb_key), because the
        source has no suburb identifier.
*/

with suburb as (

    select
        upper(trim(suburb_name))  as suburb_key,
        upper(trim(lga_name))     as lga_key,
        ingested_at
    from {{ source('bronze', 'raw_lga_suburb') }}

)

select
    md5(suburb.suburb_key)                                as suburb_id,
    suburb.suburb_key,
    initcap(suburb.suburb_key)                            as suburb_name,
    lga.lga_code,
    coalesce(lga.lga_name, initcap(suburb.lga_key))       as lga_name,
    suburb.ingested_at::timestamp                         as updated_at
from suburb
left join {{ ref('s_lga') }} as lga
       on upper(lga.lga_name) = suburb.lga_key
