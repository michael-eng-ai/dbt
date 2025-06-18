-- Modelo Gold: Análise de Coorte
-- Demonstra análise de retenção de clientes por coorte de aquisição

{{ config(
    materialized='table',
    tags=['gold', 'analytics', 'cohort', 'retention'],
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_coorte_mes_aquisicao ON {{ this }} (mes_aquisicao)",
        "CREATE INDEX IF NOT EXISTS idx_coorte_periodo ON {{ this }} (periodo_desde_aquisicao)"
    ]
) }}

WITH clientes_primeira_compra AS (
    SELECT 
        cliente_id,
        MIN(data_pedido) as primeira_compra,
        DATE_TRUNC('month', MIN(data_pedido)) as mes_aquisicao
    FROM {{ ref('fct_pedidos') }}
    GROUP BY cliente_id
),

atividade_mensal AS (
    SELECT 
        p.cliente_id,
        DATE_TRUNC('month', p.data_pedido) as mes_atividade,
        SUM(p.valor_liquido) as receita_mes,
        COUNT(*) as pedidos_mes
    FROM {{ ref('fct_pedidos') }} p
    GROUP BY p.cliente_id, DATE_TRUNC('month', p.data_pedido)
),

coorte_base AS (
    SELECT 
        cpc.mes_aquisicao,
        COUNT(DISTINCT cpc.cliente_id) as clientes_adquiridos,
        SUM(am.receita_mes) as receita_aquisicao
    FROM clientes_primeira_compra cpc
    INNER JOIN atividade_mensal am ON cpc.cliente_id = am.cliente_id 
                                   AND cpc.mes_aquisicao = am.mes_atividade
    GROUP BY cpc.mes_aquisicao
),

coorte_retencao AS (
    SELECT 
        cpc.mes_aquisicao,
        am.mes_atividade,
        
        -- Período desde aquisição (em meses)
        EXTRACT(YEAR FROM am.mes_atividade) * 12 + EXTRACT(MONTH FROM am.mes_atividade) -
        (EXTRACT(YEAR FROM cpc.mes_aquisicao) * 12 + EXTRACT(MONTH FROM cpc.mes_aquisicao)) as periodo_desde_aquisicao,
        
        COUNT(DISTINCT cpc.cliente_id) as clientes_ativos,
        SUM(am.receita_mes) as receita_periodo,
        AVG(am.receita_mes) as receita_media_cliente,
        COUNT(am.pedidos_mes) as total_pedidos
        
    FROM clientes_primeira_compra cpc
    INNER JOIN atividade_mensal am ON cpc.cliente_id = am.cliente_id
    WHERE am.mes_atividade >= cpc.mes_aquisicao
    GROUP BY 
        cpc.mes_aquisicao, 
        am.mes_atividade,
        periodo_desde_aquisicao
),

coorte_metricas AS (
    SELECT 
        cr.mes_aquisicao,
        cr.periodo_desde_aquisicao,
        cr.clientes_ativos,
        cb.clientes_adquiridos,
        
        -- Taxa de retenção
        ROUND(
            (cr.clientes_ativos::DECIMAL / cb.clientes_adquiridos) * 100, 2
        ) as taxa_retencao_pct,
        
        -- Métricas financeiras
        cr.receita_periodo,
        cr.receita_media_cliente,
        cr.total_pedidos,
        
        -- Revenue per User (RPU)
        ROUND(
            cr.receita_periodo / NULLIF(cr.clientes_ativos, 0), 2
        ) as rpu,
        
        -- Lifetime Value acumulado por coorte
        SUM(cr.receita_periodo) OVER (
            PARTITION BY cr.mes_aquisicao 
            ORDER BY cr.periodo_desde_aquisicao 
            ROWS UNBOUNDED PRECEDING
        ) as ltv_acumulado,
        
        -- Churn rate (diferença de retenção entre períodos)
        LAG(cr.clientes_ativos) OVER (
            PARTITION BY cr.mes_aquisicao 
            ORDER BY cr.periodo_desde_aquisicao
        ) - cr.clientes_ativos as clientes_perdidos,
        
        -- Taxa de churn
        CASE 
            WHEN LAG(cr.clientes_ativos) OVER (
                PARTITION BY cr.mes_aquisicao 
                ORDER BY cr.periodo_desde_aquisicao
            ) > 0 THEN
                ROUND(
                    ((LAG(cr.clientes_ativos) OVER (
                        PARTITION BY cr.mes_aquisicao 
                        ORDER BY cr.periodo_desde_aquisicao
                    ) - cr.clientes_ativos)::DECIMAL / 
                    LAG(cr.clientes_ativos) OVER (
                        PARTITION BY cr.mes_aquisicao 
                        ORDER BY cr.periodo_desde_aquisicao
                    )) * 100, 2
                )
            ELSE 0
        END as taxa_churn_pct
        
    FROM coorte_retencao cr
    INNER JOIN coorte_base cb ON cr.mes_aquisicao = cb.mes_aquisicao
),

