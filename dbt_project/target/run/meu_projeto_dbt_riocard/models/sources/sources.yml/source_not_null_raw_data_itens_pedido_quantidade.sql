
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select quantidade
from "db_source"."public"."itens_pedido"
where quantidade is null



  
  
      
    ) dbt_internal_test