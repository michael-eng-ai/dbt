
  create view "db_source"."public_bronze"."bronze_clientes__dbt_tmp"
    
    
  as (
    -- models/bronze/bronze_clientes.sql

-- Seleciona todos os dados da tabela de clientes da fonte
-- Esta é uma visão simples dos dados brutos, sem transformações complexas ainda.



-- Camada Bronze: Dados brutos de clientes com schema atualizado

-- Bronze: Dados brutos de clientes diretamente do source (replicado via Airbyte CDC)
-- Inclui todas as colunas da nova estrutura empresarial
SELECT 
    id,
    nome,
    email,
    telefone,
    cpf,
    data_nascimento,
    endereco,
    status,
    tipo_cliente,
    limite_credito,
    data_cadastro,
    updated_at,
    created_by,
    version,
    -- Metadados para auditoria CDC
    updated_at as ultima_modificacao_fonte
FROM "db_source"."public"."clientes"
WHERE nome IS NOT NULL  -- Validação básica: nome obrigatório
  );