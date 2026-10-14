/*
    Gold: host dimension, Slowly Changing Dimension Type 2
    Grain : one row per version of a host
    Source: silver.host_snapshot

    A row is valid for a fact when
        fact.month_start >= valid_from  and  fact.month_start < valid_to

    valid_from of a host's first version is moved back to 1900-01-01 and
    valid_to of the current version is 9999-12-31, so the versions of a host
    cover every possible date with no gap and no overlap. A fact row therefore
    always finds exactly one version (checked by tests/).
*/

select
    dbt_scd_id                                              as host_version_id,
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    host_neighbourhood,
    case
        when row_number() over (partition by host_id order by dbt_valid_from) = 1
            then date '1900-01-01'
        else dbt_valid_from::date
    end                                                     as valid_from,
    coalesce(dbt_valid_to::date, date '9999-12-31')         as valid_to,
    dbt_valid_to is null                                    as is_current
from {{ ref('host_snapshot') }}
