# 🔐 SISTEMA DE CREDENCIAIS CENTRALIZADO

## 📋 Credenciais Padronizadas

**Todas as credenciais foram padronizadas para facilitar o uso:**

### Para Serviços Principais:
```
Usuário: admin
Senha: admin
```

### Para MinIO (Data Lake):
```
Usuário: minioadmin
Senha: minioadmin
```

## 🗂️ Arquivos de Configuração

### 📄 `env.config`
- **Arquivo principal** com todas as variáveis de ambiente
- Define credenciais, portas e configurações
- Usado automaticamente pelo `docker-compose.yml`

### 📄 `load_env.sh`
- **Script helper** para carregar variáveis no terminal
- Uso: `source config/load_env.sh`
- Mostra resumo das configurações carregadas

### 📄 `docker-compose.yml`
- **Configuração principal** dos serviços
- Usa variáveis de `env.config` automaticamente
- Valores padrão incorporados (fallback)

## 🚀 Serviços e Credenciais

### 🐘 PostgreSQL Source (Dados originais)
```
Host: localhost:5430
Usuário: admin
Senha: admin
Database: db_source
Descrição: Banco transacional com dados simulados
```

### 🗃️ MinIO (Data Lake)
```
Console: http://localhost:9001
API: http://localhost:9000
Usuário: minioadmin
Senha: minioadmin
Descrição: Armazenamento S3-compatible para data lake
```

### 🛠️ DBT (Transformações)
```
Conecta automaticamente no PostgreSQL Source
Usuário: admin
Senha: admin
Database: db_source
Schemas: public_bronze, public_silver, public_gold
```

### 📊 Dashboard Streamlit
```
URL: http://localhost:8501
Credenciais: Não requer autenticação
Descrição: Interface web para visualização de métricas
```

### 📚 DBT Docs
```
URL: http://localhost:8080 (após dbt docs serve)
Credenciais: Não requer autenticação
Descrição: Documentação automática do projeto DBT
```

## 🔧 Como Usar

### 1. Carregar Variáveis (Opcional)
```bash
source config/load_env.sh
```

### 2. Iniciar Ambiente Completo
```bash
./start_pipeline.sh
```

### 3. Ou Iniciar Apenas Infraestrutura
```bash
cd config
docker compose up -d
```

### 4. Verificar Serviços
```bash
docker compose -f config/docker-compose.yml ps
```

### 5. Testar Conexões
```bash
# PostgreSQL Source
psql -h localhost -p 5430 -U admin -d db_source

# DBT
cd dbt_project && dbt debug

# Dashboard
streamlit run scripts/dashboard.py
```

## 🛠️ Personalizações

### Alterar Credenciais
1. Edite `config/env.config`
2. Reinicie os serviços: `docker compose down && docker compose up -d`

### Alterar Portas
1. Edite as variáveis `*_PORT` em `config/env.config`
2. Reinicie os serviços

### Adicionar Variáveis
1. Adicione em `config/env.config`
2. Adicione no `env_file` dos serviços relevantes no `docker-compose.yml`
3. Use `${VARIAVEL:-valor_padrao}` no docker-compose

## 🔍 Troubleshooting

### Verificar Variáveis Carregadas
```bash
source config/load_env.sh
echo $POSTGRES_SOURCE_USER
echo $MINIO_ROOT_USER
```

### Testar Conexão PostgreSQL
```bash
# Verificar se está rodando
docker compose -f config/docker-compose.yml exec postgres_source pg_isready -U admin -d db_source

# Conectar manualmente
psql -h localhost -p 5430 -U admin -d db_source
```

### Testar MinIO
```bash
# Verificar se está rodando
curl -f http://localhost:9000/minio/health/live

# Acessar console
open http://localhost:9001
```

### Ver Logs dos Serviços
```bash
docker compose -f config/docker-compose.yml logs postgres_source
docker compose -f config/docker-compose.yml logs minio
docker compose -f config/docker-compose.yml logs dbt_runner
```

### Problemas Comuns

#### Porta já em uso
```bash
# Verificar quem está usando a porta
lsof -i :5430
lsof -i :9001

# Parar containers conflitantes
docker compose -f config/docker-compose.yml down --remove-orphans
```

#### Container não inicia
```bash
# Ver logs detalhados
docker compose -f config/docker-compose.yml up --no-detach

# Reiniciar serviço específico
docker compose -f config/docker-compose.yml restart postgres_source
```

## 📊 Arquitetura Atual do Pipeline

```
[Scripts Python] → [PostgreSQL Source] → [DBT Transformações] → [Dashboard Streamlit]
      ↓                    ↓                        ↓                     ↓
[Inserção Contínua]  [Dados Originais]    [Bronze/Silver/Gold]    [Visualização Tempo Real]
                            ↓
                      [MinIO Data Lake]
```

### Fluxo de Dados:
1. **Scripts Python** → Inserem dados simulados no PostgreSQL
2. **PostgreSQL Source** → Armazena dados transacionais
3. **DBT** → Transforma dados em camadas (Bronze → Silver → Gold)
4. **MinIO** → Data Lake para armazenamento de arquivos
5. **Dashboard** → Visualiza métricas em tempo real

**Todos os componentes usam credenciais padronizadas para simplicidade!** 🎯

## 📚 Documentação Relacionada

- 📖 **README Principal**: `/README.md` - Visão geral completa do projeto
- 🚀 **Guia de Inicialização**: `/README_START_PIPELINE.md` - Como usar o pipeline
- 📊 **Capacidades DBT**: `/README_DBT.md` - Governança e funcionalidades avançadas
- 🔧 **Ajustes Técnicos**: `/AJUSTES_DASHBOARD.md` - Configurações específicas
- 🏗️ **Arquiteturas**: `/docs/arquiteturas_comparacao.md` - Comparação de abordagens 