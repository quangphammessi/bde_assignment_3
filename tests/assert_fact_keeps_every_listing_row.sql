-- The fact table must have exactly as many rows as the cleaned listings.
-- A difference would mean the LGA / suburb lookups dropped or duplicated rows.

with counts as (

    select
        (select count(*) from {{ ref('s_listings_monthly') }})   as silver_rows,
        (select count(*) from {{ ref('fact_listing_monthly') }}) as fact_rows

)

select *
from counts
where silver_rows <> fact_rows
