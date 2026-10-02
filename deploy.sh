#!/usr/bin/env bash
set -e

# Cores para saída
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}    UGB CLOUD AGENCY - SCRIPT DE DEPLOY AUTOMATIZADO  ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Gerenciamento do Contador de Deploys
COUNTER_FILE="$BASE_DIR/deploys.txt"
LOG_FILE="$BASE_DIR/deploys.log"

if [ ! -f "$COUNTER_FILE" ]; then
    echo "0" > "$COUNTER_FILE"
fi

CURRENT_DEPLOY=$(cat "$COUNTER_FILE")
NEW_DEPLOY=$((CURRENT_DEPLOY + 1))
echo "$NEW_DEPLOY" > "$COUNTER_FILE"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$TIMESTAMP] Deploy #$NEW_DEPLOY realizado por $(whoami) em $(hostname)" >> "$LOG_FILE"

echo -e "${YELLOW}>>> Registrando Deploy #${NEW_DEPLOY} às ${TIMESTAMP}${NC}"

# 2. Build e Deploy dos Contêineres Docker
echo -e "${YELLOW}>>> Iniciando build e orquestração dos contêineres...${NC}"

if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif sudo docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="sudo docker compose"
elif sudo docker-compose version >/dev/null 2>&1; then
    COMPOSE_CMD="sudo docker-compose"
else
    echo -e "${RED}Erro: Nem 'docker compose' nem 'docker-compose' foram encontrados.${NC}"
    exit 1
fi

echo -e "${YELLOW}>>> Utilizando: ${COMPOSE_CMD}${NC}"
$COMPOSE_CMD up -d --build

echo -e "${YELLOW}>>> Aguardando inicialização dos serviços (3s)...${NC}"
sleep 3

# 3. Health Check Automatizado dos Serviços
echo -e "${YELLOW}>>> Executando verificação de integridade (Health Check)...${NC}"

check_url() {
    local url=$1
    local name=$2
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "FALHA")

    if [ "$status" = "200" ] || [ "$status" = "301" ]; then
        echo -e "  [✔] ${name}: ${GREEN}ONLINE (HTTP $status)${NC}"
    else
        echo -e "  [✖] ${name}: ${RED}ERRO (HTTP $status)${NC}"
    fi
}

check_url "http://localhost/" "Portfólio Aluno (Yamaguti)"
check_url "http://localhost/yamaguti/" "Portfólio Aluno (Yamaguti)"
check_url "http://localhost/cliente-1/" "Portfólio Aluna - Arquitetura e Urbanismo (Letícia Martins)"
check_url "http://localhost/cliente-2/" "Portfólio Aluna - Direito (Mariana Souza)"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}  DEPLOY #${NEW_DEPLOY} CONCLUÍDO COM SUCESSO!            ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Histórico gravado em: ${LOG_FILE}"
echo -e "Total de Deploys acumulados: ${NEW_DEPLOY}"
