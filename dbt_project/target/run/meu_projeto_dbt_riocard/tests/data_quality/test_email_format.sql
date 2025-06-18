
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- Teste de qualidade de dados: Validação de formato de email
-- Este teste identifica emails com formato inválido

SELECT 
    cliente_id,
    email_original as email,
    'Formato de email inválido' as erro_descricao
FROM "db_source"."public_silver"."dim_clientes"
WHERE email_original IS NOT NULL
  AND email_original NOT LIKE '%@%.%'
  OR email_original LIKE '%@%@%'
  OR email_original LIKE '.%@%'
  OR email_original LIKE '%@.%'
  OR LENGTH(email_original) < 5
  
  
      
    ) dbt_internal_test