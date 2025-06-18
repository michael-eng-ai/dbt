
    
    

select
    cpf as unique_field,
    count(*) as n_records

from "db_source"."public"."clientes"
where cpf is not null
group by cpf
having count(*) > 1


