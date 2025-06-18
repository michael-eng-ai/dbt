
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select pedido_id_origem
from "db_source"."public_silver"."silver_pedidos"
where pedido_id_origem is null



  
  
      
    ) dbt_internal_test