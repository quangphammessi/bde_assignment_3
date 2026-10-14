/*
    Datamart: dm_listing_neighbourhood
    Grain   : one row per listing_neighbourhood and month/year
    Type    : view on fact_listing_monthly joined to its dimensions

    listing_neighbourhood is the name of the LGA the listing is in (dim_lga).

    SCD2 joins
      Every dimension is joined on its key AND on the validity range
          fact.month_start >= dim.valid_from and fact.month_start < dim.valid_to
      so each fact row gets the dimension values that were true in that month,
      not today's values. The joins are inner joins: tests/ proves that every
      fact row matches exactly one version, so no row is lost or duplicated.

    Definitions (from the brief)
      active listing          has_availability = 't'
      active listings rate    active listings / total listings * 100
      superhost rate          distinct superhosts / distinct hosts * 100
      percentage change       (this month - previous month) / previous month * 100
      number of stays         30 - availability_30, active listings only
      estimated revenue       number of stays * price, active listings only

    Percentage change is NULL in the first month, when the group has no row in
    the previous calendar month, and when the previous value is 0.
*/

with listing_month as (

    select
        fact.month_start,
        lga.lga_name                       as listing_neighbourhood,
        fact.listing_id,
        fact.host_id,
        listing.has_availability           as is_active,
        host.host_is_superhost             as is_superhost,
        fact.price,
        fact.review_scores_rating,
        30 - fact.availability_30          as number_of_stays,
        (30 - fact.availability_30) * fact.price
                                           as estimated_revenue
    from {{ ref('fact_listing_monthly') }} as fact

    -- listing attributes as they were in that month (active or not, type, ...)
    inner join {{ ref('dim_listing') }} as listing
            on listing.listing_id = fact.listing_id
           and fact.month_start >= listing.valid_from
           and fact.month_start <  listing.valid_to

    -- host attributes as they were in that month (superhost or not)
    inner join {{ ref('dim_host') }} as host
            on host.host_id = fact.host_id
           and fact.month_start >= host.valid_from
           and fact.month_start <  host.valid_to

    -- LGA of the listing: gives listing_neighbourhood
    inner join {{ ref('dim_lga') }} as lga
            on lga.lga_code = fact.lga_code
           and fact.month_start >= lga.valid_from
           and fact.month_start <  lga.valid_to

),

monthly as (

    select
        listing_neighbourhood,
        month_start,
        count(*)                                                          as total_listings,
        count(*) filter (where is_active)                                 as active_listings,
        count(*) filter (where not is_active)                             as inactive_listings,
        min(price) filter (where is_active)                               as min_price,
        max(price) filter (where is_active)                               as max_price,
        percentile_cont(0.5) within group (order by price)
            filter (where is_active)                                      as median_price,
        avg(price) filter (where is_active)                               as avg_price,
        count(distinct host_id)                                           as distinct_hosts,
        count(distinct host_id) filter (where is_superhost)               as distinct_superhosts,
        avg(review_scores_rating) filter (where is_active)                as avg_review_scores_rating,
        sum(number_of_stays) filter (where is_active)                     as total_stays,
        sum(estimated_revenue) filter (where is_active)                   as total_estimated_revenue
    from listing_month
    group by listing_neighbourhood, month_start

),

with_previous_month as (

    -- Self-join on the previous calendar month. Unlike lag(), this cannot
    -- compare two months that are not next to each other.
    select
        monthly.*,
        previous.active_listings      as previous_active_listings,
        previous.inactive_listings    as previous_inactive_listings
    from monthly
    left join monthly as previous
           on  previous.listing_neighbourhood = monthly.listing_neighbourhood
           and previous.month_start = (monthly.month_start - interval '1 month')::date

)

select
    listing_neighbourhood,
    month_start                                                           as month_year,
    round(100.0 * active_listings / total_listings, 2)                    as active_listings_rate,
    min_price,
    max_price,
    round(median_price::numeric, 2)                                       as median_price,
    round(avg_price, 2)                                                   as avg_price,
    distinct_hosts,
    round(100.0 * distinct_superhosts / distinct_hosts, 2)                as superhost_rate,
    round(avg_review_scores_rating, 2)                                    as avg_review_scores_rating,
    round(100.0 * (active_listings - previous_active_listings)
          / nullif(previous_active_listings, 0), 2)                       as pct_change_active_listings,
    round(100.0 * (inactive_listings - previous_inactive_listings)
          / nullif(previous_inactive_listings, 0), 2)                     as pct_change_inactive_listings,
    total_stays,
    round(total_estimated_revenue / nullif(active_listings, 0), 2)        as avg_estimated_revenue_per_active_listing,
    -- supporting counts, so every rate above can be checked by hand
    total_listings,
    active_listings,
    inactive_listings
from with_previous_month
order by listing_neighbourhood, month_start
