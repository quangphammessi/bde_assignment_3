/*
    Datamart: dm_host_neighbourhood
    Grain   : one row per host_neighbourhood_lga and month/year
    Type    : view on fact_listing_monthly joined to its dimensions

    host_neighbourhood_lga is the LGA of the suburb the host lives in:
        host_neighbourhood (suburb name) -> dim_suburb -> lga_name
    Hosts with a blank neighbourhood, or one that is not a NSW suburb
    ('Overseas'), fall under 'Unknown'. They are kept, not dropped, so the
    totals of this view agree with the other two.

    SCD2 joins
      Every dimension is joined on its key AND on the validity range
          fact.month_start >= dim.valid_from and fact.month_start < dim.valid_to
      so each fact row gets the dimension values that were true in that month.

    Definitions (from the brief)
      active listing                has_availability = 't'
      number of stays               30 - availability_30, active listings only
      estimated revenue             number of stays * price, active listings only
      estimated revenue per host    total estimated revenue / distinct hosts
*/

with listing_month as (

    select
        fact.month_start,
        suburb.lga_name                        as host_neighbourhood_lga,
        fact.listing_id,
        fact.host_id,
        listing.has_availability               as is_active,
        (30 - fact.availability_30) * fact.price
                                               as estimated_revenue
    from {{ ref('fact_listing_monthly') }} as fact

    -- suburb of the host -> LGA of the host
    inner join {{ ref('dim_suburb') }} as suburb
            on suburb.suburb_id = fact.host_suburb_id
           and fact.month_start >= suburb.valid_from
           and fact.month_start <  suburb.valid_to

    -- listing attributes as they were in that month (active or not)
    inner join {{ ref('dim_listing') }} as listing
            on listing.listing_id = fact.listing_id
           and fact.month_start >= listing.valid_from
           and fact.month_start <  listing.valid_to

),

monthly as (

    select
        host_neighbourhood_lga,
        month_start,
        count(distinct host_id)                                       as distinct_hosts,
        count(*) filter (where is_active)                             as active_listings,
        coalesce(sum(estimated_revenue) filter (where is_active), 0)  as total_estimated_revenue
    from listing_month
    group by host_neighbourhood_lga, month_start

)

select
    host_neighbourhood_lga,
    month_start                                                           as month_year,
    distinct_hosts,
    round(total_estimated_revenue / nullif(active_listings, 0), 2)        as avg_estimated_revenue_per_active_listing,
    round(total_estimated_revenue / distinct_hosts, 2)                    as estimated_revenue_per_host,
    -- supporting totals, so both ratios above can be checked by hand
    total_estimated_revenue,
    active_listings
from monthly
order by host_neighbourhood_lga, month_start
