
      insert into "db_source"."public_silver"."silver_pedidos_incremental" ("pedido_id", "cliente_id", "valor_bruto", "desconto", "valor_liquido", "status", "data_pedido", "updated_at", "row_hash", "dbt_created_at", "dbt_updated_at", "dbt_run_id", "dbt_created_by", "data_quality_flag", "categoria_valor", "valor_liquido_unitario", "is_high_value", "is_today")
    (
        select "pedido_id", "cliente_id", "valor_bruto", "desconto", "valor_liquido", "status", "data_pedido", "updated_at", "row_hash", "dbt_created_at", "dbt_updated_at", "dbt_run_id", "dbt_created_by", "data_quality_flag", "categoria_valor", "valor_liquido_unitario", "is_high_value", "is_today"
        from "silver_pedidos_incremental__dbt_tmp223725062447"
    )


  