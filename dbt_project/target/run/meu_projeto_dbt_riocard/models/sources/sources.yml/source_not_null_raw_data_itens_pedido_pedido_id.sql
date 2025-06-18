
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select pedido_id
from "db_source"."public"."itens_pedido"
where pedido_id is null



  
  
      
    ) dbt_internal_test