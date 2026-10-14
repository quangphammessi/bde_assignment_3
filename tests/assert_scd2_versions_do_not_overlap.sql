-- SCD2 integrity: for every key, each version must end exactly where the next
-- one starts (no gap, no overlap), the first must start at 1900-01-01 and the
-- last must end at 9999-12-31. Returns the versions that break the chain.

{% set dimensions = [
    ('dim_host',    'host_id'),
    ('dim_listing', 'listing_id'),
    ('dim_lga',     'lga_code'),
    ('dim_suburb',  'suburb_id')
] %}

{% for dimension, key in dimensions %}

select
    '{{ dimension }}'      as dimension_name,
    {{ key }}::text        as key_value,
    valid_from,
    valid_to,
    expected_valid_from
from (
    select
        {{ key }},
        valid_from,
        valid_to,
        coalesce(
            lag(valid_to) over (partition by {{ key }} order by valid_from),
            date '1900-01-01'
        )                                                                   as expected_valid_from,
        lead(valid_from) over (partition by {{ key }} order by valid_from)  as next_valid_from
    from {{ ref(dimension) }}
) as versions
where valid_from <> expected_valid_from
   or valid_from >= valid_to
   or (next_valid_from is null and valid_to <> date '9999-12-31')

{% if not loop.last %}union all{% endif %}

{% endfor %}
