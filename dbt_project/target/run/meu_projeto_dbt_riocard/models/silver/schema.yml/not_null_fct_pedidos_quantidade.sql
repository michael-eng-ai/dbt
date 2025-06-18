
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select quantidade
from "db_source"."public_silver"."fct_pedidos"
where quantidade is null



  
  
      
    ) dbt_internal_test