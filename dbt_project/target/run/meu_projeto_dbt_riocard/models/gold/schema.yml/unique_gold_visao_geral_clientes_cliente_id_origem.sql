
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    cliente_id_origem as unique_field,
    count(*) as n_records

from "db_source"."public_gold"."gold_visao_geral_clientes"
where cliente_id_origem is not null
group by cliente_id_origem
having count(*) > 1



  
  
      
    ) dbt_internal_test