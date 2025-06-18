-- bronze_itens_pedidos.sql



SELECT
    id,
    pedido_id,
    produto_id,
    quantidade,
    preco_unitario,
    desconto_item,
    valor_total,
    observacoes,
    updated_at,
    created_by,
    version
FROM "db_source"."public"."itens_pedido"