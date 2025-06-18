-- Teste de regra de negócio: Pedidos devem ter valor positivo
-- Este teste falha se encontrar pedidos com valor <= 0

SELECT 
    pedido_id,
    valor_liquido,
    'Valor de pedido inválido' as erro_descricao
FROM "db_source"."public_silver"."fct_pedidos"
WHERE valor_liquido <= 0