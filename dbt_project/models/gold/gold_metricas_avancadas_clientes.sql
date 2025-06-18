-- Modelo Gold: Métricas Avançadas de Clientes
-- Demonstra capacidades analíticas avançadas do DBT

{{ config(
    materialized='table',
    tags=['gold', 'analytics', 'advanced'],
    post_hook="CREATE INDEX IF NOT EXISTS idx_gold_metricas_cliente_id ON {{ this }} (cliente_id)"
) }}

WITH base_clientes AS (
    SELECT 
        cliente_id,
        nome,
        email_original as email,
        data_cadastro,
        status,
        tipo_cliente,
        limite_credito
    FROM {{ ref('dim_clientes') }}
),

pedidos_agregados AS (
    SELECT 
        cliente_id,
        COUNT(*) as total_pedidos,
        SUM(valor_liquido) as receita_total,
        AVG(valor_liquido) as ticket_medio,
        MIN(data_pedido) as primeira_compra,
        MAX(data_pedido) as ultima_compra,
        
        -- Métricas temporais
        COUNT(CASE WHEN data_pedido >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as pedidos_30d,
        COUNT(CASE WHEN data_pedido >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) as pedidos_90d,
        COUNT(CASE WHEN data_pedido >= CURRENT_DATE - INTERVAL '365 days' THEN 1 END) as pedidos_12m,
        
        -- Receita por período
        SUM(CASE WHEN data_pedido >= CURRENT_DATE - INTERVAL '30 days' THEN valor_liquido ELSE 0 END) as receita_30d,
        SUM(CASE WHEN data_pedido >= CURRENT_DATE - INTERVAL '90 days' THEN valor_liquido ELSE 0 END) as receita_90d,
        SUM(CASE WHEN data_pedido >= CURRENT_DATE - INTERVAL '365 days' THEN valor_liquido ELSE 0 END) as receita_12m
        
    FROM {{ ref('fct_pedidos') }}
    GROUP BY cliente_id
),

metricas_comportamentais AS (
    SELECT 
        p.cliente_id,
        
        -- Frequência de compra
        CASE 
            WHEN pa.total_pedidos = 0 THEN 0
            ELSE EXTRACT(DAYS FROM (pa.ultima_compra - pa.primeira_compra)) / NULLIF(pa.total_pedidos - 1, 0)
        END as dias_entre_compras,
        
        -- Recência (dias desde última compra)
        EXTRACT(DAYS FROM (CURRENT_DATE - pa.ultima_compra)) as dias_desde_ultima_compra,
        
        -- Tendência de crescimento (comparando últimos 3 meses vs 3 meses anteriores)
        COALESCE(
            (SUM(CASE WHEN p.data_pedido >= CURRENT_DATE - INTERVAL '90 days' THEN p.valor_liquido ELSE 0 END) -
         SUM(CASE WHEN p.data_pedido >= CURRENT_DATE - INTERVAL '180 days' 
                   AND p.data_pedido < CURRENT_DATE - INTERVAL '90 days' 
                   THEN p.valor_liquido ELSE 0 END)) /
        NULLIF(SUM(CASE WHEN p.data_pedido >= CURRENT_DATE - INTERVAL '180 days' 
                        AND p.data_pedido < CURRENT_DATE - INTERVAL '90 days' 
                        THEN p.valor_liquido ELSE 0 END), 0), 0
        ) as tendencia_crescimento,
        
        -- Sazonalidade (mês com maior volume)
        MODE() WITHIN GROUP (ORDER BY EXTRACT(MONTH FROM p.data_pedido)) as mes_preferido
        
    FROM {{ ref('fct_pedidos') }} p
    INNER JOIN pedidos_agregados pa ON p.cliente_id = pa.cliente_id
    GROUP BY p.cliente_id, pa.total_pedidos, pa.primeira_compra, pa.ultima_compra
),

rfm_analysis AS (
    SELECT 
        pa.cliente_id,
        
        -- Recency Score (1-5, onde 5 é mais recente)
        CASE 
            WHEN dias_desde_ultima_compra <= 30 THEN 5
            WHEN dias_desde_ultima_compra <= 60 THEN 4
            WHEN dias_desde_ultima_compra <= 90 THEN 3
            WHEN dias_desde_ultima_compra <= 180 THEN 2
            ELSE 1
        END as recency_score,
        
        -- Frequency Score (baseado em quartis)
        NTILE(5) OVER (ORDER BY pa.total_pedidos) as frequency_score,
        
        -- Monetary Score (baseado em quartis)
        NTILE(5) OVER (ORDER BY pa.receita_total) as monetary_score
        
    FROM pedidos_agregados pa
    INNER JOIN metricas_comportamentais mc ON pa.cliente_id = mc.cliente_id
),

segmentacao_avancada AS (
    SELECT 
        rfm.*,
        
        -- Segmentação RFM
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score <= 2 THEN 'Potential Loyalists'
            WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'Big Spenders'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score >= 2 AND monetary_score <= 2 THEN 'Cannot Lose Them'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'Hibernating'
            ELSE 'Lost'
        END as segmento_rfm,
        
        -- Score RFM combinado
        (recency_score * 100) + (frequency_score * 10) + monetary_score as rfm_score
        
    FROM rfm_analysis rfm
),

metricas_finais AS (
    SELECT 
        bc.cliente_id,
        bc.nome,
        bc.email,
        bc.data_cadastro,
        bc.status,
        bc.tipo_cliente,
        bc.limite_credito,
        
        -- Métricas básicas
        COALESCE(pa.total_pedidos, 0) as total_pedidos,
        COALESCE(pa.receita_total, 0) as receita_total,
        COALESCE(pa.ticket_medio, 0) as ticket_medio,
        pa.primeira_compra,
        pa.ultima_compra,
        
        -- Métricas temporais
        COALESCE(pa.pedidos_30d, 0) as pedidos_30d,
        COALESCE(pa.pedidos_90d, 0) as pedidos_90d,
        COALESCE(pa.pedidos_12m, 0) as pedidos_12m,
        COALESCE(pa.receita_30d, 0) as receita_30d,
        COALESCE(pa.receita_90d, 0) as receita_90d,
        COALESCE(pa.receita_12m, 0) as receita_12m,
        
        -- Métricas comportamentais
        COALESCE(mc.dias_entre_compras, 0) as dias_entre_compras,
        COALESCE(mc.dias_desde_ultima_compra, 999) as dias_desde_ultima_compra,
        COALESCE(mc.tendencia_crescimento, 0) as tendencia_crescimento,
        mc.mes_preferido,
        
        -- RFM e Segmentação
        COALESCE(sa.recency_score, 1) as recency_score,
        COALESCE(sa.frequency_score, 1) as frequency_score,
        COALESCE(sa.monetary_score, 1) as monetary_score,
        COALESCE(sa.rfm_score, 111) as rfm_score,
        COALESCE(sa.segmento_rfm, 'Lost') as segmento_rfm,
        
        -- Customer Lifetime Value (CLV) estimado
        CASE 
            WHEN pa.total_pedidos > 0 AND mc.dias_entre_compras > 0 THEN
                (pa.ticket_medio * (365.0 / mc.dias_entre_compras) * 2) -- Estimativa para 2 anos
            ELSE 0
        END as clv_estimado,
        
        -- Flags de risco e oportunidade
        CASE 
            WHEN mc.dias_desde_ultima_compra > 180 THEN true 
            ELSE false 
        END as em_risco_churn,
        
        CASE 
            WHEN pa.receita_30d > pa.receita_90d / 3 * 1.5 THEN true 
            ELSE false 
        END as crescimento_acelerado,
        
        -- Classificação de valor
        {{ classify_customer_value('COALESCE(pa.receita_total, 0)') }} as categoria_valor,
        
        -- Auditoria
        {{ add_audit_columns() }}
        
    FROM base_clientes bc
    LEFT JOIN pedidos_agregados pa ON bc.cliente_id = pa.cliente_id
    LEFT JOIN metricas_comportamentais mc ON bc.cliente_id = mc.cliente_id
    LEFT JOIN segmentacao_avancada sa ON bc.cliente_id = sa.cliente_id
)

SELECT * FROM metricas_finais
ORDER BY receita_total DESC, total_pedidos DESC