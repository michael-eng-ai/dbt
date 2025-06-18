
    
    

with child as (
    select campanha_id as from_field
    from "db_source"."public"."leads"
    where campanha_id is not null
),

parent as (
    select id as to_field
    from "db_source"."public"."campanhas_marketing"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


