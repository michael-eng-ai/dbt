
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    numero_pedido as unique_field,
    count(*) as n_records

from "db_source"."public"."pedidos"
where numero_pedido is not null
group by numero_pedido
having count(*) > 1



  
  
      
    ) dbt_internal_test