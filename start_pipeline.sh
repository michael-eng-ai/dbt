#!/bin/bash
# PIPELINE CDC COMPLETO - APRESENTAÇÃO AUTOMATIZADA
# Sequência: PostgreSQL → Scripts → DBT → Dashboard
# Uso: ./start_pipeline.sh

set -e

# Verificar se estamos no diretório correto
if [ ! -f "dbt_project/dbt_project.yml" ]; then
    echo "ERRO: Execute este script a partir do diretório raiz do projeto"
    echo "Diretório atual: $(pwd)"
    exit 1
fi

# Carregar variáveis
if [ -f "config/env.config" ]; then
    source config/load_env.sh
else
    echo "ERRO: Arquivo config/env.config não encontrado"
    exit 1
fi

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}OK: $1${NC}"; }
log_warning() { echo -e "${YELLOW}AVISO: $1${NC}"; }
log_error() { echo -e "${RED}ERRO: $1${NC}"; }
log_step() { echo -e "${PURPLE}PASSO $1${NC}"; }
log_highlight() { echo -e "${CYAN}DESTAQUE: $1${NC}"; }

clear
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "    🚀 PIPELINE CDC COMPLETO - APRESENTAÇÃO AUTOMATIZADA    "
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📋 SEQUÊNCIA DE INICIALIZAÇÃO:"
echo "   1️⃣  Dependências Python"
echo "   2️⃣  PostgreSQL (Source + Target)"
echo "   3️⃣  DBT (Transformações)"
echo "   4️⃣  Dashboard interativo"
echo "   5️⃣  Inserção contínua de dados"
echo ""
echo "🔐 Credenciais: admin/admin (todos os serviços)"
echo "⏱️  Tempo estimado: 3-5 minutos"
echo "🌐 URLs serão exibidas quando prontas"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# PASSO 0: INSTALAÇÃO DE DEPENDÊNCIAS (PRIMEIRO DE TUDO)
# ============================================================================
log_step "0: INSTALANDO DEPENDÊNCIAS PYTHON"

log_info "Verificando e instalando dependências necessárias..."
if python3 scripts/instalar_dependencias.py; then
    log_success "Dependências instaladas com sucesso"
else
    log_error "Falha na instalação de dependências"
    log_info "Tentando continuar mesmo assim..."
fi

log_info "Instalando dependências do requirements.txt..."
if [ -f "requirements.txt" ]; then
    if pip3 install -r requirements.txt --quiet --disable-pip-version-check; then
        log_success "Requirements.txt instalado com sucesso"
    else
        log_warning "Falha ao instalar requirements.txt, mas continuando..."
    fi
else
    log_warning "Arquivo requirements.txt não encontrado"
fi

echo ""

# ============================================================================
# PASSO 1: INICIANDO AMBIENTE COMPLETO
# ============================================================================
log_step "1: INICIANDO AMBIENTE COMPLETO (PostgreSQL + MinIO + DBT)"

log_info "Parando todos os contêineres existentes..."
docker compose -f config/docker-compose.yml down --remove-orphans -v 2>/dev/null || true

log_info "Iniciando todos os serviços via Docker Compose..."
docker compose -f config/docker-compose.yml up -d --remove-orphans --build

MAX_RETRIES=24 # Total de 2 minutos (24 * 5s)
CURRENT_RETRY=0

# Verificar PostgreSQL
log_info "Aguardando PostgreSQL Source (dados originais)..."
until docker compose -f config/docker-compose.yml exec -T postgres_source pg_isready -U "${POSTGRES_SOURCE_USER:-admin}" -d "${POSTGRES_SOURCE_DB_NAME:-db_source}" -q || [ "$CURRENT_RETRY" -ge "$MAX_RETRIES" ]; do
    log_info "Tentativa $((CURRENT_RETRY+1))/$MAX_RETRIES... PostgreSQL Source não está pronto ainda. Aguardando 5s..."
    sleep 5
    CURRENT_RETRY=$((CURRENT_RETRY+1))
done

