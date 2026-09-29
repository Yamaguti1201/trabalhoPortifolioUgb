# Plataforma de Hospedagem de Portfólios UGB (DevOps & Azure)

Ecossistema multi-container para hospedagem de portfólios institucionais de alunos e professores do **Centro Universitário Geraldo Di Biase (UGB)**, operando em contêineres Docker isolados e unificados sob um **Proxy Reverso Nginx** com roteamento por subdomínios e subcaminhos.

---

## 🏛️ Arquitetura do Sistema

```text
                                [ Usuário / Avaliador ]
                                           │
                                    Porta 80 (HTTP)
                                           ▼
                           ┌───────────────────────────────┐
                           │   ugb-proxy (Nginx Gateway)   │
                           └───────────────┬───────────────┘
                                           │ Rede Interna Docker (portfolio-net)
                   ┌───────────────────────┼───────────────────────┐
                   ▼                       ▼                       ▼
       ┌───────────────────────┐ ┌───────────────────┐ ┌───────────────────────┐
       │     meu-portfolio     │ │     cliente-1     │ │       cliente-2       │
       │ (João Pedro Yamaguti) │ │ (Prof. Carlos S.) │ │   (Mariana Souza)     │
       │     Nginx Alpine      │ │   Nginx Alpine    │ │     Nginx Alpine      │
       │ Rota: /yamaguti/      │ │ Rota: /cliente-1/ │ │ Rota: /cliente-2/     │
       │ Sub: joao-yamaguti.*  │ │ Sub: carlos-silva │ │ Sub: mariana-souza.*  │
       └───────────────────────┘ └───────────────────┘ └───────────────────────┘
```

---

## 🌐 Roteamento e Acesso aos Portfólios

O gateway Nginx suporta tanto o acesso por **subcaminho** quanto por **subdomínio com nome e sobrenome** (usando resolução automática [nip.io](https://nip.io) no IP da VM Azure `64.236.192.17`):

| Portfólio | Perfil UGB | Acesso por Subcaminho | Acesso por Subdomínio (Nome e Sobrenome) |
| :--- | :--- | :--- | :--- |
| **Hub da Agência** | Landing Page Central | `http://64.236.192.17/` | `http://64.236.192.17/` |
| **João Pedro Yamaguti** | Aluno Principal | `http://64.236.192.17/yamaguti/` | `http://joao-yamaguti.64.236.192.17.nip.io` |
| **Lucas Ferreira** | Aluno - Letras (Cliente 1) | `http://64.236.192.17/cliente-1/` | `http://carlos-silva.64.236.192.17.nip.io` |
| **Mariana Souza** | Aluna - Direito (Cliente 2) | `http://64.236.192.17/cliente-2/` | `http://mariana-souza.64.236.192.17.nip.io` |

---

## 💼 Regras Comerciais da Agência
- **Preço Fixo:** R$ 5,00 por portfólio.
- **Público:** Exclusivo para alunos e professores do UGB.
- **Garantia:** Hospedagem em nuvem por até 3 meses.

---

## 🚀 Automação de Deploy e Métricas

### 1. Deploy Automatizado (com Contador Oficial de Deploys)
O script `deploy.sh` incrementa automaticamente o arquivo `deploys.txt`, grava o histórico em `deploys.log`, recompila os containers e executa o health check em todas as rotas:

```bash
./deploy.sh
```

### 2. Painel de Métricas em Tempo Real
O script `metrics.sh` emite o relatório exigido pelo professor contendo número de clientes, total de deploys, status dos containers, consumo de CPU/Memória e latência HTTP:

```bash
./metrics.sh
```

### 3. Registro de Incidentes
Conforme a regra do professor (*"Todo incidente precisa ser relatado"*), consulte e atualize o arquivo [INCIDENTES.md](file:///Users/favelafood/Documents/portfolio-ugb/INCIDENTES.md).

---

## ☁️ Deploy na Máquina Virtual Azure

### 1. Dados do Servidor
- **IP Público:** `64.236.192.17`
- **Usuário:** `azureuser`
- **Resource Group:** `rg-aula-devops`
- **VM Name:** `vm-flask-app`

### 2. Liberar Porta 80 no Azure NSG
```bash
az network nsg rule create \
  --resource-group rg-aula-devops \
  --nsg-name vm-flask-appNSG \
  --name Allow-HTTP-80 \
  --priority 1010 \
  --destination-port-ranges 80 \
  --protocol Tcp \
  --access Allow
```

### 3. Sincronizar Arquivos com a VM via `rsync`
```bash
rsync -avz --exclude '.git' --exclude '.DS_Store' \
  /Users/favelafood/Documents/portfolio-ugb/ \
  azureuser@64.236.192.17:~/portfolio-ugb/
```

### 4. Executar o Deploy na VM
Conecte via SSH:
```bash
ssh azureuser@64.236.192.17
```
Dentro da VM:
```bash
cd ~/portfolio-ugb
./deploy.sh
```
