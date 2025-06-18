
    
    

select
    numero_pedido as unique_field,
    count(*) as n_records

from "db_source"."public"."pedidos"
where numero_pedido is not null
group by numero_pedido
having count(*) > 1


