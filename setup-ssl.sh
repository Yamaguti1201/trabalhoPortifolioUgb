#!/usr/bin/env bash
set -e

# Cores para saída
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}    UGB CLOUD AGENCY - CONFIGURAÇÃO SSL (CERTBOT)    ${NC}"
echo -e "${BLUE}====================================================${NC}"

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

CANDIDATE_DOMAINS=(
    "ugbio.com.br"
    "leticia-martins.ugbio.com.br"
    "sara-marcelle.ugbio.com.br"
    "joao-yamaguti.ugbio.com.br"
)

ACTIVE_ARGS=()

echo -e "${YELLOW}>>> [1/3] Verificando propagação DNS dos domínios...${NC}"
for d in "${CANDIDATE_DOMAINS[@]}"; do
    IP=$(getent hosts "$d" 2>/dev/null | awk '{print $1}' | head -n1 || true)
    if [ -z "$IP" ]; then
        IP=$(nslookup "$d" 2>/dev/null | awk '/^Address: / {print $2}' | tail -n1 || true)
    fi

    if [ -n "$IP" ]; then
        echo -e "  [✔] ${d} -> ${GREEN}${IP}${NC}"
        ACTIVE_ARGS+=("-d" "$d")
    else
        echo -e "  [✖] ${d} -> ${YELLOW}Sem apontamento DNS ainda (ignorado nesta emissão)${NC}"
    fi
done

if [ ${#ACTIVE_ARGS[@]} -eq 0 ]; then
    echo -e "${RED}Nenhum domínio apontado encontrado no momento.${NC}"
    echo -e "Configure os registros DNS na Cloudflare e execute este script novamente."
    exit 0
fi

echo -e "\n${YELLOW}>>> [2/3] Solicitando / Expandindo certificado oficial Let's Encrypt...${NC}"
$COMPOSE_CMD run --rm --entrypoint certbot certbot certonly \
    --webroot \
    -w /var/www/certbot \
    --cert-name ugbio.com.br \
    "${ACTIVE_ARGS[@]}" \
    --email favelafood@gmail.com \
    --agree-tos \
    --no-eff-email \
    --non-interactive \
    --expand

# Garante que o caminho /etc/letsencrypt/live/ugbio.com.br esperado pelo Nginx aponte para a versão mais recente
$COMPOSE_CMD exec proxy sh -c '
LATEST=$(ls -d /etc/letsencrypt/live/ugbio.com.br* 2>/dev/null | grep -E "ugbio\.com\.br(-[0-9]+)?$" | sort -V | tail -n1)
if [ -n "$LATEST" ] && [ "$LATEST" != "/etc/letsencrypt/live/ugbio.com.br" ]; then
    ln -sfn "$LATEST" /etc/letsencrypt/live/ugbio.com.br
fi
'

echo -e "\n${YELLOW}>>> [3/3] Aplicando certificados no Nginx Proxy...${NC}"
$COMPOSE_CMD exec proxy nginx -s reload

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}  CERTIFICADOS SSL CONFIGURADOS COM SUCESSO!        ${NC}"
echo -e "${GREEN}====================================================${NC}"
