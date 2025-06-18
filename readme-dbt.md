# 📊 DBT - Guia Completo de Capacidades e Governança

## 🎯 Visão Geral

Este documento apresenta uma demonstração completa das capacidades do DBT (Data Build Tool), focando em governança de dados, qualidade, documentação e melhores práticas para pipelines de dados modernos.

## 🏗️ Arquitetura Atual do Projeto

### Estrutura de Camadas (Medallion Architecture)

```
📁 dbt_project/
├── 🥉 Bronze Layer (Raw Data)
│   ├── bronze_clientes.sql
│   ├── bronze_pedidos.sql
│   ├── bronze_produtos.sql
│   └── bronze_leads.sql
│
├── 🥈 Silver Layer (Cleaned & Standardized)
│   ├── silver_clientes.sql
│   ├── silver_pedidos.sql
│   ├── silver_produtos.sql
│   ├── silver_pedidos_incremental.sql (NEW)
│   ├── dim_clientes.sql
│   └── fct_pedidos.sql
│
├── 🥇 Gold Layer (Business Metrics)
│   ├── gold_visao_geral_clientes.sql
│   ├── gold_metricas_avancadas_clientes.sql (NEW)
│   ├── gold_analise_coorte.sql (NEW)
│   ├── gold_deteccao_anomalias.sql (NEW)
│   └── agg_valor_pedidos_por_cliente_mensal.sql
│
├── 📊 Seeds (Reference Data)
│   ├── status_mapping.csv (NEW)
│   └── categoria_produtos.csv (NEW)
│
├── 📸 Snapshots (SCD Type 2)
│   └── clientes_snapshot.sql (NEW)
│
├── 🧪 Tests
│   ├── business_rules/
│   │   ├── test_pedido_valor_positivo.sql (NEW)
│   │   └── test_cliente_sem_pedidos_antigos.sql (NEW)
│   └── data_quality/
│       └── test_email_format.sql (NEW)
│
├── 🔧 Macros
│   └── governance.sql (NEW)
│
├── 📋 Sources & Tests
│   ├── sources.yml (ENHANCED)
│   ├── schema.yml (por camada)
│   └── exposures.yml (NEW)
│
└── 📚 Examples
    └── incremental_model_example.sql
```

## 🛡️ Governança de Dados Implementada

### 1. **Testes de Qualidade de Dados**

#### Testes Genéricos (Built-in)
- ✅ `unique`: Garante unicidade de chaves primárias
- ✅ `not_null`: Previne valores nulos em campos obrigatórios
- ✅ `accepted_values`: Valida valores permitidos em enums
- ✅ `relationships`: Garante integridade referencial

#### Testes Customizados de Negócio
```sql
-- tests/business_rules/test_pedido_valor_positivo.sql
-- Garante que todos os pedidos tenham valor positivo
SELECT pedido_id, valor_total
FROM {{ ref('fct_pedidos') }}
WHERE valor_total <= 0

-- tests/business_rules/test_cliente_sem_pedidos_antigos.sql
-- Identifica clientes antigos sem pedidos (possível problema de retenção)
SELECT cliente_id, nome, data_cadastro
FROM {{ ref('dim_clientes') }}
WHERE data_cadastro < CURRENT_DATE - INTERVAL '1 year'
  AND cliente_id NOT IN (SELECT DISTINCT cliente_id FROM {{ ref('fct_pedidos') }})
```

#### Testes de Qualidade de Dados
```sql
-- tests/data_quality/test_email_format.sql
-- Valida formato de emails usando regex
SELECT cliente_id, email
FROM {{ ref('dim_clientes') }}
WHERE email IS NOT NULL 
  AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')

-- Exemplo: Teste de data futura
{{ test_no_future_dates('data_cadastro') }}
```

### 2. **Macros de Governança Avançadas**

O arquivo `macros/governance.sql` contém macros reutilizáveis para governança:

#### Macros de Auditoria
```sql
-- Adiciona colunas de auditoria automaticamente
{{ add_audit_columns() }}
-- Gera: created_at, updated_at, dbt_run_id, data_source

-- Gera hash para detecção de mudanças
{{ generate_row_hash(['col1', 'col2', 'col3']) }}
```

