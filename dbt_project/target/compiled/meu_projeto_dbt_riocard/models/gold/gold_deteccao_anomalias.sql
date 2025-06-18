-- Modelo Gold: Detecção de Anomalias
-- Identifica padrões anômalos em vendas, comportamento de clientes e métricas de negócio



WITH vendas_diarias AS (
    SELECT 
        DATE(data_pedido) as data_venda,
        COUNT(*) as total_pedidos,
        SUM(valor_liquido) as receita_total,
        AVG(valor_liquido) as ticket_medio,
        COUNT(DISTINCT cliente_id) as clientes_unicos
    FROM "db_source"."public_silver"."fct_pedidos"
    WHERE data_pedido >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(data_pedido)
),

metricas_estatisticas AS (
    SELECT 
        -- Estatísticas para pedidos
        AVG(total_pedidos) as media_pedidos,
        STDDEV(total_pedidos) as desvio_pedidos,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_pedidos) as q1_pedidos,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_pedidos) as q3_pedidos,
        
        -- Estatísticas para receita
        AVG(receita_total) as media_receita,
        STDDEV(receita_total) as desvio_receita,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY receita_total) as q1_receita,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY receita_total) as q3_receita,
        
        -- Estatísticas para ticket médio
        AVG(ticket_medio) as media_ticket,
        STDDEV(ticket_medio) as desvio_ticket,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ticket_medio) as q1_ticket,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ticket_medio) as q3_ticket,
        
        -- Estatísticas para clientes únicos
        AVG(clientes_unicos) as media_clientes,
        STDDEV(clientes_unicos) as desvio_clientes
        
    FROM vendas_diarias
),

anomalias_vendas AS (
    SELECT 
        vd.data_venda,
        vd.total_pedidos,
        vd.receita_total,
        vd.ticket_medio,
        vd.clientes_unicos,
        
        -- Z-Score para cada métrica
        CASE 
            WHEN me.desvio_pedidos > 0 THEN 
                ABS(vd.total_pedidos - me.media_pedidos) / me.desvio_pedidos
            ELSE 0
        END as z_score_pedidos,
        
        CASE 
            WHEN me.desvio_receita > 0 THEN 
                ABS(vd.receita_total - me.media_receita) / me.desvio_receita
            ELSE 0
        END as z_score_receita,
        
        CASE 
            WHEN me.desvio_ticket > 0 THEN 
                ABS(vd.ticket_medio - me.media_ticket) / me.desvio_ticket
            ELSE 0
        END as z_score_ticket,
        
        CASE 
            WHEN me.desvio_clientes > 0 THEN 
                ABS(vd.clientes_unicos - me.media_clientes) / me.desvio_clientes
            ELSE 0
        END as z_score_clientes,
        
        -- IQR (Interquartile Range) para detecção de outliers
        (me.q3_pedidos - me.q1_pedidos) * 1.5 as iqr_pedidos,
        (me.q3_receita - me.q1_receita) * 1.5 as iqr_receita,
        (me.q3_ticket - me.q1_ticket) * 1.5 as iqr_ticket,
        
        -- Limites para outliers (método IQR)
        me.q1_pedidos - (me.q3_pedidos - me.q1_pedidos) * 1.5 as limite_inf_pedidos,
        me.q3_pedidos + (me.q3_pedidos - me.q1_pedidos) * 1.5 as limite_sup_pedidos,
        me.q1_receita - (me.q3_receita - me.q1_receita) * 1.5 as limite_inf_receita,
        me.q3_receita + (me.q3_receita - me.q1_receita) * 1.5 as limite_sup_receita,
        me.q1_ticket - (me.q3_ticket - me.q1_ticket) * 1.5 as limite_inf_ticket,
        me.q3_ticket + (me.q3_ticket - me.q1_ticket) * 1.5 as limite_sup_ticket
        
    FROM vendas_diarias vd
    CROSS JOIN metricas_estatisticas me
),

