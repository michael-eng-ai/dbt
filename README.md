# Pipeline de Dados Completo com DBT

Este projeto implementa um pipeline de dados completo para demonst## 🏗️ **Arquitetura Detalhada**

### **Ordem do Pipeline de Dados**
```
1. 📝 Scripts Python inserem dados → PostgreSQL Source
2. 🔄 DBT executa transformações → Bronze → Silver → Gold  
3. 📊 Dashboard consome dados transformados → Visualização em tempo real
4. 🔄 Scheduler mantém pipeline atualizado → Execução automática
```

### **Fluxo Tecnológico**
- **Docker**: Infraestrutura (PostgreSQL, MinIO, DBT Runner)
- **Python**: Automação (inserção, scheduler, dashboard)
- **DBT**: Transformações de dados (SQL + Jinja2)
- **Streamlit**: Interface web interativa
- **Credenciais Padronizadas**: admin/admin para todos os serviços

### **Camadas de Dados (Medalhão)**
```
🥉 Bronze → Dados brutos (cópia exata do source)
🥈 Silver → Dados limpos e padronizados  
🥇 Gold → Agregações e métricas de negócio
```T para transformações em camadas (Bronze, Silver, Gold), incluindo dashboard interativo e simulação de dados em tempo real.

## 🏗️ Arquitetura do Pipeline

```
[Scripts Python] → [PostgreSQL Source] → [DBT Transformações] → [Dashboard Streamlit]
      ↓                    ↓                        ↓                     ↓
[Inserção Contínua]  [Dados Originais]    [Bronze/Silver/Gold]    [Visualização Tempo Real]
                            ↓
                      [MinIO Data Lake]
```

### Componentes:

- **PostgreSQL Source**: Banco transacional com dados simulados e CDC habilitado
- **Scripts Python**: Automação para inserção contínua e execução do pipeline
- **DBT**: Transformações de dados em camadas medalhão (Bronze → Silver → Gold)
- **MinIO**: Data Lake S3-compatible para armazenamento
- **Dashboard Streamlit**: Interface web para visualização de métricas em tempo real
- **Scheduler DBT**: Script Python para execução automática do pipeline

### Vantagens desta Abordagem:

- ✅ **Pipeline Completo**: Demonstra todo o ciclo de dados
- ✅ **Transformações DBT**: Implementa padrão medalhão completo
- ✅ **Dashboard Interativo**: Visualização em tempo real das métricas
- ✅ **Inserção Automática**: Simula ambiente de produção
- ✅ **Setup Automatizado**: Inicialização com um comando

## 🔐 **Credenciais Padronizadas**

**Todos os serviços usam:**
```
Usuário: admin
Senha: admin
```

## 🚀 **Inicialização Completa (Recomendado)**

```bash
# 1. Clone e acesse o diretório
git clone <repo-url>
cd dbt

# 2. Execute o pipeline completo (automatizado)
./start_pipeline.sh

# 3. Aguarde a inicialização (3-5 minutos)
# O script irá automaticamente:
# - Instalar dependências Python
# - Subir PostgreSQL Source + MinIO
# - Configurar e executar DBT (Bronze → Silver → Gold)
# - Iniciar dashboard interativo
# - Começar inserção contínua de dados

# 4. Acesse as interfaces
# Dashboard: http://localhost:8501 (aberto automaticamente)
# MinIO: http://localhost:9001 (minioadmin/minioadmin)
# PostgreSQL: localhost:5430 (admin/admin)
```

## 🎯 **Opções de Execução**

### 1️⃣ **Pipeline Completo (Recomendado)**
```bash
./start_pipeline.sh
```
**Executa**: Todo o ambiente + Dashboard automático + Inserção contínua

### 2️⃣ **Pipeline DBT Focado**
```bash
./scripts/start_dbt_pipeline.sh
```
**Executa**: Apenas infraestrutura + DBT (sem dashboard automático)