#### Macros de Limpeza e Padronização
```sql
-- Limpa e padroniza texto
{{ clean_text('nome_campo') }}
-- Remove espaços, caracteres especiais, padroniza case

-- Padroniza emails
{{ standardize_email('email_campo') }}
-- Converte para lowercase, remove espaços

-- Extrai domínio do email
{{ extract_email_domain('email_campo') }}
```

#### Macros de Negócio
```sql
-- Calcula Customer Lifetime Value
{{ calculate_clv('receita_total', 'frequencia_compra', 'tempo_ativo') }}

-- Classifica valor do cliente
{{ classify_customer_value('valor_total') }}
-- Retorna: 'Alto Valor', 'Médio Valor', 'Baixo Valor'

-- Detecta outliers usando IQR
{{ detect_outliers('valor_campo', 1.5) }}
```

#### Macros de Validação
```sql
-- Valida CPF brasileiro
{{ validate_cpf('cpf_campo') }}

-- Categoriza por data
{{ categorize_by_date('data_campo') }}
-- Retorna: 'Hoje', 'Esta Semana', 'Este Mês', etc.
```

### 3. **Seeds - Dados de Referência**

Seeds são arquivos CSV com dados de referência que o DBT carrega:

#### `seeds/status_mapping.csv`
```csv
status_code,status_name,status_category,status_description,is_active
1,Ativo,Válido,Cliente ativo no sistema,true
2,Inativo,Inválido,Cliente temporariamente inativo,false
3,Suspenso,Pendente,Cliente com pendências financeiras,false
```

#### `seeds/categoria_produtos.csv`
```csv
categoria_id,categoria_nome,categoria_descricao,margem_padrao,is_ativo
1,Eletrônicos,Produtos eletrônicos e tecnologia,0.25,true
2,Roupas,Vestuário e acessórios,0.40,true
```

**Uso nos modelos:**
```sql
SELECT 
    c.*,
    sm.status_name,
    sm.status_category
FROM {{ ref('silver_clientes') }} c
LEFT JOIN {{ ref('status_mapping') }} sm ON c.status = sm.status_code
```

### 4. **Snapshots - Slowly Changing Dimensions (SCD Type 2)**

O arquivo `snapshots/clientes_snapshot.sql` implementa SCD Type 2:

```sql
{% snapshot clientes_snapshot %}
    {{
        config(
            target_schema='snapshots',
            unique_key='id',
            strategy='timestamp',
            updated_at='updated_at'
        )
    }}
    
    SELECT 
        id,
        nome,
        email,
        status,
        {{ clean_text('nome') }} as nome_limpo,
        {{ standardize_email('email') }} as email_padronizado,
        {{ extract_email_domain('email') }} as dominio_email,
        updated_at
    FROM {{ source('raw_data', 'clientes') }}
    
{% endsnapshot %}
```

**Benefícios:**
- 📊 Histórico completo de mudanças
- 🕐 Análise temporal de dados
- 🔍 Auditoria de alterações
- 📈 Análise de tendências históricas

### 5. **Modelos Incrementais Avançados**

O modelo `silver_pedidos_incremental.sql` demonstra estratégias incrementais:

```sql
{{
    config(
        materialized='incremental',
        unique_key='pedido_id',
        on_schema_change='sync_all_columns',
        merge_update_columns=['status', 'valor_total', 'updated_at', 'row_hash']
    )
}}

-- Estratégia híbrida: timestamp + hash para detecção de mudanças
{% if is_incremental() %}
    WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
       OR {{ generate_row_hash(['cliente_id', 'valor_total', 'status']) }} != 
          (SELECT row_hash FROM {{ this }} WHERE pedido_id = source.pedido_id)
{% endif %}
```

### 6. **Análises Avançadas - Gold Layer**

#### Métricas Avançadas de Clientes
`gold_metricas_avancadas_clientes.sql` inclui:

- 📊 **Análise RFM** (Recency, Frequency, Monetary)
- 🎯 **Segmentação automática** (Champions, At Risk, Lost, etc.)
- 💰 **Customer Lifetime Value (CLV)** estimado
- 📈 **Métricas comportamentais** (frequência, sazonalidade)
- ⚠️ **Flags de risco** (churn, crescimento acelerado)

#### Análise de Coorte
`gold_analise_coorte.sql` fornece:

