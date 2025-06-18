
    
    

select
    email as unique_field,
    count(*) as n_records

from "db_source"."public_silver"."dim_clientes"
where email is not null
group by email
having count(*) > 1


