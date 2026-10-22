#!/bin/sh
set -e

CERT_DIR="/etc/letsencrypt/live/ugbio.com.br"

# Se o certificado ainda não existir (primeira inicialização),
# gera um certificado auto-assinado dummy para que o Nginx inicie na porta 443 sem falhas.
if [ ! -f "$CERT_DIR/fullchain.pem" ]; then
    echo "[UGB-PROXY] Certificado SSL definitivo não encontrado em $CERT_DIR."
    echo "[UGB-PROXY] Gerando certificado provisório para bootstrap do Nginx..."
    mkdir -p "$CERT_DIR"
    openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
        -keyout "$CERT_DIR/privkey.pem" \
        -out "$CERT_DIR/fullchain.pem" \
        -subj "/CN=ugbio.com.br"
fi

echo "[UGB-PROXY] Iniciando Nginx..."
exec nginx -g "daemon off;"
