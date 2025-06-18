
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    email_original as unique_field,
    count(*) as n_records

from "db_source"."public_silver"."dim_clientes"
where email_original is not null
group by email_original
having count(*) > 1



  
  
      
    ) dbt_internal_test