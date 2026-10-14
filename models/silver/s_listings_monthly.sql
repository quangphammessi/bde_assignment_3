/*
    Silver: cleaned Airbnb listings
    Grain : one row per listing per month (listing_id, month_start)

    Bronze keeps every column as text. This model
      - casts each column to its proper type,
      - trims text and turns empty strings into NULL,
      - converts the 't' / 'f' flags to booleans,
      - parses host_since, which arrives as d/m/yyyy,
      - fixes the listing date problem described below.

    Listing dates
      The reporting period of a row is the month of the file it came from
      (source_file = 'MM_YYYY.csv'), exposed here as month_start (first day of
      that month). scraped_date cannot be used for this: 07_2020.csv holds
      4,780 rows scraped "2020-09-05", later than every row of 08_2020.csv.
      scraped_date is kept when it falls inside the file's month and set to
      NULL otherwise, because the real day is unknown.
*/

with source as (

    select * from {{ source('bronze', 'raw_listings') }}

),

typed as (

    select
        -- keys
        listing_id::bigint                                       as listing_id,
        host_id::bigint                                          as host_id,

        -- period of the row, from the file name ('05_2020.csv' -> 2020-05-01)
        to_date(left(source_file, 7), 'MM_YYYY')                 as month_start,
        scraped_date::date                                       as scraped_date_raw,

        -- host attributes
        nullif(trim(host_name), '')                              as host_name,
        to_date(nullif(trim(host_since), ''), 'DD/MM/YYYY')      as host_since,
        case trim(host_is_superhost)
            when 't' then true
            when 'f' then false
        end                                                      as host_is_superhost,
        nullif(trim(host_neighbourhood), '')                     as host_neighbourhood,

        -- listing attributes
        nullif(trim(listing_neighbourhood), '')                  as listing_neighbourhood,
        nullif(trim(property_type), '')                          as property_type,
        nullif(trim(room_type), '')                              as room_type,
        accommodates::integer                                    as accommodates,
        case trim(has_availability)
            when 't' then true
            when 'f' then false
        end                                                      as has_availability,

        -- measures
        price::numeric(10, 2)                                    as price,
        availability_30::integer                                 as availability_30,
        number_of_reviews::integer                               as number_of_reviews,
        review_scores_rating::numeric(5, 2)                      as review_scores_rating,
        review_scores_accuracy::numeric(5, 2)                    as review_scores_accuracy,
        review_scores_cleanliness::numeric(5, 2)                 as review_scores_cleanliness,
        review_scores_checkin::numeric(5, 2)                     as review_scores_checkin,
        review_scores_communication::numeric(5, 2)               as review_scores_communication,
        review_scores_value::numeric(5, 2)                       as review_scores_value,

        -- lineage
        source_file,
        ingested_at

    from source

)

select
    listing_id,
    host_id,
    month_start,
    case
        when date_trunc('month', scraped_date_raw)::date = month_start then scraped_date_raw
    end                                                          as scraped_date,
    host_name,
    host_since,
    host_is_superhost,
    host_neighbourhood,
    listing_neighbourhood,
    property_type,
    room_type,
    accommodates,
    has_availability,
    price,
    availability_30,
    number_of_reviews,
    review_scores_rating,
    review_scores_accuracy,
    review_scores_cleanliness,
    review_scores_checkin,
    review_scores_communication,
    review_scores_value,
    source_file,
    ingested_at
from typed