coorte_benchmarks AS (
    SELECT 
        periodo_desde_aquisicao,
        
        -- Benchmarks por período
        AVG(taxa_retencao_pct) as taxa_retencao_media,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY taxa_retencao_pct) as taxa_retencao_mediana,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY taxa_retencao_pct) as taxa_retencao_p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY taxa_retencao_pct) as taxa_retencao_p75,
        
        AVG(rpu) as rpu_medio,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rpu) as rpu_mediano
        
    FROM coorte_metricas
    WHERE periodo_desde_aquisicao <= 12 -- Primeiros 12 meses
    GROUP BY periodo_desde_aquisicao
),

resultado_final AS (
    SELECT 
        cm.mes_aquisicao,
        cm.periodo_desde_aquisicao,
        
        -- Informações da coorte
        cm.clientes_adquiridos,
        cm.clientes_ativos,
        cm.clientes_perdidos,
        
        -- Taxas de retenção e churn
        cm.taxa_retencao_pct,
        cm.taxa_churn_pct,
        
        -- Métricas financeiras
        cm.receita_periodo,
        cm.receita_media_cliente,
        cm.rpu,
        cm.ltv_acumulado,
        cm.total_pedidos,
        
        -- Comparação com benchmarks
        cb.taxa_retencao_media as benchmark_retencao_media,
        cb.rpu_medio as benchmark_rpu_medio,
        
        -- Performance vs benchmark
        CASE 
            WHEN cm.taxa_retencao_pct > cb.taxa_retencao_p75 THEN 'Excelente'
            WHEN cm.taxa_retencao_pct > cb.taxa_retencao_mediana THEN 'Acima da Média'
            WHEN cm.taxa_retencao_pct > cb.taxa_retencao_p25 THEN 'Abaixo da Média'
            ELSE 'Crítico'
        END as performance_retencao,
        
        -- Classificação da coorte
        CASE 
            WHEN cm.periodo_desde_aquisicao = 0 THEN 'Aquisição'
            WHEN cm.periodo_desde_aquisicao <= 3 THEN 'Onboarding'
            WHEN cm.periodo_desde_aquisicao <= 6 THEN 'Estabelecimento'
            WHEN cm.periodo_desde_aquisicao <= 12 THEN 'Maturação'
            ELSE 'Longo Prazo'
        END as fase_ciclo_vida,
        
        -- Flags de alerta
        CASE 
            WHEN cm.taxa_churn_pct > 20 THEN true 
            ELSE false 
        END as alerta_churn_alto,
        
        CASE 
            WHEN cm.rpu < cb.rpu_medio * 0.8 THEN true 
            ELSE false 
        END as alerta_rpu_baixo,
        
        -- Auditoria
        {{ add_audit_columns() }}
        
    FROM coorte_metricas cm
    LEFT JOIN coorte_benchmarks cb ON cm.periodo_desde_aquisicao = cb.periodo_desde_aquisicao
)

SELECT * FROM resultado_final
WHERE periodo_desde_aquisicao <= 24 -- Limitar a 24 meses para performance
ORDER BY mes_aquisicao DESC, periodo_desde_aquisicao ASC