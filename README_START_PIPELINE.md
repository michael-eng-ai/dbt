# 🚀 Pipeline DBT - Guia de Inicialização Automatizada

## 📋 Visão Geral

O script `start_pipeline.sh` foi completamente reorganizado para iniciar todo o ambiente DBT de forma automatizada, incluindo:

- ✅ **PostgreSQL** (Source Database com dados simulados)
- ✅ **MinIO** (Data Lake S3-compatible)
- ✅ **DBT Runner** (Transformações de dados em camadas Bronze/Silver/Gold)
- ✅ **Dashboard Streamlit** (Visualização em tempo real das métricas)
- ✅ **Inserção contínua de dados** (Simulação de ambiente produtivo)
- ✅ **Scheduler DBT** (Execução automática do pipeline)

## 🎯 Como Usar

### Inicialização Completa
```bash
./start_pipeline.sh
```

**O script irá automaticamente:**
1. 🔧 Instalar dependências Python necessárias
2. 🐳 Iniciar todos os containers Docker
3. 🗄️ Configurar PostgreSQL e MinIO
4. 🔄 Executar transformações DBT
5. 📊 Abrir dashboard no navegador
6. 🔄 Iniciar inserção contínua de dados

## 🖥️ Serviços Disponíveis

Após a inicialização, os seguintes serviços estarão disponíveis:

| Serviço | URL | Credenciais | Descrição |
|---------|-----|-------------|-----------|
| 📊 **Dashboard Principal** | http://localhost:8501 | - | Interface web com métricas em tempo real |
| 🗄️ **MinIO Console** | http://localhost:9001 | minioadmin/minioadmin | Data Lake S3-compatible |
| 🐘 **PostgreSQL** | localhost:5430 | admin/admin | Banco de dados transacional |
| 📚 **DBT Docs** | http://localhost:8080 | - | Documentação do projeto DBT (após `dbt docs serve`) |

## 📊 Funcionalidades do Dashboard

- **Métricas em tempo real** de clientes, pedidos e vendas
- **Gráficos interativos** com Plotly
- **Atualização automática** a cada 5 segundos
- **Visualização de transformações DBT**
- **Monitoramento do pipeline**

## 🔄 Inserção Contínua de Dados

O script automaticamente inicia um processo que:
- Insere novos clientes a cada 30 segundos
- Gera pedidos aleatórios com produtos
- Simula um ambiente real de produção
- Permite visualizar transformações DBT em tempo real
- Alimenta as camadas Bronze → Silver → Gold automaticamente

## 📝 Comandos Úteis

### Monitoramento
```bash
# Ver logs do insersor de dados
tail -f /tmp/insere_dados.log

# Ver logs do dashboard
tail -f /tmp/dashboard.log

# Status dos containers
docker compose -f config/docker-compose.yml ps

# Ver logs dos serviços
docker compose -f config/docker-compose.yml logs -f
```

### Controle Manual
```bash
# Executar DBT manualmente
cd dbt_project && dbt run

# Executar DBT por camadas
dbt run --models tag:bronze
dbt run --models tag:silver
dbt run --models tag:gold

# Executar via Python
python3 scripts/executar_dbt.py run

# Scheduler automático
python3 scripts/scheduler_dbt.py

# Gerar documentação DBT
cd dbt_project && dbt docs generate && dbt docs serve
```

### Limpeza
```bash
# Parar todos os containers e limpar volumes
docker compose -f config/docker-compose.yml down -v

# Limpar logs
rm /tmp/insere_dados.log /tmp/dashboard.log

# Limpeza completa do ambiente
./clean_docker_environment.sh
```

## 🎯 Fluxo de Demonstração

1. **Execute o script**: `./start_pipeline.sh`
2. **Aguarde a inicialização** (3-5 minutos)
3. **Dashboard abrirá automaticamente** no navegador
4. **Observe os dados sendo inseridos** em tempo real
5. **Explore as transformações DBT** no dashboard
6. **Acesse o MinIO Console** para ver o data lake
7. **Conecte ao PostgreSQL** para análises SQL

## 🛠️ Solução de Problemas

### Dashboard não abre
```bash
# Verificar se Streamlit está instalado
pip3 install streamlit

# Iniciar manualmente
streamlit run scripts/dashboard.py --server.port 8501
```

### Containers não iniciam
```bash
# Verificar Docker
docker --version
docker compose --version

# Limpar e reiniciar
docker compose -f config/docker-compose.yml down -v
./start_pipeline.sh
```

### Erro de conexão com banco
```bash
# Verificar se PostgreSQL está rodando
docker compose -f config/docker-compose.yml ps postgres_source

# Testar conexão
psql -h localhost -p 5430 -U admin -d db_source
```

## 📈 Monitoramento em Tempo Real

O script fornece monitoramento contínuo mostrando:
- ⏰ **Timestamp** atual
- 📊 **Número de clientes** e pedidos no banco
- 🐳 **Status dos containers** (PostgreSQL, MinIO, DBT)
- 📈 **Status do dashboard** (ON/OFF)
- 🔄 **Status do insersor** (ON/OFF)
- 🏗️ **Progresso das transformações DBT** (Bronze/Silver/Gold)

## 📚 Documentação Adicional

- 📖 **Capacidades DBT**: Veja `README_DBT.md` para guia completo sobre governança e funcionalidades avançadas
- 🔧 **Ajustes Técnicos**: Veja `AJUSTES_DASHBOARD.md` para detalhes de configuração
- 🔐 **Credenciais**: Veja `config/README_CREDENCIAIS.md` para informações de acesso
- 🏗️ **Arquiteturas**: Veja `docs/arquiteturas_comparacao.md` para comparação de abordagens

## 🎉 Finalização

Para parar toda a demonstração:
- Pressione **Ctrl+C** no terminal onde o script está rodando
- O script automaticamente limpará todos os processos
- Os containers Docker continuarão rodando para uso posterior

---

**🎯 Objetivo**: Demonstrar um pipeline completo de dados com DBT, transformações em camadas medalhão e visualização em tempo real de forma totalmente automatizada.

**📚 Para funcionalidades avançadas do DBT**: Consulte `README_DBT.md` para governança, testes customizados, snapshots, macros e outras capacidades avançadas implementadas no projeto.