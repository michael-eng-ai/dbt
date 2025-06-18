# Pipeline de Dados Local com DBT (POC sem Airbyte)

Este projeto implementa um pipeline de dados simplificado para demonstração local, conectando DBT diretamente ao banco de origem para transformações em camadas (Bronze, Silver, Gold), sem a complexidade do Airbyte.

## 🏗️ Arquitetura Simplificada

```
[Script Inserção] → [PostgreSQL Source] → [DBT] → [Camadas Bronze/Silver/Gold]
                                            ↓
                                      [MinIO Data Lake]
```

### Componentes:

- **PostgreSQL Source**: Banco transacional com dados simulados
- **Script de Inserção**: Simula dados sendo inseridos continuamente
- **DBT**: Ferramenta de transformação conectada diretamente ao banco de origem
- **MinIO**: Data Lake para armazenamento de arquivos
- **Scheduler DBT**: Script Python para execução automática do pipeline

### Vantagens desta Abordagem para POC:

- ✅ **Simplicidade**: Menos componentes para gerenciar
- ✅ **Foco no DBT**: Demonstra claramente as capacidades de transformação
- ✅ **Setup Rápido**: Inicialização em minutos
- ✅ **Recursos Mínimos**: Menor consumo de CPU/memória
- ✅ **Ideal para Demonstrações**: Fácil de explicar e entender

## 🔐 **Credenciais Padronizadas**

**Todos os serviços usam:**
```
Usuário: admin
Senha: admin
```

## 🚀 **Inicialização Rápida**

```bash
# 1. Clone e acesse o diretório
git clone <repo-url>
cd dbt

# 2. Inicie o pipeline simplificado
./scripts/start_dbt_pipeline.sh

# 3. Aguarde a inicialização (1-2 minutos)
# O script irá:
# - Subir PostgreSQL Source
# - Configurar DBT para conectar diretamente
# - Executar DBT (Bronze → Silver → Gold)
# - Iniciar inserção contínua de dados

# 4. Para execução automática contínua
python scripts/scheduler_dbt.py

# 5. Acesse as interfaces
# MinIO: http://localhost:9001 (admin/admin123)
# PostgreSQL: localhost:5430 (admin/admin)
```

## 🎯 **Início Rápido**

### 1️⃣ **Executar Pipeline Completo**
```bash
./start_pipeline.sh
```

### 2️⃣ **Executar Pipeline DBT**

> ✅ **Simples**: O pipeline agora conecta diretamente ao banco de origem, sem necessidade de configuração adicional.

1. **Execute o script de inicialização**:
   ```bash
   ./scripts/start_dbt_pipeline.sh
   ```

2. **Ou execute manualmente**:
   ```bash
   # Subir infraestrutura
   docker compose up -d
   
   # Inserir dados de exemplo
   python3 scripts/insere_dados.py
   
   # Executar DBT
   docker compose exec dbt_runner dbt run
   ```

### 3️⃣ **Executar DBT (Após CDC configurado)**
```bash
python3 scripts/executar_dbt.py debug    # Testar conexão
python3 scripts/executar_dbt.py bronze   # Modelos bronze
python3 scripts/executar_dbt.py silver   # Modelos silver
python3 scripts/executar_dbt.py gold     # Modelos gold
python3 scripts/executar_dbt.py full     # Pipeline completo
```

### 4️⃣ **Limpeza Completa (quando quiser resetar tudo)**
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

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **DBT Docs** | http://localhost:8080 (após executar `dbt docs serve`) | - |
| **PostgreSQL Source** | localhost:5430 | admin/admin |
| **PostgreSQL Analytics** | localhost:5431 | admin/admin |

## 📊 **Comandos DBT**

```bash
# Navegar para o projeto DBT
cd dbt_project

# Instalar dependências
dbt deps

# Executar modelos por camada
dbt run --models tag:bronze    # Camada Bronze
dbt run --models tag:silver    # Camada Silver  
dbt run --models tag:gold      # Camada Gold

# Executar todos os modelos
dbt run

# Executar testes
dbt test

# Gerar documentação
dbt docs generate
dbt docs serve

# Execução automática com scheduler
python ../scripts/scheduler_dbt.py --interval 300  # A cada 5 minutos
python ../scripts/scheduler_dbt.py --run-once      # Apenas uma vez
```

