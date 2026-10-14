-- A listing must appear at most once per month in Silver (and so in the fact).
-- Returns the offending keys; the test passes when no row is returned.

select
    listing_id,
    month_start,
    count(*) as row_count
from {{ ref('s_listings_monthly') }}
group by listing_id, month_start
having count(*) > 1
