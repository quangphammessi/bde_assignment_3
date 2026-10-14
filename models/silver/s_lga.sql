/*
    Silver: Local Government Areas (from NSW_LGA_CODE.csv)
    Grain : one row per LGA
    Feeds : snapshots/lga_snapshot.sql  ->  gold.dim_lga

    lga_code is the bare 5-digit code ('17200'), the same format the Census
    models are converted to. updated_at is the load time of the reference
    file: the file has no date of its own, and it is loaded only once.
*/

select
    trim(lga_code)                as lga_code,
    trim(lga_name)                as lga_name,
    ingested_at::timestamp        as updated_at
from {{ source('bronze', 'raw_lga_code') }}
