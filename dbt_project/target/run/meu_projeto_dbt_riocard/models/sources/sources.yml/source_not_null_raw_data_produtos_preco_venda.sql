
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select preco_venda
from "db_source"."public"."produtos"
where preco_venda is null



  
  
      
    ) dbt_internal_test