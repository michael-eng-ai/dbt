
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select valor_liquido_decimal
from "db_source"."public_silver"."silver_pedidos"
where valor_liquido_decimal is null



  
  
      
    ) dbt_internal_test