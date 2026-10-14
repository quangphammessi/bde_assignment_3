{#
    Snapshot (Silver layer): history of each host's attributes
    Source   : silver.s_host (current state, one row per host_id)
    Strategy : timestamp on updated_at
               updated_at = month the host's attributes last changed (see s_host.sql).
    Result   : silver.host_snapshot, one row per version, with dbt_valid_from and
               dbt_valid_to (NULL = current version). gold.dim_host is built on it.

    Run with "dbt build" (or "dbt snapshot") after EVERY monthly load. A
    snapshot can only record the state it sees when it runs, so a month that
    is loaded but never snapshotted leaves no history behind.
#}

{% snapshot host_snapshot %}

{{
    config(
        target_schema='silver',
        unique_key='host_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select * from {{ ref('s_host') }}

{% endsnapshot %}
