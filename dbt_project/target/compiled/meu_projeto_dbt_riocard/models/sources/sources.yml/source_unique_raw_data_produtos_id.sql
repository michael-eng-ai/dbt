
    
    

select
    id as unique_field,
    count(*) as n_records

from "db_source"."public"."produtos"
where id is not null
group by id
having count(*) > 1