### 3️⃣ **Execução Manual do DBT**
```bash
# Após qualquer uma das opções acima:
cd dbt_project
dbt run --models tag:bronze    # Camada Bronze
dbt run --models tag:silver    # Camada Silver  
dbt run --models tag:gold      # Camada Gold
dbt run                        # Pipeline completo
```

### 4️⃣ **Scheduler Automático**
```bash
python scripts/scheduler_dbt.py --interval 300  # A cada 5 minutos
python scripts/scheduler_dbt.py --run-once      # Apenas uma vez
```

### 5️⃣ **Dashboard Independente**
```bash
streamlit run scripts/dashboard.py
```

### 6️⃣ **Limpeza Completa**
```bash
./clean_docker_environment.sh
```
**⚠️ CUIDADO:** Remove TUDO - containers, volumes, dados, configurações!

## ��️ **Arquitetura**

### **Abordagem Híbrida: Docker + Python**
- **Docker**: Apenas para infraestrutura (PostgreSQL, MinIO, DBT Runner)
- **Python**: Execução de lógica (DBT, verificações, criação de tabelas)
- **Credenciais Padronizadas**: admin/admin para todos os serviços

### **Fluxo de Dados**
```
1. PostgreSQL Source (dados originais)
   ↓
2. DBT para transformações de dados
   ↓
3. PostgreSQL Target (dados replicados)
   ↓
4. DBT Python (transformações)
   ↓
5. Dashboard Streamlit
```

## 📊 **Estrutura de Dados**

### **Tabelas Principais:**
- **clientes** - Dados de clientes com perfil empresarial
- **pedidos** - Pedidos sem itens (estrutura empresarial)
- **produtos** - Catálogo de produtos e-commerce
- **itens_pedido** - Relacionamento produtos↔pedidos
- **campanhas_marketing** - Campanhas de marketing
- **leads** - Leads gerados pelas campanhas

### **Camadas DBT:**
- **🥉 Bronze** - Dados brutos do banco de origem
- **🥈 Silver** - Dados limpos e padronizados
- **🥇 Gold** - Agregações e métricas de negócio

## 🌐 **URLs dos Serviços**

| Serviço | URL | Credenciais | Descrição |
|---------|-----|-------------|-----------|
| **🎯 Dashboard Principal** | http://localhost:8501 | - | Interface web principal com métricas |
| **📚 DBT Docs** | http://localhost:8080 | - | Documentação do DBT (após `dbt docs serve`) |
| **🗄️ MinIO Console** | http://localhost:9001 | minioadmin/minioadmin | Data Lake S3-compatible |
| **🐘 PostgreSQL Source** | localhost:5430 | admin/admin | Banco de dados transacional |

## 📊 **Comandos DBT Detalhados**

```bash
# Navegar para o projeto DBT
cd dbt_project

# Instalar dependências do DBT
dbt deps

# Executar modelos por camada (ordem recomendada)
dbt run --models tag:bronze    # 🥉 Camada Bronze
dbt run --models tag:silver    # 🥈 Camada Silver  
dbt run --models tag:gold      # 🥇 Camada Gold

# Executar pipeline completo
dbt run

# Inserir dados de referência (seeds)
dbt seed

# Executar testes de qualidade
dbt test

# Gerar e servir documentação
dbt docs generate
dbt docs serve --port 8080

# Execução via Python (automatizada)
python ../scripts/executar_dbt.py debug    # Testar conexão
python ../scripts/executar_dbt.py bronze   # Modelos bronze
python ../scripts/executar_dbt.py silver   # Modelos silver
python ../scripts/executar_dbt.py gold     # Modelos gold
python ../scripts/executar_dbt.py full     # Pipeline completo

# Scheduler automático (execução contínua)
python ../scripts/scheduler_dbt.py --interval 300  # A cada 5 minutos
python ../scripts/scheduler_dbt.py --run-once      # Apenas uma vez
```

## 🛠️ **Comandos Úteis**

