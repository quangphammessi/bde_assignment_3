{#
    Snapshot (Silver layer): history of each suburb's LGA
    Source   : silver.s_suburb (current state, one row per suburb_id)
    Strategy : timestamp on updated_at
               updated_at = load time of the suburb reference file (ingested_at in Bronze).
    Result   : silver.suburb_snapshot, one row per version, with dbt_valid_from and
               dbt_valid_to (NULL = current version). gold.dim_suburb is built on it.

    Run with "dbt build" (or "dbt snapshot") after EVERY monthly load. A
    snapshot can only record the state it sees when it runs, so a month that
    is loaded but never snapshotted leaves no history behind.
#}

{% snapshot suburb_snapshot %}

{{
    config(
        target_schema='silver',
        unique_key='suburb_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select * from {{ ref('s_suburb') }}

{% endsnapshot %}
