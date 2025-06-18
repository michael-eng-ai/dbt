
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select valor_bruto
from "db_source"."public"."pedidos"
where valor_bruto is null



  
  
      
    ) dbt_internal_test