```bash
# === PIPELINE PRINCIPAL ===
# Iniciar ambiente completo (recomendado)
./start_pipeline.sh

# Iniciar apenas DBT pipeline  
./scripts/start_dbt_pipeline.sh

# Apenas construir serviços sem executar
./scripts/start_dbt_pipeline.sh --build-only

# Iniciar com logs visíveis
./scripts/start_dbt_pipeline.sh --logs

# Parar todos os serviços
docker-compose -f config/docker-compose.yml down

# Limpar ambiente completamente
./clean_docker_environment.sh

# === DBT ===
# Executar DBT por camadas
cd dbt_project
dbt run --models tag:bronze    # Camada Bronze
dbt run --models tag:silver    # Camada Silver  
dbt run --models tag:gold      # Camada Gold
dbt run                        # Pipeline completo

# Executar testes
dbt test

# Gerar e servir documentação
dbt docs generate && dbt docs serve

# Executar via container
docker-compose -f config/docker-compose.yml exec dbt_runner dbt run

# === AUTOMAÇÃO ===
# Scheduler automático (a cada 5 minutos)
python scripts/scheduler_dbt.py --interval 300

# Scheduler uma única execução
python scripts/scheduler_dbt.py --run-once

# Dashboard independente
streamlit run scripts/dashboard.py

# === DADOS ===
# Inserir dados manualmente
python scripts/insere_dados.py

# Conectar ao banco via psql
psql -h localhost -p 5430 -U admin -d db_source

# === MONITORAMENTO ===
# Status dos containers
docker-compose -f config/docker-compose.yml ps

# Ver logs de todos os serviços
docker-compose -f config/docker-compose.yml logs -f

# Logs específicos
docker-compose -f config/docker-compose.yml logs -f postgres_source
docker-compose -f config/docker-compose.yml logs -f dbt_runner
docker-compose -f config/docker-compose.yml logs -f minio

# Verificar saúde dos serviços
docker-compose -f config/docker-compose.yml exec postgres_source pg_isready -U admin
```

## 📁 **Estrutura do Projeto**

```
├── start_pipeline.sh              # 🎯 Script principal (pipeline completo)
├── scripts/
│   ├── start_dbt_pipeline.sh       # 🔧 Pipeline DBT focado
│   ├── scheduler_dbt.py            # 🔄 Execução automática
│   ├── dashboard.py                # 📊 Interface web Streamlit  
│   ├── insere_dados.py             # 📝 Inserção de dados
│   └── executar_dbt.py             # 🛠️ Execução manual DBT
├── config/
│   ├── env.config                  # 🔧 Variáveis centralizadas
│   ├── docker-compose.yml          # 🐳 Configuração completa
│   └── load_env.sh                 # 📋 Helper para variáveis
├── postgres_init_scripts/
│   └── init_source_db.sql          # 🗄️ Schema do banco source
├── dbt_project/                    # 🏗️ Projeto DBT
│   ├── models/
│   │   ├── bronze/                 # 🥉 Camada Bronze (dados brutos)
│   │   ├── silver/                 # 🥈 Camada Silver (limpos)
│   │   └── gold/                   # 🥇 Camada Gold (agregações)
│   ├── seeds/                      # 🌱 Dados de referência
│   ├── tests/                      # 🧪 Testes de qualidade
│   └── dbt_project.yml             # ⚙️ Configuração DBT
└── dbt_profiles/
    └── profiles.yml                # 🔌 Conexões DBT
```

## 🚨 **Troubleshooting**

### **Problema: "role admin does not exist"**
```bash
# Solução: Reset completo do ambiente
cd config && docker compose down --volumes
docker system prune -f
./start_pipeline.sh
```

### **Problema: DBT não encontra tabelas**
1. Verifique se os dados estão no banco:
```bash
docker compose -f config/docker-compose.yml exec postgres_source psql -U admin -d db_source -c "SELECT COUNT(*) FROM clientes;"
```

