-- Every fact row must match exactly ONE version of each dimension when joined
-- with the SCD2 validity range. This is what allows the datamart views to use
-- inner joins without losing or duplicating rows.
-- Returns the fact rows with zero or several matches, per dimension.

{% set dimensions = [
    ('dim_host',    'host_id',    'host_id'),
    ('dim_listing', 'listing_id', 'listing_id'),
    ('dim_lga',     'lga_code',   'lga_code'),
    ('dim_suburb',  'suburb_id',  'host_suburb_id')
] %}

{% for dimension, dimension_key, fact_key in dimensions %}

select
    '{{ dimension }}'             as dimension_name,
    fact.listing_id,
    fact.month_start,
    count(dim.{{ dimension_key }}) as matching_versions
from {{ ref('fact_listing_monthly') }} as fact
left join {{ ref(dimension) }} as dim
       on dim.{{ dimension_key }} = fact.{{ fact_key }}
      and fact.month_start >= dim.valid_from
      and fact.month_start <  dim.valid_to
group by fact.listing_id, fact.month_start
having count(dim.{{ dimension_key }}) <> 1

{% if not loop.last %}union all{% endif %}

{% endfor %}
