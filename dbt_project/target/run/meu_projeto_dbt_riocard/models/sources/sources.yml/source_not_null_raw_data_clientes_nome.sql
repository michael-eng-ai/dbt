
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select nome
from "db_source"."public"."clientes"
where nome is null



  
  
      
    ) dbt_internal_test