2. Se retornar erro, execute inserção manual:
```bash
python scripts/insere_dados.py
```

### **Problema: Dashboard não carrega**
1. Verifique se o Streamlit está instalado:
```bash
pip install streamlit plotly pandas psycopg2-binary
```

2. Execute o dashboard manualmente:
```bash
streamlit run scripts/dashboard.py
```

### **Problema: Portas ocupadas**
```bash
# Verificar portas em uso
lsof -i :5430 -i :8501 -i :9001

# Parar processos conflitantes
docker compose -f config/docker-compose.yml down --remove-orphans
```

### **Problema: Pipeline não inicia automaticamente**
1. Verifique dependências:
```bash
python scripts/verificar_ambiente.py
```

2. Execute etapas manualmente:
```bash
./scripts/start_dbt_pipeline.sh --build-only
python scripts/insere_dados.py
cd dbt_project && dbt run
streamlit run scripts/dashboard.py
```

## 🔄 **Ordem do Pipeline (Sequência Completa)**

### **Execução Automática (start_pipeline.sh)**
```
1. � Instalar dependências Python
2. 🐳 Iniciar containers (PostgreSQL + MinIO + DBT Runner)  
3. ⏳ Aguardar serviços ficarem prontos
4. 📝 Inserir dados iniciais no PostgreSQL
5. 🛠️ Executar transformações DBT (Bronze → Silver → Gold)
6. 📊 Abrir dashboard Streamlit automaticamente
7. 🔄 Iniciar inserção contínua de dados em background
8. ✅ Pipeline pronto para uso
```

### **Camadas DBT (Ordem de Execução)**
```
🥉 Bronze: Cópia exata dos dados source (clientes, pedidos, produtos)
🥈 Silver: Limpeza e padronização (dimensões e fatos)  
🥇 Gold: Agregações e métricas de negócio (análises e KPIs)
```

### **Monitoramento em Tempo Real**
- **Dashboard**: Atualiza automaticamente a cada 5 segundos
- **Inserção**: Novos dados a cada 30 segundos
- **Scheduler**: Executa DBT conforme configurado

## 🎯 **Próximos Passos**

### **Para Demonstração Rápida:**
1. Execute `./start_pipeline.sh`
2. Aguarde 3-5 minutos para inicialização completa
3. Dashboard abrirá automaticamente no navegador
4. Explore as métricas atualizando em tempo real

### **Para Desenvolvimento/Análise:**
1. Acesse MinIO Console: http://localhost:9001
2. Conecte ao PostgreSQL: `psql -h localhost -p 5430 -U admin -d db_source`
3. Explore modelos DBT: `cd dbt_project && dbt docs serve`
4. Configure scheduler: `python scripts/scheduler_dbt.py --interval 300`

### **Para Customização:**
1. Modifique modelos DBT em `dbt_project/models/`
2. Ajuste dashboard em `scripts/dashboard.py`
3. Configure inserção de dados em `scripts/insere_dados.py`
4. Personalize variáveis em `config/env.config`

---

**🎉 Pipeline DBT completo pronto para demonstração com credenciais admin/admin!**

## 📚 **Documentação Complementar**

- 🚀 **[Guia de Inicialização](README_START_PIPELINE.md)** - Como usar o script automatizado
- 📊 **[Capacidades DBT](README_DBT.md)** - Governança, testes, snapshots e funcionalidades avançadas  
- 🔧 **[Ajustes Técnicos](AJUSTES_DASHBOARD.md)** - Configurações e troubleshooting do dashboard
- 🔐 **[Credenciais](config/README_CREDENCIAIS.md)** - Sistema centralizado de credenciais
- 🏗️ **[Arquiteturas](docs/arquiteturas_comparacao.md)** - Comparação de diferentes abordagens

**📖 Ordem de leitura recomendada:**
1. Este README (visão geral)
2. README_START_PIPELINE.md (execução prática)  
3. readme-dbt.md (funcionalidades avançadas)
4. Demais documentos conforme necessidade