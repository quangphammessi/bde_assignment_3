/*
    Gold: suburb dimension, Slowly Changing Dimension Type 2
    Grain : one row per version of a suburb, plus one 'unknown' member
    Source: silver.suburb_snapshot

    Maps a suburb to its LGA. The fact table points here with host_suburb_id
    (the suburb the host lives in), which is how host_neighbourhood becomes
    host_neighbourhood_lga in dm_host_neighbourhood.

    The 'unknown' member receives hosts whose neighbourhood is blank (37% of
    rows) or is not a NSW suburb (the value 'Overseas').
*/

select
    dbt_scd_id                                              as suburb_version_id,
    suburb_id,
    suburb_key,
    suburb_name,
    lga_code,
    lga_name,
    case
        when row_number() over (partition by suburb_id order by dbt_valid_from) = 1
            then date '1900-01-01'
        else dbt_valid_from::date
    end                                                     as valid_from,
    coalesce(dbt_valid_to::date, date '9999-12-31')         as valid_to,
    dbt_valid_to is null                                    as is_current
from {{ ref('suburb_snapshot') }}

union all

select
    'unknown'             as suburb_version_id,
    'unknown'             as suburb_id,
    'UNKNOWN'             as suburb_key,
    'Unknown'             as suburb_name,
    'unknown'             as lga_code,
    'Unknown'             as lga_name,
    date '1900-01-01'     as valid_from,
    date '9999-12-31'     as valid_to,
    true                  as is_current
