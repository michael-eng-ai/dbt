
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select tipo
from "db_source"."public"."campanhas_marketing"
where tipo is null



  
  
      
    ) dbt_internal_test