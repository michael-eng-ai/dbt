
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with child as (
    select cliente_id as from_field
    from "db_source"."public"."pedidos"
    where cliente_id is not null
),

parent as (
    select id as to_field
    from "db_source"."public"."clientes"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



  
  
      
    ) dbt_internal_test