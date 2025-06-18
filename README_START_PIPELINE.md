# 🚀 Pipeline DBT - Guia de Inicialização Automatizada

## 📋 Visão Geral

O script `start_pipeline.sh` foi completamente reorganizado para iniciar todo o ambiente DBT de forma automatizada, incluindo:

- ✅ **PostgreSQL** (Source Database com CDC)
- ✅ **MinIO** (Data Lake S3-compatible)
- ✅ **DBT Runner** (Transformações de dados)
- ✅ **Dashboard Streamlit** (Visualização em tempo real)
- ✅ **Inserção contínua de dados** (Simulação CDC)

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

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| 📊 **Dashboard Principal** | http://localhost:8501 | - |
| 🗄️ **MinIO Console** | http://localhost:9001 | minioadmin/minioadmin |
| 🐘 **PostgreSQL** | localhost:5430 | admin/admin |

## 📊 Funcionalidades do Dashboard

- **Métricas em tempo real** de clientes, pedidos e vendas
- **Gráficos interativos** com Plotly
- **Atualização automática** a cada 5 segundos
- **Visualização de transformações DBT**
- **Monitoramento do pipeline**

## 🔄 Inserção Contínua de Dados

O script automaticamente inicia um processo que:
- Insere novos clientes a cada 30 segundos
- Gera pedidos aleatórios
- Simula um ambiente real de CDC
- Permite visualizar transformações em tempo real

## 📝 Comandos Úteis

### Monitoramento
```bash
# Ver logs do insersor de dados
tail -f /tmp/insere_dados.log

# Ver logs do dashboard
tail -f /tmp/dashboard.log

# Status dos containers
docker compose -f config/docker-compose.yml ps
```

### Controle Manual
```bash
# Executar DBT manualmente
python3 scripts/executar_dbt.py run

# Ver estrutura do pipeline
python3 scripts/visualizar_pipeline.py

# Parar processos (use os PIDs mostrados no script)
kill <PID_DASHBOARD>
kill <PID_INSERSOR>
```

### Limpeza
```bash
# Parar todos os containers e limpar volumes
docker compose -f config/docker-compose.yml down -v

# Limpar logs
rm /tmp/insere_dados.log /tmp/dashboard.log
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
- 📊 **Número de clientes** no banco
- 🐳 **Status dos containers** (PostgreSQL, MinIO, DBT)
- 📈 **Status do dashboard** (ON/OFF)
- 🔄 **Status do insersor** (ON/OFF)

## 🎉 Finalização

Para parar toda a demonstração:
- Pressione **Ctrl+C** no terminal onde o script está rodando
- O script automaticamente limpará todos os processos
- Os containers Docker continuarão rodando para uso posterior

---

**🎯 Objetivo**: Demonstrar um pipeline completo de dados com DBT, CDC e visualização em tempo real de forma totalmente automatizada.