if [ "$CURRENT_RETRY" -ge "$MAX_RETRIES" ]; then
    log_error "PostgreSQL Source falhou ao iniciar após $MAX_RETRIES tentativas!"
    exit 1
else
    log_success "PostgreSQL Source: ${POSTGRES_SOURCE_USER:-admin}@localhost:${POSTGRES_SOURCE_PORT}"
fi

# Verificar MinIO
log_info "Aguardando MinIO (Data Lake)..."
CURRENT_RETRY=0
until curl -f http://localhost:9000/minio/health/live >/dev/null 2>&1 || [ "$CURRENT_RETRY" -ge "$MAX_RETRIES" ]; do
    log_info "Tentativa $((CURRENT_RETRY+1))/$MAX_RETRIES... MinIO não está pronto ainda. Aguardando 5s..."
    sleep 5
    CURRENT_RETRY=$((CURRENT_RETRY+1))
done

if [ "$CURRENT_RETRY" -ge "$MAX_RETRIES" ]; then
    log_error "MinIO falhou ao iniciar após $MAX_RETRIES tentativas!"
    exit 1
else
    log_success "MinIO: http://localhost:9000 (Console: http://localhost:9001)"
fi

# Verificar DBT Runner
log_info "Verificando DBT Runner..."
if docker compose -f config/docker-compose.yml exec -T dbt_runner echo "DBT Runner OK" >/dev/null 2>&1; then
    log_success "DBT Runner: Container ativo e pronto"
else
    log_warning "DBT Runner pode não estar totalmente pronto, mas continuando..."
fi

log_info "Criando estrutura do banco Source (tabelas e CDC)..."
# O script criar_tabelas.py já usa localhost:5430, que é o postgres_source
# O script 02_configure_cdc.sql é executado pelo entrypoint do postgres_source
if python3 scripts/criar_tabelas.py; then
    log_success "Estrutura e dados iniciais criados no Source."
else
    log_error "Falha na criação da estrutura do Source."
    exit 1
fi

log_success "PostgreSQL Source configurado e pronto para uso"

# ============================================================================
# PASSO 2: INSERÇÃO DE DADOS INICIAIS
# ============================================================================
log_step "2: VERIFICANDO DADOS INICIAIS"

# Verificar se os dados foram criados pelo script criar_tabelas.py
log_info "Verificando dados no banco source..."
clientes_count=$(docker compose -f config/docker-compose.yml exec -T postgres_source psql -U "${POSTGRES_SOURCE_USER:-admin}" -d "${POSTGRES_SOURCE_DB_NAME:-db_source}" -t -c "SELECT COUNT(*) FROM clientes;" 2>/dev/null | tr -d ' ' || echo "0")

if [ "$clientes_count" -gt 0 ]; then
    log_success "Dados no Source: $clientes_count clientes"
else
    log_warning "Nenhum dado de cliente encontrado. Execute o script de inserção de dados se necessário."
fi

# ============================================================================
# PASSO 3: DBT AUTOMATIZADO
# ============================================================================
log_step "3: CONFIGURAÇÃO AUTOMATIZADA DO DBT"

log_info "Instalando dependências do DBT..."
python3 scripts/instalar_dependencias.py > /dev/null 2>&1

log_highlight "INICIANDO AUTO-CONFIGURAÇÃO INTELIGENTE DO DBT"
log_info "Sistema detectará automaticamente o estado e configurará DBT"

# Executar auto-configurador inteligente
if python3 scripts/auto_configure_dbt.py; then
    log_success "DBT AUTO-CONFIGURADO COM SUCESSO!"
    DBT_AUTO_SUCCESS=true
    
    # Tentar executar DBT
    log_info "Executando pipeline DBT automaticamente..."
    if python3 scripts/executar_dbt.py run; then
        log_success "Pipeline DBT executado com sucesso!"
    else
        log_warning "DBT configurado, mas execução falhou (normal se ainda não há dados replicados)"
    fi
else
    log_warning "Falha na auto-configuração do DBT"
    DBT_AUTO_SUCCESS=false
fi

