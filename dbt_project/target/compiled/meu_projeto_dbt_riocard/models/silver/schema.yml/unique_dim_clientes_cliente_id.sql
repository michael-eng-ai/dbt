
    
    

select
    cliente_id as unique_field,
    count(*) as n_records

from "db_source"."public_silver"."dim_clientes"
where cliente_id is not null
group by cliente_id
having count(*) > 1


