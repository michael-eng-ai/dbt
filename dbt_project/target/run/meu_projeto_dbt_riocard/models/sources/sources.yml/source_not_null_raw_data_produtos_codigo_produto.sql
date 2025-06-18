
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select codigo_produto
from "db_source"."public"."produtos"
where codigo_produto is null



  
  
      
    ) dbt_internal_test