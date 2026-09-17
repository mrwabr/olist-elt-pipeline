 {#
    Force le nom de schéma défini dans dbt_project.yml (staging / analytics)
    au lieu du comportement par défaut dbt (<schema_cible>_<custom_schema>).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}