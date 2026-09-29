# Registro Oficial de Incidentes e Estabilidade (UGB DevOps)

Este documento atende à exigência formal da disciplina:
> *"Todo incidente ou problema com container fora do ar precisa ser relatado. VMs/portfolio serão monitoradas e se estiverem fora do ar serão penalizadas."*

---

## 🛡️ Política de Resiliência e Prevenção de Quedas

Para garantir a disponibilidade contínua dos portfólios hospedados na VM Azure (`64.236.192.17`), a infraestrutura adota as seguintes medidas automáticas:

1. **Reinício Automático dos Containers (`restart: always`)**:
   - Declarado em todos os serviços no [docker-compose.yml](file:///Users/favelafood/Documents/portfolio-ugb/docker-compose.yml).
   - Caso um container do Nginx falhe ou o processo morra, o daemon do Docker o reinicia imediatamente em milissegundos.
2. **Isolamento de Falha**:
   - Cada portfólio roda em processo e container estritamente isolado. O eventual erro em um portfólio não compromete os outros clientes nem o proxy central.
3. **Health Check Automatizado pós-Deploy**:
   - O script [deploy.sh](file:///Users/favelafood/Documents/portfolio-ugb/deploy.sh) testa automaticamente os endpoints com código HTTP 200/301 a cada deploy.
4. **Monitoramento de Recursos**:
   - Coleta periódica de latência, CPU e memória via [metrics.sh](file:///Users/favelafood/Documents/portfolio-ugb/metrics.sh).

---

## 📝 Histórico de Incidentes

| ID | Data / Hora | Componente Afetado | Gravidade | Descrição do Incidente | Causa Raiz | Ação Corretiva Adotada | Tempo de Downtime | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **INC-001** | 2026-09-20 18:30 | Gateway Nginx / NSG | Média | Porta 80 inacessível externamente no primeiro teste na Azure | Porta 80 não estava liberada no NSG `vm-flask-appNSG` (apenas 5000 liberada). | Criação da regra de entrada `Allow-HTTP-80` com prioridade 1010 no Azure NSG. | 0 min (ambiente pré-deploy) | **Resolvido** |
| **INC-002** | - | - | - | Nenhum incidente em produção registrado até o momento. | - | Monitoramento ativo via `metrics.sh`. | 0 min | **Estável** |

---

## 🚨 Procedimento Operacional Padrão (SOP) em Caso de Incidente

Caso um container caia ou fique inacessível durante as avaliações do professor:

1. **Identificar o container com problema**:
   ```bash
   docker compose ps
   ```
2. **Examinar os logs do serviço afetado**:
   ```bash
   docker logs <nome_do_container> --tail 50
   ```
3. **Reiniciar o serviço específico**:
   ```bash
   docker compose restart <serviço>
   ```
4. **Registrar o evento**:
   Adicionar uma nova linha na tabela acima especificando a data, causa e tempo de restabelecimento.
