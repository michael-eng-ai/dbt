
    
    

select
    codigo_produto as unique_field,
    count(*) as n_records

from "db_source"."public"."produtos"
where codigo_produto is not null
group by codigo_produto
having count(*) > 1


