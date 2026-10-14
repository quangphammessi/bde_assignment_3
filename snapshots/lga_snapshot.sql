{#
    Snapshot (Silver layer): history of each LGA's name
    Source   : silver.s_lga (current state, one row per lga_code)
    Strategy : timestamp on updated_at
               updated_at = load time of the LGA reference file (ingested_at in Bronze).
    Result   : silver.lga_snapshot, one row per version, with dbt_valid_from and
               dbt_valid_to (NULL = current version). gold.dim_lga is built on it.

    Run with "dbt build" (or "dbt snapshot") after EVERY monthly load. A
    snapshot can only record the state it sees when it runs, so a month that
    is loaded but never snapshotted leaves no history behind.
#}

{% snapshot lga_snapshot %}

{{
    config(
        target_schema='silver',
        unique_key='lga_code',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select * from {{ ref('s_lga') }}

{% endsnapshot %}
