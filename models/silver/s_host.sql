/*
    Silver: host entity (decomposed from the listings table)
    Grain : one row per host = the host's most recent state
    Feeds : snapshots/host_snapshot.sql  ->  gold.dim_host

    updated_at, the snapshot timestamp
      dbt's timestamp strategy opens a new version of a host every time
      updated_at moves forward, whether or not anything changed. If updated_at
      were simply "the latest month", every host would get twelve identical
      versions. Instead updated_at is the first month of the host's current
      run of unchanged attributes, i.e. the month the host last changed:

        month      superhost   changed?   run   updated_at of the latest row
        2020-05    f           yes        1
        2020-06    f           no         1
        2020-07    t           yes        2     2020-07-01
        2020-08    t           no         2     2020-07-01  (no new version)

      It is built from month_start (the file's month), not from scraped_date,
      because of the wrong scrape dates in 07_2020.csv.
*/

with host_month as (

    -- A host appears once per listing; keep one row per host per month.
    -- (Within a month a host's attributes are identical on all its listings.)
    select distinct on (host_id, month_start)
        host_id,
        month_start,
        host_name,
        host_since,
        host_is_superhost,
        host_neighbourhood
    from {{ ref('s_listings_monthly') }}
    order by host_id, month_start, listing_id

),

fingerprinted as (

    -- One value that changes whenever any tracked attribute changes.
    select
        *,
        md5(concat_ws('|',
            coalesce(host_name, '<null>'),
            coalesce(host_since::text, '<null>'),
            coalesce(host_is_superhost::text, '<null>'),
            coalesce(host_neighbourhood, '<null>')
        )) as attribute_hash
    from host_month

),

change_flagged as (

    select
        *,
        case
            when attribute_hash is distinct from
                 lag(attribute_hash) over (partition by host_id order by month_start)
            then 1 else 0
        end as is_change
    from fingerprinted

),

runs as (

    -- Running count of changes = number of the run of unchanged months.
    select
        *,
        sum(is_change) over (partition by host_id order by month_start) as run_number
    from change_flagged

),

latest as (

    select
        *,
        min(month_start) over (partition by host_id, run_number)             as run_start,
        row_number() over (partition by host_id order by month_start desc)   as recency
    from runs

)

select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    host_neighbourhood,
    run_start::timestamp as updated_at
from latest
where recency = 1