- 👥 **Coortes por mês de aquisição**
- 📉 **Taxa de retenção por período**
- 💸 **Revenue per User (RPU)**
- 📊 **Benchmarks automáticos**
- 🚨 **Alertas de churn alto**

#### Detecção de Anomalias
`gold_deteccao_anomalias.sql` identifica:

- 📈 **Anomalias em vendas diárias** (Z-Score + IQR)
- 👤 **Comportamento anômalo de clientes**
- 🎯 **Scores de anomalia automáticos**
- 💡 **Recomendações de ação**
- 🚨 **Priorização por severidade**

### 7. **Monitoramento de Freshness**

Configuração em `sources.yml`:

```yaml
sources:
  - name: raw_data
    freshness:
      warn_after: {count: 2, period: hour}
      error_after: {count: 6, period: hour}
    loaded_at_field: updated_at
```

### 8. **Exposures - Documentação de Dependências**

O arquivo `exposures.yml` documenta:

- 📊 **Dashboards** que usam os modelos
- 🤖 **APIs** que consomem os dados
- 🧠 **Modelos de ML** que dependem dos dados
- 📱 **Aplicações** que utilizam as métricas
```

### 2. **Documentação Automática**

#### Descrições de Modelos e Colunas
```yaml
models:
  - name: dim_clientes
    description: >
      Dimensão de clientes com dados limpos e enriquecidos.
      Inclui categorização automática e métricas derivadas.
    columns:
      - name: cliente_id
        description: Identificador único do cliente
        tests:
          - unique
          - not_null
```

#### Lineage de Dados
- 📊 Rastreamento automático de dependências
- 🔄 Visualização de fluxo de dados
- 📈 Impacto de mudanças (upstream/downstream)

### 3. **Controle de Versão e Deploy**

#### Ambientes Separados
```yaml
# profiles.yml
default:
  target: dev
  outputs:
    dev:
      type: postgres
      schema: dev_schema
    prod:
      type: postgres
      schema: prod_schema
```

## 🔧 Capacidades Avançadas do DBT

### 1. **Materializações Inteligentes**

#### Views (Padrão para Bronze/Silver)
```sql
{{ config(materialized='view') }}
-- Ideal para transformações leves e dados que mudam frequentemente
```

#### Tables (Silver/Gold)
```sql
{{ config(materialized='table') }}
-- Para dados que precisam de performance de consulta
```

#### Incremental Models
```sql
{{ config(
    materialized='incremental',
    unique_key='id',
    on_schema_change='fail'
) }}

SELECT * FROM {{ ref('source_table') }}
{% if is_incremental() %}
  WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
{% endif %}
```

#### Snapshots (SCD Type 2)
```sql
{% snapshot clientes_snapshot %}
    {{
        config(
          target_schema='snapshots',
          unique_key='id',
          strategy='timestamp',
          updated_at='updated_at',
        )
    }}
    SELECT * FROM {{ source('raw_data', 'clientes') }}
{% endsnapshot %}
```

### 2. **Macros e Reutilização de Código**

#### Macro para Limpeza de Dados
```sql
-- macros/clean_text.sql
{% macro clean_text(column_name) %}
    TRIM(UPPER(REGEXP_REPLACE({{ column_name }}, '[^a-zA-Z0-9\s]', '', 'g')))
{% endmacro %}
```

#### Macro para Cálculos de Negócio
```sql
-- macros/calculate_customer_lifetime_value.sql
{% macro calculate_clv(customer_id, revenue_column, period_months=12) %}
    SUM(CASE 
        WHEN DATE_PART('month', AGE(CURRENT_DATE, data_pedido)) <= {{ period_months }}
        THEN {{ revenue_column }}
        ELSE 0 
    END)
{% endmacro %}
```

### 3. **Seeds (Dados de Referência)**

```csv
-- seeds/status_mapping.csv
status_code,status_name,status_category
1,Ativo,Válido
2,Inativo,Inválido
3,Suspenso,Pendente
```

### 4. **Hooks e Automação**

#### Pre-hooks
```sql
{{ config(
    pre_hook="CREATE INDEX IF NOT EXISTS idx_cliente_id ON {{ this }} (cliente_id)"
) }}
```

#### Post-hooks
```sql
{{ config(
    post_hook="ANALYZE {{ this }}"
) }}
```

## 📊 Métricas e Monitoramento

### 1. **Elementary Data Observability**

```yaml
# packages.yml
packages:
  - package: elementary-data/elementary
    version: 0.13.0
