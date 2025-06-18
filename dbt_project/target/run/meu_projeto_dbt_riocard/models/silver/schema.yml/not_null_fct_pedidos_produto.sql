
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select produto
from "db_source"."public_silver"."fct_pedidos"
where produto is null



  
  
      
    ) dbt_internal_test