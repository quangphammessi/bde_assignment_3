{#
    Use the custom schema name exactly as configured (silver, gold).

    dbt's default is <target schema>_<custom schema>, e.g. dbt_luke_silver.
    The assignment needs fixed layer names, in development and in the
    deployment job alike, so the prefix is removed. Models without a custom
    schema still go to the target schema.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
