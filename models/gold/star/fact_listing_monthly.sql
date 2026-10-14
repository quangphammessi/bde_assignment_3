/*
    Gold: fact table of the star schema
    Grain : one row per listing per month (listing_id, month_start)
    Source: silver.s_listings_monthly

    Contains only IDs and measures:
      IDs      listing_id      -> dim_listing
               host_id         -> dim_host
               lga_code        -> dim_lga     (LGA the listing is in)
               host_suburb_id  -> dim_suburb  (suburb the host lives in)
               month_start     the month of the observation
      measures price, availability_30, number_of_reviews, review scores

    Descriptive columns (property type, superhost flag, has_availability, ...)
    are NOT stored here. They live in the dimensions and are joined back in
    the datamart with the SCD2 validity range.

    lga_code and host_suburb_id are looked up from the names in the monthly
    row. The lookups use the dimension version valid in that month, so a
    dimension with several versions cannot duplicate fact rows. The dimensions
    are built from the snapshots, which is why they must exist before this
    model runs; ref() makes dbt build them first.
*/

with listings as (

    select * from {{ ref('s_listings_monthly') }}

)

select
    -- IDs
    listings.listing_id,
    listings.host_id,
    coalesce(lga.lga_code, 'unknown')           as lga_code,
    coalesce(suburb.suburb_id, 'unknown')       as host_suburb_id,
    listings.month_start,

    -- measures
    listings.price,
    listings.availability_30,
    listings.number_of_reviews,
    listings.review_scores_rating,
    listings.review_scores_accuracy,
    listings.review_scores_cleanliness,
    listings.review_scores_checkin,
    listings.review_scores_communication,
    listings.review_scores_value

from listings

-- listing_neighbourhood is an LGA name
left join {{ ref('dim_lga') }} as lga
       on lower(lga.lga_name) = lower(listings.listing_neighbourhood)
      and listings.month_start >= lga.valid_from
      and listings.month_start <  lga.valid_to

-- host_neighbourhood is a suburb name
left join {{ ref('dim_suburb') }} as suburb
       on suburb.suburb_key = upper(listings.host_neighbourhood)
      and listings.month_start >= suburb.valid_from
      and listings.month_start <  suburb.valid_to
