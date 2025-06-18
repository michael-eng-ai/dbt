
    
    

select
    email_original as unique_field,
    count(*) as n_records

from "db_source"."public_silver"."dim_clientes"
where email_original is not null
group by email_original
having count(*) > 1