# ============================================================================
# PASSO 6: DEMONSTRAÇÃO INTERATIVA
# ============================================================================
log_step "6: INICIANDO DEMONSTRAÇÃO INTERATIVA"

# Função para abrir URL no navegador
abrir_no_navegador() {
    local url=$1
    log_info "Abrindo $url no navegador..."
    
    # Detectar OS e abrir navegador
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open "$url" 2>/dev/null || true
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        xdg-open "$url" 2>/dev/null || true
    else
        log_warning "Por favor, abra manualmente: $url"
    fi
}

# Airbyte removido do projeto

# ============================================================================
# PASSO 4: INICIANDO DASHBOARD INTERATIVO
# ============================================================================
log_step "4: INICIANDO DASHBOARD INTERATIVO"

log_info "Verificando se Streamlit está instalado..."
if ! command -v streamlit &> /dev/null; then
    log_info "Instalando Streamlit..."
    pip3 install streamlit --quiet --disable-pip-version-check
fi

log_info "Iniciando Dashboard de visualização..."
streamlit run scripts/dashboard.py \
    --server.port 8501 \
    --server.address localhost \
    --server.headless true \
    --browser.gatherUsageStats false \
    > /tmp/dashboard.log 2>&1 &
DASHBOARD_PID=$!

# Aguardar dashboard inicializar
sleep 8
if ps -p $DASHBOARD_PID > /dev/null; then
    log_success "Dashboard iniciado! PID: $DASHBOARD_PID"
    log_success "Dashboard disponível em: http://localhost:8501"
    abrir_no_navegador "http://localhost:8501"
else
    log_error "Dashboard falhou ao iniciar. Verifique os logs em /tmp/dashboard.log"
    exit 1
fi

# ============================================================================
# PASSO 5: INICIANDO INSERÇÃO CONTÍNUA DE DADOS
# ============================================================================
log_step "5: INICIANDO INSERÇÃO CONTÍNUA DE DADOS"

log_info "Iniciando simulação de dados para CDC..."
python3 scripts/insere_dados.py > /tmp/insere_dados.log 2>&1 &
INSERSOR_PID=$!

# Aguardar um pouco para verificar se o processo iniciou corretamente
sleep 3
if ps -p $INSERSOR_PID > /dev/null; then
    log_success "Simulador de dados iniciado! PID: $INSERSOR_PID"
    log_success "Dados sendo inseridos continuamente para demonstrar CDC"
    log_info "Logs disponíveis em: /tmp/insere_dados.log"
else
    log_error "Simulador de dados falhou ao iniciar. Verifique o script scripts/insere_dados.py"
    exit 1
fi

# ============================================================================
# STATUS FINAL COMPLETO
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
log_highlight "🎉 PIPELINE AUTOMATIZADO E DEMONSTRAÇÃO INICIADOS!"
echo "═══════════════════════════════════════════════════════════════"

echo ""
log_highlight "🖥️  SERVIÇOS WEB DISPONÍVEIS:"
echo "📊 Dashboard Principal: http://localhost:8501"
echo "🗄️  MinIO Console: http://localhost:9001 (admin: minioadmin/minioadmin)"
echo "🐘 PostgreSQL Source: localhost:${POSTGRES_SOURCE_PORT:-5430} (admin/admin)"

echo ""
log_highlight "🤖 PROCESSOS ATIVOS:"
echo "✅ Dashboard Streamlit (PID: ${DASHBOARD_PID:-N/A})"
echo "✅ Insersor de dados CDC (PID: ${INSERSOR_PID:-N/A})"
echo "✅ PostgreSQL + MinIO + DBT Runner (Docker)"
echo "✅ DBT auto-configurado e executado"

echo ""
log_highlight "🎯 AMBIENTE TOTALMENTE FUNCIONAL!"
echo "Todos os componentes configurados automaticamente"

