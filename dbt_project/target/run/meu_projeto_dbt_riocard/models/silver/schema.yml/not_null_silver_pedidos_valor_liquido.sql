
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select valor_liquido
from "db_source"."public_silver"."silver_pedidos"
where valor_liquido is null



  
  
      
    ) dbt_internal_test