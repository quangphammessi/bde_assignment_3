-- History check. The attributes obtained through the SCD2 joins must equal the
-- attributes that were in that month's file. This proves that the snapshots
-- captured every month correctly.
--
-- It can only pass if "dbt build" ran after each monthly load. If several
-- months were loaded before dbt ran, the months in between were never
-- snapshotted and show up here. Severity is "warn" so the rest of the build
-- still completes and the problem is visible in the run summary.

{{ config(severity='warn') }}

select
    monthly.listing_id,
    monthly.month_start
from {{ ref('s_listings_monthly') }} as monthly

inner join {{ ref('dim_listing') }} as listing
        on listing.listing_id = monthly.listing_id
       and monthly.month_start >= listing.valid_from
       and monthly.month_start <  listing.valid_to

inner join {{ ref('dim_host') }} as host
        on host.host_id = monthly.host_id
       and monthly.month_start >= host.valid_from
       and monthly.month_start <  host.valid_to

where (listing.listing_neighbourhood, listing.property_type, listing.room_type,
       listing.accommodates, listing.has_availability)
      is distinct from
      (monthly.listing_neighbourhood, monthly.property_type, monthly.room_type,
       monthly.accommodates, monthly.has_availability)
   or (host.host_name, host.host_since, host.host_is_superhost, host.host_neighbourhood)
      is distinct from
      (monthly.host_name, monthly.host_since, monthly.host_is_superhost, monthly.host_neighbourhood)