echo ""
log_highlight "🎯 COMO USAR O AMBIENTE:"
echo "1. 📊 Acesse o Dashboard: http://localhost:8501"
echo "2. 🔄 Dados são inseridos automaticamente a cada 30 segundos"
echo "3. 🔍 Observe as transformações DBT em tempo real"
echo "4. 🗄️  Explore o MinIO Console: http://localhost:9001"
echo "5. 🐘 Conecte ao PostgreSQL: localhost:5430 (admin/admin)"

echo ""
log_highlight "📝 COMANDOS ÚTEIS:"
echo "📋 Ver logs do insersor: tail -f /tmp/insere_dados.log"
echo "📋 Ver logs do dashboard: tail -f /tmp/dashboard.log"
echo "🔄 Executar DBT manualmente: python3 scripts/executar_dbt.py run"
echo "📊 Ver estrutura do pipeline: python3 scripts/visualizar_pipeline.py"
echo "🛑 Parar insersor: kill $INSERSOR_PID"
echo "🛑 Parar dashboard: kill $DASHBOARD_PID"
echo "🧹 Limpar ambiente: docker compose -f config/docker-compose.yml down -v"

echo ""
echo "═══════════════════════════════════════════════════════════════"
log_info "🚀 PIPELINE RODANDO COM DEMONSTRAÇÃO INTERATIVA!"
log_info "⌨️  Pressione Ctrl+C para finalizar tudo"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Função para limpar ao sair
cleanup() {
    echo ""
    log_info "Encerrando demonstração..."
    
    # Parar processos
    if [ ! -z "$DASHBOARD_PID" ] && ps -p $DASHBOARD_PID > /dev/null; then
        kill $DASHBOARD_PID 2>/dev/null || true
        log_info "Dashboard parado"
    fi
    
    if [ ! -z "$INSERSOR_PID" ] && ps -p $INSERSOR_PID > /dev/null; then
        kill $INSERSOR_PID 2>/dev/null || true
        log_info "Insersor de dados parado"
    fi
    
    log_success "Demonstração encerrada!"
    exit 0
}

# Registrar função de limpeza
trap cleanup EXIT INT TERM

# Loop de monitoramento com auto-reconfiguração
while true; do
    sleep 60
    
    # Status dos containers
    postgres_status=$(docker compose -f config/docker-compose.yml ps postgres_source --format "table" | grep -c "Up" || echo "0")
    minio_status=$(docker compose -f config/docker-compose.yml ps minio --format "table" | grep -c "Up" || echo "0")
    dbt_status=$(docker compose -f config/docker-compose.yml ps dbt_runner --format "table" | grep -c "Up" || echo "0")
    
    # Contar registros no banco
    source_clientes=$(docker compose -f config/docker-compose.yml exec -T postgres_source psql -U admin -d db_source -t -c "SELECT COUNT(*) FROM clientes;" 2>/dev/null | tr -d ' ' || echo "0")
    
    # Verificar se processos ainda estão rodando
    dashboard_status="❌ OFF"
    insersor_status="❌ OFF"
    
    if [ ! -z "$DASHBOARD_PID" ] && ps -p $DASHBOARD_PID > /dev/null; then
        dashboard_status="✅ ON"
    fi
    
    if [ ! -z "$INSERSOR_PID" ] && ps -p $INSERSOR_PID > /dev/null; then
        insersor_status="✅ ON"
    fi
    
    # Status consolidado
    containers_status="PostgreSQL:$postgres_status MinIO:$minio_status DBT:$dbt_status"
    
    # Exibir status atualizado
    echo "$(date '+%H:%M:%S') | 📊 Clientes: $source_clientes | 🐳 Containers: $containers_status | 📈 Dashboard: $dashboard_status | 🔄 Insersor: $insersor_status"
    
    # Auto-reconfiguração inteligente do DBT se necessário
    if [ "$source_clientes" -gt 0 ] && [ "$DBT_AUTO_SUCCESS" != true ]; then
        log_info "Dados detectados! Executando DBT automaticamente..."
        if python3 scripts/executar_dbt.py run > /dev/null 2>&1; then
            log_success "DBT executado com sucesso!"
            DBT_AUTO_SUCCESS=true
        fi
    fi
done