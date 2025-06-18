-- Snapshot para Slowly Changing Dimensions (SCD Type 2)
-- Mantém histórico completo de mudanças nos dados de clientes

{% snapshot clientes_snapshot %}
    {{
        config(
          target_schema='snapshots',
          unique_key='id',
          strategy='timestamp',
          updated_at='updated_at',
          invalidate_hard_deletes=True,
          tags=['snapshot', 'scd2', 'clientes']
        )
    }}
    
    SELECT 
        id,
        nome,
        email,
        telefone,
        cpf,
        data_nascimento,
        endereco,
        status,
        tipo_cliente,
        limite_credito,
        data_cadastro,
        updated_at,
        
        -- Campos adicionais para análise histórica
        {{ standardize_email('email') }} as email_padronizado,
        {{ extract_email_domain('email') }} as dominio_email,
        {{ validate_cpf('cpf') }} as cpf_valido,
        
        -- Categorização temporal
        {{ categorize_by_date('data_cadastro') }} as categoria_cadastro
        
    FROM {{ source('raw_data', 'clientes') }}
    
{% endsnapshot %}

-- Este snapshot permite:
-- 1. Rastrear mudanças históricas em dados de clientes
-- 2. Análises temporais (como cliente estava em determinada data)
-- 3. Auditoria de mudanças de dados
-- 4. Recuperação de dados deletados (se invalidate_hard_deletes=True)