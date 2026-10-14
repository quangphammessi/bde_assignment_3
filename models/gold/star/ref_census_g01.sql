/*
    Gold: 2016 Census table G01 as reference data
    Grain : one row per NSW LGA
    Join  : lga_code = dim_lga.lga_code = fact_listing_monthly.lga_code

    Census 2016 is a single point in time, so there is no history to track
    and no snapshot.

    Caveat: three Census codes have no LGA name in the mapping file (16650,
    19399, 19799). 16650 has 109,404 residents and matches the former Rockdale
    council, which merged with Botany Bay into Bayside after the 2016 Census
    boundaries were drawn. The mapping file gives Bayside the code 11100,
    whose Census row covers the former Botany Bay area only (46,654
    residents). Census figures for Bayside are therefore partial.
*/

select * from {{ ref('s_census_g01') }}