## 🛠️ **Comandos Úteis**

```bash
# === GERENCIAMENTO GERAL ===
# Iniciar pipeline completo
./scripts/start_dbt_pipeline.sh

# Apenas construir serviços
./scripts/start_dbt_pipeline.sh --build-only

# Iniciar com logs
./scripts/start_dbt_pipeline.sh --logs

# Parar todos os serviços
docker-compose -f config/docker-compose.yml down

# Limpar ambiente (remove volumes)
./scripts/clean_environment.sh

# === LOGS E MONITORAMENTO ===
# Ver logs de todos os serviços
docker-compose -f config/docker-compose.yml logs -f

# Logs específicos
docker-compose -f config/docker-compose.yml logs -f postgres_source
docker-compose -f config/docker-compose.yml logs -f dbt_runner
docker-compose -f config/docker-compose.yml logs -f minio

# === DBT ===
# Executar DBT localmente
cd dbt_project && dbt run

# Executar DBT via container
docker-compose -f config/docker-compose.yml exec dbt_runner dbt run

# Scheduler automático
python scripts/scheduler_dbt.py

# === DADOS ===
# Inserir dados manualmente
python scripts/insere_dados.py

# Conectar ao banco source
psql -h localhost -p 5430 -U admin -d db_source

# === MONITORAMENTO ===
# Status dos containers
docker-compose -f config/docker-compose.yml ps

# Verificar saúde dos serviços
docker-compose -f config/docker-compose.yml exec postgres_source pg_isready -U admin
```

## 📁 **Estrutura do Projeto**

```
├── start_pipeline.sh              # 🎯 Script principal
├── config/
│   ├── env.config                 # Variáveis centralizadas
│   ├── docker-compose.yml         # Configuração completa
│   ├── load_env.sh               # Helper para variáveis
│   └── README_CREDENCIAIS.md     # Documentação de credenciais
├── postgres_init_scripts/
│   └── init_source_db.sql        # Schema do banco source
├── dbt_project/                  # Projeto DBT
│   ├── models/
│   │   ├── bronze/              # Camada Bronze
│   │   ├── silver/              # Camada Silver
│   │   └── gold/                # Camada Gold
│   └── dbt_project.yml
└── dbt_profiles/
    └── profiles.yml             # Configuração DBT
```

## 🚨 **Troubleshooting**

### **Problema: "role admin does not exist"**
```bash
cd config && docker compose down --volumes
docker system prune -f
./start_pipeline.sh
```

### **Problema: DBT não encontra tabelas**
1. Verifique se os dados estão disponíveis no banco de origem:
```bash
docker compose exec postgres_source psql -U admin -d db_source -c "SELECT COUNT(*) FROM clientes;"
```

2. Se retornar erro, execute o script de inserção de dados primeiro

### **Problema: Portas ocupadas**
```bash
# Verificar portas em uso
lsof -i :5430 -i :5431 -i :8001 -i :9001

# Matar processos se necessário
killall postgres
docker compose down --remove-orphans
```

## 🔄 **Fluxo de Dados Simplificado**

1. **📝 APIs inserem dados** → PostgreSQL Source
2. **🛠️ DBT processa diretamente** → Bronze → Silver → Gold
3. **📊 Dashboard consome** → Dados transformados
4. **🔄 Scheduler executa** → Pipeline automatizado

## 🎯 **Próximos Passos**

1. Execute `./scripts/start_dbt_pipeline.sh`
2. Aguarde os dados serem inseridos automaticamente
3. Execute transformações DBT
4. Configure o scheduler para execução contínua
5. Monitore pipeline em tempo real

---

**🎉 Pipeline DBT pronto para demonstração local com credenciais admin/admin!**