
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select numero_pedido
from "db_source"."public"."pedidos"
where numero_pedido is null



  
  
      
    ) dbt_internal_test