```

### 2. **Testes de Performance**

```sql
-- tests/performance/test_query_performance.sql
SELECT 
    '{{ model }}' as model_name,
    COUNT(*) as row_count,
    EXTRACT(EPOCH FROM (MAX(updated_at) - MIN(updated_at))) as time_span_seconds
FROM {{ ref(model) }}
HAVING COUNT(*) > 1000000  -- Alerta se mais de 1M de registros
```

### 3. **Alertas de Qualidade**

```yaml
models:
  - name: fct_pedidos
    tests:
      - dbt_utils.expression_is_true:
          expression: "valor_total >= 0"
          config:
            severity: error
      - dbt_utils.not_null_proportion:
          at_least: 0.95
          column_name: cliente_id
```

## 🚀 Comandos Essenciais do DBT

### Desenvolvimento
```bash
# Compilar modelos sem executar
dbt compile

# Executar modelos específicos
dbt run --select dim_clientes

# Executar com dependências
dbt run --select +dim_clientes+

# Executar apenas modelos modificados
dbt run --select state:modified

# Executar testes
dbt test

# Executar testes específicos
dbt test --select dim_clientes
```

### Documentação
```bash
# Gerar documentação
dbt docs generate

# Servir documentação localmente
dbt docs serve --port 8080

# Gerar e servir em um comando
dbt docs generate && dbt docs serve
```

### Snapshots
```bash
# Executar snapshots
dbt snapshot

# Executar snapshot específico
dbt snapshot --select clientes_snapshot
```

### Seeds
```bash
# Carregar seeds
dbt seed

# Recarregar seeds (drop e recreate)
dbt seed --full-refresh
```

## 📈 Métricas de Governança

### 1. **Cobertura de Testes**
```sql
-- Análise de cobertura de testes
WITH model_tests AS (
    SELECT 
        model_name,
        COUNT(*) as test_count
    FROM information_schema.tables 
    WHERE table_schema = 'dbt_test_results'
    GROUP BY model_name
),
total_models AS (
    SELECT COUNT(*) as total_count
    FROM information_schema.tables
    WHERE table_schema IN ('bronze', 'silver', 'gold')
)
SELECT 
    (SELECT COUNT(*) FROM model_tests) * 100.0 / 
    (SELECT total_count FROM total_models) as test_coverage_percentage
```

### 2. **Freshness de Dados**
```yaml
# models/sources/sources.yml
sources:
  - name: raw_data
    freshness:
      warn_after: {count: 1, period: hour}
      error_after: {count: 6, period: hour}
    tables:
      - name: clientes
        loaded_at_field: updated_at
```

### 3. **Monitoramento de Performance**
```sql
-- Análise de performance de modelos
SELECT 
    model_name,
    execution_time_seconds,
    rows_affected,
    execution_time_seconds / NULLIF(rows_affected, 0) as seconds_per_row
FROM dbt_run_results
WHERE execution_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY execution_time_seconds DESC
```

## 🎯 Próximas Implementações Sugeridas

### 1. **Great Expectations Integration**
```yaml
# packages.yml
packages:
  - package: calogica/dbt_expectations
    version: 0.10.0
```

### 2. **dbt-utils para Funcionalidades Avançadas**
```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1
```

### 3. **Audit Helper para Comparações**
```yaml
packages:
  - package: dbt-labs/audit_helper
    version: 0.9.0
```

### 4. **Codegen para Geração Automática**
```yaml
packages:
  - package: dbt-labs/codegen
    version: 0.12.1