comportamento_clientes AS (
    SELECT 
        cliente_id,
        COUNT(*) as pedidos_periodo,
        SUM(valor_liquido) as gasto_total,
        AVG(valor_liquido) as ticket_medio_cliente,
        MAX(valor_liquido) as maior_pedido,
        MIN(valor_liquido) as menor_pedido,
        
        -- Variação no comportamento
        STDDEV(valor_liquido) as variacao_ticket,
        
        -- Frequência de compra
        EXTRACT(DAYS FROM (MAX(data_pedido) - MIN(data_pedido))) / NULLIF(COUNT(*) - 1, 0) as dias_entre_compras
        
    FROM "db_source"."public_silver"."fct_pedidos"
    WHERE data_pedido >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY cliente_id
    HAVING COUNT(*) >= 2 -- Apenas clientes com múltiplos pedidos
),

anomalias_clientes AS (
    SELECT 
        cliente_id,
        pedidos_periodo,
        gasto_total,
        ticket_medio_cliente,
        maior_pedido,
        variacao_ticket,
        dias_entre_compras,
        
        -- Detecção de comportamento anômalo
        CASE 
            WHEN maior_pedido > ticket_medio_cliente * 5 THEN true
            ELSE false
        END as pedido_muito_alto,
        
        CASE 
            WHEN variacao_ticket > ticket_medio_cliente * 2 THEN true
            ELSE false
        END as comportamento_erratico,
        
        CASE 
            WHEN dias_entre_compras < 1 THEN true
            ELSE false
        END as compras_muito_frequentes,
        
        -- Score de anomalia do cliente (0-100)
        LEAST(100, 
            (CASE WHEN maior_pedido > ticket_medio_cliente * 5 THEN 30 ELSE 0 END) +
            (CASE WHEN variacao_ticket > ticket_medio_cliente * 2 THEN 25 ELSE 0 END) +
            (CASE WHEN dias_entre_compras < 1 THEN 20 ELSE 0 END) +
            (CASE WHEN pedidos_periodo > 30 THEN 25 ELSE 0 END)
        ) as score_anomalia_cliente
        
    FROM comportamento_clientes
),

anomalias_consolidadas AS (
    -- Anomalias de vendas diárias
    SELECT 
        data_venda as data_analise,
        'VENDAS_DIARIAS' as tipo_anomalia,
        'VOLUME_PEDIDOS' as subtipo,
        
        CASE 
            WHEN z_score_pedidos > 3 OR 
                 total_pedidos < limite_inf_pedidos OR 
                 total_pedidos > limite_sup_pedidos THEN 'ALTA'
            WHEN z_score_pedidos > 2 THEN 'MEDIA'
            WHEN z_score_pedidos > 1.5 THEN 'BAIXA'
            ELSE 'NORMAL'
        END as severidade,
        
        total_pedidos as valor_observado,
        NULL as valor_esperado,
        z_score_pedidos as score_anomalia,
        
        CONCAT(
            'Volume de pedidos anômalo: ', total_pedidos, 
            ' (Z-Score: ', ROUND(z_score_pedidos, 2), ')'
        ) as descricao
        
    FROM anomalias_vendas
    WHERE z_score_pedidos > 1.5 OR 
          total_pedidos < limite_inf_pedidos OR 
          total_pedidos > limite_sup_pedidos
    
    UNION ALL
    
    -- Anomalias de receita diária
    SELECT 
        data_venda as data_analise,
        'VENDAS_DIARIAS' as tipo_anomalia,
        'RECEITA_TOTAL' as subtipo,
        
        CASE 
            WHEN z_score_receita > 3 OR 
                 receita_total < limite_inf_receita OR 
                 receita_total > limite_sup_receita THEN 'ALTA'
            WHEN z_score_receita > 2 THEN 'MEDIA'
            WHEN z_score_receita > 1.5 THEN 'BAIXA'
            ELSE 'NORMAL'
        END as severidade,
        
        receita_total as valor_observado,
        NULL as valor_esperado,
        z_score_receita as score_anomalia,
        
        CONCAT(
            'Receita anômala: R$ ', ROUND(receita_total, 2), 
            ' (Z-Score: ', ROUND(z_score_receita, 2), ')'
        ) as descricao
        
    FROM anomalias_vendas
    WHERE z_score_receita > 1.5 OR 
          receita_total < limite_inf_receita OR 
          receita_total > limite_sup_receita
    
    UNION ALL
    
    -- Anomalias de ticket médio
    SELECT 
        data_venda as data_analise,
        'VENDAS_DIARIAS' as tipo_anomalia,
        'TICKET_MEDIO' as subtipo,
        
        CASE 
            WHEN z_score_ticket > 3 OR 
                 ticket_medio < limite_inf_ticket OR 
                 ticket_medio > limite_sup_ticket THEN 'ALTA'
            WHEN z_score_ticket > 2 THEN 'MEDIA'
            WHEN z_score_ticket > 1.5 THEN 'BAIXA'
            ELSE 'NORMAL'
        END as severidade,
        
        ticket_medio as valor_observado,
        NULL as valor_esperado,
        z_score_ticket as score_anomalia,
        
        CONCAT(
            'Ticket médio anômalo: R$ ', ROUND(ticket_medio, 2), 
            ' (Z-Score: ', ROUND(z_score_ticket, 2), ')'
        ) as descricao
        
    FROM anomalias_vendas
    WHERE z_score_ticket > 1.5 OR 
          ticket_medio < limite_inf_ticket OR 
          ticket_medio > limite_sup_ticket
    
    UNION ALL
    
    -- Anomalias de comportamento de clientes
    SELECT 
        CURRENT_DATE as data_analise,
        'COMPORTAMENTO_CLIENTE' as tipo_anomalia,
        'COMPORTAMENTO_ERRATICO' as subtipo,
        
        CASE 
            WHEN score_anomalia_cliente >= 70 THEN 'ALTA'
            WHEN score_anomalia_cliente >= 40 THEN 'MEDIA'
            WHEN score_anomalia_cliente >= 20 THEN 'BAIXA'
            ELSE 'NORMAL'
        END as severidade,
        
        cliente_id as valor_observado,
        NULL as valor_esperado,
        score_anomalia_cliente as score_anomalia,
        
        CONCAT(
            'Cliente ID ', cliente_id, ' com comportamento anômalo. ',
            CASE WHEN pedido_muito_alto THEN 'Pedido muito alto. ' ELSE '' END,
            CASE WHEN comportamento_erratico THEN 'Variação erratica. ' ELSE '' END,
            CASE WHEN compras_muito_frequentes THEN 'Compras muito frequentes. ' ELSE '' END,
            'Score: ', score_anomalia_cliente
        ) as descricao
        
    FROM anomalias_clientes
    WHERE score_anomalia_cliente >= 20
),

