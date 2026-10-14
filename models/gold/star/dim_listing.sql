/*
    Gold: listing dimension, Slowly Changing Dimension Type 2
    Grain : one row per version of a listing
    Source: silver.listing_snapshot

    Descriptive attributes of a listing, including has_availability, which
    decides whether the listing counts as "active" in a given month. The
    fact table holds only IDs and measures, so the datamart reads these
    attributes from the version that was valid in the month of the fact row:
        fact.month_start >= valid_from  and  fact.month_start < valid_to

    First version starts at 1900-01-01, current version ends at 9999-12-31
    (see dim_host.sql).
*/

select
    dbt_scd_id                                              as listing_version_id,
    listing_id,
    listing_neighbourhood,
    property_type,
    room_type,
    accommodates,
    has_availability,
    case
        when row_number() over (partition by listing_id order by dbt_valid_from) = 1
            then date '1900-01-01'
        else dbt_valid_from::date
    end                                                     as valid_from,
    coalesce(dbt_valid_to::date, date '9999-12-31')         as valid_to,
    dbt_valid_to is null                                    as is_current
from {{ ref('listing_snapshot') }}
