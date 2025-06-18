
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select data_inicio
from "db_source"."public"."campanhas_marketing"
where data_inicio is null



  
  
      
    ) dbt_internal_test