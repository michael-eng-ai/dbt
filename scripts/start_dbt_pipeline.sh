#!/bin/bash
# =============================================================================
# Script de Inicialização - Pipeline DBT Local (sem Airbyte)
# =============================================================================
# Este script inicia o ambiente simplificado focado apenas no DBT,
# conectando diretamente ao banco de origem para demonstração local.
#
# Uso:
#   ./start_dbt_pipeline.sh [--build-only] [--logs]
# =============================================================================

set -e  # Para na primeira falha

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se Docker está rodando
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando. Por favor, inicie o Docker Desktop."
        exit 1
    fi
    log_success "Docker está rodando"
}

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências..."
    
    # Verifica Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker não encontrado. Instale o Docker Desktop."
        exit 1
    fi
    
    # Verifica Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose não encontrado. Instale o Docker Compose."
        exit 1
    fi
    
    check_docker
    log_success "Todas as dependências estão disponíveis"
}

# Função para limpar ambiente anterior
clean_environment() {
    log_info "Limpando ambiente anterior..."
    
    # Determina o diretório do projeto
    if [[ "$0" == /* ]]; then
        # Caminho absoluto
        PROJECT_DIR="$(dirname "$(dirname "$0")")" 
    else
        # Caminho relativo - usa o diretório atual
        PROJECT_DIR="$(pwd)"
    fi
    CONFIG_DIR="$PROJECT_DIR/config"
    cd "$CONFIG_DIR" || { log_error "Não foi possível acessar o diretório config: $CONFIG_DIR"; exit 1; }
    
    # Para e remove containers
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Remove volumes órfãos (opcional)
    docker volume prune -f 2>/dev/null || true
    
    log_success "Ambiente limpo"
}

# Função para construir e iniciar serviços
start_services() {
    log_info "Iniciando serviços do pipeline DBT..."
    
    # Determina o diretório do projeto
    if [[ "$0" == /* ]]; then
        # Caminho absoluto
        PROJECT_DIR="$(dirname "$(dirname "$0")")"
    else
        # Caminho relativo - usa o diretório atual
        PROJECT_DIR="$(pwd)"
    fi
    CONFIG_DIR="$PROJECT_DIR/config"
    cd "$CONFIG_DIR" || { log_error "Não foi possível acessar o diretório config: $CONFIG_DIR"; exit 1; }
    
    # Constrói e inicia os serviços
    docker-compose up -d --build
    
    log_success "Serviços iniciados"
}

# Função para aguardar serviços ficarem prontos
wait_for_services() {
    log_info "Aguardando serviços ficarem prontos..."
    
    # Aguarda PostgreSQL
    log_info "Aguardando PostgreSQL..."
    timeout=60
    counter=0
    
    while [ $counter -lt $timeout ]; do
        if docker-compose exec -T postgres_source pg_isready -U admin -d db_source >/dev/null 2>&1; then
            log_success "PostgreSQL está pronto"
            break
        fi
        
        counter=$((counter + 1))
        sleep 1
        
        if [ $counter -eq $timeout ]; then
            log_error "Timeout aguardando PostgreSQL"
            exit 1
        fi
    done
    
    # Aguarda um pouco mais para estabilizar
    sleep 5
    
    log_success "Todos os serviços estão prontos"
}

# Função para iniciar inserção de dados
start_data_insertion() {
    log_info "Iniciando inserção de dados simulados..."
    
    cd "$(dirname "$0")"
    
    # Inicia o script de inserção em background
    python3 insere_dados.py &
    DATA_INSERTION_PID=$!
    
    log_success "Inserção de dados iniciada (PID: $DATA_INSERTION_PID)"
    echo $DATA_INSERTION_PID > data_insertion.pid
}

# Função para executar DBT inicial
run_initial_dbt() {
    log_info "Executando DBT inicial..."
    
    cd "$(dirname "$0")/../dbt_project"
    
    # Verifica se dbt está instalado
    if ! command -v dbt &> /dev/null; then
        log_warning "DBT não encontrado localmente. Usando container..."
        
        # Executa via container
        docker-compose -f ../config/docker-compose.yml exec dbt_runner bash -c "
            dbt deps && 
            dbt seed && 
            dbt run && 
            dbt test
        "
    else
        # Executa localmente
        dbt deps
        dbt seed
        dbt run
        dbt test
    fi
    
    log_success "DBT executado com sucesso"
}

# Função para mostrar status dos serviços
show_status() {
    log_info "Status dos serviços:"
    
    # Determina o diretório do projeto
    if [[ "$0" == /* ]]; then
        # Caminho absoluto
        PROJECT_DIR="$(dirname "$(dirname "$0")")"
    else
        # Caminho relativo - usa o diretório atual
        PROJECT_DIR="$(pwd)"
    fi
    CONFIG_DIR="$PROJECT_DIR/config"
    cd "$CONFIG_DIR" || { log_error "Não foi possível acessar o diretório config: $CONFIG_DIR"; exit 1; }
    docker-compose ps
    
    echo ""
    log_info "URLs de acesso:"
    echo "  📊 MinIO (Data Lake): http://localhost:9001 (admin/admin123)"
    echo "  🗄️  PostgreSQL: localhost:5430 (admin/admin)"
    echo "  📈 Dashboard: streamlit run scripts/dashboard.py"
    echo ""
    
    log_info "Comandos úteis:"
    echo "  📈 Executar DBT: cd dbt_project && dbt run"
    echo "  🔄 Scheduler DBT: python scripts/scheduler_dbt.py"
    echo "  🧪 Testar Dashboard: python scripts/test_dashboard_connection.py"
    echo "  📋 Ver logs: docker-compose -f config/docker-compose.yml logs -f"
    echo "  🛑 Parar tudo: docker-compose -f config/docker-compose.yml down"
}

# Função para mostrar logs
show_logs() {
    # Determina o diretório do projeto
    if [[ "$0" == /* ]]; then
        # Caminho absoluto
        PROJECT_DIR="$(dirname "$(dirname "$0")")"
    else
        # Caminho relativo - usa o diretório atual
        PROJECT_DIR="$(pwd)"
    fi
    CONFIG_DIR="$PROJECT_DIR/config"
    cd "$CONFIG_DIR" || { log_error "Não foi possível acessar o diretório config: $CONFIG_DIR"; exit 1; }
    docker-compose logs -f
}

# Função principal
main() {
    echo "="*70
    log_info "Pipeline DBT Local - Inicialização (sem Airbyte)"
    echo "="*70
    
    # Parse argumentos
    BUILD_ONLY=false
    SHOW_LOGS=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --build-only)
                BUILD_ONLY=true
                shift
                ;;
            --logs)
                SHOW_LOGS=true
                shift
                ;;
            -h|--help)
                echo "Uso: $0 [--build-only] [--logs]"
                echo "  --build-only: Apenas constrói e inicia serviços"
                echo "  --logs: Mostra logs após inicialização"
                exit 0
                ;;
            *)
                log_error "Argumento desconhecido: $1"
                exit 1
                ;;
        esac
    done
    
    # Executa passos
    check_dependencies
    clean_environment
    start_services
    wait_for_services
    
    if [ "$BUILD_ONLY" = false ]; then
        start_data_insertion
        run_initial_dbt
        show_status
        
        echo ""
        log_success "🚀 Pipeline DBT iniciado com sucesso!"
        log_info "💡 Use 'python scripts/scheduler_dbt.py' para execução automática"
        log_info "📊 Para visualizar dados: streamlit run scripts/dashboard.py"
        log_info "🧪 Para testar conexões: python scripts/test_dashboard_connection.py"
        
        if [ "$SHOW_LOGS" = true ]; then
            echo ""
            log_info "Mostrando logs (Ctrl+C para sair)..."
            show_logs
        fi
    else
        log_success "🏗️  Serviços construídos e iniciados"
        show_status
    fi
}

# Tratamento de sinais
trap 'log_warning "Script interrompido pelo usuário"; exit 130' INT TERM

# Executa função principal
main "$@"