
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    cpf as unique_field,
    count(*) as n_records

from "db_source"."public"."clientes"
where cpf is not null
group by cpf
having count(*) > 1



  
  
      
    ) dbt_internal_test