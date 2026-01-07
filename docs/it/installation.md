# Guida all'Installazione

Istruzioni complete per l'installazione della skill Brainery e dei container.

## Prerequisiti

- **Docker Desktop** (versione 20.10+)
- **Docker Compose** (versione 2.0+)
- **Git** per clonare i repository
- **8GB RAM minimo** (12GB consigliati)
- **~13GB spazio su disco** per container e modelli

### Specifico per Windows
- Docker Desktop con backend WSL 2 abilitato
- Git Bash o PowerShell

### Linux/macOS
- Docker e Docker Compose installati via package manager

## Passo 1: Installare i Container Docker

Clona il repository brainery-containers:

```bash
git clone https://github.com/Tapiocapioca/brainery-containers.git
cd brainery-containers
```

Avvia tutti i container:

```bash
docker-compose up -d
```

Questo scaricherà le immagini pre-costruite da Docker Hub:
- `tapiocapioca/crawl4ai:latest`
- `tapiocapioca/yt-dlp-server:latest`
- `tapiocapioca/whisper-server:latest`
- `tapiocapioca/anythingllm:latest`

**Il primo avvio richiede 2-5 minuti** per scaricare le immagini e inizializzare.

## Passo 2: Verificare i Container

Controlla che tutti i container siano attivi:

```bash
docker ps --filter "name=brainery-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Output atteso:
```
NAMES                     STATUS          PORTS
brainery-anythingllm-1    Up 2 minutes    0.0.0.0:9103->3001/tcp
brainery-whisper-server-1 Up 2 minutes    0.0.0.0:9102->8502/tcp
brainery-yt-dlp-server-1  Up 2 minutes    0.0.0.0:9101->8501/tcp
brainery-crawl4ai-1       Up 2 minutes    0.0.0.0:9100->11235/tcp
```

Testa gli endpoint di salute:

```bash
curl http://localhost:9100/health   # crawl4ai
curl http://localhost:9101/health   # yt-dlp-server
curl http://localhost:9102/health   # whisper-server
curl http://localhost:9103/api/ping # anythingllm
```

Tutti dovrebbero restituire `{"status":"ok"}` o una risposta di successo simile.

## Passo 3: Configurare AnythingLLM

Apri l'interfaccia web di AnythingLLM:

```
http://localhost:9103
```

### Prima Configurazione

1. **Crea Account Admin**
   - Username: a tua scelta
   - Password: a tua scelta (salvata localmente)

2. **Configura Provider LLM**
   - Vai a: Impostazioni → Preferenza LLM
   - Seleziona provider con tier gratuito (consigliato: **iFlow Platform**)
   - Aggiungi credenziali API

#### Configurazione iFlow Platform (Consigliato)

1. Registrati su: https://iflow.cn/oauth?redirect=https%3A%2F%2Fvibex.iflow.cn%2Fsession%2Fsso_login
2. Ottieni la chiave API dalla dashboard
3. In AnythingLLM:
   - Provider: `OpenAI Compatible`
   - Base URL: `https://vibex.iflow.cn/v1`
   - Model: `glm-4.6`
   - API Key: `<la-tua-chiave>`

**Vantaggi del modello:**
- Tier gratuito: 200K token di contesto
- Buon supporto multilingua (EN/IT/ZH)
- Tempi di risposta veloci

3. **Crea Workspace**
   - Clicca "Nuovo Workspace"
   - Nome: `brainery` (o a tua preferenza)
   - Salva lo slug del workspace per uso futuro

4. **Ottieni Chiave API**
   - Vai a: Impostazioni → Chiavi API
   - Clicca "Genera Nuova Chiave API"
   - Copia la chiave

5. **Salva Chiave API nell'Ambiente**

Modifica il file `.env` nella directory `brainery-containers`:

```bash
ANYTHINGLLM_API_KEY=tua-chiave-api-qui
```

O aggiungi al tuo CLAUDE.md di Claude Code:

```markdown
## Configurazione AnythingLLM

API Key: tua-chiave-api-qui
Workspace: brainery
```

## Passo 4: Installare la Skill Brainery

### Opzione A: Installazione Manuale

1. Clona il repository della skill brainery:

```bash
cd ~/.claude/skills  # o la tua directory delle skill
git clone https://github.com/Tapiocapioca/brainery.git
```

2. Riavvia Claude Code per caricare la skill

### Opzione B: Tramite Sistema Plugin di Claude Code

In Claude Code, esegui:

```
/install-skill https://github.com/Tapiocapioca/brainery
```

## Passo 5: Verificare l'Installazione

Testa il workflow completo in Claude Code:

1. **Importa una pagina web:**
   ```
   Importa questo articolo in Brainery: https://example.com/article
   ```

2. **Interroga il contenuto:**
   ```
   Quali sono i punti principali nell'articolo che ho appena importato?
   ```

Se entrambi funzionano, l'installazione è completa!

## Risoluzione Problemi

### I Container Non Si Avviano

**Problema:** `docker-compose up -d` fallisce

**Soluzione:**
1. Verifica che Docker Desktop sia in esecuzione
2. Assicurati che non ci siano conflitti di porte (9100-9103)
3. Controlla i log: `docker-compose logs <nome-servizio>`

### AnythingLLM Mostra "Unauthorized"

**Problema:** Le chiamate API restituiscono errore 401

**Soluzione:**
1. Verifica la chiave API nel file `.env`
2. Rigenera la chiave API nelle impostazioni di AnythingLLM
3. Inizializza il client MCP:
   ```
   mcp__anythingllm__initialize_anythingllm
     apiKey: "tua-chiave"
     baseUrl: "http://localhost:9103"
   ```

### Porta Già in Uso

**Problema:** Il container fallisce con "port already allocated"

**Soluzione:**
1. Trova il processo che usa la porta: `netstat -ano | findstr :9100` (Windows)
2. Termina il processo o cambia le porte nel file `.env`:
   ```
   CRAWL4AI_PORT=9200
   YT_DLP_PORT=9201
   WHISPER_PORT=9202
   ANYTHINGLLM_PORT=9203
   ```

### Modello Whisper Non Scaricato

**Problema:** La trascrizione audio fallisce

**Soluzione:**
I modelli sono auto-scaricati al primo uso. Attendi 2-3 minuti per completare il download.

Controlla i log: `docker-compose logs whisper-server`

## Personalizzazione Porte

Le porte predefinite (9100-9103) funzionano per la maggior parte degli utenti. Per personalizzare:

1. Copia il file di ambiente di esempio:
   ```bash
   cp .env.example .env
   ```

2. Modifica `.env` con le tue porte preferite:
   ```
   CRAWL4AI_PORT=9100
   YT_DLP_PORT=9101
   WHISPER_PORT=9102
   ANYTHINGLLM_PORT=9103
   ```

3. Riavvia i container:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Aggiornamento

### Aggiorna Container

Scarica le immagini più recenti:

```bash
cd brainery-containers
docker-compose pull
docker-compose up -d
```

### Aggiorna Skill

```bash
cd ~/.claude/skills/brainery
git pull origin main
```

## Disinstallazione

### Rimuovi Container

```bash
cd brainery-containers
docker-compose down -v  # -v rimuove i volumi (elimina i dati RAG!)
```

### Rimuovi Skill

```bash
rm -rf ~/.claude/skills/brainery
```

## Prossimi Passi

Vedi [Esempi d'Uso](usage.md) per workflow pratici e scenari comuni.
