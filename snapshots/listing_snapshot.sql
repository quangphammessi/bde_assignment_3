{#
    Snapshot (Silver layer): history of each listing's attributes
    Source   : silver.s_listing (current state, one row per listing_id)
    Strategy : timestamp on updated_at
               updated_at = month the listing's attributes last changed (see s_listing.sql).
    Result   : silver.listing_snapshot, one row per version, with dbt_valid_from and
               dbt_valid_to (NULL = current version). gold.dim_listing is built on it.

    Run with "dbt build" (or "dbt snapshot") after EVERY monthly load. A
    snapshot can only record the state it sees when it runs, so a month that
    is loaded but never snapshotted leaves no history behind.
#}

{% snapshot listing_snapshot %}

{{
    config(
        target_schema='silver',
        unique_key='listing_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select * from {{ ref('s_listing') }}

{% endsnapshot %}
