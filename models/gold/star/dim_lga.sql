/*
    Gold: Local Government Area dimension, Slowly Changing Dimension Type 2
    Grain : one row per version of an LGA, plus one 'unknown' member
    Source: silver.lga_snapshot

    lga_code is the key shared with the fact table and with the two Census
    reference tables. The reference file was loaded after the Airbnb period,
    so the first version must start at 1900-01-01 for 2020-21 facts to find it.

    The 'unknown' member lets the fact table keep a non-null lga_code even if
    a listing_neighbourhood ever fails to match an LGA name.
*/

select
    dbt_scd_id                                              as lga_version_id,
    lga_code,
    lga_name,
    case
        when row_number() over (partition by lga_code order by dbt_valid_from) = 1
            then date '1900-01-01'
        else dbt_valid_from::date
    end                                                     as valid_from,
    coalesce(dbt_valid_to::date, date '9999-12-31')         as valid_to,
    dbt_valid_to is null                                    as is_current
from {{ ref('lga_snapshot') }}

union all

select
    'unknown'             as lga_version_id,
    'unknown'             as lga_code,
    'Unknown'             as lga_name,
    date '1900-01-01'     as valid_from,
    date '9999-12-31'     as valid_to,
    true                  as is_current