```

## 📋 Checklist de Governança

### ✅ Implementado
- [x] Estrutura de camadas (Bronze/Silver/Gold)
- [x] Testes básicos de qualidade
- [x] Documentação de modelos
- [x] Sources definidos
- [x] Materializações apropriadas
- [x] Scheduler automatizado

### 🔄 Em Desenvolvimento
- [ ] Snapshots para SCD Type 2
- [ ] Testes customizados de negócio
- [ ] Macros para reutilização
- [ ] Exposures para dashboards
- [ ] Monitoramento de freshness
- [ ] Testes de performance

### 🎯 Próximos Passos
- [ ] Integração com Great Expectations
- [ ] Implementação de Elementary
- [ ] CI/CD com GitHub Actions
- [ ] Alertas automáticos
- [ ] Métricas de observabilidade
- [ ] Data lineage avançado

## 🔗 Recursos Adicionais

- [DBT Documentation](https://docs.getdbt.com/)
- [DBT Best Practices](https://docs.getdbt.com/guides/best-practices)
- [DBT Style Guide](https://github.com/dbt-labs/corp/blob/main/dbt_style_guide.md)
- [Elementary Data Observability](https://docs.elementary-data.com/)
- [Great Expectations](https://greatexpectations.io/)

---

**🎉 Este projeto demonstra as principais capacidades do DBT para governança e qualidade de dados em um ambiente de produção!**

## 🔄 Implementações Recomendadas

### 1. **Modelos Incrementais Avançados**

```sql
-- models/silver/silver_pedidos_incremental.sql
{{ config(
    materialized='incremental',
    unique_key='pedido_id',
    merge_update_columns=['status', 'valor_total', 'updated_at'],
    on_schema_change='sync_all_columns'
) }}

WITH source_data AS (
    SELECT 
        pedido_id,
        cliente_id,
        produto_id,
        quantidade,
        valor_unitario,
        valor_total,
        status,
        data_pedido,
        updated_at,
        -- Adicionar hash para detectar mudanças
        MD5(CONCAT(
            COALESCE(status, ''),
            COALESCE(valor_total::text, ''),
            COALESCE(quantidade::text, '')
        )) as row_hash
    FROM {{ ref('bronze_pedidos') }}
    {% if is_incremental() %}
        WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
           OR pedido_id IN (
               SELECT pedido_id 
               FROM {{ this }} 
               WHERE row_hash != MD5(CONCAT(
                   COALESCE(status, ''),
                   COALESCE(valor_total::text, ''),
                   COALESCE(quantidade::text, '')
               ))
           )
    {% endif %}
)

SELECT * FROM source_data
```

### 2. **Testes Customizados de Negócio**

```sql
-- tests/business_rules/test_pedido_valor_positivo.sql
SELECT 
    pedido_id,
    valor_total
FROM {{ ref('fct_pedidos') }}
WHERE valor_total <= 0
```

```sql
-- tests/business_rules/test_cliente_sem_pedidos_antigos.sql
SELECT 
    c.cliente_id,
    c.data_cadastro
FROM {{ ref('dim_clientes') }} c
LEFT JOIN {{ ref('fct_pedidos') }} p ON c.cliente_id = p.cliente_id
WHERE c.data_cadastro < CURRENT_DATE - INTERVAL '1 year'
  AND p.cliente_id IS NULL
```

### 3. **Macros para Governança**

```sql
-- macros/governance/audit_columns.sql
{% macro add_audit_columns() %}
    CURRENT_TIMESTAMP as dbt_created_at,
    CURRENT_TIMESTAMP as dbt_updated_at,
    '{{ invocation_id }}' as dbt_run_id,
    '{{ var("dbt_user", "system") }}' as dbt_created_by
{% endmacro %}
```

```sql
-- macros/governance/data_classification.sql
{% macro classify_pii_columns(model_name) %}
    {% set pii_columns = {
        'email': 'PII',
        'cpf': 'PII',
        'telefone': 'PII',
        'endereco': 'PII'
    } %}
    
    {% for column, classification in pii_columns.items() %}
        -- {{ classification }}: {{ column }}
    {% endfor %}
{% endmacro %}
```

### 4. **Exposures (Dashboards e APIs)**

```yaml
# models/exposures.yml
exposures:
  - name: dashboard_vendas
    type: dashboard
    maturity: high
    url: https://dashboard.empresa.com/vendas
    description: >
      Dashboard principal de vendas usado pela equipe comercial
      para acompanhar métricas de performance.
    depends_on:
      - ref('gold_visao_geral_clientes')
      - ref('agg_valor_pedidos_por_cliente_mensal')
    owner:
      name: Equipe Analytics
      email: analytics@empresa.com

  - name: api_clientes
    type: application
    maturity: high
    url: https://api.empresa.com/clientes
    description: >
      API REST que serve dados de clientes para aplicações internas.
    depends_on:
      - ref('dim_clientes')
    owner:
      name: Equipe Backend
      email: backend@empresa.com
