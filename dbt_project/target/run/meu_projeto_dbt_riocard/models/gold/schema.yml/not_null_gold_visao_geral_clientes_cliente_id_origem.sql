
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select cliente_id_origem
from "db_source"."public_gold"."gold_visao_geral_clientes"
where cliente_id_origem is null



  
  
      
    ) dbt_internal_test