resultado_final AS (
    SELECT 
        data_analise,
        tipo_anomalia,
        subtipo,
        severidade,
        valor_observado,
        valor_esperado,
        score_anomalia,
        descricao,
        
        -- Prioridade para ação
        CASE 
            WHEN severidade = 'ALTA' THEN 1
            WHEN severidade = 'MEDIA' THEN 2
            WHEN severidade = 'BAIXA' THEN 3
            ELSE 4
        END as prioridade,
        
        -- Recomendações automáticas
        CASE 
            WHEN tipo_anomalia = 'VENDAS_DIARIAS' AND subtipo = 'VOLUME_PEDIDOS' AND severidade = 'ALTA' THEN
                'Investigar: possível problema no sistema de pedidos ou campanha promocional'
            WHEN tipo_anomalia = 'VENDAS_DIARIAS' AND subtipo = 'RECEITA_TOTAL' AND severidade = 'ALTA' THEN
                'Verificar: possível erro de precificação ou pedidos fraudulentos'
            WHEN tipo_anomalia = 'COMPORTAMENTO_CLIENTE' AND severidade = 'ALTA' THEN
                'Analisar cliente: possível fraude ou erro no sistema'
            ELSE 'Monitorar tendência'
        END as recomendacao,
        
        -- Flags de alerta
        CASE WHEN severidade IN ('ALTA', 'MEDIA') THEN true ELSE false END as requer_atencao,
        CASE WHEN score_anomalia > 3 THEN true ELSE false END as outlier_extremo,
        
        -- Auditoria
        
    CURRENT_TIMESTAMP as dbt_created_at,
    CURRENT_TIMESTAMP as dbt_updated_at,
    '7b0ac06c-66b2-40fc-80a9-d80ace88de6b' as dbt_run_id,
    'system' as dbt_created_by

        
    FROM anomalias_consolidadas
)

SELECT * FROM resultado_final
ORDER BY prioridade ASC, score_anomalia DESC, data_analise DESC