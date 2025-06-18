
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select valor_total_pedidos_mensal
from "db_source"."public_gold"."agg_valor_pedidos_por_cliente_mensal"
where valor_total_pedidos_mensal is null



  
  
      
    ) dbt_internal_test