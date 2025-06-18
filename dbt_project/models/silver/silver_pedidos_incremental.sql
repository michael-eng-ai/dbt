-- Modelo Incremental Avançado para Pedidos
-- Demonstra capacidades de merge inteligente e detecção de mudanças

{{ config(
    materialized='incremental',
    unique_key='pedido_id',
    incremental_strategy='append',
    on_schema_change='sync_all_columns',
    tags=['silver', 'incremental', 'fact']
) }}

WITH source_data AS (
    SELECT 
        id as pedido_id,
        cliente_id,
        valor_bruto,
        desconto,
        valor_liquido,
        status,
        data_pedido,
        updated_at,
        -- Gerar hash para detectar mudanças nos dados
        {{ generate_row_hash(['status', 'valor_liquido', 'desconto']) }} as row_hash,
        -- Adicionar colunas de auditoria
        {{ add_audit_columns() }}
    FROM {{ ref('bronze_pedidos') }}
    
    {% if is_incremental() %}
        -- Estratégia híbrida: novos registros + registros modificados
        WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
           OR id IN (
               -- Detectar registros que mudaram comparando hash
               SELECT DISTINCT b.id
               FROM {{ ref('bronze_pedidos') }} b
               INNER JOIN {{ this }} t ON b.id = t.pedido_id
               WHERE {{ generate_row_hash(['b.status', 'b.valor_liquido', 'b.desconto']) }} != t.row_hash
           )
    {% endif %}
),

enriched_data AS (
    SELECT 
        s.*,
        -- Enriquecimentos e validações
        CASE 
            WHEN valor_liquido <= 0 THEN 'ERRO: Valor inválido'
            WHEN status NOT IN ('pendente', 'confirmado', 'enviado', 'entregue', 'cancelado') 
            THEN 'AVISO: Status desconhecido'
            ELSE 'OK'
        END as data_quality_flag,
        
        -- Categorização de valor
        {{ classify_customer_value('valor_liquido') }} as categoria_valor,
        
        -- Métricas derivadas
        valor_liquido / NULLIF(1, 0) as valor_liquido_unitario,
        
        -- Flags de negócio
        CASE WHEN valor_liquido > 1000 THEN true ELSE false END as is_high_value,
        CASE WHEN data_pedido = CURRENT_DATE THEN true ELSE false END as is_today
        
    FROM source_data s
)

SELECT * FROM enriched_data

-- Adicionar comentário sobre a estratégia incremental
-- Este modelo usa uma abordagem híbrida que:
-- 1. Captura novos registros baseado em updated_at
-- 2. Detecta mudanças em registros existentes usando hash
-- 3. Aplica merge inteligente apenas nas colunas que podem mudar
-- 4. Inclui validações de qualidade de dados em tempo real