
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select email
from "db_source"."public_silver"."dim_clientes"
where email is null



  
  
      
    ) dbt_internal_test