```

## 🚀 Comandos Essenciais do DBT

### Desenvolvimento
```bash
# Compilar modelos sem executar
dbt compile

# Executar modelos específicos
dbt run --select dim_clientes

# Executar com dependências
dbt run --select +dim_clientes+

# Executar apenas modelos modificados
dbt run --select state:modified

# Executar testes
dbt test

# Executar testes específicos
dbt test --select dim_clientes
```

### Documentação
```bash
# Gerar documentação
dbt docs generate

# Servir documentação localmente
dbt docs serve --port 8080

# Gerar e servir em um comando
dbt docs generate && dbt docs serve
```

### Snapshots
```bash
# Executar snapshots
dbt snapshot

# Executar snapshot específico
dbt snapshot --select clientes_snapshot
```

### Seeds
```bash
# Carregar seeds
dbt seed

# Recarregar seeds (drop e recreate)
dbt seed --full-refresh
```

## 📈 Métricas de Governança

### 1. **Cobertura de Testes**
```sql
-- Análise de cobertura de testes
WITH model_tests AS (
    SELECT 
        model_name,
        COUNT(*) as test_count
    FROM information_schema.tables 
    WHERE table_schema = 'dbt_test_results'
    GROUP BY model_name
),
total_models AS (
    SELECT COUNT(*) as total_count
    FROM information_schema.tables
    WHERE table_schema IN ('bronze', 'silver', 'gold')
)
SELECT 
    (SELECT COUNT(*) FROM model_tests) * 100.0 / 
    (SELECT total_count FROM total_models) as test_coverage_percentage
```

### 2. **Freshness de Dados**
```yaml
# models/sources/sources.yml
sources:
  - name: raw_data
    freshness:
      warn_after: {count: 1, period: hour}
      error_after: {count: 6, period: hour}
    tables:
      - name: clientes
        loaded_at_field: updated_at
```

### 3. **Monitoramento de Performance**
```sql
-- Análise de performance de modelos
SELECT 
    model_name,
    execution_time_seconds,
    rows_affected,
    execution_time_seconds / NULLIF(rows_affected, 0) as seconds_per_row
FROM dbt_run_results
WHERE execution_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY execution_time_seconds DESC
```

## 🎯 Próximas Implementações Sugeridas

### 1. **Great Expectations Integration**
```yaml
# packages.yml
packages:
  - package: calogica/dbt_expectations
    version: 0.10.0
```

### 2. **dbt-utils para Funcionalidades Avançadas**
```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1
```

### 3. **Audit Helper para Comparações**
```yaml
packages:
  - package: dbt-labs/audit_helper
    version: 0.9.0
```

### 4. **Codegen para Geração Automática**
```yaml
packages:
  - package: dbt-labs/codegen
    version: 0.12.1
```

## 📋 Checklist de Governança

### ✅ Implementado
- [x] Estrutura de camadas (Bronze/Silver/Gold)
- [x] Testes básicos de qualidade
- [x] Documentação de modelos
- [x] Sources definidos
- [x] Materializações apropriadas
- [x] Scheduler automatizado

### 🔄 Em Desenvolvimento
- [ ] Snapshots para SCD Type 2
- [ ] Testes customizados de negócio
- [ ] Macros para reutilização
- [ ] Exposures para dashboards
- [ ] Monitoramento de freshness
- [ ] Testes de performance

### 🎯 Próximos Passos
- [ ] Integração com Great Expectations
- [ ] Implementação de Elementary
- [ ] CI/CD com GitHub Actions
- [ ] Alertas automáticos
- [ ] Métricas de observabilidade
- [ ] Data lineage avançado

## 🔗 Recursos Adicionais

- [DBT Documentation](https://docs.getdbt.com/)
- [DBT Best Practices](https://docs.getdbt.com/guides/best-practices)
- [DBT Style Guide](https://github.com/dbt-labs/corp/blob/main/dbt_style_guide.md)
- [Elementary Data Observability](https://docs.elementary-data.com/)
- [Great Expectations](https://greatexpectations.io/)

---

**🎉 Este projeto demonstra as principais capacidades do DBT para governança e qualidade de dados em um ambiente de produção!**