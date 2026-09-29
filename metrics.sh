#!/usr/bin/env bash

# Cores para saída
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}      UGB CLOUD AGENCY - PAINEL DE MÉTRICAS DEVOPS    ${NC}"
echo -e "${CYAN}======================================================${NC}"

# 1. Métrica: Quantidade de Deploys
COUNTER_FILE="$BASE_DIR/deploys.txt"
if [ -f "$COUNTER_FILE" ]; then
    TOTAL_DEPLOYS=$(cat "$COUNTER_FILE")
else
    TOTAL_DEPLOYS=0
fi

# 2. Métrica: Quantidade de Clientes
CLIENTS_COUNT=3

echo -e "\n${BLUE}--- [1] MÉTRICAS GERAIS DA AGÊNCIA ---${NC}"
echo -e "  • Total de Clientes Cadastrados: ${GREEN}${CLIENTS_COUNT}${NC} (1 Aluno Principal + 2 Clientes UGB)"
echo -e "  • Total de Deploys Executados:   ${GREEN}${TOTAL_DEPLOYS}${NC}"
echo -e "  • Preço Cobrado:                 ${GREEN}R$ 5,00 / cliente${NC}"
echo -e "  • Período de Garantia:           ${GREEN}Até 3 meses${NC}"

# 3. Métrica: Status e Isolamento dos Contêineres
echo -e "\n${BLUE}--- [2] STATUS DOS CONTÊINERES DOCKER ---${NC}"

if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
    DOCKER_CMD="docker"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
    DOCKER_CMD="docker"
elif sudo docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="sudo docker compose"
    DOCKER_CMD="sudo docker"
elif sudo docker-compose version >/dev/null 2>&1; then
    COMPOSE_CMD="sudo docker-compose"
    DOCKER_CMD="sudo docker"
else
    echo -e "${RED}Erro: Docker não encontrado.${NC}"
    exit 1
fi

$COMPOSE_CMD ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# 4. Métrica: Consumo de Recursos (CPU, Memória, I/O)
echo -e "\n${BLUE}--- [3] CONSUMO DE RECURSOS (CPU & MEMÓRIA) ---${NC}"
$DOCKER_CMD stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# 5. Métrica: Disponibilidade e Tempos de Resposta
echo -e "\n${BLUE}--- [4] TESTE DE TEMPO DE RESPOSTA (LATÊNCIA) ---${NC}"
test_latency() {
    local url=$1
    local name=$2
    local time_total
    time_total=$(curl -s -o /dev/null -w "%{time_total}s" "$url" || echo "Falha")
    echo -e "  • ${name}: ${GREEN}${time_total}${NC}"
}

test_latency "http://localhost/" "Hub da Agência (/)"
test_latency "http://localhost/yamaguti/" "Portfólio Aluno (/yamaguti/)"
test_latency "http://localhost/cliente-1/" "Portfólio Aluno - Letras (/cliente-1/)"
test_latency "http://localhost/cliente-2/" "Portfólio Aluna - Direito (/cliente-2/)"

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${CYAN}      FIM DO RELATÓRIO DE MÉTRICAS                    ${NC}"
echo -e "${CYAN}======================================================${NC}"
