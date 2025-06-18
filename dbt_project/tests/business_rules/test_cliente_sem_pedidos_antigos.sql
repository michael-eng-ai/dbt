-- Teste de regra de negócio: Clientes cadastrados há mais de 1 ano devem ter pelo menos 1 pedido
-- Este teste identifica clientes antigos sem atividade de compra

SELECT 
    c.cliente_id,
    c.nome,
    c.data_cadastro,
    'Cliente antigo sem pedidos' as alerta_descricao
FROM {{ ref('dim_clientes') }} c
LEFT JOIN {{ ref('fct_pedidos') }} p ON c.cliente_id = p.cliente_id
WHERE c.data_cadastro < CURRENT_DATE - INTERVAL '1 year'
  AND p.cliente_id IS NULL