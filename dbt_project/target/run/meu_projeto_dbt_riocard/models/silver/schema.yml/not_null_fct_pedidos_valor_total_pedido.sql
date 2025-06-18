
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select valor_total_pedido
from "db_source"."public_silver"."fct_pedidos"
where valor_total_pedido is null



  
  
      
    ) dbt_internal_test