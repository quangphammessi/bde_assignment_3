# BDE Assignment 3 - dbt project

Sydney Airbnb + 2016 Census warehouse on Postgres, Medallion architecture.

## Layers

| Layer | Schema | Built by | Contents |
|---|---|---|---|
| Bronze | `bronze` | Airflow DAG `bde_a3_bronze_load` | `raw_listings`, `raw_census_g01`, `raw_census_g02`, `raw_lga_code`, `raw_lga_suburb` |
| Silver | `silver` | dbt models + snapshots | `s_listings_monthly`, `s_host`, `s_listing`, `s_lga`, `s_suburb`, `s_census_g01`, `s_census_g02`, and the snapshots `host_snapshot`, `listing_snapshot`, `lga_snapshot`, `suburb_snapshot` |
| Gold (star) | `gold` | dbt models | `dim_host`, `dim_listing`, `dim_lga`, `dim_suburb`, `fact_listing_monthly`, `ref_census_g01`, `ref_census_g02` |
| Gold (datamart) | `gold` | dbt views | `dm_listing_neighbourhood`, `dm_property_type`, `dm_host_neighbourhood` |

## How to run

One command does everything in the right order (Silver models, snapshots,
dimensions, fact, datamart views, tests):

    dbt build

Run it **after every monthly Airflow load**, before the next month is loaded:

    load 05_2020 -> dbt build -> load 06_2020 -> dbt build -> ... -> load 04_2021 -> dbt build

The snapshots record the state of hosts and listings at the moment dbt runs.
If two months are loaded before dbt runs, the first of them is never
snapshotted. The test `assert_scd2_join_reproduces_each_month` then reports a
warning with the number of affected rows.

`dbt build --full-refresh` rebuilds every table model. It does not reset the
snapshots; to start again from scratch drop the `silver` and `gold` schemas,
truncate the Bronze tables and reload month by month.

## Folder guide

    dbt_project.yml                 layer -> schema / materialisation settings
    macros/generate_schema_name.sql use schema names exactly as configured
    models/bronze/sources.yml       Bronze tables declared as dbt sources
    models/silver/                  cleaning, typing, entity decomposition
    snapshots/                      timestamp-strategy snapshots (SCD2 history)
    models/gold/star/               dimensions, fact, census reference tables
    models/gold/mart/               the three datamart views
    tests/                          SQL tests for grain and SCD2 integrity
