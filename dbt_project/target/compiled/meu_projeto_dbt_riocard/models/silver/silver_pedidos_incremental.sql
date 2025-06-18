-- Modelo Incremental Avançado para Pedidos
-- Demonstra capacidades de merge inteligente e detecção de mudanças



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
        
    MD5(CONCAT(
        
            COALESCE(status::text, ''),
            COALESCE(valor_liquido::text, ''),
            COALESCE(desconto::text, '')
    ))
 as row_hash,
        -- Adicionar colunas de auditoria
        
    CURRENT_TIMESTAMP as dbt_created_at,
    CURRENT_TIMESTAMP as dbt_updated_at,
    '7b0ac06c-66b2-40fc-80a9-d80ace88de6b' as dbt_run_id,
    'system' as dbt_created_by

    FROM "db_source"."public_bronze"."bronze_pedidos"
    
    
        -- Estratégia híbrida: novos registros + registros modificados
        WHERE updated_at > (SELECT MAX(updated_at) FROM "db_source"."public_silver"."silver_pedidos_incremental")
           OR id IN (
               -- Detectar registros que mudaram comparando hash
               SELECT DISTINCT b.id
               FROM "db_source"."public_bronze"."bronze_pedidos" b
               INNER JOIN "db_source"."public_silver"."silver_pedidos_incremental" t ON b.id = t.pedido_id
               WHERE 
    MD5(CONCAT(
        
            COALESCE(b.status::text, ''),
            COALESCE(b.valor_liquido::text, ''),
            COALESCE(b.desconto::text, '')
    ))
 != t.row_hash
           )
    
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
        
    CASE 
        WHEN valor_liquido >= 10000 THEN 'VIP'
        WHEN valor_liquido >= 5000 THEN 'Premium'
        WHEN valor_liquido >= 1000 THEN 'Regular'
        ELSE 'Básico'
    END
 as categoria_valor,
        
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