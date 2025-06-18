-- Macros para Governança de Dados
-- Este arquivo contém macros úteis para implementar governança e qualidade de dados

-- Macro para adicionar colunas de auditoria automáticas
{% macro add_audit_columns() %}
    CURRENT_TIMESTAMP as dbt_created_at,
    CURRENT_TIMESTAMP as dbt_updated_at,
    '{{ invocation_id }}' as dbt_run_id,
    '{{ var("dbt_user", "system") }}' as dbt_created_by
{% endmacro %}

-- Macro para limpeza de texto
{% macro clean_text(column_name) %}
    TRIM(UPPER(REGEXP_REPLACE({{ column_name }}, '[^a-zA-Z0-9\s]', '', 'g')))
{% endmacro %}

-- Macro para padronização de email
{% macro standardize_email(email_column) %}
    LOWER(TRIM({{ email_column }}))
{% endmacro %}

-- Macro para cálculo de Customer Lifetime Value
{% macro calculate_clv(customer_id_col, revenue_col, period_months=12) %}
    SUM(CASE 
        WHEN DATE_PART('month', AGE(CURRENT_DATE, data_pedido)) <= {{ period_months }}
        THEN {{ revenue_col }}
        ELSE 0 
    END)
{% endmacro %}

-- Macro para classificação de clientes por valor
{% macro classify_customer_value(revenue_column) %}
    CASE 
        WHEN {{ revenue_column }} >= 10000 THEN 'VIP'
        WHEN {{ revenue_column }} >= 5000 THEN 'Premium'
        WHEN {{ revenue_column }} >= 1000 THEN 'Regular'
        ELSE 'Básico'
    END
{% endmacro %}

-- Macro para detectar outliers usando IQR
{% macro detect_outliers(column_name, table_ref) %}
    WITH quartiles AS (
        SELECT 
            PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY {{ column_name }}) as q1,
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY {{ column_name }}) as q3
        FROM {{ table_ref }}
    ),
    iqr_bounds AS (
        SELECT 
            q1,
            q3,
            q3 - q1 as iqr,
            q1 - 1.5 * (q3 - q1) as lower_bound,
            q3 + 1.5 * (q3 - q1) as upper_bound
        FROM quartiles
    )
    SELECT *
    FROM {{ table_ref }}
    CROSS JOIN iqr_bounds
    WHERE {{ column_name }} < lower_bound 
       OR {{ column_name }} > upper_bound
{% endmacro %}

-- Macro para gerar hash de linha para detectar mudanças
{% macro generate_row_hash(columns) %}
    MD5(CONCAT(
        {% for column in columns %}
            COALESCE({{ column }}::text, '')
            {%- if not loop.last -%},{%- endif -%}
        {% endfor %}
    ))
{% endmacro %}

-- Macro para validação de CPF (formato brasileiro)
{% macro validate_cpf(cpf_column) %}
    CASE 
        WHEN LENGTH(REGEXP_REPLACE({{ cpf_column }}, '[^0-9]', '', 'g')) = 11
        THEN true
        ELSE false
    END
{% endmacro %}

-- Macro para extrair domínio de email
{% macro extract_email_domain(email_column) %}
    SPLIT_PART({{ email_column }}, '@', 2)
{% endmacro %}

-- Macro para categorização temporal
{% macro categorize_by_date(date_column, reference_date='CURRENT_DATE') %}
    CASE 
        WHEN {{ date_column }} >= {{ reference_date }} - INTERVAL '30 days' THEN 'Recente'
        WHEN {{ date_column }} >= {{ reference_date }} - INTERVAL '90 days' THEN 'Médio'
        WHEN {{ date_column }} >= {{ reference_date }} - INTERVAL '365 days' THEN 'Antigo'
        ELSE 'Muito Antigo'
    END
{% endmacro %}