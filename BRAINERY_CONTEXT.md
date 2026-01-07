# Brainery - Guida Completa

---

## PARTE 1: OVERVIEW

### 1. Cos'è Brainery

**Brainery** è una skill per Claude Code che importa contenuti web (pagine, video YouTube, PDF) in un sistema RAG (Retrieval-Augmented Generation) locale.

#### Il Problema

Quando lavori con Claude, spesso hai bisogno di informazioni da contenuti lunghi:
- Video YouTube di 2 ore
- Articoli tecnici lunghi
- Documentazione PDF di centinaia di pagine

Copiare e incollare tutto è scomodo e consuma token.

#### La Soluzione

Brainery importa questi contenuti in un database locale sul tuo PC. Poi puoi:
- **Video YouTube**: Importa un video di 2 ore e chatta con il contenuto senza guardarlo tutto
- **Articoli web**: Salva articoli tecnici lunghi e ritrovali quando servono
- **PDF**: Importa documentazione e fai domande specifiche

Il vantaggio del **RAG locale**: i contenuti restano sul tuo PC, nessun servizio cloud a pagamento.

#### Come Funziona

Brainery usa **4 container Docker** che lavorano insieme:

| Container | Porta | Scopo |
|-----------|-------|-------|
| **crawl4ai** | 9100 | Estrae testo pulito da pagine web |
| **yt-dlp-server** | 9101 | Scarica trascrizioni da YouTube |
| **whisper-server** | 9102 | Trascrive audio quando non ci sono sottotitoli |
| **anythingllm** | 9103 | Database RAG locale per interrogare i contenuti |

**Porte:** Il range 9100-9103 è scelto per evitare conflitti con servizi comuni. Le porte seguono l'ordine logico del workflow (estrazione → processamento → storage). Puoi personalizzarle via file `.env` se necessario.

**Gestione Dati:** Brainery usa una strategia mista per ottimizzare performance e persistenza:
- **Cache temporanee (tmpfs in RAM)**: crawl4ai e yt-dlp-server usano RAM per performance elevate
- **Dati persistenti (disco host)**: anythingllm-storage (database RAG) e whisper-models rimangono su disco
- **Requisiti RAM aggiuntivi**: ~1.5GB per cache temporanee

Output finale: un database locale interrogabile da Claude.

#### Pattern di Gestione Stato: Manus (File-Based State)

**IMPORTANTE:** La skill Brainery DEVE utilizzare il **Manus Pattern** per gestire lo stato delle operazioni.

**Cos'è Manus:**
- Pattern per gestire stato persistente usando file invece di variabili in memoria
- Stato salvato su disco in formato JSON
- Permette di riprendere operazioni interrotte
- Evita perdita di informazioni tra sessioni Claude

**Perché Manus per Brainery:**
- Import di contenuti può essere lungo (video, PDF grandi)
- Se la sessione Claude si interrompe, non si perde il progresso
- Tracciabilità: ogni operazione è registrata su file
- Debug facilitato: puoi vedere esattamente cosa è stato importato

**Implementazione:**
La skill salverà lo stato in `~/.brainery/state.json` contenente:
- Lista contenuti importati (URL, tipo, workspace, timestamp)
- Operazioni in corso
- Errori occorsi
- Statistiche (n. import, dimensione totale, ecc.)

#### Architettura 2 Repository

Il progetto è diviso in 2 repository GitHub:
- **brainery**: La skill Claude Code (codice leggero)
- **brainery-containers**: I container Docker pre-compilati (pubblicati su Docker Hub)

#### Tecnologie

- Docker (containerizzazione)
- FastAPI (API dei server custom)
- GitHub Actions (build automatico)
- Docker Hub (distribuzione immagini)

#### Target Utente

Persone che usano Claude Code e vogliono:
- Memoria persistente per contenuti web
- Sistema RAG locale senza costi cloud
- Controllo completo sui propri dati

#### Costi e Requisiti

- **Costo**: Zero, tutto gratuito (piani free di GitHub e Docker Hub)
- **Spazio disco**: ~13GB per i container
- **Prerequisito**: Docker installato e funzionante

#### Etimologia

"Brainery" = "Brain" (cervello) + "Library" (libreria) → Un cervello-libreria per Claude.

---

#### ⚠️ DISCLAIMER IMPORTANTE

**Questo è un progetto personale/sperimentale.**

- ❌ **NON usare in produzione**
- ❌ **NON usare per dati sensibili/aziendali**
- ⚠️ **Se lo usi, è a tuo rischio e pericolo**

Il progetto è creato per scopi di apprendimento e uso personale. Non ci sono garanzie di sicurezza, stabilità o manutenzione.

### 2. Perché questa architettura

Questa sezione spiega le scelte architetturali di Brainery. Non è necessariamente la soluzione "perfetta", ma è quella che funziona per questo progetto.

#### Il Problema dei Repository Abbandonati

Cercando online, ho trovato che **moltissimi repository vengono abbandonati** per un motivo ricorrente: **difficoltà di setup dei prerequisiti**.

Gli utenti provano a installare il progetto, incontrano errori con dipendenze, versioni Python incompatibili, librerie mancanti... e abbandonano.

#### Soluzione: Docker

**Docker risolve il problema "works on my machine"** (funziona sulla mia macchina).

I container sono ambienti isolati con tutto pre-installato:
- Stesso ambiente su Windows, Mac, Linux
- Nessun conflitto con altre installazioni
- Setup: `docker pull` invece di compilare per 30+ minuti

**Perché Docker?**
- Gratuito per uso personale
- Molto diffuso e ben documentato
- Facile da installare

#### Il Problema RAG

Un altro problema che ho incontrato: **creare RAG efficaci è difficilissimo**.

La community ripete che:
- Servono competenze di ML/AI
- Configurazione complessa
- Risultati spesso deludenti

#### Soluzione: AnythingLLM

**AnythingLLM** rende il RAG accessibile con poco sforzo:
- Interfaccia semplice
- RAG locale (dati sul tuo PC)
- Configurazione automatica
- Nessun vendor lock-in

#### Perché 2 Repository Separati

Il progetto è diviso in:
- **brainery**: Codice della skill (leggero, cambia spesso)
- **brainery-containers**: Container Docker (pesanti, stabili)

**Vantaggi:**
- Posso aggiornare la skill senza ricompilare i container
- Posso aggiornare i container senza toccare la skill
- Setup utente semplificato: `docker pull` scarica immagini già pronte da Docker Hub

#### Perché Questi 4 Container

Ho scelto questi progetti perché:
- **Molto diffusi**: Community attiva, documentazione buona
- **Testati**: Li ho provati e funzionano bene
- **Standard de-facto**:
  - **crawl4ai**: Estrazione web pulita, migliore di scraping manuale
  - **yt-dlp**: Standard per YouTube e centinaia di altri siti video
  - **Whisper**: Modello OpenAI, accuracy massima per trascrizioni audio
  - **AnythingLLM**: RAG locale, nessun servizio cloud, controllo totale

#### Alternative Scartate

Ho considerato soluzioni cloud:
- Pinecone (RAG cloud)
- Weaviate Cloud
- OpenAI Embeddings API

**Problema**: Tutte a pagamento, con costi ricorrenti mensili.

**Vincolo fondamentale**: Budget zero. Brainery deve funzionare senza costi.

#### Ridurre il Rischio di Abbandono

Setup semplice = maggiore probabilità di continuare il progetto.

Se tra 6 mesi voglio riprendere Brainery:
- `docker pull` → container pronti
- Nessuna compilazione
- Nessun debug dipendenze
- Funziona subito

Questo aumenta le chance che il progetto resti utilizzabile nel tempo.

### 3. Prerequisiti

Prima di iniziare l'implementazione, assicurati di avere tutto quello che serve.

#### Requisiti Sistema

| Requisito | Minimo | Consigliato |
|-----------|--------|-------------|
| **Sistema operativo** | Windows 10, macOS 10.15, Ubuntu 20.04 | Windows 11, macOS 12+, Ubuntu 22.04+ |
| **RAM** | 8GB | 12GB |
| **Spazio disco** | 15GB liberi | 20GB+ liberi |
| **Connessione internet** | Stabile (per download ~13GB) | Banda larga |

**Note:**
- Docker + 4 container occupano ~13GB
- Durante l'uso, i container consumano memoria in base al carico
- Su sistemi con 16GB RAM non ci sono mai stati problemi

#### Account Necessari

**Nota:** Alcuni account sono necessari solo per lo **sviluppatore** (chi crea Brainery), altri per tutti.

##### 1. Account GitHub (SVILUPPATORE)

**Cosa serve:** Account GitHub per creare i due repository.

**Come ottenerlo:**
1. Vai su https://github.com/signup
2. Crea un account gratuito
3. Verifica email

**Configurazione GitHub CLI (opzionale ma consigliato):**
```bash
# Installa GitHub CLI
# Windows: winget install GitHub.cli
# macOS: brew install gh
# Linux: vedi https://github.com/cli/cli#installation

# Login
gh auth login
```

##### 2. Account Docker Hub (SVILUPPATORE)

**Cosa serve:** Account Docker Hub per pubblicare le immagini container.

**Come ottenerlo:**
1. Vai su https://hub.docker.com/signup
2. Crea un account gratuito
3. Verifica email
4. **Annota il tuo username** (es: `tapiocapioca`) - ti servirà dopo

**Nota:** Useremo il piano gratuito che permette repository pubblici illimitati.

##### 3. Provider LLM con Free Tier (TUTTI) ⚠️

**⚠️ CRITICO:** Senza questo, Brainery NON funziona. Necessario sia per sviluppatore che utente finale.

**Provider consigliato: iFlow Platform (FREE)**

iFlow offre un free tier con accesso a modelli LLM potenti:
- `glm-4.6` (200K context, 128K output) - Consigliato
- `qwen3-max` (256K context)
- `deepseek-v3` (128K context)
- `kimi-k2` (128K context)

**Come registrarsi (SENZA numero telefonico cinese):**

1. **Registrazione:**
   - Usa questo link diretto: https://iflow.cn/oauth?redirect=https%3A%2F%2Fvibex.iflow.cn%2Fsession%2Fsso_login
   - Questo bypassa la richiesta del numero telefonico cinese
   - Registrati con email

2. **Ottieni API Key:**
   - Link diretto: https://platform.iflow.cn/profile?tab=apiKey
   - Clicca "Create API Key"
   - **Copia e salva la chiave** - ti servirà dopo
   - Formato: `sk-xxxxxxxxxxxxxxxxxxxxxxxxxx`

3. **⚠️ Trucco importante:**
   - Se il sito è in inglese, il menu utente potrebbe essere nascosto
   - Usa il link diretto sopra per accedere alle impostazioni API

**Alternativa (a pagamento):**
- OpenAI: https://platform.openai.com/api-keys
- Anthropic: https://console.anthropic.com/
- OpenRouter: https://openrouter.ai/keys

#### Software da Installare

Dovrai installare manualmente:

**Tutti i sistemi operativi:**
- Docker Desktop
- Git
- Node.js (versione LTS, es. v22)
- Python 3.11+
- ~~Deno~~ (NON necessario - yt-dlp moderno usa Python nativo)

**Tool aggiuntivi:**
- poppler/pdftotext (per estrazione testo da PDF)

**Tempo stimato:** ~30-45 minuti la prima volta (include download di ~13GB di immagini Docker).

**Nota:** Le istruzioni dettagliate di installazione saranno nella Sezione 4 "Setup iniziale".

#### Conoscenze Richieste

| Cosa serve sapere | Livello |
|-------------------|---------|
| **Aprire un terminale** | Essenziale |
| **Seguire istruzioni passo-passo** | Essenziale |
| **Copiare/incollare comandi** | Essenziale |
| **Programmazione** | ❌ NON necessaria |
| **Docker** | ❌ NON necessaria (script automatico) |
| **Git** | ❌ NON necessaria (comandi forniti) |

**In pratica:** Se sai aprire un terminale e seguire istruzioni, sei pronto.

#### Permessi e Privilegi

| Sistema | Quando servono privilegi Admin | Quando NON servono |
|---------|-------------------------------|-------------------|
| **Windows** | Solo durante installazione software | Uso quotidiano di Brainery |
| **Linux/macOS** | Solo per installare Docker (`sudo`) | Uso quotidiano di Brainery |

**Nota:** Dopo l'installazione iniziale, NON servono più privilegi amministratore.

#### Riepilogo Checklist Pre-Installazione

Prima di procedere, assicurati di avere:

- [ ] Account GitHub creato
- [ ] Account Docker Hub creato (username annotato)
- [ ] Account iFlow Platform creato (API key salvata)
- [ ] Almeno 15GB spazio disco libero
- [ ] Almeno 8GB RAM (12GB consigliati)
- [ ] Connessione internet stabile
- [ ] Accesso amministratore (solo per installazione)

**Se hai tutto, sei pronto per il Setup iniziale (Sezione 4)!**

---

## PARTE 2: QUICK START

### 4. Setup iniziale

Questa sezione distingue tra **Sviluppatore** (tu che crei Brainery) e **Utente Finale** (chi userà Brainery).

#### Chi ha bisogno di cosa?

**SOFTWARE (necessari a tutti):**
- Docker Desktop
- Git
- Node.js (LTS, es. v22)
- Python 3.11+
- ~~Deno~~ (non più necessario)
- ffmpeg (codec video/audio)
- poppler (pdftotext)

**ACCOUNT (solo sviluppatore):**
- Account Docker Hub
- Account GitHub
- GitHub CLI (opzionale ma consigliato)

**ACCOUNT (tutti):**
- Account iFlow (o altro provider LLM)

---

## Setup Base (Tutti)

### 1. Installare Docker Desktop

**Link ufficiale:** https://www.docker.com/products/docker-desktop/

**Installazione rapida:**

**Windows:**
```bash
winget install Docker.DockerDesktop
```

**macOS:**
```bash
brew install --cask docker
```

**Linux (Ubuntu/Debian):**
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Riavvia la sessione per applicare i permessi
```

**Raccomandazioni:**
- Abilita "Start Docker Desktop when you log in" nelle impostazioni (opzionale)
- Su Windows, abilita WSL 2 se richiesto durante l'installazione
- Riavvia il sistema dopo l'installazione se richiesto

**Verifica installazione:**
```bash
docker --version
docker ps
```

Output atteso:
```
Docker version 24.x.x, build xxxxx
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**Per istruzioni dettagliate:** https://docs.docker.com/get-docker/

---

## Setup Sviluppatore

Se sei lo **sviluppatore** di Brainery, segui anche questi passaggi.

### 2. Installare Git

**Link ufficiale:** https://git-scm.com/downloads

**Installazione rapida:**

**Windows:**
```bash
winget install Git.Git
```

**macOS:**
```bash
brew install git
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install git
```

**Verifica installazione:**
```bash
git --version
```

Output atteso: `git version 2.x.x`

**Per istruzioni dettagliate:** https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

### 3. Installare Node.js (LTS)

**Link ufficiale:** https://nodejs.org/

Scarica e installa la versione **LTS** (Long Term Support, es. v22.x).

**Installazione rapida:**

**Windows:**
```bash
winget install OpenJS.NodeJS.LTS
```

**macOS:**
```bash
brew install node@22
```

**Linux (Ubuntu/Debian):**
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Verifica installazione:**
```bash
node --version
npm --version
```

Output atteso:
```
v22.x.x
10.x.x
```

**Per istruzioni dettagliate:** https://nodejs.org/en/download/package-manager

### 4. Installare Python 3.11+

**Link ufficiale:** https://www.python.org/downloads/

**Installazione rapida:**

**Windows:**
```bash
winget install Python.Python.3.12
```

**macOS:**
```bash
brew install python@3.12
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install python3.12 python3-pip
```

**Verifica installazione:**
```bash
python --version
# oppure
python3 --version
```

Output atteso: `Python 3.12.x`

**Per istruzioni dettagliate:** https://www.python.org/downloads/

### 5. ~~Installare Deno~~ (NON NECESSARIO)

**Nota:** Versioni precedenti di yt-dlp richiedevano Deno per YouTube, ma le versioni moderne (2024+) usano estrattori Python nativi. **Deno NON è più richiesto.**

Se stai seguendo guide vecchie che menzionano Deno, puoi **saltare questa sezione**

### 6. Installare ffmpeg

Necessario per elaborazione video/audio (usato da yt-dlp).

**Installazione rapida:**

**Windows:**
```bash
winget install Gyan.FFmpeg
```

**macOS:**
```bash
brew install ffmpeg
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install ffmpeg
```

**Verifica installazione:**
```bash
ffmpeg -version
```

Output atteso: `ffmpeg version x.x.x`

### 7. Installare poppler (pdftotext)

Necessario per estrarre testo da file PDF.

**Installazione rapida:**

**Windows:**
```bash
winget install poppler
```

**macOS:**
```bash
brew install poppler
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install poppler-utils
```

**Verifica installazione:**
```bash
pdftotext -v
```

Output atteso: `pdftotext version x.x.x`

### 8. Configurare Docker Hub (Solo Sviluppatore)

Se sei lo sviluppatore, devi fare login per pubblicare immagini.

**Login Docker Hub CLI:**

```bash
docker login
```

Ti verrà chiesto:
- **Username:** Il tuo username Docker Hub (es: `tapiocapioca`)
- **Password:** La tua password o Personal Access Token

**Verifica login:**
```bash
docker info | grep Username
```

Output atteso: `Username: tapiocapioca`

**Utente finale:** Puoi saltare questo passaggio.

### 9. Configurare GitHub CLI (Solo Sviluppatore - Opzionale)

**Link ufficiale:** https://cli.github.com/

**Installazione rapida:**

**Windows:**
```bash
winget install GitHub.cli
```

**macOS:**
```bash
brew install gh
```

**Linux (Ubuntu/Debian):**
```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt-get update
sudo apt-get install gh
```

**Configurazione:**
```bash
gh auth login
```

Segui le istruzioni interattive (scegli HTTPS o SSH, browser login consigliato).

**Verifica:**
```bash
gh auth status
```

Output atteso: `✓ Logged in to github.com as YourUsername`

**Per istruzioni dettagliate:** https://cli.github.com/manual/installation

### 10. Salvare API Key iFlow

Hai già ottenuto la tua API key iFlow nella Sezione 3.

**Salvala in un posto sicuro:**
- Password manager (consigliato: Bitwarden, 1Password, LastPass)
- File di testo cifrato
- File `.env` locale (⚠️ NON committare su Git)

Formato chiave: `sk-xxxxxxxxxxxxxxxxxxxxxxxxxx`

Ti servirà per configurare AnythingLLM.

---

## Riepilogo Setup Completato

Dopo aver completato il setup, dovresti avere tutto installato:

### ✅ Checklist Completa:

**Software:**
- [ ] Docker Desktop installato e funzionante (`docker --version`)
- [ ] Git installato (`git --version`)
- [ ] Node.js LTS installato (`node --version`)
- [ ] Python 3.11+ installato (`python --version`)
- [ ] ~~Deno~~ (non più necessario per yt-dlp moderno)
- [ ] ffmpeg installato (`ffmpeg -version`)
- [ ] poppler/pdftotext installato (`pdftotext -v`)

**Account e Configurazione:**
- [ ] API Key iFlow salvata in sicurezza
- [ ] Docker Hub login effettuato (`docker info | grep Username`) - **solo sviluppatore**
- [ ] GitHub CLI configurato (`gh auth status`) - **solo sviluppatore, opzionale**

**Ora sei pronto per la Checklist Implementazione (Sezione 5)!**

### 5. Checklist implementazione

Questa sezione ti guida passo-passo nella creazione di Brainery, partendo dai container fino alla skill finale.

**Prerequisito:** Devi aver completato la Sezione 4 (Setup iniziale).

---

> ⚠️ **IMPORTANTE - Sostituzione Username Docker Hub**
>
> In TUTTO questo documento, vedrai `tapiocapioca` negli esempi (Docker images, GitHub Actions, docker-compose).
>
> **DEVI sostituire `tapiocapioca` con il TUO username Docker Hub in:**
> - `docker-compose.yml` (4 immagini)
> - `.github/workflows/build-containers.yml` (tag Docker)
> - Comandi `docker build -t` / `docker push`
> - Variabile `DOCKER_USERNAME` nei GitHub Secrets
>
> **Esempio:** Se il tuo username Docker Hub è `johndoe`, usa:
> - `docker.io/johndoe/crawl4ai:latest` (NON `tapiocapioca/crawl4ai:latest`)
> - `docker build -t johndoe/whisper-server .`
> - `gh secret set DOCKER_USERNAME --body "johndoe"`
>
> **Eccezione:** Se usi le immagini pre-built senza modifiche, puoi usare `tapiocapioca/...` direttamente (Sezione 6, end-user).

---

## FASE 1: Repository brainery-containers

Iniziamo creando il repository per i container Docker.

### Passo 1: Creare repository GitHub

**Comando GitHub CLI:**
```bash
gh repo create brainery-containers --public --description "Docker containers for Brainery RAG system"
cd brainery-containers
```

**Oppure via web:**
1. Vai su https://github.com/new
2. Nome: `brainery-containers`
3. Descrizione: "Docker containers for Brainery RAG system"
4. Visibilità: **Public**
5. Clicca "Create repository"

**Clone locale (se creato via web):**
```bash
# Sostituisci YOUR_GITHUB_USERNAME con il tuo username GitHub
git clone https://github.com/YOUR_GITHUB_USERNAME/brainery-containers.git
cd brainery-containers
```

**Se creato via CLI:** Sei già nella directory `brainery-containers`, procedi direttamente.

### Passo 2: Struttura directory

Crea questa struttura:

```
brainery-containers/
├── .github/
│   └── workflows/
│       └── build-and-push.yml    # GitHub Actions
├── dockerfiles/
│   ├── crawl4ai/
│   │   └── Dockerfile
│   ├── anythingllm/
│   │   └── Dockerfile
│   ├── yt-dlp-server/
│   │   ├── Dockerfile
│   │   ├── server.py
│   │   └── requirements.txt
│   └── whisper-server/
│       ├── Dockerfile
│       ├── server.py
│       └── requirements.txt
├── docker-compose.yml            # Per utenti finali
├── .gitignore
├── README.md
└── VERSION
```

**Comandi:**
```bash
mkdir -p .github/workflows
mkdir -p dockerfiles/{crawl4ai,anythingllm,yt-dlp-server,whisper-server}
touch docker-compose.yml .gitignore README.md VERSION
```

**Spiegazione:**
- `.github/workflows/`: GitHub Actions per build automatico
- `dockerfiles/`: Dockerfile per ogni container
- `docker-compose.yml`: Setup semplificato per utenti finali
- `VERSION`: Versione corrente (es: `0.1.0` per il primo rilascio)

### Passo 3: Dockerfile per ogni container

#### 3.1 Crawl4AI (usare immagine ufficiale)

**File:** `dockerfiles/crawl4ai/Dockerfile`

```dockerfile
# Usa immagine ufficiale Crawl4AI
FROM unclecode/crawl4ai:latest

# Nessuna modifica necessaria
# L'immagine ufficiale è già ottimizzata
```

**Nota:** Crawl4AI ha già un'immagine Docker ufficiale ben mantenuta. Non serve personalizzarla.

#### 3.2 AnythingLLM (usare immagine ufficiale)

**File:** `dockerfiles/anythingllm/Dockerfile`

```dockerfile
# Usa immagine ufficiale AnythingLLM
FROM mintplexlabs/anythingllm:latest

# Configurazione storage directory
ENV STORAGE_DIR=/app/server/storage

# Nessuna altra modifica necessaria
```

**Nota:** Anche AnythingLLM ha un'immagine ufficiale stabile.

#### 3.3 yt-dlp-server (custom)

**File:** `dockerfiles/yt-dlp-server/Dockerfile`

```dockerfile
FROM python:3.12-slim

# Installa yt-dlp e dipendenze
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    pip install --no-cache-dir yt-dlp fastapi uvicorn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copia server
WORKDIR /app
COPY server.py .
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Esponi porta
EXPOSE 8501

# Avvia server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8501"]
```

**Best practices:**
- `python:3.12-slim`: Immagine leggera
- `--no-cache-dir`: Riduce dimensione immagine
- `apt-get clean`: Rimuove cache non necessaria
- Installa `ffmpeg` per processing video/audio

**File:** `dockerfiles/yt-dlp-server/requirements.txt`

```
fastapi==0.109.0
uvicorn[standard]==0.27.0
yt-dlp>=2024.1.0
```

**File:** `dockerfiles/yt-dlp-server/server.py` (struttura base)

```python
from fastapi import FastAPI
import yt_dlp

app = FastAPI()

@app.get("/health")
async def health():
    return {"status": "ok", "service": "yt-dlp-server"}

@app.post("/transcript")
async def get_transcript(url: str):
    # Logica per estrarre trascrizioni YouTube
    # Implementazione completa nella Sezione 8
    pass
```

#### 3.4 whisper-server (custom)

**File:** `dockerfiles/whisper-server/Dockerfile`

```dockerfile
FROM python:3.12-slim

# Installa dipendenze sistema
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Installa Whisper e FastAPI
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia server
COPY server.py .

# Directory per modelli (volume)
RUN mkdir -p /app/models

# Esponi porta
EXPOSE 8502

# Avvia server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8502"]
```

**File:** `dockerfiles/whisper-server/requirements.txt`

```
fastapi==0.109.0
uvicorn[standard]==0.27.0
openai-whisper>=20231117
torch>=2.1.0
```

**File:** `dockerfiles/whisper-server/server.py` (struttura base)

```python
from fastapi import FastAPI
import whisper

app = FastAPI()

# Carica modello Whisper all'avvio
model = whisper.load_model("base")

@app.get("/health")
async def health():
    return {"status": "ok", "service": "whisper-server"}

@app.post("/transcribe")
async def transcribe_audio(audio_url: str):
    # Logica per trascrivere audio
    # Implementazione completa nella Sezione 8
    pass
```

**Best practices Dockerfile (applicate sopra):**
- Usa immagini `slim` per ridurre dimensione
- Multi-stage build (se necessario per compilazione)
- Layer caching: comandi che cambiano raramente vanno prima
- Rimuovi cache apt/pip con `--no-cache-dir`
- Non usare `latest` tag in produzione (usa versioni specifiche)
- Esponi solo porte necessarie
- Esegui come utente non-root (opzionale ma consigliato)

### Passo 4: docker-compose.yml per utenti finali

**File:** `docker-compose.yml`

```yaml
version: '3.8'

services:
  crawl4ai:
    image: tapiocapioca/crawl4ai:latest
    container_name: crawl4ai
    ports:
      - "11235:11235"
    volumes:
      - crawl4ai-data:/app/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11235/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  anythingllm:
    image: tapiocapioca/anythingllm:latest
    container_name: anythingllm
    ports:
      - "3001:3001"
    environment:
      - STORAGE_DIR=/app/server/storage
    volumes:
      - anythingllm-storage:/app/server/storage
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/api/ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  yt-dlp-server:
    image: tapiocapioca/yt-dlp-server:latest
    container_name: yt-dlp-server
    ports:
      - "8501:8501"
    volumes:
      - ytdlp-cache:/app/temp
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8501/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  whisper-server:
    image: tapiocapioca/whisper-server:latest
    container_name: whisper-server
    ports:
      - "8502:8502"
    volumes:
      - whisper-models:/app/models
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8502/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  crawl4ai-data:
  anythingllm-storage:
  ytdlp-cache:
  whisper-models:
```

**Spiegazione:**
- `version: '3.8'`: Versione Docker Compose
- `restart: unless-stopped`: Container ripartono automaticamente dopo reboot
- `healthcheck`: Verifica che il container sia funzionante
- `volumes`: Named volumes per persistenza dati
- Utenti finali possono fare: `docker-compose up -d`

### Passo 5: GitHub Actions workflow

**File:** `.github/workflows/build-and-push.yml`

```yaml
name: Build and Push Docker Images

on:
  push:
    branches:
      - main
    tags:
      - 'v*'
  pull_request:
    branches:
      - main
  schedule:
    # Rebuild settimanale ogni lunedì alle 00:00
    - cron: '0 0 * * 1'

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [crawl4ai, anythingllm, yt-dlp-server, whisper-server]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract version
        id: version
        run: |
          if [[ $GITHUB_REF == refs/tags/* ]]; then
            echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
          else
            echo "VERSION=latest" >> $GITHUB_OUTPUT
          fi

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: ./dockerfiles/${{ matrix.service }}
          push: true
          tags: |
            tapiocapioca/${{ matrix.service }}:${{ steps.version.outputs.VERSION }}
            tapiocapioca/${{ matrix.service }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**Spiegazione:**
- **Trigger**: Push su main, tag versione, schedule settimanale
- **Matrix build**: Compila tutti i 4 container in parallelo
- **Secrets**: Usa GitHub Secrets per credenziali Docker Hub
- **Cache**: Velocizza build successive con GitHub Actions cache
- **Versioning**: Tag con versione se rilascio, altrimenti `latest`

**Configurare secrets GitHub:**
**Prima, genera Docker Hub Access Token:**

⚠️ **NON usare la tua password Docker Hub** - usa un Access Token invece (best practice security).

1. Vai su https://hub.docker.com/settings/security
2. Clicca "New Access Token"
3. Description: `github-actions-brainery`
4. Access permissions: **Read & Write**
5. Clicca "Generate"
6. **Copia il token** (formato: `dckr_pat_xxxxxxxxxxxxx`) - non lo vedrai più!

**Poi, configura GitHub Secrets:**

Via web:
```bash
# Vai su repository GitHub > Settings > Secrets and variables > Actions
# Clicca "New repository secret" due volte per aggiungere:
# 1. DOCKER_USERNAME: tapiocapioca (o il tuo username)
# 2. DOCKER_PASSWORD: dckr_pat_xxxxxxxxxxxxx (il token copiato sopra)
```

O via CLI (più veloce):
```bash
gh secret set DOCKER_USERNAME --body "tapiocapioca"
gh secret set DOCKER_PASSWORD --body "dckr_pat_xxxxxxxxxxxxx"
```

**Verifica secrets configurati:**
```bash
gh secret list
# Output atteso:
# DOCKER_USERNAME  Updated 2026-01-07
# DOCKER_PASSWORD  Updated 2026-01-07
```

### Passo 6: File aggiuntivi

**File:** `.gitignore`

```
# Python
__pycache__/
*.py[cod]
*$py.class
.venv/
venv/

# Docker
*.log

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
```

**File:** `VERSION`

```
0.1.0
```

**File:** `README.md` (struttura)

```markdown
# Brainery Containers

Docker containers per il sistema RAG Brainery.

## Containers

- **crawl4ai**: Web scraping
- **anythingllm**: RAG database
- **yt-dlp-server**: YouTube transcripts
- **whisper-server**: Audio transcription

## Quick Start

```bash
docker-compose up -d
```

## Images disponibili

Tutte le immagini sono su Docker Hub:
- `tapiocapioca/crawl4ai:latest`
- `tapiocapioca/anythingllm:latest`
- `tapiocapioca/yt-dlp-server:latest`
- `tapiocapioca/whisper-server:latest`

## Versioning

Usa Semantic Versioning: `v1.0.0`, `v1.1.0`, ecc.
```

### Passo 7: Testing locale

Prima di committare, testa i container localmente:

```bash
# Build locale
cd dockerfiles/yt-dlp-server
docker build -t yt-dlp-server:test .

cd ../whisper-server
docker build -t whisper-server:test .

# Test avvio
docker run -d --name test-ytdlp -p 8501:8501 yt-dlp-server:test
docker run -d --name test-whisper -p 8502:8502 whisper-server:test

# Verifica health
curl http://localhost:8501/health
curl http://localhost:8502/health

# Cleanup
docker stop test-ytdlp test-whisper
docker rm test-ytdlp test-whisper
```

**Cosa verificare:**
- Container si avvia senza errori
- Endpoint `/health` risponde
- Nessun warning/errore nei log (`docker logs <container>`)

### Passo 8: Commit e push

```bash
git add .
git commit -m "Initial commit: Docker containers setup"
git push origin main
```

### Passo 9: Verificare GitHub Actions

1. Vai su repository GitHub
2. Tab "Actions"
3. Verifica che il workflow sia partito
4. Attendi completamento (5-15 minuti)
5. Verifica su Docker Hub: https://hub.docker.com/u/tapiocapioca

### Passo 10: Strategia versioning e aggiornamenti

**Semantic Versioning:**
- `v1.0.0`: Prima release stabile
- `v1.1.0`: Nuove funzionalità (backward compatible)
- `v1.0.1`: Bug fix
- `v2.0.0`: Breaking changes

**Creare una release:**
```bash
# Aggiorna VERSION file
echo "1.1.0" > VERSION

# Commit
git add VERSION
git commit -m "Bump version to 1.1.0"

# Tag
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin v1.1.0
```

GitHub Actions builderà automaticamente le immagini con tag `v1.1.0` e `latest`.

**Gestione aggiornamenti utenti:**
- Utenti con `latest`: Aggiornamento automatico (`docker-compose pull`)
- Utenti con versione fissa: Aggiornamento manuale

---

## FASE 2: Repository brainery (skill)

Ora creiamo la skill Claude Code.

### Passo 11: Creare repository GitHub

**Comando GitHub CLI:**
```bash
gh repo create brainery --public --description "Claude Code skill for web content RAG"
cd brainery
```

### Passo 12: Struttura skill

```
brainery/
├── skill.json              # Metadata skill
├── prompt.md               # Istruzioni principale
├── docs/
│   ├── installation.md     # Guida installazione
│   └── usage.md            # Esempi d'uso
├── .gitignore
└── README.md
```

**Comandi:**
```bash
mkdir docs
touch skill.json prompt.md docs/installation.md docs/usage.md README.md .gitignore
```

### Passo 13: File skill.json

**File:** `skill.json`

```json
{
  "name": "brainery",
  "version": "1.0.0",
  "description": "Import web content (pages, YouTube, PDFs) into local RAG system",
  "author": "Tapiocapioca",
  "repository": "https://github.com/Tapiocapioca/brainery",
  "main": "prompt.md",
  "dependencies": {
    "containers": "tapiocapioca/brainery-containers",
    "mcp_servers": [
      "anythingllm",
      "duckduckgo-search",
      "yt-dlp",
      "crawl4ai"
    ]
  },
  "tags": ["rag", "youtube", "pdf", "web-scraping"]
}
```

**Spiegazione:**
- `main`: File con le istruzioni per Claude
- `dependencies`: Container e MCP servers necessari
- `tags`: Per ricerca skill

### Passo 14: File prompt.md (istruzioni skill)

**File:** `prompt.md` (struttura base)

```markdown
# Brainery Skill

You are using the Brainery skill to import web content into a local RAG system.

## Available Tools

### MCP Servers
- **anythingllm**: Query and manage RAG database
- **crawl4ai**: Scrape web pages
- **yt-dlp**: Download YouTube transcripts
- **duckduckgo-search**: Web search

## Workflow

When user asks to import content:

1. Identify content type (YouTube, web page, PDF)
2. Use appropriate tool to fetch content
3. Store in AnythingLLM workspace
4. Confirm import success

## Examples

**Import YouTube video:**
```
User: Import this YouTube video https://youtube.com/watch?v=...
Assistant:
1. Use yt-dlp to get transcript
2. Store in AnythingLLM
3. Confirm
```

(Continua con esempi dettagliati...)
```

**Nota:** Le istruzioni complete saranno nella Sezione 8 "API endpoints".

### Passo 15: Documentazione

**File:** `docs/installation.md`

```markdown
# Installazione Brainery

## Prerequisiti

Vedi [BRAINERY_CONTEXT.md Sezione 3](link-al-documento)

## Installazione

1. Installa container:
```bash
docker-compose up -d
```

2. Configura AnythingLLM:

   **a) Accesso iniziale:**
   - Apri http://localhost:3001 nel browser
   - Primo accesso: crea account admin (username/password locale)
   - Salta l'onboarding wizard (useremo configurazione custom)

   **b) Configura LLM Provider (iFlow):**
   - Sidebar → ⚙️ Settings → LLM Preference
   - Provider: Seleziona "Generic OpenAI"
   - Base URL: `https://api.iflow.cn/v1`
   - API Key: Incolla la tua iFlow API key (`sk-xxx...`)
   - Model: `glm-4.6` (o `glm-4-flash` per velocità)
   - Token limit: `8192`
   - Temperature: `0.7` (default)
   - Clicca "Save changes"

   **c) Configura Embedding Provider (locale):**
   - Settings → Embedding Preference
   - Provider: "AnythingLLM Embedder" (default, gratuito)
   - Modello: `nomic-embed-text` (default)
   - Chunk size: `1000` (default)
   - Overlap: `20` (default)

   **d) Genera API Key per MCP:**
   - Settings → API Keys
   - Clicca "Generate New API Key"
   - Description: "MCP Server"
   - Copia la chiave generata (formato: `ALML-xxx...`)
   - **Salvala in sicurezza** - servirà per configurare l'MCP server

   **e) Verifica configurazione:**
   - Crea workspace test: Sidebar → "New Workspace" → nome "test"
   - Vai in chat, scrivi "Hello, can you respond?"
   - Se ricevi risposta → configurazione OK ✅
   - Se errore 401/403 → verifica API key iFlow
   - Se errore 500 → controlla logs: `docker logs anythingllm`

3. Installa skill:
```bash
# Clona repository
git clone https://github.com/Tapiocapioca/brainery.git

# Installa nella directory skills di Claude Code
cp -r brainery ~/.claude/skills/
```

4. Restart Claude Code
```

**File:** `docs/usage.md`

```markdown
# Esempi d'uso Brainery

## Importare video YouTube

```
User: Import this YouTube video about Docker
Assistant: [usa yt-dlp + anythingllm]
```

## Importare articolo web

```
User: Import this article https://example.com/article
Assistant: [usa crawl4ai + anythingllm]
```

(Continua con esempi...)
```

### Passo 16: README.md principale

**File:** `README.md`

```markdown
# Brainery

Claude Code skill per importare contenuti web in un sistema RAG locale.

## Features

- Import YouTube videos (transcripts)
- Import web pages
- Import PDFs
- Local RAG (nessun costo cloud)

## Quick Start

Vedi [Installation Guide](docs/installation.md)

## Documentation

- [BRAINERY_CONTEXT.md](link): Guida completa
- [Usage Examples](docs/usage.md)

## Requirements

- Docker containers: [brainery-containers](https://github.com/Tapiocapioca/brainery-containers)
- MCP servers: anythingllm, crawl4ai, yt-dlp, duckduckgo-search

## License

MIT
```

### Passo 17: Testing locale skill

```bash
# Copia skill in directory Claude Code
cp -r . ~/.claude/skills/brainery

# Restart Claude Code

# Test comandi base
# In Claude Code:
# "Use brainery to import https://example.com"
```

### Passo 18: Commit e pubblicazione

```bash
git add .
git commit -m "Initial commit: Brainery skill"
git push origin main

# Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

---

## Riepilogo Checklist Implementazione

### ✅ FASE 1: brainery-containers
- [ ] Repository GitHub creato
- [ ] Struttura directory completa
- [ ] Dockerfiles per 4 container (crawl4ai, anythingllm, yt-dlp, whisper)
- [ ] docker-compose.yml configurato
- [ ] GitHub Actions workflow setup
- [ ] Secrets Docker Hub configurati
- [ ] Test build locale OK
- [ ] Push su GitHub e verifica Actions
- [ ] Immagini pubblicate su Docker Hub
- [ ] Versioning strategy definita (semver)

### ✅ FASE 2: brainery skill
- [ ] Repository GitHub creato
- [ ] Struttura skill completa
- [ ] skill.json configurato
- [ ] prompt.md con istruzioni
- [ ] Documentazione (installation.md, usage.md)
- [ ] README.md completo
- [ ] Test locale skill OK
- [ ] Push su GitHub
- [ ] Release v1.0.0 taggata

**Ora sei pronto per testare che tutto funzioni (Sezione 6)!**

### 6. Test che funziona

Questa sezione ti guida nel verificare che l'implementazione funzioni correttamente end-to-end.

**Prerequisiti:**
- Completata Sezione 5 (Checklist implementazione)
- Container in esecuzione (`docker ps` mostra 4 container)
- **curl installato e nel PATH** (necessario per gli script di test)

**Verifica curl:**
```bash
curl --version
```

**Se curl non è installato:**
- **Windows:** Incluso in Windows 10 1803+. Se manca: `winget install curl.curl`
- **macOS:** Pre-installato
- **Linux:** `sudo apt install curl` (Debian/Ubuntu) o `sudo yum install curl` (RHEL/CentOS)

---

## Script di Test Automatico

Per semplificare il testing, usa questi script automatici:

### Windows (PowerShell)

**File:** `test-brainery.ps1`

```powershell
# Test Brainery - Script automatico
Write-Host "`n=== BRAINERY TEST SUITE ===" -ForegroundColor Cyan
Write-Host "Testing all components...`n" -ForegroundColor Cyan

$passed = 0
$failed = 0

function Test-Command {
    param($Name, $Command)
    Write-Host "Testing: $Name... " -NoNewline
    try {
        $result = Invoke-Expression $Command 2>$null
        if ($LASTEXITCODE -eq 0 -or $result) {
            Write-Host "✅ PASS" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ FAIL" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ FAIL" -ForegroundColor Red
        return $false
    }
}

# TEST 1: Docker Containers
Write-Host "`n--- LEVEL 1: Docker Containers ---" -ForegroundColor Yellow
if (Test-Command "Docker running" "docker ps") { $passed++ } else { $failed++ }
if (Test-Command "crawl4ai container" "docker ps -q -f name=crawl4ai") { $passed++ } else { $failed++ }
if (Test-Command "anythingllm container" "docker ps -q -f name=anythingllm") { $passed++ } else { $failed++ }
if (Test-Command "yt-dlp-server container" "docker ps -q -f name=yt-dlp-server") { $passed++ } else { $failed++ }
if (Test-Command "whisper-server container" "docker ps -q -f name=whisper-server") { $passed++ } else { $failed++ }

# TEST 2: API Endpoints
Write-Host "`n--- LEVEL 2: API Endpoints ---" -ForegroundColor Yellow
if (Test-Command "crawl4ai health" "curl -s http://localhost:11235/health") { $passed++ } else { $failed++ }
if (Test-Command "anythingllm health" "curl -s http://localhost:3001/api/ping") { $passed++ } else { $failed++ }
if (Test-Command "yt-dlp health" "curl -s http://localhost:8501/health") { $passed++ } else { $failed++ }
if (Test-Command "whisper health" "curl -s http://localhost:8502/health") { $passed++ } else { $failed++ }

# TEST 3: Volumes
Write-Host "`n--- LEVEL 3: Docker Volumes ---" -ForegroundColor Yellow
if (Test-Command "crawl4ai-data volume" "docker volume inspect crawl4ai-data") { $passed++ } else { $failed++ }
if (Test-Command "anythingllm-storage volume" "docker volume inspect anythingllm-storage") { $passed++ } else { $failed++ }
if (Test-Command "ytdlp-cache volume" "docker volume inspect ytdlp-cache") { $passed++ } else { $failed++ }
if (Test-Command "whisper-models volume" "docker volume inspect whisper-models") { $passed++ } else { $failed++ }

# Summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "Total:  $($passed + $failed)`n"

if ($failed -eq 0) {
    Write-Host "🎉 All tests passed! Brainery is ready to use." -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Some tests failed. Check the output above." -ForegroundColor Yellow
    exit 1
}
```

**Esecuzione:**
```powershell
.\test-brainery.ps1
```

### Linux/macOS (Bash)

**File:** `test-brainery.sh`

```bash
#!/bin/bash

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}\n=== BRAINERY TEST SUITE ===${NC}"
echo -e "${CYAN}Testing all components...\n${NC}"

passed=0
failed=0

test_command() {
    local name=$1
    local command=$2
    echo -n "Testing: $name... "

    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((passed++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((failed++))
    fi
}

# TEST 1: Docker Containers
echo -e "\n${YELLOW}--- LEVEL 1: Docker Containers ---${NC}"
test_command "Docker running" "docker ps"
test_command "crawl4ai container" "docker ps -q -f name=crawl4ai | grep -q ."
test_command "anythingllm container" "docker ps -q -f name=anythingllm | grep -q ."
test_command "yt-dlp-server container" "docker ps -q -f name=yt-dlp-server | grep -q ."
test_command "whisper-server container" "docker ps -q -f name=whisper-server | grep -q ."

# TEST 2: API Endpoints
echo -e "\n${YELLOW}--- LEVEL 2: API Endpoints ---${NC}"
test_command "crawl4ai health" "curl -sf http://localhost:11235/health"
test_command "anythingllm health" "curl -sf http://localhost:3001/api/ping"
test_command "yt-dlp health" "curl -sf http://localhost:8501/health"
test_command "whisper health" "curl -sf http://localhost:8502/health"

# TEST 3: Volumes
echo -e "\n${YELLOW}--- LEVEL 3: Docker Volumes ---${NC}"
test_command "crawl4ai-data volume" "docker volume inspect crawl4ai-data"
test_command "anythingllm-storage volume" "docker volume inspect anythingllm-storage"
test_command "ytdlp-cache volume" "docker volume inspect ytdlp-cache"
test_command "whisper-models volume" "docker volume inspect whisper-models"

# Summary
echo -e "\n${CYAN}=== TEST SUMMARY ===${NC}"
echo -e "${GREEN}Passed: $passed${NC}"
echo -e "${RED}Failed: $failed${NC}"
echo -e "Total:  $((passed + failed))\n"

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Brainery is ready to use.${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check the output above.${NC}"
    exit 1
fi
```

**Esecuzione:**
```bash
chmod +x test-brainery.sh
./test-brainery.sh
```

---

## Test Manuali Dettagliati

Se preferisci testare manualmente o lo script fallisce, segui questi test passo-passo.

### LIVELLO 1: Test Container Docker

#### Test 1.1: Verificare container running

**Comando:**
```bash
docker ps
```

**Output atteso:**
```
CONTAINER ID   IMAGE                              STATUS         PORTS                    NAMES
xxxxx          tapiocapioca/crawl4ai:latest      Up 5 minutes   0.0.0.0:11235->11235/tcp crawl4ai
xxxxx          tapiocapioca/anythingllm:latest   Up 5 minutes   0.0.0.0:3001->3001/tcp   anythingllm
xxxxx          tapiocapioca/yt-dlp-server:latest Up 5 minutes   0.0.0.0:8501->8501/tcp   yt-dlp-server
xxxxx          tapiocapioca/whisper-server:latest Up 5 minutes  0.0.0.0:8502->8502/tcp   whisper-server
```

**✅ PASS:** Tutti e 4 i container sono presenti con STATUS "Up"
**❌ FAIL:** Container mancanti o con STATUS "Exited"

**Se fallisce:**
```bash
# Verifica container stopped
docker ps -a

# Avvia container fermi
docker start crawl4ai anythingllm yt-dlp-server whisper-server

# Se container non esistono, avvia con docker-compose
docker-compose up -d
```

#### Test 1.2: Verificare healthcheck

**Comando:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

**Output atteso:**
```
NAMES             STATUS
crawl4ai          Up 5 minutes (healthy)
anythingllm       Up 5 minutes (healthy)
yt-dlp-server     Up 5 minutes (healthy)
whisper-server    Up 5 minutes (healthy)
```

**✅ PASS:** Tutti mostrano "(healthy)"
**❌ FAIL:** Qualcuno mostra "(unhealthy)" o "(health: starting)"

**Se fallisce:**
Attendi 1-2 minuti e riprova. Se persiste:
```bash
# Verifica log per errori
docker logs crawl4ai
docker logs anythingllm
docker logs yt-dlp-server
docker logs whisper-server
```

#### Test 1.3: Verificare volumi Docker

**Comando:**
```bash
docker volume ls | grep -E "crawl4ai-data|anythingllm-storage|ytdlp-cache|whisper-models"
```

**Output atteso:**
```
local     crawl4ai-data
local     anythingllm-storage
local     ytdlp-cache
local     whisper-models
```

**✅ PASS:** Tutti e 4 i volumi esistono
**❌ FAIL:** Volumi mancanti

**Se fallisce:**
I volumi vengono creati automaticamente da docker-compose. Se mancano:
```bash
docker-compose down
docker-compose up -d
```

---

### LIVELLO 2: Test API Endpoints

#### Test 2.1: crawl4ai health endpoint

**Comando:**
```bash
curl http://localhost:11235/health
```

**Output atteso:**
```json
{"status":"ok"}
```

**✅ PASS:** Risposta JSON con status "ok"
**❌ FAIL:** Errore connessione, timeout, o risposta diversa

**Se fallisce:**
```bash
# Verifica container
docker logs crawl4ai --tail 50

# Verifica porta
netstat -an | grep 11235  # Windows: netstat -ano | findstr 11235
```

#### Test 2.2: anythingllm health endpoint

**Comando:**
```bash
curl http://localhost:3001/api/ping
```

**Output atteso:**
```json
{"online":true}
```

**✅ PASS:** Risposta JSON con online=true
**❌ FAIL:** Errore connessione o online=false

**Se fallisce:**
```bash
docker logs anythingllm --tail 50

# Verifica se AnythingLLM è completamente avviato (può richiedere 1-2 minuti)
# Riprova dopo 30 secondi
```

#### Test 2.3: yt-dlp-server health endpoint

**Comando:**
```bash
curl http://localhost:8501/health
```

**Output atteso:**
```json
{"status":"ok","service":"yt-dlp-server"}
```

**✅ PASS:** Risposta JSON corretta
**❌ FAIL:** Errore connessione

**Se fallisce:**
```bash
docker logs yt-dlp-server --tail 50
```

#### Test 2.4: whisper-server health endpoint

**Comando:**
```bash
curl http://localhost:8502/health
```

**Output atteso:**
```json
{"status":"ok","service":"whisper-server"}
```

**✅ PASS:** Risposta JSON corretta
**❌ FAIL:** Errore connessione

**Se fallisce:**
```bash
docker logs whisper-server --tail 50

# Whisper può richiedere tempo per caricare il modello al primo avvio
# Attendi 2-3 minuti e riprova
```

---

### LIVELLO 3: Test Funzionalità Base

#### Test 3.1: crawl4ai - Scrape pagina web

**Comando:**
```bash
curl -X POST http://localhost:11235/crawl \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}'
```

**Output atteso:**
Risposta JSON con contenuto estratto dalla pagina.

**✅ PASS:** Risposta JSON con testo estratto
**❌ FAIL:** Errore o risposta vuota

#### Test 3.2: AnythingLLM - Verifica configurazione

**Apri browser:**
```
http://localhost:3001
```

**Verifica:**
1. Interfaccia AnythingLLM si carica
2. Login funziona (se configurato)
3. Workspace esistente o creabile

**✅ PASS:** Interfaccia accessibile e funzionante
**❌ FAIL:** Errore 500 o pagina non carica

**Se fallisce:**
- Verifica iFlow API key configurata
- Vai su Settings > LLM Preference
- Verifica provider configurato correttamente

---

### LIVELLO 4: Test Workflow Completo

#### Test 4.1: Import pagina web → Query RAG

**Passo 1: Importa contenuto**

Via Claude Code (se skill installata):
```
User: "Import this page into Brainery: https://example.com/article"
```

**O manualmente:**
1. Usa crawl4ai per estrarre contenuto
2. Copia il testo estratto
3. Vai su AnythingLLM (http://localhost:3001)
4. Crea/apri workspace "test"
5. Incolla contenuto e fai upload

**Passo 2: Query RAG**

In AnythingLLM:
```
User: "What is this article about?"
```

**Output atteso:**
Risposta basata sul contenuto importato.

**✅ PASS:** AnythingLLM risponde correttamente basandosi sul contenuto
**❌ FAIL:** Risposta generica o "I don't have information about that"

#### Test 4.2: Verifica persistenza dati

**Comando:**
```bash
# Riavvia container
docker-compose restart

# Attendi 30 secondi
sleep 30

# Verifica workspace ancora esistente
curl http://localhost:3001/api/ping
```

**Verifica manualmente:**
1. Apri http://localhost:3001
2. Workspace creato nel Test 4.1 esiste ancora
3. Documenti importati sono ancora presenti

**✅ PASS:** Dati persistiti dopo restart
**❌ FAIL:** Workspace o documenti persi

**Se fallisce:**
Problema con volumi Docker. Verifica:
```bash
docker volume inspect anythingllm-storage
```

---

## Checklist Test Completa

### ✅ LIVELLO 1: Container
- [ ] Tutti e 4 i container running
- [ ] Healthcheck tutti (healthy)
- [ ] Porte esposte correttamente
- [ ] Volumi Docker creati
- [ ] Log container senza errori critici

### ✅ LIVELLO 2: API Endpoints
- [ ] crawl4ai /health → OK
- [ ] anythingllm /api/ping → OK
- [ ] yt-dlp-server /health → OK
- [ ] whisper-server /health → OK

### ✅ LIVELLO 3: Funzionalità Base
- [ ] crawl4ai scrape funziona
- [ ] AnythingLLM interfaccia accessibile
- [ ] AnythingLLM configurato con iFlow
- [ ] Workspace AnythingLLM creabile

### ✅ LIVELLO 4: Workflow Completo
- [ ] Import contenuto web → RAG query OK
- [ ] Persistenza dati dopo restart OK

---

## Troubleshooting Rapido

| Problema | Soluzione |
|----------|-----------|
| Container non parte | `docker-compose down && docker-compose up -d` |
| Healthcheck unhealthy | Attendi 2-3 minuti, verifica log |
| Porta già in uso | Cambia porta in docker-compose.yml |
| AnythingLLM errore 500 | Verifica iFlow API key, riavvia container |
| Crawl4ai timeout | Aumenta timeout, verifica connessione internet |
| Whisper lento | Normale al primo avvio (download modello) |

---

## Test Superati! 🎉

Se tutti i test passano, Brainery è funzionante e pronto all'uso!

**Prossimi passi:**
- Sezione 7: Architettura container (dettagli tecnici)
- Sezione 8: API endpoints (documentazione completa)
- Sezione 10: Troubleshooting (guida completa problemi comuni)

---

## PARTE 3: REFERENCE TECNICA

### 7. Architettura container

Questa sezione spiega come i 4 container Docker lavorano insieme per creare il sistema Brainery.

---

## Overview Architettura

Brainery usa **4 container Docker indipendenti** che comunicano via HTTP su una rete Docker condivisa.

```
┌─────────────────────────────────────────────────────────────┐
│                    BRAINERY ARCHITECTURE                    │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐
│ Claude Code  │  (Skill Brainery)
│   + MCP      │
└──────┬───────┘
       │
       │ HTTP requests
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network (bridge)                  │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  crawl4ai   │  │ yt-dlp-server│  │whisper-server│      │
│  │             │  │              │  │              │      │
│  │ Port: 11235 │  │ Port: 8501   │  │ Port: 8502   │      │
│  └──────┬──────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                │                  │              │
│         │ Extracted     │ Transcripts      │ Audio        │
│         │ text          │                  │ transcription│
│         │                │                  │              │
│         └────────────────┴──────────────────┘              │
│                          │                                 │
│                          ▼                                 │
│                  ┌──────────────┐                          │
│                  │ anythingllm  │                          │
│                  │              │                          │
│                  │ Port: 3001   │                          │
│                  │              │                          │
│                  │ (RAG System) │                          │
│                  └──────────────┘                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
       │              │              │              │
       ▼              ▼              ▼              ▼
  [crawl4ai-    [anythingllm-  [ytdlp-cache]  [whisper-
    data]         storage]                      models]
  (Volume)        (Volume)       (Volume)      (Volume)
```

**Flusso tipico:**
1. User richiede import contenuto (via Claude Code)
2. Claude Code chiama MCP servers appropriati
3. MCP servers comunicano con container Docker
4. Container processano contenuto
5. Risultato viene caricato in AnythingLLM (RAG)
6. User può interrogare il RAG

---

## Container: Ruoli e Motivazioni

### Container 1: crawl4ai

**Ruolo:** Web scraping e estrazione testo da pagine HTML.

**Perché è necessario:**
- Le pagine web moderne sono complesse (JavaScript, CSS, ads)
- Copiare/incollare manualmente è inefficiente
- Crawl4AI estrae solo il contenuto rilevante (no header/footer/ads)
- Migliore qualità RAG: meno rumore = risposte più accurate

**Cosa fa:**
- Scarica pagina web
- Renderizza JavaScript (se necessario)
- Estrae testo pulito in markdown
- Rimuove elementi non rilevanti

**Best practices Docker applicate:**
- **Immagine ufficiale:** Usa `unclecode/crawl4ai:latest` (ben mantenuta)
- **Volume per cache:** Riduce re-download di pagine
- **Healthcheck:** Verifica servizio attivo

**Alternative scartate:** BeautifulSoup (troppo basic), Selenium (troppo pesante).

---

### Container 2: yt-dlp-server

**Ruolo:** Download trascrizioni da YouTube e altri video hosting.

**Perché è necessario:**
- YouTube ha API rate limits
- yt-dlp supporta 1000+ siti video (non solo YouTube)
- Trascrizioni automatiche disponibili per la maggior parte dei video
- Video lunghi (2+ ore) impossibili da seguire manualmente

**Cosa fa:**
- Estrae metadata video (titolo, durata, autore)
- Scarica trascrizioni (sottotitoli auto-generati o manuali)
- Fallback: Se no trascrizioni, chiama whisper-server per trascrivere audio

**Best practices Docker applicate:**
- **Custom Dockerfile:** Server FastAPI dedicato
- **ffmpeg incluso:** Necessario per processing audio/video
- **Volume cache:** Evita re-download trascrizioni
- **Python 3.12-slim:** Immagine leggera

**Alternative scartate:** YouTube Data API (quota limits), video player embed (no accesso trascrizioni).

---

### Container 3: whisper-server

**Ruolo:** Trascrizione audio → testo quando non ci sono sottotitoli.

**Perché è necessario:**
- Molti video NON hanno trascrizioni disponibili
- Podcast, conferenze, lezioni universitarie spesso senza sottotitoli
- Whisper (OpenAI) è lo stato dell'arte per accuracy
- Fallback automatico quando yt-dlp non trova trascrizioni

**Cosa fa:**
- Riceve file audio (estratto da yt-dlp-server)
- Usa modello Whisper per trascrivere
- Restituisce testo con timestamp
- Supporta multiple lingue

**Best practices Docker applicate:**
- **Volume per modelli:** Whisper model (~1GB) scaricato una sola volta
- **Python 3.12-slim + torch:** Ottimizzato per ML
- **Modello "base":** Bilanciamento velocità/accuracy
- **Healthcheck:** Verifica modello caricato

**Nota performance:** Prima trascrizione lenta (download modello). Successive veloci.

**Alternative scartate:** Google Speech-to-Text (a pagamento), Assembly.ai (a pagamento).

---

### Container 4: anythingllm

**Ruolo:** Database RAG locale per storage e query contenuti.

**Perché è necessario:**
- Creare un RAG da zero è estremamente complesso
- AnythingLLM gestisce: embeddings, vector store, chunking, retrieval
- Interfaccia web per configurazione (no config files complessi)
- Supporta LLM provider gratuiti (iFlow)

**Cosa fa:**
- Riceve testo dai 3 container sopra
- Genera embeddings (vector representations)
- Salva in vector database locale
- Query RAG: trova chunk rilevanti + genera risposta con LLM

**Best practices Docker applicate:**
- **Immagine ufficiale:** `mintplexlabs/anythingllm:latest`
- **Volume storage:** Persistenza workspace + documenti + embeddings
- **Environment var:** Configurazione STORAGE_DIR
- **Healthcheck ping endpoint:** Verifica servizio pronto

**Alternative scartate:** LlamaIndex (richiede coding), LangChain (richiede coding), Pinecone (cloud, a pagamento).

---

## Network Configuration

### Rete Docker

Tutti i container usano la **default bridge network** creata da docker-compose.

**Caratteristiche:**
- Container possono comunicare tra loro via hostname (nome container)
- Isolamento dalla rete host
- Port mapping: solo porte specificate esposte su host

**Porte esposte:**

| Container       | Porta Interna | Porta Host | Protocollo |
|-----------------|---------------|------------|------------|
| crawl4ai        | 11235         | 11235      | HTTP       |
| anythingllm     | 3001          | 3001       | HTTP       |
| yt-dlp-server   | 8501          | 8501       | HTTP       |
| whisper-server  | 8502          | 8502       | HTTP       |

**Comunicazione inter-container:**

```yaml
# Esempio: Claude Code → yt-dlp-server → whisper-server → anythingllm

# 1. Claude Code chiama yt-dlp-server
POST http://localhost:8501/transcript
Body: {"url": "https://youtube.com/watch?v=xyz"}

# 2. yt-dlp-server (se no trascrizioni) chiama whisper-server
POST http://whisper-server:8502/transcribe
Body: {"audio_url": "extracted_audio.mp3"}

# 3. Risultato finale caricato in anythingllm
POST http://localhost:3001/api/workspace/upload
Body: {"text": "transcript_content..."}
```

**Hostname resolution:**
- Container usano nomi Docker come hostname: `http://whisper-server:8502`
- Host usa `localhost`: `http://localhost:8502`

---

## Volume Mounts

I volumi Docker garantiscono **persistenza dati** tra restart container.

### Volume 1: crawl4ai-data

**Path container:** `/app/data`

**Cosa contiene:**
- Cache pagine scaricate
- Metadata scraping
- Temporary files

**Dimensione tipica:** ~500MB - 2GB (dipende da uso)

**Perché necessario:**
- Evita re-download stessa pagina
- Velocizza scraping ripetuto
- Riduce carico server esterni

**Pulizia:** Può essere svuotato periodicamente senza perdita dati critici.

```bash
# Pulire cache crawl4ai
docker volume rm crawl4ai-data
docker-compose up -d crawl4ai
```

---

### Volume 2: anythingllm-storage

**Path container:** `/app/server/storage`

**Cosa contiene:**
- **Workspace data:** Configurazione workspace
- **Documenti caricati:** Testo originale importato
- **Vector embeddings:** Rappresentazioni vettoriali per RAG
- **Chat history:** Conversazioni RAG
- **System config:** Configurazione LLM provider

**Dimensione tipica:** ~1GB - 10GB+ (cresce con uso)

**Perché necessario:**
- **CRITICO:** Perdere questo volume = perdere tutto il RAG
- Persistenza workspace tra restart
- Backup centralizzato (backup solo questo volume)

**⚠️ NON cancellare mai questo volume senza backup!**

**Backup:**
```bash
# Backup volume anythingllm
docker run --rm -v anythingllm-storage:/data -v $(pwd):/backup \
  alpine tar czf /backup/anythingllm-backup.tar.gz /data

# Restore
docker run --rm -v anythingllm-storage:/data -v $(pwd):/backup \
  alpine tar xzf /backup/anythingllm-backup.tar.gz -C /
```

---

### Volume 3: ytdlp-cache

**Path container:** `/app/temp`

**Cosa contiene:**
- File audio/video temporanei scaricati
- Trascrizioni in processing
- Cache metadata video

**Dimensione tipica:** ~1GB - 5GB

**Perché necessario:**
- Processing video richiede file temporanei
- Cache trascrizioni già scaricate
- Riduce bandwidth YouTube

**Pulizia:** Sicuro cancellare periodicamente.

```bash
# Pulire cache yt-dlp
docker volume rm ytdlp-cache
docker-compose up -d yt-dlp-server
```

---

### Volume 4: whisper-models

**Path container:** `/app/models`

**Cosa contiene:**
- Modello Whisper scaricato (~1GB per modello "base")
- Cache model files

**Dimensione tipica:** ~1GB - 3GB

**Perché necessario:**
- Modello Whisper grande (~1GB)
- Download una sola volta, riuso successivo
- Primo avvio: download automatico (lento)
- Avvii successivi: model già presente (veloce)

**⚠️ Non cancellare:** Re-download 1GB ogni volta che container riparte.

---

## Resource Limits

### Raccomandazioni CPU/RAM per container

| Container       | RAM Min | RAM Consigliata | CPU Cores | Note |
|-----------------|---------|-----------------|-----------|------|
| crawl4ai        | 512MB   | 1GB             | 1         | Spike durante scraping |
| anythingllm     | 2GB     | 4GB             | 2         | Dipende da LLM provider (iFlow = remoto, basso uso) |
| yt-dlp-server   | 512MB   | 1GB             | 1         | Spike durante download |
| whisper-server  | 2GB     | 4GB             | 2         | ML model, CPU-intensive |

**TOTALE Sistema:**
- **Minimo:** 8GB RAM, 4 CPU cores
- **Consigliato:** 12GB+ RAM, 4+ CPU cores

**Configurazione resource limits (opzionale):**

Aggiungere a `docker-compose.yml`:

```yaml
services:
  whisper-server:
    # ... resto config ...
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
```

**Quando usare limits:**
- Sistema con RAM limitata (8GB totale)
- Whisper impatta performance altri container
- Vuoi garantire CPU a container critici

**⚠️ NON usare limits troppo stretti:**
- Whisper con <2GB RAM: crash o lentezza estrema
- AnythingLLM con <1GB RAM: instabile

---

## Startup Dependencies

**Ordine avvio container:**

```
1. anythingllm      (nessuna dipendenza)
2. crawl4ai         (indipendente)
3. yt-dlp-server    (indipendente)
4. whisper-server   (indipendente, ma lento primo avvio)
```

**Nota:** I container sono **indipendenti** e possono partire in qualsiasi ordine.

**Tempo avvio tipico:**

| Container       | Primo Avvio | Avvii Successivi | Healthcheck OK dopo |
|-----------------|-------------|------------------|---------------------|
| crawl4ai        | ~30 sec     | ~10 sec          | ~15 sec             |
| anythingllm     | ~60 sec     | ~20 sec          | ~30 sec             |
| yt-dlp-server   | ~20 sec     | ~10 sec          | ~15 sec             |
| whisper-server  | ~120 sec    | ~15 sec          | ~30 sec             |

**Primo avvio whisper-server lento:**
- Scarica modello Whisper (~1GB) da Hugging Face
- Successive avvii: modello già in volume

**⚠️ Attendi tutti healthcheck "healthy" prima di usare Brainery:**

```bash
# Verifica stato
docker-compose ps

# Tutti devono mostrare (healthy)
```

**Se healthcheck stuck su "starting":**
- Attendi 2-3 minuti
- Verifica log: `docker logs <container-name>`
- Se persiste dopo 5 minuti: problema configurazione

---

## Best Practices Docker Applicate

### 1. Immagini Base Leggere

**✅ Usato:** `python:3.12-slim` (~150MB)
**❌ Evitato:** `python:3.12` (~1GB)

**Vantaggi:**
- Build più veloci
- Meno vulnerabilità
- Meno spazio disco

### 2. Multi-Stage Builds (se necessario)

Per container custom con compilazione:

```dockerfile
# Stage 1: Build
FROM python:3.12 AS builder
RUN pip install --user dependencies

# Stage 2: Runtime
FROM python:3.12-slim
COPY --from=builder /root/.local /root/.local
```

**Brainery:** Non usato perché dipendenze già binarie.

### 3. Layer Caching

**Ordine Dockerfile:**
1. Comandi che cambiano raramente (apt-get, system deps)
2. Dipendenze Python (requirements.txt)
3. Codice applicazione (server.py)

**Esempio:**
```dockerfile
# Layer 1: Raramente cambia
RUN apt-get update && apt-get install -y ffmpeg

# Layer 2: Cambia se requirements.txt aggiornato
COPY requirements.txt .
RUN pip install -r requirements.txt

# Layer 3: Cambia spesso (codice)
COPY server.py .
```

### 4. No Cache Package Managers

```dockerfile
# ✅ Corretto
RUN pip install --no-cache-dir package

# ❌ Sbagliato
RUN pip install package  # Lascia cache (~100MB extra)
```

### 5. Cleanup in Stesso Layer

```dockerfile
# ✅ Corretto (cleanup stesso RUN)
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ❌ Sbagliato (layer separati = cache non rimossa)
RUN apt-get update
RUN apt-get install -y ffmpeg
RUN apt-get clean  # Troppo tardi, cache già in layer precedente
```

### 6. Healthchecks

Ogni container ha healthcheck per verificare stato:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8501/health"]
  interval: 30s      # Check ogni 30 secondi
  timeout: 10s       # Timeout risposta
  retries: 3         # Fallimenti prima di "unhealthy"
  start_period: 40s  # Grace period primo avvio
```

**Vantaggi:**
- Docker Compose verifica container funzionanti
- Restart automatico se unhealthy (con `restart: unless-stopped`)
- Monitoring chiaro con `docker ps`

### 7. Named Volumes

```yaml
# ✅ Named volumes (consigliato)
volumes:
  anythingllm-storage:

# ❌ Bind mounts (evitato)
volumes:
  - ./data:/app/storage  # Problema permessi, portabilità
```

**Vantaggi named volumes:**
- Gestiti da Docker
- Portabili cross-platform
- No problemi permessi
- Backup centralizzato

### 8. Restart Policy

```yaml
restart: unless-stopped
```

**Comportamento:**
- Container riparte automaticamente se crash
- Container riparte dopo reboot sistema
- Container NON riparte se fermato manualmente

**Alternative:**
- `restart: always`: Riparte anche se fermato manualmente (troppo aggressivo)
- `restart: on-failure`: Riparte solo se exit code != 0
- `restart: no`: Nessun restart automatico (non consigliato)

---

## Riepilogo Architettura

**4 Container indipendenti:**
1. **crawl4ai:** Web scraping
2. **yt-dlp-server:** YouTube transcripts
3. **whisper-server:** Audio transcription
4. **anythingllm:** RAG database

**Comunicazione:** HTTP su rete Docker bridge

**Persistenza:** 4 named volumes per dati critici

**Resource usage:** ~8-12GB RAM, 4 CPU cores

**Startup:** ~2-3 minuti primo avvio, ~30 sec successivi

**Best practices:** Immagini slim, healthchecks, layer caching, named volumes

**Prossima sezione:** API endpoints (Sezione 8) documenterà gli endpoint HTTP di ogni container.

### 8. API endpoints

Questa sezione documenta tutti gli endpoint HTTP dei 4 container Brainery.

---

## Indice API

| Container | Base URL | Endpoint Principali |
|-----------|----------|-------------------|
| crawl4ai | `http://localhost:11235` | `/health`, `/md`, `/crawl` |
| yt-dlp-server | `http://localhost:8501` | `/health`, `/transcript`, `/metadata` |
| whisper-server | `http://localhost:8502` | `/health`, `/transcribe` |
| anythingllm | `http://localhost:3001` | `/api/ping`, `/api/workspace/*`, `/api/document/*` |

---

## crawl4ai API

### GET /health

**Descrizione:** Verifica che il servizio sia attivo.

**Request:**
```bash
curl http://localhost:11235/health
```

**Response 200:**
```json
{
  "status": "ok"
}
```

**Errori comuni:**
- **Connection refused:** Container non avviato o porta non esposta

---

### POST /md

**Descrizione:** Estrae contenuto markdown pulito da una pagina web.

**Request:**
```bash
curl -X POST http://localhost:11235/md \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/article",
    "f": "fit",
    "q": null
  }'
```

**Parameters:**

| Campo | Tipo | Required | Descrizione |
|-------|------|----------|-------------|
| `url` | string | ✅ | URL pagina da scrapare |
| `f` | string | ❌ | Filtro contenuto: `fit`, `raw`, `bm25`, `llm` (default: `fit`) |
| `q` | string | ❌ | Query per filtri BM25/LLM (default: `null`) |

**Response 200:**
```json
{
  "markdown": "# Article Title\n\nArticle content in clean markdown...",
  "metadata": {
    "title": "Article Title",
    "description": "Article description",
    "url": "https://example.com/article"
  }
}
```

**Response 400 (Bad Request):**
```json
{
  "error": "Invalid URL format",
  "details": "URL must start with http:// or https://"
}
```

**Response 500 (Server Error):**
```json
{
  "error": "Failed to fetch page",
  "details": "Connection timeout after 30 seconds"
}
```

**Errori comuni:**
- **Invalid URL:** Verifica formato URL (deve includere `http://` o `https://`)
- **Timeout:** Sito troppo lento o non raggiungibile
- **403 Forbidden:** Sito blocca scraping (usa headers custom)
- **JavaScript not rendered:** Usa parametro `render_js: true` se pagina richiede JS

---

### POST /crawl

**Descrizione:** Scraping completo con opzioni avanzate.

**Request:**
```bash
curl -X POST http://localhost:11235/crawl \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["https://example.com/page1", "https://example.com/page2"],
    "crawler_config": {
      "verbose": true
    }
  }'
```

**Parameters:**

| Campo | Tipo | Required | Descrizione |
|-------|------|----------|-------------|
| `urls` | array | ✅ | Lista URL da scrapare (max 100) |
| `crawler_config` | object | ❌ | Configurazione crawler |

**Response 200:**
```json
{
  "results": [
    {
      "url": "https://example.com/page1",
      "success": true,
      "markdown": "# Page 1\n\nContent...",
      "metadata": {...}
    },
    {
      "url": "https://example.com/page2",
      "success": false,
      "error": "404 Not Found"
    }
  ]
}
```

**Note:**
- Endpoint `/md` è consigliato per singole pagine (più semplice)
- Endpoint `/crawl` per batch processing di multiple URL

---

## yt-dlp-server API

### Implementazione Completa

**File:** `dockerfiles/yt-dlp-server/server.py`

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, HttpUrl
import yt_dlp
import asyncio
from typing import Optional, List, Dict, Any
import logging

app = FastAPI(title="yt-dlp-server", version="1.0.0")

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class TranscriptRequest(BaseModel):
    url: HttpUrl
    language: Optional[str] = "en"


class MetadataRequest(BaseModel):
    url: HttpUrl


class TranscriptResponse(BaseModel):
    url: str
    title: str
    duration: int
    transcript: str
    language: str
    source: str  # "subtitles" or "whisper"


class MetadataResponse(BaseModel):
    url: str
    title: str
    duration: int
    uploader: str
    view_count: int
    upload_date: str
    description: str
    thumbnail: str


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "ok", "service": "yt-dlp-server"}


@app.post("/transcript", response_model=TranscriptResponse)
async def get_transcript(request: TranscriptRequest):
    """
    Get video transcript from YouTube or other platforms.
    Falls back to whisper-server if no subtitles available.
    """
    url = str(request.url)
    language = request.language

    logger.info(f"Fetching transcript for: {url} (language: {language})")

    ydl_opts = {
        'writesubtitles': True,
        'writeautomaticsub': True,
        'subtitleslangs': [language],
        'skip_download': True,
        'quiet': True,
        'no_warnings': True,
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            # Extract info
            info = ydl.extract_info(url, download=False)

            title = info.get('title', 'Unknown')
            duration = info.get('duration', 0)

            # Try to get subtitles
            subtitles = info.get('subtitles', {})
            automatic_captions = info.get('automatic_captions', {})

            transcript_text = None
            source = None

            # Priority: manual subtitles > auto captions
            if language in subtitles:
                transcript_text = await _extract_subtitle_text(subtitles[language])
                source = "subtitles"
                logger.info(f"Found manual subtitles for {language}")
            elif language in automatic_captions:
                transcript_text = await _extract_subtitle_text(automatic_captions[language])
                source = "subtitles"
                logger.info(f"Found auto-generated captions for {language}")

            # Fallback: call whisper-server
            if not transcript_text:
                logger.info("No subtitles found, falling back to whisper-server")
                audio_url = info.get('url')
                if audio_url:
                    transcript_text = await _call_whisper_server(audio_url)
                    source = "whisper"
                else:
                    raise HTTPException(
                        status_code=404,
                        detail="No subtitles found and unable to extract audio"
                    )

            return TranscriptResponse(
                url=url,
                title=title,
                duration=duration,
                transcript=transcript_text,
                language=language,
                source=source
            )

    except yt_dlp.utils.DownloadError as e:
        logger.error(f"yt-dlp error: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Failed to process video: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.post("/metadata", response_model=MetadataResponse)
async def get_metadata(request: MetadataRequest):
    """Get video metadata without downloading content"""
    url = str(request.url)

    logger.info(f"Fetching metadata for: {url}")

    ydl_opts = {
        'skip_download': True,
        'quiet': True,
        'no_warnings': True,
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)

            return MetadataResponse(
                url=url,
                title=info.get('title', 'Unknown'),
                duration=info.get('duration', 0),
                uploader=info.get('uploader', 'Unknown'),
                view_count=info.get('view_count', 0),
                upload_date=info.get('upload_date', 'Unknown'),
                description=info.get('description', '')[:500],  # Truncate
                thumbnail=info.get('thumbnail', '')
            )

    except yt_dlp.utils.DownloadError as e:
        logger.error(f"yt-dlp error: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Failed to fetch metadata: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


async def _extract_subtitle_text(subtitle_formats: List[Dict]) -> str:
    """Extract text from subtitle formats (prefer vtt or srt)"""
    # Find vtt or srt format
    subtitle_url = None
    for fmt in subtitle_formats:
        if fmt.get('ext') in ['vtt', 'srt']:
            subtitle_url = fmt.get('url')
            break

    if not subtitle_url:
        return None

    # Download and parse subtitle file
    import httpx
    async with httpx.AsyncClient() as client:
        response = await client.get(subtitle_url)
        if response.status_code == 200:
            # Simple parsing: remove timestamps and tags
            text = response.text
            # Remove WebVTT headers
            text = '\n'.join([line for line in text.split('\n')
                             if not line.startswith('WEBVTT')
                             and not '-->' in line
                             and not line.strip().isdigit()])
            return text.strip()

    return None


async def _call_whisper_server(audio_url: str) -> str:
    """Call whisper-server to transcribe audio"""
    import httpx

    whisper_url = "http://whisper-server:8502/transcribe"

    try:
        async with httpx.AsyncClient(timeout=300.0) as client:
            response = await client.post(
                whisper_url,
                json={"audio_url": audio_url}
            )

            if response.status_code == 200:
                data = response.json()
                return data.get('transcript', '')
            else:
                raise Exception(f"Whisper server returned {response.status_code}")

    except Exception as e:
        logger.error(f"Failed to call whisper-server: {str(e)}")
        raise


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8501)
```

**File:** `dockerfiles/yt-dlp-server/requirements.txt`

```
fastapi==0.109.0
uvicorn[standard]==0.27.0
yt-dlp>=2024.1.0
httpx==0.26.0
pydantic==2.5.3
```

---

### GET /health

**Descrizione:** Verifica che il servizio sia attivo.

**Request:**
```bash
curl http://localhost:8501/health
```

**Response 200:**
```json
{
  "status": "ok",
  "service": "yt-dlp-server"
}
```

---

### POST /transcript

**Descrizione:** Ottiene trascrizione completa del video (sottotitoli o Whisper fallback).

**Request:**
```bash
curl -X POST http://localhost:8501/transcript \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "language": "en"
  }'
```

**Parameters:**

| Campo | Tipo | Required | Descrizione |
|-------|------|----------|-------------|
| `url` | string (URL) | ✅ | URL video YouTube (o altro sito supportato) |
| `language` | string | ❌ | Codice lingua sottotitoli (default: `en`) |

**Response 200:**
```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Example Video Title",
  "duration": 212,
  "transcript": "Full transcript text here...",
  "language": "en",
  "source": "subtitles"
}
```

**Response 400 (Bad Request):**
```json
{
  "detail": "Failed to process video: Video unavailable"
}
```

**Response 404 (Not Found):**
```json
{
  "detail": "No subtitles found and unable to extract audio"
}
```

**Response 500 (Server Error):**
```json
{
  "detail": "Internal server error: Connection timeout"
}
```

**Errori comuni:**
- **Video unavailable:** Video privato, rimosso, o region-locked
- **No subtitles found:** Nessun sottotitolo disponibile (fallback automatico a Whisper)
- **Unsupported URL:** Piattaforma non supportata da yt-dlp
- **Rate limit exceeded:** Troppi request in breve tempo (attendi qualche minuto)

**Note:**
- `source: "subtitles"` = Trascrizione da sottotitoli YouTube
- `source: "whisper"` = Trascrizione generata da whisper-server
- Trascrizione Whisper richiede più tempo (~1-2 minuti per video di 10 minuti)

---

### POST /metadata

**Descrizione:** Ottiene metadata video senza scaricare contenuto.

**Request:**
```bash
curl -X POST http://localhost:8501/metadata \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  }'
```

**Parameters:**

| Campo | Tipo | Required | Descrizione |
|-------|------|----------|-------------|
| `url` | string (URL) | ✅ | URL video |

**Response 200:**
```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Example Video Title",
  "duration": 212,
  "uploader": "Channel Name",
  "view_count": 1234567,
  "upload_date": "20200101",
  "description": "Video description (first 500 chars)...",
  "thumbnail": "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg"
}
```

**Response 400:**
```json
{
  "detail": "Failed to fetch metadata: Invalid video ID"
}
```

**Errori comuni:**
- **Invalid video ID:** URL malformato
- **Private video:** Video non accessibile pubblicamente

---

## whisper-server API

### Implementazione Completa

**File:** `dockerfiles/whisper-server/server.py`

```python
from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel, HttpUrl
import whisper
import tempfile
import os
import logging
import httpx
from pathlib import Path

app = FastAPI(title="whisper-server", version="1.0.0")

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load Whisper model at startup
logger.info("Loading Whisper model...")
MODEL_NAME = os.getenv("WHISPER_MODEL", "base")  # base, small, medium, large
model = whisper.load_model(MODEL_NAME)
logger.info(f"Whisper model '{MODEL_NAME}' loaded successfully")


class TranscribeURLRequest(BaseModel):
    audio_url: HttpUrl
    language: str = None  # Auto-detect if None


class TranscribeResponse(BaseModel):
    transcript: str
    language: str
    duration: float


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "whisper-server",
        "model": MODEL_NAME
    }


@app.post("/transcribe", response_model=TranscribeResponse)
async def transcribe_from_url(request: TranscribeURLRequest):
    """
    Transcribe audio from URL using Whisper.
    Downloads audio temporarily, transcribes, and deletes temp file.
    """
    audio_url = str(request.audio_url)
    language = request.language

    logger.info(f"Transcribing audio from URL: {audio_url}")

    # Download audio to temp file
    temp_file = None
    try:
        temp_file = await _download_audio(audio_url)

        # Transcribe with Whisper
        logger.info(f"Running Whisper transcription (model: {MODEL_NAME})...")
        result = model.transcribe(
            temp_file,
            language=language,
            fp16=False  # CPU compatibility
        )

        transcript_text = result['text'].strip()
        detected_language = result.get('language', 'unknown')

        logger.info(f"Transcription complete. Language: {detected_language}")

        # Get audio duration (approximate from Whisper result)
        segments = result.get('segments', [])
        duration = segments[-1]['end'] if segments else 0.0

        return TranscribeResponse(
            transcript=transcript_text,
            language=detected_language,
            duration=duration
        )

    except httpx.HTTPError as e:
        logger.error(f"Failed to download audio: {str(e)}")
        raise HTTPException(
            status_code=400,
            detail=f"Failed to download audio from URL: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Transcription error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Transcription failed: {str(e)}"
        )
    finally:
        # Cleanup temp file
        if temp_file and os.path.exists(temp_file):
            os.remove(temp_file)
            logger.info(f"Cleaned up temp file: {temp_file}")


@app.post("/transcribe/upload", response_model=TranscribeResponse)
async def transcribe_from_upload(file: UploadFile = File(...), language: str = None):
    """
    Transcribe audio from uploaded file.
    Useful for local files or when URL download fails.
    """
    logger.info(f"Transcribing uploaded file: {file.filename}")

    # Save uploaded file to temp location
    temp_file = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=Path(file.filename).suffix) as tmp:
            content = await file.read()
            tmp.write(content)
            temp_file = tmp.name

        # Transcribe
        logger.info(f"Running Whisper transcription (model: {MODEL_NAME})...")
        result = model.transcribe(
            temp_file,
            language=language,
            fp16=False
        )

        transcript_text = result['text'].strip()
        detected_language = result.get('language', 'unknown')

        segments = result.get('segments', [])
        duration = segments[-1]['end'] if segments else 0.0

        return TranscribeResponse(
            transcript=transcript_text,
            language=detected_language,
            duration=duration
        )

    except Exception as e:
        logger.error(f"Transcription error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Transcription failed: {str(e)}"
        )
    finally:
        if temp_file and os.path.exists(temp_file):
            os.remove(temp_file)


async def _download_audio(url: str) -> str:
    """Download audio from URL to temporary file"""
    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.get(url)
        response.raise_for_status()

        # Detect file extension from Content-Type or URL
        content_type = response.headers.get('content-type', '')
        if 'audio/mpeg' in content_type or url.endswith('.mp3'):
            suffix = '.mp3'
        elif 'audio/wav' in content_type or url.endswith('.wav'):
            suffix = '.wav'
        elif url.endswith('.m4a'):
            suffix = '.m4a'
        else:
            suffix = '.audio'  # Generic

        # Save to temp file
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(response.content)
            return tmp.name


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8502)
```

**File:** `dockerfiles/whisper-server/requirements.txt`

```
fastapi==0.109.0
uvicorn[standard]==0.27.0
openai-whisper>=20231117
torch>=2.1.0
httpx==0.26.0
pydantic==2.5.3
python-multipart==0.0.6
```

---

### GET /health

**Descrizione:** Verifica che il servizio sia attivo e Whisper model caricato.

**Request:**
```bash
curl http://localhost:8502/health
```

**Response 200:**
```json
{
  "status": "ok",
  "service": "whisper-server",
  "model": "base"
}
```

**Note:**
- Primo avvio: richiede ~1-2 minuti per scaricare modello Whisper
- Healthcheck fallisce finché modello non è completamente caricato

---

### POST /transcribe

**Descrizione:** Trascrizione audio da URL (usato da yt-dlp-server come fallback).

**Request:**
```bash
curl -X POST http://localhost:8502/transcribe \
  -H "Content-Type: application/json" \
  -d '{
    "audio_url": "https://example.com/audio.mp3",
    "language": "en"
  }'
```

**Parameters:**

| Campo | Tipo | Required | Descrizione |
|-------|------|----------|-------------|
| `audio_url` | string (URL) | ✅ | URL file audio (mp3, wav, m4a, etc.) |
| `language` | string | ❌ | Codice lingua ISO (es: `en`, `it`, `es`). Auto-detect se omesso |

**Response 200:**
```json
{
  "transcript": "Full transcript text generated by Whisper...",
  "language": "en",
  "duration": 125.5
}
```

**Response 400 (Bad Request):**
```json
{
  "detail": "Failed to download audio from URL: Connection timeout"
}
```

**Response 500 (Server Error):**
```json
{
  "detail": "Transcription failed: Out of memory"
}
```

**Errori comuni:**
- **Download failed:** URL non raggiungibile o formato non supportato
- **Out of memory:** File audio troppo lungo (>1 ora su sistema con 8GB RAM)
- **Invalid audio format:** Formato audio non riconosciuto da Whisper
- **Timeout:** Trascrizione troppo lunga (aumenta timeout request)

**Performance:**
- **Modello "base":** ~10 minuti per trascrivere 1 ora di audio
- **Modello "small":** Più accurato ma 2x più lento
- **Primo avvio:** Download modello (~1GB) richiede tempo extra

**Lingue supportate:**
- Whisper supporta 99 lingue
- Codici comuni: `en` (English), `it` (Italian), `es` (Spanish), `fr` (French), `de` (German), `ja` (Japanese), `zh` (Chinese)
- Auto-detect se `language` omesso (consigliato per lingue miste)

---

### POST /transcribe/upload

**Descrizione:** Trascrizione audio da file caricato (alternativa a /transcribe).

**Request:**
```bash
curl -X POST http://localhost:8502/transcribe/upload \
  -F "file=@/path/to/audio.mp3" \
  -F "language=en"
```

**Parameters:**

| Campo | Tipo | Required | Descrizione |
|-------|------|----------|-------------|
| `file` | file (multipart) | ✅ | File audio da trascrivere |
| `language` | string | ❌ | Codice lingua (default: auto-detect) |

**Response 200:**
```json
{
  "transcript": "Transcribed text...",
  "language": "en",
  "duration": 45.2
}
```

**Errori comuni:**
- **File too large:** Limite upload (default 10MB, configurabile)
- **Invalid format:** Formato file non supportato

**Note:**
- Preferisci `/transcribe` (URL) per integrazione con yt-dlp-server
- Usa `/transcribe/upload` solo per file locali o test manuali

---

## anythingllm API

### Documentazione Ufficiale

**Link:** https://docs.useanything.com/api

AnythingLLM ha un'API REST completa. Questa sezione documenta solo gli endpoint **critici per Brainery**.

### Base URL

```
http://localhost:3001
```

### Authentication

Tutti gli endpoint (tranne `/api/ping`) richiedono API key.

**Ottieni API key:**
1. Apri http://localhost:3001
2. Settings > API Keys
3. Generate New API Key
4. Salva key (formato: `ALLLM-xxxx...`)

**Header richiesto:**
```
Authorization: Bearer ALLLM-xxxxxxxxxxxxxx
```

---

### GET /api/ping

**Descrizione:** Health check senza autenticazione.

**Request:**
```bash
curl http://localhost:3001/api/ping
```

**Response 200:**
```json
{
  "online": true
}
```

---

### GET /api/workspaces

**Descrizione:** Lista tutti i workspace.

**Request:**
```bash
curl http://localhost:3001/api/workspaces \
  -H "Authorization: Bearer ALLLM-xxxxx"
```

**Response 200:**
```json
{
  "workspaces": [
    {
      "id": 1,
      "name": "brainery-workspace",
      "slug": "brainery-workspace",
      "createdAt": "2026-01-01T00:00:00.000Z"
    }
  ]
}
```

---

### POST /api/workspace/new

**Descrizione:** Crea nuovo workspace.

**Request:**
```bash
curl -X POST http://localhost:3001/api/workspace/new \
  -H "Authorization: Bearer ALLLM-xxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "brainery-workspace"
  }'
```

**Response 200:**
```json
{
  "workspace": {
    "id": 1,
    "name": "brainery-workspace",
    "slug": "brainery-workspace"
  },
  "message": "Workspace created successfully"
}
```

---

### POST /api/workspace/{slug}/upload

**Descrizione:** Carica documento in workspace.

**Request:**
```bash
curl -X POST http://localhost:3001/api/workspace/brainery-workspace/upload \
  -H "Authorization: Bearer ALLLM-xxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "textContent": "Document content here...",
    "metadata": {
      "title": "Document Title",
      "source": "youtube",
      "url": "https://youtube.com/watch?v=xxx"
    }
  }'
```

**Response 200:**
```json
{
  "success": true,
  "document": {
    "id": "doc_123",
    "title": "Document Title"
  }
}
```

---

### POST /api/workspace/{slug}/chat

**Descrizione:** Query RAG workspace.

**Request:**
```bash
curl -X POST http://localhost:3001/api/workspace/brainery-workspace/chat \
  -H "Authorization: Bearer ALLLM-xxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is this document about?",
    "mode": "query"
  }'
```

**Parameters:**

| Campo | Tipo | Required | Descrizione |
|-------|------|----------|-------------|
| `message` | string | ✅ | Domanda da fare al RAG |
| `mode` | string | ✅ | `"query"` (usa documenti) o `"chat"` (conversazione libera) |

**Response 200:**
```json
{
  "textResponse": "This document discusses...",
  "sources": [
    {
      "title": "Document Title",
      "chunk": "Relevant text chunk..."
    }
  ],
  "type": "textResponse"
}
```

**⚠️ IMPORTANTE: Mode Parameter**

| Mode | Comportamento |
|------|--------------|
| `"query"` | **USA documenti RAG** - Risposta basata su contenuti caricati |
| `"chat"` | **IGNORA documenti** - Conversazione libera con LLM |

**Errore comune:**
```json
{
  "message": "What is this document about?",
  "mode": "chat"  // ❌ SBAGLIATO - ignora documenti!
}
```

**Corretto:**
```json
{
  "message": "What is this document about?",
  "mode": "query"  // ✅ CORRETTO - usa RAG
}
```

---

### GET /api/workspace/{slug}/documents

**Descrizione:** Lista documenti in workspace.

**Request:**
```bash
curl http://localhost:3001/api/workspace/brainery-workspace/documents \
  -H "Authorization: Bearer ALLLM-xxxxx"
```

**Response 200:**
```json
{
  "documents": [
    {
      "id": "doc_123",
      "title": "Document Title",
      "createdAt": "2026-01-01T00:00:00.000Z",
      "metadata": {...}
    }
  ]
}
```

---

### DELETE /api/workspace/{slug}/document/{docId}

**Descrizione:** Elimina documento da workspace.

**Request:**
```bash
curl -X DELETE http://localhost:3001/api/workspace/brainery-workspace/document/doc_123 \
  -H "Authorization: Bearer ALLLM-xxxxx"
```

**Response 200:**
```json
{
  "success": true,
  "message": "Document deleted"
}
```

---

## Riepilogo Quick Reference

### Endpoint Health Check (tutti i container)

```bash
# Verifica rapida tutti i servizi
curl http://localhost:11235/health  # crawl4ai
curl http://localhost:3001/api/ping # anythingllm
curl http://localhost:8501/health   # yt-dlp-server
curl http://localhost:8502/health   # whisper-server
```

### Workflow Tipico: Import YouTube Video

```bash
# 1. Ottieni trascrizione
curl -X POST http://localhost:8501/transcript \
  -H "Content-Type: application/json" \
  -d '{"url": "https://youtube.com/watch?v=xxx"}'

# 2. Carica in AnythingLLM
curl -X POST http://localhost:3001/api/workspace/brainery-workspace/upload \
  -H "Authorization: Bearer ALLLM-xxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "textContent": "<transcript_from_step_1>",
    "metadata": {
      "title": "<video_title>",
      "source": "youtube"
    }
  }'

# 3. Query RAG
curl -X POST http://localhost:3001/api/workspace/brainery-workspace/chat \
  -H "Authorization: Bearer ALLLM-xxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Summarize the video",
    "mode": "query"
  }'
```

### Workflow Tipico: Import Web Page

```bash
# 1. Scrape pagina
curl -X POST http://localhost:11235/md \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/article"}'

# 2. Carica in AnythingLLM
curl -X POST http://localhost:3001/api/workspace/brainery-workspace/upload \
  -H "Authorization: Bearer ALLLM-xxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "textContent": "<markdown_from_step_1>",
    "metadata": {
      "title": "<article_title>",
      "source": "web"
    }
  }'
```

---

## Error Handling Strategy

### Errori comuni e soluzioni

| Status Code | Significato | Azione |
|-------------|-------------|--------|
| 400 Bad Request | Parametri invalidi | Verifica formato request (JSON, URL, etc.) |
| 401 Unauthorized | API key mancante/invalida | Aggiungi header Authorization corretto |
| 404 Not Found | Risorsa non trovata | Verifica URL/endpoint corretto |
| 429 Too Many Requests | Rate limit superato | Attendi qualche secondo e riprova |
| 500 Internal Server Error | Errore server | Verifica log container: `docker logs <container>` |
| 502 Bad Gateway | Container non risponde | Verifica container running: `docker ps` |
| 504 Gateway Timeout | Request troppo lunga | Aumenta timeout o riduci dimensione input |

### Retry Strategy (consigliata)

```python
import time
import requests

def api_call_with_retry(url, max_retries=3, backoff=2):
    for attempt in range(max_retries):
        try:
            response = requests.post(url, json={...}, timeout=60)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code in [429, 500, 502, 504]:
                if attempt < max_retries - 1:
                    wait_time = backoff ** attempt
                    print(f"Retry {attempt+1}/{max_retries} after {wait_time}s...")
                    time.sleep(wait_time)
                else:
                    raise
            else:
                raise  # Don't retry on 400, 401, 404
```

---

**Prossima sezione:** GitHub Actions workflow (Sezione 9) documenterà il CI/CD automatico per build container.

### 9. GitHub Actions workflow

Questa sezione spiega come funziona il CI/CD automatico per build e pubblicazione container Docker su Docker Hub.

---

## Overview CI/CD

**GitHub Actions** compila automaticamente le immagini Docker e le pubblica su Docker Hub ogni volta che:
1. Fai push su branch `main`
2. Crei un tag versione (es: `v1.0.0`)
3. Ogni lunedì alle 00:00 UTC (rebuild settimanale automatico)

**Vantaggi:**
- ✅ Build automatico: nessun comando manuale
- ✅ Multi-platform: immagini per `linux/amd64` e `linux/arm64`
- ✅ Matrix build: compila tutti i 4 container in parallelo
- ✅ Cache ottimizzata: build veloci (3-5 minuti)
- ✅ Versioning automatico: tag `latest` + versione specifica

---

## Workflow File

**File:** `.github/workflows/build-and-push.yml`

Questo è il workflow completo già mostrato nella Sezione 5, ma qui lo spieghiamo in dettaglio.

```yaml
name: Build and Push Docker Images

on:
  push:
    branches:
      - main
    tags:
      - 'v*'
  pull_request:
    branches:
      - main
  schedule:
    # Rebuild settimanale ogni lunedì alle 00:00
    - cron: '0 0 * * 1'

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [crawl4ai, anythingllm, yt-dlp-server, whisper-server]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract version
        id: version
        run: |
          if [[ $GITHUB_REF == refs/tags/* ]]; then
            echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
          else
            echo "VERSION=latest" >> $GITHUB_OUTPUT
          fi

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: ./dockerfiles/${{ matrix.service }}
          push: true
          tags: |
            tapiocapioca/${{ matrix.service }}:${{ steps.version.outputs.VERSION }}
            tapiocapioca/${{ matrix.service }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## Spiegazione Step-by-Step

### Trigger Events (`on:`)

```yaml
on:
  push:
    branches:
      - main
    tags:
      - 'v*'
  pull_request:
    branches:
      - main
  schedule:
    - cron: '0 0 * * 1'
```

**Quando si attiva il workflow:**

| Event | Trigger | Esempio |
|-------|---------|---------|
| **Push su main** | Ogni commit su branch main | `git push origin main` |
| **Tag versione** | Creazione tag che inizia con `v` | `git tag v1.0.0 && git push origin v1.0.0` |
| **Pull Request** | PR verso main (solo build, no push) | Apri PR su GitHub |
| **Schedule** | Ogni lunedì 00:00 UTC | Automatico |

**Perché schedule settimanale?**
- Aggiorna base images (security patches)
- Mantiene immagini fresche con ultime dipendenze
- Previene build failure dovuti a dipendenze obsolete

---

### Matrix Build Strategy

```yaml
strategy:
  matrix:
    service: [crawl4ai, anythingllm, yt-dlp-server, whisper-server]
```

**Matrix build** = GitHub Actions crea **4 job paralleli**, uno per ogni servizio.

**Vantaggi:**
- ⚡ Build paralleli: tutti i container compilano contemporaneamente
- ⏱️ Tempo totale: ~5-7 minuti (vs ~20 minuti sequenziali)
- 🔄 Isolation: se un build fallisce, gli altri continuano

**Come funziona:**
```
Job 1: crawl4ai       ──────> Build ──────> Push
Job 2: anythingllm    ──────> Build ──────> Push
Job 3: yt-dlp-server  ──────> Build ──────> Push
Job 4: whisper-server ──────> Build ──────> Push
```

**Variabile `${{ matrix.service }}`:**
- Viene sostituita con il nome servizio corrente
- Es: `dockerfiles/${{ matrix.service }}` diventa `dockerfiles/yt-dlp-server`

---

### Step 1: Checkout Code

```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

**Cosa fa:**
- Clona repository nel runner GitHub Actions
- Permette accesso a Dockerfiles e codice sorgente

**Actions usata:** `actions/checkout@v4` (versione ufficiale GitHub)

---

### Step 2: Setup Docker Buildx

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
```

**Cosa fa:**
- Configura Docker Buildx (builder avanzato Docker)
- Abilita funzionalità: multi-platform builds, cache avanzata, parallelizzazione

**Buildx vs Docker normale:**
- Buildx: supporta `linux/amd64` e `linux/arm64` (Apple Silicon)
- Buildx: cache layers più efficiente
- Buildx: build parallelizzati

**Perché necessario:**
- GitHub Actions runner usa Ubuntu (amd64)
- Buildx permette cross-compilation per ARM (Apple M1/M2/M3)

---

### Step 3: Login Docker Hub

```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

**Cosa fa:**
- Autentica GitHub Actions con Docker Hub
- Permette push immagini su `tapiocapioca/*`

**Secrets necessari:**

| Secret Name | Valore | Come ottenerlo |
|-------------|--------|----------------|
| `DOCKER_USERNAME` | `tapiocapioca` | Il tuo username Docker Hub |
| `DOCKER_PASSWORD` | Token/password | Personal Access Token da Docker Hub |

**⚠️ IMPORTANTE: Usare Personal Access Token, NON password diretta**

**Creare Personal Access Token Docker Hub:**
1. Login su https://hub.docker.com/
2. Account Settings > Security > Personal Access Tokens
3. Generate New Token
4. Scope: "Read, Write, Delete"
5. Copia token (mostrato una sola volta)

**Configurare secrets GitHub:**

Via web:
1. Vai su repository GitHub
2. Settings > Secrets and variables > Actions
3. "New repository secret"
4. Name: `DOCKER_USERNAME`, Value: `tapiocapioca`
5. Ripeti con `DOCKER_PASSWORD` e il token

Via CLI:
```bash
gh secret set DOCKER_USERNAME --body "tapiocapioca"
gh secret set DOCKER_PASSWORD --body "dckr_pat_xxxxxxxxxxxxx"
```

---

### Step 4: Extract Version

```yaml
- name: Extract version
  id: version
  run: |
    if [[ $GITHUB_REF == refs/tags/* ]]; then
      echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
    else
      echo "VERSION=latest" >> $GITHUB_OUTPUT
    fi
```

**Cosa fa:**
- Determina versione da usare per tag Docker
- Se trigger = tag git (`v1.0.0`) → versione = `v1.0.0`
- Se trigger = push/schedule → versione = `latest`

**Output variable:** `steps.version.outputs.VERSION`

**Esempi:**

| Trigger | `GITHUB_REF` | `VERSION` output |
|---------|--------------|------------------|
| `git push origin main` | `refs/heads/main` | `latest` |
| `git push origin v1.0.0` | `refs/tags/v1.0.0` | `v1.0.0` |
| `git push origin v2.1.3` | `refs/tags/v2.1.3` | `v2.1.3` |
| Schedule (cron) | `refs/heads/main` | `latest` |

**Bash breakdown:**
```bash
# ${GITHUB_REF#refs/tags/} = rimuove prefisso "refs/tags/"
# Esempio: refs/tags/v1.0.0 → v1.0.0
```

---

### Step 5: Build and Push

```yaml
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: ./dockerfiles/${{ matrix.service }}
    push: true
    tags: |
      tapiocapioca/${{ matrix.service }}:${{ steps.version.outputs.VERSION }}
      tapiocapioca/${{ matrix.service }}:latest
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

**Cosa fa:**
- Compila immagine Docker dal Dockerfile
- Tagga con versione specifica + `latest`
- Pusha su Docker Hub
- Usa cache GitHub Actions per velocizzare build successivi

**Parameters:**

| Parametro | Valore | Spiegazione |
|-----------|--------|-------------|
| `context` | `./dockerfiles/yt-dlp-server` | Directory con Dockerfile |
| `push` | `true` | Pusha su Docker Hub dopo build |
| `tags` | `tapiocapioca/yt-dlp-server:v1.0.0`<br>`tapiocapioca/yt-dlp-server:latest` | Doppio tag: versione + latest |
| `cache-from` | `type=gha` | Riusa cache da build precedenti |
| `cache-to` | `type=gha,mode=max` | Salva cache per build futuri |

**Esempio concreto (yt-dlp-server, versione v1.2.0):**
```yaml
context: ./dockerfiles/yt-dlp-server
tags:
  - tapiocapioca/yt-dlp-server:v1.2.0
  - tapiocapioca/yt-dlp-server:latest
```

**Risultato su Docker Hub:**
```
tapiocapioca/yt-dlp-server:v1.2.0  ← Versione specifica
tapiocapioca/yt-dlp-server:latest  ← Sempre punta all'ultima
```

---

## GitHub Actions Cache

**Cache Strategy:** `type=gha,mode=max`

**Cosa viene cachato:**
- Layer Docker intermedi (FROM, RUN, COPY)
- Dipendenze Python (pip install)
- Dipendenze sistema (apt-get install)

**Vantaggi:**
- Prima build: ~8-10 minuti
- Build successive: ~3-5 minuti (cache hit)
- Riduce carico su package registries (PyPI, apt repositories)

**Come funziona:**
1. Build iniziale: salva ogni layer Docker in cache GitHub
2. Build successivo: verifica se Dockerfile/requirements cambiati
3. Se non cambiati: riusa layer dalla cache (no re-download)

**Cache invalidation:**
- Cambio Dockerfile → cache invalidata da quel layer in poi
- Cambio requirements.txt → cache invalidata da pip install in poi
- Cambio server.py → solo ultimo layer ricompilato

**Esempio:**
```dockerfile
FROM python:3.12-slim           # ← Cache hit (layer non cambia mai)
RUN apt-get install ffmpeg      # ← Cache hit (comando non cambiato)
COPY requirements.txt .         # ← Cache hit (file non cambiato)
RUN pip install -r requirements.txt  # ← Cache hit (requirements non cambiato)
COPY server.py .                # ← Cache MISS (server.py modificato)
```

Solo l'ultimo layer viene ricompilato → build velocissimo.

---

## Workflow Execution Flow

### Scenario 1: Push su main (normale sviluppo)

```
1. Developer fa commit e push:
   $ git add .
   $ git commit -m "Fix: bug in yt-dlp parsing"
   $ git push origin main

2. GitHub Actions trigger automatico:
   ✓ Checkout code
   ✓ Setup Buildx
   ✓ Login Docker Hub
   ✓ Extract version → VERSION=latest
   ✓ Build 4 container in parallelo
   ✓ Push su Docker Hub con tag "latest"

3. Risultato Docker Hub:
   tapiocapioca/crawl4ai:latest (aggiornato)
   tapiocapioca/anythingllm:latest (aggiornato)
   tapiocapioca/yt-dlp-server:latest (aggiornato)
   tapiocapioca/whisper-server:latest (aggiornato)
```

**Tempo totale:** ~5-7 minuti

---

### Scenario 2: Release versione (tag git)

```
1. Developer crea release:
   $ echo "1.2.0" > VERSION
   $ git add VERSION
   $ git commit -m "Bump version to 1.2.0"
   $ git tag -a v1.2.0 -m "Release version 1.2.0"
   $ git push origin v1.2.0

2. GitHub Actions trigger automatico:
   ✓ Checkout code
   ✓ Setup Buildx
   ✓ Login Docker Hub
   ✓ Extract version → VERSION=v1.2.0
   ✓ Build 4 container in parallelo
   ✓ Push con DOPPIO TAG: v1.2.0 + latest

3. Risultato Docker Hub:
   tapiocapioca/yt-dlp-server:v1.2.0 (nuovo)
   tapiocapioca/yt-dlp-server:latest (aggiornato a v1.2.0)
```

**Vantaggi doppio tag:**
- Utenti con `latest` → aggiornamento automatico
- Utenti con `v1.2.0` → versione fissa (no breaking changes)

---

### Scenario 3: Pull Request (test prima di merge)

```
1. Developer crea PR:
   $ git checkout -b fix-bug
   $ git add .
   $ git commit -m "Fix bug"
   $ git push origin fix-bug
   (Crea PR su GitHub)

2. GitHub Actions trigger automatico:
   ✓ Checkout PR code
   ✓ Setup Buildx
   ✓ Login Docker Hub
   ✓ Build 4 container in parallelo
   ✗ NO PUSH (solo test build)

3. Risultato:
   ✅ Se build OK → PR approvabile
   ❌ Se build fallisce → PR bloccata
```

**Scopo:** Verifica che modifiche non rompano build prima di merge su main.

---

### Scenario 4: Rebuild settimanale automatico

```
1. Ogni lunedì 00:00 UTC:
   GitHub Actions trigger automatico (cron)

2. Workflow execution:
   ✓ Checkout code (branch main)
   ✓ Setup Buildx
   ✓ Login Docker Hub
   ✓ Extract version → VERSION=latest
   ✓ Build 4 container con dipendenze aggiornate
   ✓ Push su Docker Hub con tag "latest"

3. Risultato:
   Container con ultime security patches
   Dipendenze Python/Node aggiornate
   Base images aggiornate
```

**Perché utile:**
- Security patches automatici
- Previene "dependency rot" (dipendenze obsolete)
- Container sempre aggiornati senza intervento manuale

---

## Monitoring e Debugging

### Visualizzare workflow execution

**Via GitHub Web:**
1. Vai su repository GitHub
2. Tab "Actions"
3. Vedi lista workflow runs
4. Click su run specifico per dettagli

**Via GitHub CLI:**
```bash
# Lista workflow runs recenti
gh run list

# Dettagli specifico run
gh run view <run-id>

# Log completi
gh run view <run-id> --log
```

---

### Interpretare workflow status

**Icone status:**

| Icona | Status | Significato |
|-------|--------|-------------|
| 🟡 (giallo) | In progress | Workflow in esecuzione |
| ✅ (verde) | Success | Tutti i job completati con successo |
| ❌ (rosso) | Failure | Almeno un job fallito |
| ⚪ (grigio) | Queued | In coda, in attesa di runner disponibile |
| 🟠 (arancione) | Cancelled | Workflow cancellato manualmente |

---

### Debugging build failures

**Scenario comune: Build fallisce**

**1. Verifica log job fallito:**
```bash
gh run view --log
```

Cerca sezione "Build and push" per il servizio che ha fallito.

**2. Errori comuni:**

**Error: `Error response from daemon: pull access denied`**
```
Causa: Docker Hub secrets non configurati o errati
Fix: Verifica DOCKER_USERNAME e DOCKER_PASSWORD in GitHub Secrets
```

**Error: `failed to solve: process "/bin/sh -c pip install..." did not complete`**
```
Causa: Dipendenza Python non trovata o incompatibile
Fix: Verifica requirements.txt, testa build locale
```

**Error: `COPY server.py: no such file or directory`**
```
Causa: File mancante o path sbagliato in Dockerfile
Fix: Verifica struttura directory, correggi path COPY
```

**Error: `denied: requested access to the resource is denied`**
```
Causa: Token Docker Hub senza permessi write
Fix: Rigenera token con scope "Read, Write, Delete"
```

---

### Test build locale (prima di push)

Prima di committare, testa build localmente:

```bash
# Build singolo container
cd dockerfiles/yt-dlp-server
docker build -t yt-dlp-server:test .

# Build tutti i container (simula GitHub Actions)
docker build -t crawl4ai:test dockerfiles/crawl4ai
docker build -t anythingllm:test dockerfiles/anythingllm
docker build -t yt-dlp-server:test dockerfiles/yt-dlp-server
docker build -t whisper-server:test dockerfiles/whisper-server

# Test avvio
docker run -d --name test-ytdlp -p 8501:8501 yt-dlp-server:test
curl http://localhost:8501/health

# Cleanup
docker stop test-ytdlp
docker rm test-ytdlp
```

---

## Best Practices CI/CD

### 1. Semantic Versioning

**Formato:** `vMAJOR.MINOR.PATCH`

```
v1.0.0 → Prima release stabile
v1.1.0 → Nuove funzionalità (backward compatible)
v1.1.1 → Bug fix
v2.0.0 → Breaking changes
```

**Quando incrementare:**
- MAJOR: Cambi API incompatibili, breaking changes
- MINOR: Nuove funzionalità backward compatible
- PATCH: Bug fix, security patches

**Esempio:**
```bash
# Feature: nuovo endpoint /metadata
git tag -a v1.1.0 -m "Add metadata endpoint"

# Bugfix: fix transcript parsing
git tag -a v1.1.1 -m "Fix transcript parsing bug"

# Breaking: cambio formato response API
git tag -a v2.0.0 -m "Breaking: new response format"
```

---

### 2. Conventional Commits

**Formato:** `type(scope): message`

```
feat(yt-dlp): add metadata endpoint
fix(whisper): handle audio download timeout
docs(readme): update installation instructions
chore(deps): update yt-dlp to 2024.2.0
```

**Vantaggi:**
- Changelog automatico generabile
- Chiaro impatto delle modifiche
- Facilita code review

---

### 3. Protected Branches

**Configura branch protection su `main`:**

1. GitHub > Settings > Branches > Add rule
2. Branch name pattern: `main`
3. Abilita:
   - ✅ Require status checks to pass (workflow deve passare)
   - ✅ Require pull request reviews (almeno 1 reviewer)
   - ✅ Include administrators (regole valgono per tutti)

**Risultato:**
- Push diretto su main bloccato
- Solo merge via PR dopo build success
- Maggiore qualità codice

---

### 4. Dependabot (opzionale ma consigliato)

**Automated dependency updates:**

**File:** `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: "docker"
    directory: "/dockerfiles/yt-dlp-server"
    schedule:
      interval: "weekly"

  - package-ecosystem: "pip"
    directory: "/dockerfiles/yt-dlp-server"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

**Cosa fa:**
- Crea PR automatiche per aggiornare dipendenze
- Aggiorna base images Docker
- Aggiorna GitHub Actions versions

---

### 5. Multi-Platform Builds (opzionale)

**Supporto Apple Silicon (ARM64):**

Modifica step "Build and push":

```yaml
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: ./dockerfiles/${{ matrix.service }}
    push: true
    platforms: linux/amd64,linux/arm64  # ← Aggiungi questa riga
    tags: |
      tapiocapioca/${{ matrix.service }}:${{ steps.version.outputs.VERSION }}
      tapiocapioca/${{ matrix.service }}:latest
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

**Effetto:**
- Build per Intel (amd64) e Apple Silicon (arm64)
- Utenti Mac M1/M2/M3 usano immagine nativa (più veloce)

**⚠️ Attenzione:** Build time raddoppia (~10-15 minuti totali)

---

## Troubleshooting Common Issues

### Problema: Build fallisce con "disk space"

**Error:**
```
Error: No space left on device
```

**Causa:** GitHub Actions runner ha spazio limitato (~14GB disponibili)

**Fix:**
```yaml
- name: Free disk space
  run: |
    docker system prune -af --volumes
    sudo rm -rf /usr/local/lib/android
    sudo rm -rf /opt/hostedtoolcache
```

Aggiungi prima di "Build and push".

---

### Problema: Cache troppo vecchia

**Sintomo:** Build usa dipendenze obsolete nonostante requirements.txt aggiornato

**Fix:** Invalida cache manualmente

```bash
# Via GitHub web: Re-run workflow con checkbox "Clear cache"

# Via CLI: Cancella cache
gh cache delete --all
```

---

### Problema: Push fallisce con 401 Unauthorized

**Causa:** Token Docker Hub scaduto o revocato

**Fix:**
1. Genera nuovo token su Docker Hub
2. Aggiorna secret GitHub: `gh secret set DOCKER_PASSWORD --body "nuovo-token"`
3. Re-run workflow fallito

---

## Riepilogo GitHub Actions

**Configurazione:**
- 1 workflow file: `.github/workflows/build-and-push.yml`
- 2 secrets GitHub: `DOCKER_USERNAME`, `DOCKER_PASSWORD`
- Matrix build: 4 container in parallelo

**Trigger automatici:**
- Push su `main` → build + push con tag `latest`
- Tag `v*` → build + push con tag versione + `latest`
- PR → build only (no push)
- Schedule lunedì 00:00 → rebuild settimanale

**Risultato:**
- Immagini su Docker Hub sempre aggiornate
- Zero intervento manuale per deploy
- CI/CD completamente automatizzato

**Tempo build tipico:** ~5-7 minuti (con cache)

---

**Prossima sezione:** Troubleshooting (Sezione 10) con guida completa ai problemi comuni.

### 10. Troubleshooting

Questa sezione raccoglie i problemi più comuni con Brainery e le loro soluzioni.

---

## Indice Problemi

**Setup e Installazione:**
- [Docker non si avvia](#problema-docker-non-si-avvia)
- [Container non parte dopo docker-compose up](#problema-container-non-parte)
- [Porta già in uso](#problema-porta-già-in-uso)
- [Spazio disco insufficiente](#problema-spazio-disco-insufficiente)

**Container Runtime:**
- [Container stuck su "starting" healthcheck](#problema-healthcheck-stuck)
- [Container crash e restart continuo](#problema-container-crash-loop)
- [AnythingLLM errore 500](#problema-anythingllm-errore-500)
- [Whisper primo avvio lentissimo](#problema-whisper-lento)

**API e Funzionalità:**
- [Trascrizioni YouTube non funzionano](#problema-trascrizioni-youtube)
- [Crawl4AI timeout su pagine web](#problema-crawl4ai-timeout)
- [AnythingLLM non trova documenti](#problema-anythingllm-rag-vuoto)
- [Whisper out of memory](#problema-whisper-oom)

**Performance:**
- [Sistema troppo lento](#problema-performance-generale)
- [Container consumano troppa RAM](#problema-memoria-alta)
- [Build GitHub Actions fallisce](#problema-github-actions-fail)

---

## Setup e Installazione

### Problema: Docker non si avvia

**Sintomi:**
```bash
$ docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Causa:** Docker Desktop non avviato o servizio Docker non running.

**Soluzioni:**

**Windows:**
```powershell
# Verifica Docker Desktop aperto
Get-Process "Docker Desktop" -ErrorAction SilentlyContinue

# Se non running, avvia Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Attendi 30-60 secondi, poi verifica
docker version
```

**macOS:**
```bash
# Avvia Docker Desktop
open -a Docker

# Attendi startup, poi verifica
docker version
```

**Linux:**
```bash
# Avvia servizio Docker
sudo systemctl start docker

# Abilita avvio automatico
sudo systemctl enable docker

# Verifica
docker version
```

**Se persiste:**
- Reinstalla Docker Desktop
- Verifica virtualizzazione abilitata (Windows: WSL2, macOS: Hypervisor)

---

### Problema: Container non parte

**Sintomi:**
```bash
$ docker-compose up -d
ERROR: ... failed to start
```

**Diagnosi:**
```bash
# Verifica log specifico container
docker logs crawl4ai
docker logs anythingllm
docker logs yt-dlp-server
docker logs whisper-server
```

**Causa 1: Porta già in uso**

Vedi [Porta già in uso](#problema-porta-già-in-uso).

**Causa 2: Errore nel Dockerfile**

```bash
# Test build manuale
docker build -t test dockerfiles/yt-dlp-server

# Se fallisce: verifica errore nel Dockerfile
# Correggi e riprova
```

**Causa 3: Immagine corrotta**

```bash
# Cancella immagine e re-pull
docker rmi tapiocapioca/yt-dlp-server:latest
docker-compose pull
docker-compose up -d
```

**Causa 4: Volume permission issue (Linux)**

```bash
# Reset permessi volumi
docker-compose down -v  # ⚠️ Cancella dati!
docker-compose up -d
```

---

### Problema: Porta già in uso

**Sintomi:**
```
Error: bind: address already in use
Port 3001 is already allocated
```

**Verifica quale processo usa la porta:**

**Windows:**
```powershell
netstat -ano | findstr :3001
# Output: TCP  0.0.0.0:3001  0.0.0.0:0  LISTENING  1234
# 1234 = Process ID (PID)

# Trova processo
Get-Process -Id 1234

# Termina processo (se sicuro)
Stop-Process -Id 1234 -Force
```

**Linux/macOS:**
```bash
# Trova processo
lsof -i :3001
# Output: node  1234 user  ... (LISTEN)

# Termina processo
kill -9 1234
```

**Alternativa: Cambia porta in docker-compose.yml**

```yaml
services:
  anythingllm:
    ports:
      - "3002:3001"  # Host:Container - cambia 3002 con porta libera
```

Poi accedi su `http://localhost:3002` invece di `3001`.

---

### Problema: Spazio disco insufficiente

**Sintomi:**
```
no space left on device
ERROR: failed to create shim task
```

**Verifica spazio:**
```bash
# Spazio totale
df -h

# Spazio Docker
docker system df
```

**Pulizia Docker:**

```bash
# Rimuovi container stopped
docker container prune -f

# Rimuovi immagini unused
docker image prune -a -f

# Rimuovi volumi unused (⚠️ attenzione ai dati!)
docker volume prune -f

# Pulizia completa (libera ~5-10GB)
docker system prune -a --volumes -f
```

**⚠️ ATTENZIONE:** `docker system prune -a --volumes` cancella TUTTI i volumi → **perdi dati AnythingLLM**.

**Backup prima di pulire:**
```bash
# Backup volume anythingllm (vedi Sezione 7)
docker run --rm -v anythingllm-storage:/data -v $(pwd):/backup \
  alpine tar czf /backup/anythingllm-backup.tar.gz /data
```

---

## Container Runtime

### Problema: Healthcheck stuck

**Sintomi:**
```bash
$ docker ps
... (health: starting) ...  # Stuck per >5 minuti
```

**Verifica log container:**
```bash
docker logs <container-name> --tail 100
```

**Scenario 1: Whisper downloading model**

```
Log: "Downloading whisper model..."
```

**Soluzione:** NORMALE. Primo avvio Whisper scarica ~1GB model.
- Attendi 5-10 minuti (dipende da connessione)
- Avvii successivi: immediati

**Scenario 2: AnythingLLM startup lento**

```
Log: "Starting AnythingLLM server..."
```

**Soluzione:** Attendi 2-3 minuti. AnythingLLM richiede tempo iniziale.

**Scenario 3: Errore nell'applicazione**

```
Log: "Error: ... crashed"
```

**Soluzione:** Leggi errore specifico, cerca soluzione in questa sezione.

**Forzare restart:**
```bash
docker restart <container-name>

# Se persiste
docker-compose down
docker-compose up -d
```

---

### Problema: Container crash loop

**Sintomi:**
```bash
$ docker ps -a
... Restarting (1) 2 seconds ago ...
```

**Verifica causa crash:**
```bash
# Log completi
docker logs <container-name> --tail 200

# Follow log real-time
docker logs <container-name> -f
```

**Causa 1: Out of Memory**

```
Log: "Killed" o "OOMKilled"
```

**Soluzione:**
- Chiudi applicazioni che consumano RAM
- Aumenta RAM allocata a Docker (Docker Desktop > Settings > Resources)
- Vedi [Problema memoria alta](#problema-memoria-alta)

**Causa 2: Dipendenza mancante**

```
Log: "ModuleNotFoundError: No module named 'xxx'"
```

**Soluzione:**
```bash
# Rebuild container
docker-compose build <service-name>
docker-compose up -d <service-name>
```

**Causa 3: Config errata**

```
Log: "Configuration error: ..."
```

**Soluzione:** Verifica environment variables in `docker-compose.yml`.

---

### Problema: AnythingLLM errore 500

**Sintomi:**
```bash
$ curl http://localhost:3001/api/ping
Internal Server Error
```

**Causa 1: LLM provider non configurato**

**Soluzione:**
1. Apri http://localhost:3001
2. Settings > LLM Preference
3. Configura iFlow:
   - Provider: Generic OpenAI
   - Base URL: `https://api.iflow.cn/v1`
   - API Key: `sk-xxxxx` (tua key iFlow)
   - Model: `glm-4.6`

**Causa 2: API Key invalida**

```
Log: "Invalid API key"
```

**Soluzione:**
- Verifica key iFlow valida: https://platform.iflow.cn/profile?tab=apiKey
- Rigenera se necessario
- Riconfigura in AnythingLLM

**Causa 3: Storage corrotto**

```
Log: "Database error" o "SQLite error"
```

**Soluzione (⚠️ perde dati):**
```bash
docker-compose down
docker volume rm anythingllm-storage
docker-compose up -d

# Riconfigura LLM provider
```

**Soluzione (preserva backup):**
```bash
# Backup volume
docker run --rm -v anythingllm-storage:/data -v $(pwd):/backup \
  alpine tar czf /backup/anythingllm-backup.tar.gz /data

# Reset
docker-compose down
docker volume rm anythingllm-storage
docker-compose up -d
```

---

### Problema: Whisper lento

**Sintomi:**
- Primo avvio: container impiega 10+ minuti per diventare healthy
- Trascrizione audio: 30+ minuti per 1 ora audio

**Causa 1: Download modello primo avvio**

**Soluzione:** NORMALE. Attendi completamento download (~1GB).

**Verifica:**
```bash
docker logs whisper-server | grep -i download
```

**Causa 2: Modello troppo grande**

Default: modello "base" (~140MB parameters)

**Soluzione: Usa modello più piccolo (meno accurato)**

Modifica `dockerfiles/whisper-server/server.py`:
```python
# Prima:
MODEL_NAME = os.getenv("WHISPER_MODEL", "base")

# Dopo:
MODEL_NAME = os.getenv("WHISPER_MODEL", "tiny")  # 39M params, 10x più veloce
```

Oppure via environment variable in `docker-compose.yml`:
```yaml
whisper-server:
  environment:
    - WHISPER_MODEL=tiny
```

**Modelli disponibili:**
| Modello | Size | Speed | Accuracy |
|---------|------|-------|----------|
| tiny | 39M | 10x | Bassa |
| base | 74M | 1x (baseline) | Media |
| small | 244M | 0.5x | Alta |
| medium | 769M | 0.2x | Molto alta |

**Causa 3: CPU insufficiente**

Whisper richiede CPU potente (4+ core consigliati).

**Soluzione:**
- Chiudi applicazioni CPU-intensive
- Usa modello "tiny"
- Considera GPU support (richiede CUDA, solo Linux)

---

## API e Funzionalità

### Problema: Trascrizioni YouTube

**Sintomi:**
```bash
$ curl -X POST http://localhost:8501/transcript -d '{"url":"..."}'
{"detail":"Video unavailable"}
```

**Causa 1: Video privato/rimosso**

**Soluzione:** Verifica video accessibile su browser. Se privato/removed, impossibile scaricare.

**Causa 2: Region-locked**

```
Log: "Video not available in your region"
```

**Soluzione:** Video bloccato geograficamente. Impossibile aggirare senza VPN (non supportato).

**Causa 3: Rate limit YouTube**

```
Log: "HTTP Error 429: Too Many Requests"
```

**Soluzione:**
- Attendi 10-30 minuti
- Riduci frequenza richieste
- YouTube limita per IP

**Causa 4: No subtitles e Whisper fallback fail**

```
Log: "No subtitles found and unable to extract audio"
```

**Soluzione:**
- Verifica whisper-server running: `docker ps | grep whisper`
- Verifica whisper-server healthy: `curl http://localhost:8502/health`
- Se whisper down, vedi [Problema whisper lento](#problema-whisper-lento)

---

### Problema: Crawl4AI timeout

**Sintomi:**
```bash
$ curl -X POST http://localhost:11235/md -d '{"url":"https://..."}'
{"error":"Connection timeout"}
```

**Causa 1: Sito lento/non risponde**

**Soluzione:** Aumenta timeout (modifica Crawl4AI config, avanzato).

**Workaround:** Prova URL alternativo o copia manualmente contenuto.

**Causa 2: Sito blocca scraping (403 Forbidden)**

```
Log: "HTTP 403: Forbidden"
```

**Soluzione:**
- Alcuni siti bloccano bot/scraper
- Crawl4AI ha user-agent browser, ma alcuni siti rilevano comunque
- Workaround: Copia manualmente contenuto pagina

**Causa 3: JavaScript-heavy page**

**Soluzione:** Crawl4AI renderizza JS, ma pagine molto complesse possono fallire.

**Workaround:** Usa endpoint `/crawl` invece di `/md` con config custom (avanzato).

---

### Problema: AnythingLLM RAG vuoto

**Sintomi:**
```bash
$ curl -X POST http://localhost:3001/api/workspace/test/chat \
  -d '{"message":"Summarize document","mode":"query"}'
{"textResponse":"I don't have information about that"}
```

**Causa 1: Mode "chat" invece di "query"**

```json
{"mode":"chat"}  // ❌ IGNORA documenti
```

**Soluzione:**
```json
{"mode":"query"}  // ✅ USA documenti RAG
```

**Causa 2: Workspace vuoto**

**Verifica:**
```bash
curl http://localhost:3001/api/workspace/test/documents \
  -H "Authorization: Bearer ALLLM-xxxxx"
```

Se `{"documents":[]}` → workspace vuoto.

**Soluzione:** Carica documenti (vedi Sezione 8 API).

**Causa 3: Embedding fallito**

```
Log AnythingLLM: "Failed to generate embeddings"
```

**Soluzione:**
- Verifica LLM provider configurato correttamente
- Ricarica documento: delete + re-upload

---

### Problema: Whisper OOM

**Sintomi:**
```
Log: "Killed"
Container exit code: 137 (OOMKilled)
```

**Causa:** File audio troppo lungo per RAM disponibile.

**Soluzioni:**

**1. Usa modello più piccolo:**
```yaml
whisper-server:
  environment:
    - WHISPER_MODEL=tiny  # Consuma meno RAM
```

**2. Aumenta RAM Docker:**
- Docker Desktop > Settings > Resources > Memory
- Aumenta a 8GB+ (se sistema ha 16GB totali)

**3. Processa audio in chunk (avanzato):**

Modifica `whisper-server/server.py` per splittare audio >30 minuti.

**4. Limita lunghezza audio:**

Documenta che audio >1 ora non supportato su sistemi con 8GB RAM.

---

## Performance

### Problema: Performance generale

**Sintomi:**
- Risposte API lente (>30 secondi)
- Sistema operativo lag
- Container usano 100% CPU

**Diagnosi:**
```bash
# CPU e RAM uso container
docker stats

# Identifica container problematico
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

**Soluzione 1: Limita risorse container**

Modifica `docker-compose.yml`:
```yaml
services:
  whisper-server:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
```

**Soluzione 2: Chiudi container non usati**

```bash
# Stop container specifico
docker-compose stop whisper-server

# Riavvia quando serve
docker-compose start whisper-server
```

**Soluzione 3: Upgrade hardware**

Requisiti minimi Brainery:
- CPU: 4 core
- RAM: 12GB
- SSD (non HDD)

Se sotto questi valori, performance scarse inevitabili.

---

### Problema: Memoria alta

**Sintomi:**
```bash
$ docker stats
CONTAINER     MEM USAGE
whisper       6.5GB / 8GB  (81%)
anythingllm   2.1GB / 8GB  (26%)
```

**Causa:** Whisper + AnythingLLM memory-intensive (modelli ML).

**Soluzioni:**

**1. Ridimensiona modelli:**

Whisper: usa "tiny" invece di "base"
```yaml
whisper-server:
  environment:
    - WHISPER_MODEL=tiny
```

AnythingLLM: usa embedding model più piccolo (Settings > Embedding Preference > Change Model)

**2. Restart periodico:**

```bash
# Restart settimanale container
docker-compose restart
```

**3. Memory limits:**

```yaml
services:
  whisper-server:
    deploy:
      resources:
        limits:
          memory: 4G
```

⚠️ Limite troppo basso causa OOM crash.

---

### Problema: GitHub Actions fail

**Sintomi:**
- Build fallisce su GitHub Actions
- Push locale funziona

**Causa 1: Secrets non configurati**

```
Error: denied: requested access to resource is denied
```

**Soluzione:** Configura `DOCKER_USERNAME` e `DOCKER_PASSWORD` secrets (vedi Sezione 9).

**Causa 2: Dipendenza non trovata**

```
Error: Could not find a version that satisfies the requirement ...
```

**Soluzione:**
- Verifica `requirements.txt` corretto
- Test build locale: `docker build -t test dockerfiles/yt-dlp-server`
- Fix dipendenze e re-push

**Causa 3: Disk space**

```
Error: no space left on device
```

**Soluzione:** Aggiungi cleanup step (vedi Sezione 9 Troubleshooting).

**Causa 4: Cache corrotta**

**Soluzione:**
```bash
# Invalida cache GitHub Actions
gh cache delete --all

# Re-run workflow
gh run rerun <run-id>
```

---

## Quick Reference: Comandi Utili

### Restart completo sistema

```bash
# Stop tutto
docker-compose down

# Pulizia cache (opzionale)
docker system prune -f

# Start tutto
docker-compose up -d

# Verifica health
docker ps
```

### Verifica stato container

```bash
# Container running + health
docker ps

# Log errori
docker logs <container> --tail 100

# Resource usage
docker stats --no-stream

# Verifica rete
docker network inspect brainery_default
```

### Reset completo (⚠️ perde dati)

```bash
# Stop e rimuovi tutto
docker-compose down -v

# Rimuovi immagini
docker rmi tapiocapioca/crawl4ai:latest \
  tapiocapioca/anythingllm:latest \
  tapiocapioca/yt-dlp-server:latest \
  tapiocapioca/whisper-server:latest

# Re-pull e start
docker-compose pull
docker-compose up -d
```

### Backup dati critici

```bash
# Backup AnythingLLM (vedi Sezione 7)
docker run --rm -v anythingllm-storage:/data -v $(pwd):/backup \
  alpine tar czf /backup/anythingllm-backup-$(date +%Y%m%d).tar.gz /data

# Restore
docker run --rm -v anythingllm-storage:/data -v $(pwd):/backup \
  alpine tar xzf /backup/anythingllm-backup-YYYYMMDD.tar.gz -C /
```

---

## Quando Chiedere Aiuto

Se dopo aver provato tutte le soluzioni sopra il problema persiste:

**1. Raccogli informazioni diagnostiche:**

```bash
# System info
docker version
docker-compose version
uname -a  # Linux/macOS
systeminfo | findstr OS  # Windows

# Container status
docker ps -a
docker-compose logs > logs.txt

# Resource usage
docker stats --no-stream > stats.txt
```

**2. Cerca online:**
- GitHub Issues: https://github.com/Tapiocapioca/brainery/issues
- Docker troubleshooting: https://docs.docker.com/config/daemon/troubleshoot/
- Specifico progetto:
  - Crawl4AI: https://github.com/unclecode/crawl4ai/issues
  - AnythingLLM: https://github.com/Mintplex-Labs/anything-llm/issues
  - yt-dlp: https://github.com/yt-dlp/yt-dlp/issues
  - Whisper: https://github.com/openai/whisper/issues

**3. Apri issue GitHub:**

Include:
- Descrizione problema
- Output comandi diagnostici sopra
- Log container rilevanti
- Cosa hai già provato

---

**Prossima sezione:** Decisioni architetturali (Sezione 11) spiega il "perché" dietro le scelte tecniche.

---

## PARTE 4: DECISIONI & NOTE

### 11. Decisioni architetturali

> **Scopo:** Documentare il "perché" dietro ogni scelta tecnica. Non è sufficiente sapere *cosa* fa il sistema—devi capire *perché* è stato progettato così per poter fare modifiche informate.

Ogni decisione segue questo formato:
- **Contesto:** Quale problema dovevamo risolvere
- **Decisione:** Cosa abbiamo scelto
- **Alternative considerate:** Cosa abbiamo scartato e perché
- **Conseguenze:** Trade-off accettati

---

#### AD-1: Container separati vs. monolitico

**Contesto:**
Dovevamo decidere come organizzare i 4 servizi (Crawl4AI, AnythingLLM, yt-dlp, Whisper). Le opzioni erano:
1. Un unico container "Brainery" con tutto
2. Container separati orchestrati da Docker Compose

**Decisione:** Container separati.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Monolitico | Setup più semplice, un'unica immagine | Immagine enorme (10+ GB), rebuild completo per ogni modifica, conflitti dipendenze Python |
| Separati | Aggiornamenti indipendenti, fault isolation, immagini più piccole | Setup iniziale più complesso, networking da configurare |

**Conseguenze:**
- ✅ Possiamo aggiornare Whisper senza toccare gli altri
- ✅ Se Crawl4AI crasha, AnythingLLM continua a funzionare
- ✅ Utenti con poco spazio disco possono escludere Whisper
- ⚠️ Docker Compose richiesto (non solo Docker)
- ⚠️ 4 immagini da mantenere invece di 1

---

#### AD-2: Docker Hub vs. GitHub Container Registry (GHCR)

**Contesto:**
Dove pubblicare le immagini? Le due opzioni principali per progetti open-source:
1. Docker Hub (docker.io)
2. GitHub Container Registry (ghcr.io)

**Decisione:** Docker Hub.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Docker Hub | Standard de facto, `docker pull` senza config, rate limit generoso per immagini pubbliche | Richiede account Docker separato |
| GHCR | Integrato con GitHub, stesso account | Richiede `docker login ghcr.io`, meno familiare agli utenti |

**Conseguenze:**
- ✅ Zero configurazione per gli utenti: `docker pull tapiocapioca/...` funziona subito
- ✅ Familiarità: tutti conoscono Docker Hub
- ⚠️ Account Docker Hub da mantenere oltre a GitHub
- ⚠️ Rate limit di 100 pull/6h per IP anonimi (non un problema per uso normale)

---

#### AD-3: iFlow vs. altri LLM provider

**Contesto:**
AnythingLLM richiede un LLM provider. Le opzioni erano:
1. OpenAI API (gpt-4, gpt-3.5)
2. Anthropic API (Claude)
3. Ollama locale
4. iFlow Platform (free tier)

**Decisione:** iFlow Platform come default, con istruzioni per alternative.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| OpenAI | Migliore qualità, standard | $0.03-0.06/1K tokens, richiede carta di credito |
| Anthropic | Claude eccellente | $0.015-0.08/1K tokens, richiede carta di credito |
| Ollama | Gratuito, 100% locale | Richiede 8+ GB RAM extra, GPU consigliata |
| iFlow | Gratuito, API compatibile OpenAI | Limiti non documentati, meno affidabile |

**Conseguenze:**
- ✅ Utenti possono iniziare senza spendere
- ✅ Compatibilità OpenAI = facile passare a provider a pagamento
- ⚠️ Qualità inferiore a GPT-4/Claude
- ⚠️ Possibili rate limit o downtime iFlow
- 📝 Documentato come cambiare provider (Sezione 4)

---

#### AD-4: FastAPI vs. Flask per server custom

**Contesto:**
Per yt-dlp-server e whisper-server serviva un framework web Python. Opzioni:
1. Flask
2. FastAPI
3. Sanic/Starlette

**Decisione:** FastAPI.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Flask | Più semplice, più documentazione | Sync by default, validazione manuale |
| FastAPI | Async nativo, validazione Pydantic, OpenAPI auto | Curva apprendimento leggermente più alta |
| Sanic | Molto veloce | Meno documentazione, community più piccola |

**Conseguenze:**
- ✅ `/docs` endpoint gratuito per testare API
- ✅ Validazione automatica con Pydantic
- ✅ Async = gestisce più richieste simultanee
- ⚠️ Richiede conoscenza async/await per modifiche avanzate

---

#### AD-5: Whisper base vs. modelli più grandi

**Contesto:**
OpenAI Whisper ha più modelli:
- tiny (39M parametri, ~1GB VRAM)
- base (74M, ~1GB)
- small (244M, ~2GB)
- medium (769M, ~5GB)
- large (1.5B, ~10GB)

**Decisione:** `base` come default, configurabile via env var.

**Alternative considerate:**

| Modello | WER* | Velocità | RAM |
|---------|------|----------|-----|
| tiny | ~16% | 32x | 1GB |
| base | ~11% | 16x | 1GB |
| small | ~8% | 6x | 2GB |
| medium | ~6% | 2x | 5GB |
| large | ~4% | 1x | 10GB |

*WER = Word Error Rate (più basso = migliore)

**Conseguenze:**
- ✅ Funziona su macchine con 8GB RAM
- ✅ Velocità accettabile (16x real-time)
- ⚠️ Qualità inferiore a small/medium su audio rumoroso
- 📝 Configurabile: `WHISPER_MODEL=small` per upgrade

---

#### AD-6: Named volumes vs. bind mounts

**Contesto:**
Come persistere i dati dei container:
1. Named volumes (Docker-managed)
2. Bind mounts (cartelle host)
3. tmpfs (solo RAM)

**Decisione:** Named volumes per dati, bind mounts opzionali per sviluppo.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Named volumes | Portabili, backup facile con docker | Meno visibili nel filesystem host |
| Bind mounts | File visibili direttamente, edit live | Path assoluti, problemi permessi su Linux |
| tmpfs | Velocissimo | Dati persi al riavvio |

**Conseguenze:**
- ✅ `docker volume ls` mostra tutti i dati
- ✅ Backup standardizzato (vedi Sezione 7)
- ⚠️ Per vedere i file serve `docker run` con volume montato
- 📝 Sviluppatori possono aggiungere bind mounts per debug

---

#### AD-7: Healthcheck strategy

**Contesto:**
Come verificare che i container siano "healthy":
1. Nessun healthcheck (Docker non sa se il servizio è up)
2. TCP port check
3. HTTP endpoint check
4. Application-specific check

**Decisione:** HTTP healthcheck con endpoint `/health` custom.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Nessuno | Zero overhead | Container "running" ma servizio down |
| TCP check | Semplice | Porta aperta ≠ servizio funzionante |
| HTTP `/` | Standard | Homepage può essere lenta |
| HTTP `/health` | Verifica reale stato servizio | Richiede implementazione custom |

**Conseguenze:**
- ✅ `docker ps` mostra stato reale (healthy/unhealthy)
- ✅ Docker Compose `depends_on.condition: service_healthy` funziona
- ⚠️ Ogni server deve implementare `/health`
- 📝 Healthcheck ogni 30s con 3 retry

Implementazione standard:
```python
@app.get("/health")
async def health():
    # Verifica componenti critici
    if not model_loaded:
        raise HTTPException(503, "Model not loaded")
    return {"status": "healthy"}
```

---

#### AD-8: GitHub Actions matrix vs. sequential builds

**Contesto:**
Come buildare 4 container nella CI:
1. Sequential: build one, then next
2. Matrix: build all in parallel

**Decisione:** Matrix strategy con build parallele.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Sequential | Semplice, facile debug | 4x tempo di build (~20 min) |
| Matrix | ~4x più veloce, fail-fast | Più complesso, usa più minuti GitHub |

**Conseguenze:**
- ✅ Build totale ~5 min invece di ~20 min
- ✅ Feedback veloce su PR
- ⚠️ Consuma più minuti parallelamente (ma stesso totale)
- ⚠️ Se un build fallisce, gli altri continuano (voluto per vedere tutti gli errori)

```yaml
strategy:
  fail-fast: false  # Continua anche se uno fallisce
  matrix:
    container: [crawl4ai, anythingllm, yt-dlp-server, whisper-server]
```

---

#### AD-9: Multi-platform builds (amd64/arm64)

**Contesto:**
Supportare sia Intel/AMD (amd64) che Apple Silicon/Raspberry Pi (arm64)?

**Decisione:** Build multi-platform per tutte le immagini.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Solo amd64 | Build più veloce, meno test | Esclude Mac M1/M2/M3, Raspberry Pi |
| Solo piattaforma dev | Funziona per developer | Non funziona per altri utenti |
| Multi-platform | Tutti supportati | Build 2x più lungo, testing più complesso |

**Conseguenze:**
- ✅ `docker pull` funziona ovunque senza config
- ✅ Mac Apple Silicon supportati nativamente
- ⚠️ Build ~2x più lunghi
- ⚠️ Whisper su ARM potrebbe essere più lento (no ottimizzazione CUDA)

```yaml
platforms: linux/amd64,linux/arm64
```

---

#### AD-10: Tag strategy (latest vs. versioned)

**Contesto:**
Quale strategia per i tag delle immagini:
1. Solo `latest`
2. Solo versioni (`v1.0.0`)
3. Entrambi

**Decisione:** Entrambi: `latest` per main, versioni semantiche per release.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Solo latest | Semplice, sempre aggiornato | No rollback, breaking changes inattesi |
| Solo versioni | Controllo totale, riproducibilità | Utenti devono aggiornare manualmente |
| Entrambi | Flessibilità | Due set di tag da mantenere |

**Conseguenze:**
- ✅ Utenti casual: `latest` sempre aggiornato
- ✅ Produzione: `v1.2.3` per stabilità
- ⚠️ Devo mantenere changelog per versioni
- 📝 `latest` = ultimo commit su main, non ultima versione stabile

```yaml
tags: |
  tapiocapioca/${{ matrix.container }}:latest
  tapiocapioca/${{ matrix.container }}:${{ github.ref_name }}
```

---

#### AD-11: Embedding model selection

**Contesto:**
AnythingLLM può usare diversi modelli per gli embeddings (vettori per RAG):
1. OpenAI text-embedding-ada-002
2. Sentence transformers locali
3. Provider built-in

**Decisione:** Sentence transformers locali (default AnythingLLM).

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| OpenAI | Qualità eccellente | $0.0001/1K tokens, richiede API key |
| Cohere | Multilingua ottimo | $0.1/1M tokens, API key |
| Locale | Gratuito, offline | Qualità leggermente inferiore, più lento |

**Conseguenze:**
- ✅ Zero costi per embeddings
- ✅ Funziona offline dopo primo download modello
- ⚠️ ~10-20% meno accurato di OpenAI embeddings
- ⚠️ Prima indicizzazione più lenta

---

#### AD-12: Rate limiting strategy

**Contesto:**
Come gestire rate limit degli endpoint:
1. Nessun limit (problemi DoS)
2. Fixed rate limit
3. Dynamic throttling

**Decisione:** Nessun rate limit built-in, delegato a reverse proxy.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Built-in | Protezione inclusa | Complessità codice, stato da gestire |
| Nessuno | Semplice, flessibile | Vulnerabile a abusi in deployment pubblico |
| Reverse proxy | Standard, configurabile | Richiede setup nginx/traefik |

**Conseguenze:**
- ✅ Codice più semplice
- ✅ Deployment locale non ha bisogno di limits
- ⚠️ NON esporre direttamente su internet senza reverse proxy
- 📝 Documentato in "deployment pubblico" (Sezione 13)

---

#### AD-13: Error response format

**Contesto:**
Come formattare gli errori API:
1. Testo libero
2. JSON strutturato
3. Standard come RFC 7807 (Problem Details)

**Decisione:** JSON strutturato semplice, ispirato a RFC 7807.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Testo | Semplice | Non parsabile |
| JSON custom | Flessibile | Non standard |
| RFC 7807 | Standard, completo | Verboso per errori semplici |

**Conseguenze:**
- ✅ Sempre parsabile: `{"error": "...", "detail": "..."}`
- ✅ Codici HTTP semantici (400, 404, 500, 503)
- ⚠️ Non 100% RFC 7807 compliant

Formato standard:
```json
{
  "error": "TranscriptNotAvailable",
  "detail": "Video does not have subtitles",
  "video_id": "abc123"
}
```

---

#### AD-14: Logging strategy

**Contesto:**
Come gestire i log dei container:
1. stdout/stderr (Docker default)
2. File logging
3. Centralized logging (ELK, etc.)

**Decisione:** stdout/stderr con formato JSON strutturato.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| stdout semplice | Zero config | Non parsabile, difficile filtrare |
| stdout JSON | Parsabile, query facili | Leggermente più verboso |
| File | Persistente | Gestione rotazione, spazio disco |
| ELK/Loki | Ricerca potente | Infrastruttura aggiuntiva |

**Conseguenze:**
- ✅ `docker logs` funziona out of the box
- ✅ `docker logs whisper | jq '.level=="error"'` per filtrare
- ⚠️ Log persi al riavvio container (a meno di volume)
- 📝 Per persistenza: `docker-compose logs > logs.txt`

Formato:
```json
{"time": "2026-01-07T10:30:00Z", "level": "info", "msg": "Request processed", "duration_ms": 1234}
```

---

#### AD-15: Security model

**Contesto:**
Che livello di sicurezza per un tool locale:
1. Zero security (trust everything)
2. Basic authentication
3. mTLS, OAuth, etc.

**Decisione:** Zero auth per default, design per deployment locale.

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Zero auth | Setup immediato | Vulnerabile se esposto |
| API key | Protezione base | Gestione chiavi |
| OAuth | Standard enterprise | Complessità enorme |

**Conseguenze:**
- ✅ Funziona subito senza config
- ✅ Perfetto per localhost e LAN trusted
- ⚠️ **MAI esporre su internet senza protezione**
- 📝 Per deployment pubblico: reverse proxy con auth (Sezione 13)

---

#### AD-16: Port mapping strategy

**Contesto:**
4 container Docker necessitano di port mapping su host. Porte originali:
- crawl4ai: 11235
- anythingllm: 3001
- yt-dlp-server: 8501
- whisper-server: 8502

Problema: Alta probabilità di conflitti (3001, 8501, 8502 sono porte comuni).

**Decisione:** Range 9100-9103 con ordinamento workflow-based.

**Mappatura:**

| Servizio | Porta | Step Workflow |
|----------|-------|---------------|
| crawl4ai | 9100 | 1. Estrazione web |
| yt-dlp-server | 9101 | 2. Estrazione video |
| whisper-server | 9102 | 3. Trascrizione audio |
| anythingllm | 9103 | 4. Storage RAG + UI |

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| Range 9100-9103 (scelto) | IANA unassigned, basso conflitto, sequenziale | Alcuni firewall aziendali potrebbero bloccare >9000 |
| Range 3001-3004 | Facile ricordare | AnythingLLM default 3001 causa conflitti |
| Range 7000-7003 | Media probabilità conflitto | Usato da alcuni IDE per debug |
| Mantenere originali | Nessun breaking change | Alto rischio conflitti |

**Configurazione:**
- Default 9100-9103 (funziona out-of-the-box)
- Override opzionale via `.env` per edge cases
- Syntax docker-compose: `${VAR:-default}`

**Conseguenze:**
- ✅ Bassa probabilità conflitti (IANA unassigned range)
- ✅ Ordinamento logico aiuta comprensione architettura
- ✅ Range consecutivo facile da ricordare (91XX)
- ✅ Override opzionale per 1% edge cases
- ⚠️ Breaking change per futuri early adopters (ma progetto pre-release)

**Riferimenti:** `docs/plans/2026-01-08-port-mapping-design.md`

---

#### AD-17: Docker volume strategy (tmpfs vs named volumes)

**Contesto:**
4 container necessitano storage per dati/cache. Opzioni:
1. Tutti named volumes (disco host)
2. Tutti tmpfs (RAM)
3. Strategia mista (cache in RAM, dati persistenti su disco)

**Problema:** Conflitto tra performance e persistenza dati.

**Decisione:** Strategia mista - tmpfs per cache, named volumes per dati critici.

**Mappatura:**

| Container | Volume | Tipo | Dimensione | Persistenza |
|-----------|--------|------|------------|-------------|
| crawl4ai | /app/data | tmpfs | 512MB | ❌ Temporaneo |
| yt-dlp-server | /app/temp | tmpfs | 1GB | ❌ Temporaneo |
| whisper-server | /app/models | named volume | ~150MB | ✅ Persistente |
| anythingllm | /app/server/storage | named volume | Variabile | ✅ Persistente |

**Alternative considerate:**

| Opzione | Pro | Contro |
|---------|-----|--------|
| **Strategia mista (scelto)** | ✅ Performance cache elevate<br>✅ Dati RAG preservati<br>✅ Modelli non riscaricati | ⚠️ Richiede ~1.5GB RAM extra |
| Tutto named volumes | ✅ Nessun dato perso<br>✅ Nessuna RAM extra | ❌ I/O disco per cache<br>❌ Performance ridotte |
| Tutto tmpfs | ✅ Massima performance | ❌ Database RAG perso a restart<br>❌ Modelli riscaricati ogni volta |
| Container filesystem | ✅ Zero config | ❌ TUTTI i dati persi con `docker rm`<br>❌ Disastroso per utenti |

**Implementazione:**

```yaml
# tmpfs (RAM) - cache temporanee
crawl4ai:
  volumes:
    - type: tmpfs
      target: /app/data
      tmpfs:
        size: 512M

# named volume (disco) - dati persistenti
anythingllm:
  volumes:
    - anythingllm-storage:/app/server/storage

volumes:
  anythingllm-storage:
    driver: local
```

**Conseguenze:**
- ✅ Cache veloci (zero I/O disco)
- ✅ Database RAG preservato tra restart
- ✅ Modelli Whisper scaricati una sola volta
- ⚠️ +1.5GB requisiti RAM (512MB + 1GB tmpfs)
- ⚠️ Cache persi a restart (accettabile, si rigenerano)
- ❌ Non adatto a sistemi con <8GB RAM totali

**Location named volumes:**
- Windows: `C:\ProgramData\Docker\volumes\`
- Linux: `/var/lib/docker/volumes/`

**Riferimenti:** Richiesta utente 2026-01-07 - "niente dati al disco host (solo essenziali)"

---

#### Riassunto decisioni chiave

| ID | Decisione | Motivazione principale |
|----|-----------|----------------------|
| AD-1 | Container separati | Fault isolation, update indipendenti |
| AD-2 | Docker Hub | Zero config per utenti |
| AD-3 | iFlow default | Gratuito, facile da cambiare |
| AD-4 | FastAPI | Async, validazione auto, /docs |
| AD-5 | Whisper base | Bilancio qualità/risorse |
| AD-6 | Named volumes | Portabilità, backup standardizzato |
| AD-7 | HTTP healthcheck | Stato reale servizio |
| AD-8 | Matrix builds | 4x più veloce |
| AD-9 | Multi-platform | Supporto universale |
| AD-10 | latest + versioni | Flessibilità utenti |
| AD-11 | Embeddings locali | Zero costi |
| AD-12 | No rate limit | Semplicità, delegato a proxy |
| AD-13 | JSON errors | Parsabile, semantico |
| AD-14 | JSON logs | Filtrabile con jq |
| AD-15 | Zero auth | Setup immediato, solo locale |
| AD-16 | Port range 9100-9103 | Bassa probabilità conflitti, workflow-ordered |
| AD-17 | Volume strategy mista | Performance cache + persistenza dati critici |

---

#### Come usare questo documento

Quando devi fare una modifica all'architettura:

1. **Trova la decisione correlata** nella tabella sopra
2. **Leggi il contesto** per capire il problema originale
3. **Valuta se le tue esigenze sono diverse** dal contesto originale
4. **Se sì, documenta una nuova AD** con lo stesso formato

Esempio: vuoi aggiungere autenticazione?
→ Leggi AD-15, capisci perché era "zero auth"
→ Le tue esigenze (deployment pubblico) sono diverse
→ Aggiungi AD-16 che documenta la scelta auth

---

**Prossima sezione:** Costi e limiti (Sezione 12) analizza le risorse necessarie e i limiti del sistema.

### 12. Costi e limiti

> **Scopo:** Trasparenza totale sui requisiti, costi monetari, e limiti tecnici. Devi sapere cosa serve realmente per far funzionare Brainery.

---

#### 12.1 Costi di Infrastruttura

##### Hardware Minimo

| Componente | Minimo | Raccomandato | Ottimale |
|------------|--------|--------------|----------|
| **RAM** | 8 GB | 12 GB | 16+ GB |
| **CPU** | 4 core | 6 core | 8+ core |
| **Disco** | 20 GB | 50 GB | 100+ GB |
| **Rete** | 10 Mbps | 50 Mbps | 100+ Mbps |

**Breakdown RAM per container:**
```
Crawl4AI:       ~1-2 GB  (browser Playwright)
AnythingLLM:    ~2-3 GB  (embeddings + vector store)
yt-dlp-server:  ~500 MB  (leggero, solo processing)
Whisper-server: ~2-4 GB  (model base, cresce con modelli più grandi)
Docker overhead: ~1 GB
Sistema operativo: ~2 GB
────────────────────────
SUBTOTALE:      ~8-12 GB

Cache tmpfs (AD-17):
  crawl4ai cache:   512 MB  (tmpfs in RAM)
  yt-dlp cache:     1 GB    (tmpfs in RAM)
────────────────────────
TOTALE:         ~10-14 GB
```

**Se hai solo 8GB RAM:** ⚠️ NON RACCOMANDATO con strategia tmpfs.
- Rimuovi tmpfs e usa named volumes (performance ridotte ma funziona)
- Oppure usa Whisper `tiny` invece di `base` (liberi ~2GB)
- Chiudi altre applicazioni pesanti durante l'uso

---

##### Spazio Disco

| Categoria | Spazio | Persistenza | Note |
|-----------|--------|-------------|------|
| Immagini Docker | ~8 GB | Disco | 4 container x ~2GB ciascuno |
| Whisper models | ~400 MB | Disco (named volume) | base model, 10GB se usi large |
| AnythingLLM data | Variabile | Disco (named volume) | 100MB per 1000 documenti indicizzati |
| Crawl4AI cache | 512 MB | ⚡ RAM (tmpfs) | Cache pagine web - AD-17 |
| yt-dlp cache | 1 GB | ⚡ RAM (tmpfs) | Video temporanei - AD-17 |
| **TOTALE disco minimo** | **~8.4 GB** | - | Senza dati utente |
| **TOTALE disco raccomandato** | **~50 GB** | - | Con 10K documenti |
| **TOTALE RAM extra** | **~1.5 GB** | - | Cache tmpfs (oltre RAM container) |

**Pulizia periodica:**
```bash
# Rimuovi cache Docker non usate
docker system prune -a --volumes

# Dimensioni prima/dopo
docker system df
```

---

#### 12.2 Costi Monetari

##### Free Tier (Default)

**Cosa è gratis:**
- ✅ Docker Engine (open source)
- ✅ Docker Hub (immagini pubbliche illimitate)
- ✅ GitHub (repo pubbliche, 2000 minuti CI/mese)
- ✅ iFlow Platform LLM (free tier non documentato)
- ✅ Tutte le librerie Python (open source)
- ✅ Whisper (modello open source)
- ✅ Sentence transformers (embeddings locali gratuiti)

**Costo totale setup base:** **$0/mese**

---

##### Costi Opzionali (Performance)

Se vuoi migliorare qualità/velocità:

| Servizio | Prezzo | Quando conviene |
|----------|--------|-----------------|
| **OpenAI GPT-4** | $30/1M input tokens | Risposti RAG di alta qualità |
| **OpenAI GPT-3.5** | $0.50/1M tokens | Compromesso costo/qualità |
| **Anthropic Claude** | $15/1M tokens | Migliore reasoning |
| **OpenAI Embeddings** | $0.10/1M tokens | Migliore retrieval RAG |
| **Cloud VM (AWS/GCP)** | $50-100/mese | Deployment 24/7 |
| **Ollama + GPU** | $0 + hardware | Locale, richiede GPU NVIDIA |

**Esempio calcolo costi:**
```
Scenario: 100 query RAG/giorno con GPT-4

AnythingLLM query:
- Retrieval: 3 chunk x 500 tokens = 1500 tokens input
- Context: 1500 tokens
- Response: 500 tokens output
= 3000 input + 500 output per query

Costo/query: (3000 x $0.03/1K) + (500 x $0.06/1K) = $0.12
Costo/giorno: 100 x $0.12 = $12
Costo/mese: $12 x 30 = $360

Alternativa GPT-3.5: $0.006/query → $18/mese (20x meno)
Alternativa Ollama: $0/mese (solo costo hardware iniziale GPU)
```

---

##### GitHub Actions Minuti

Free tier: **2000 minuti/mese** (account pubblico)

Consumo Brainery:
```
Build completo (4 container parallel): ~5 minuti x4 = 20 minuti
Frequency:
- Push to main: ~5/settimana = 100 min/mese
- Tag releases: ~2/mese = 40 min/mese
- PR builds: ~10/mese = 200 min/mese
────────────────────────────────────────
TOTALE: ~340 min/mese (17% del free tier)
```

**Sei ampiamente dentro il limite gratuito.**

Se superi (progetto molto attivo):
- GitHub Actions minuti extra: $0.008/minuto
- 1000 minuti extra = $8

---

#### 12.3 Limiti Tecnici

##### Limiti Concorrenza

| Servizio | Max richieste simultanee | Bottleneck |
|----------|-------------------------|-----------|
| Crawl4AI | ~5-10 | Browser Playwright RAM |
| AnythingLLM | ~20 | LLM provider rate limit |
| yt-dlp | ~10 | Rete, rate limit YouTube |
| Whisper | ~2-3 | CPU/RAM per transcription |

**Cosa succede se superi:**
- Crawl4AI: Timeout, browser crash
- AnythingLLM: 429 Rate Limit Error
- yt-dlp: 429 o blocco IP temporaneo YouTube
- Whisper: OOM (Out Of Memory) kill

**Come aumentare limiti:**
```yaml
# docker-compose.yml - aumenta risorse
services:
  whisper:
    deploy:
      resources:
        limits:
          cpus: '4'    # da 2 a 4
          memory: 8G   # da 4G a 8G
```

---

##### Limiti Dimensionali

| Cosa | Limite | Motivo |
|------|--------|--------|
| File upload Whisper | 25 MB | FastAPI default, configurabile |
| Audio duration Whisper | ~2h | RAM, tempo processing |
| AnythingLLM doc size | 10 MB | Chunking, context limit |
| AnythingLLM workspace docs | ~10K documenti | Vector DB performance |
| Crawl4AI page size | 10 MB HTML | RAM browser |
| yt-dlp video length | Illimitato | Ma download lento per video lunghi |

**Come gestire file grandi:**

```python
# Whisper: split audio
from pydub import AudioSegment

audio = AudioSegment.from_file("long_audio.mp3")
chunk_duration = 10 * 60 * 1000  # 10 minuti
chunks = [audio[i:i+chunk_duration] for i in range(0, len(audio), chunk_duration)]

# Trascrivi chunk separatamente, poi concatena
```

```python
# AnythingLLM: chunk documento grande
def chunk_document(text, max_chunk=5000):
    words = text.split()
    return [' '.join(words[i:i+max_chunk]) for i in range(0, len(words), max_chunk)]
```

---

##### Rate Limits Esterni

**YouTube (yt-dlp):**
- Limite soft: ~100 video/ora per IP
- Limite hard: Ban IP temporaneo (24h)
- **Soluzione:** Usa `--sleep-interval 5` per rallentare

**iFlow Platform:**
- Limiti non documentati ufficialmente
- Osservato: ~50 req/min, ~1000 req/day
- **Soluzione:** Implementa retry con exponential backoff (vedi Sezione 8)

**OpenAI (se usi):**
- Free tier: 3 RPM (requests per minute)
- Tier 1: 500 RPM
- Tier 5: 10,000 RPM
- **Soluzione:** Aumenta tier o usa queue

**Anthropic Claude (se usi):**
- Free tier: non esiste (richiede pagamento)
- Tier 1: 50 RPM
- Tier 4: 4000 RPM

---

#### 12.4 Limiti Funzionali

**Cosa Brainery NON fa:**

❌ **Real-time streaming:** Le risposte RAG impiegano 3-10 secondi
❌ **Multimodal vision:** AnythingLLM processa solo testo (immagini ignorate)
❌ **Video understanding:** yt-dlp estrae solo transcript, non analizza frame
❌ **Collaborative editing:** Un solo utente per workspace AnythingLLM
❌ **Auto-scaling:** Risorse fisse, no orchestrazione dinamica
❌ **High availability:** Se un container crasha, downtime fino a riavvio
❌ **Fine-tuning:** Usa modelli pre-trained, no training custom
❌ **Multi-language UI:** Tutto in inglese (ad eccezione di questo doc)

---

#### 12.5 Performance Benchmarks

Test eseguiti su macchina con Intel i7-12700K, 16GB RAM, SSD NVMe:

##### Crawl4AI

| Operazione | Tempo | Note |
|------------|-------|------|
| Pagina semplice (< 1MB) | 2-5s | Senza JS rendering |
| Pagina complessa (3MB+) | 10-30s | Con JS, immagini |
| Timeout default | 30s | Configurabile |

##### AnythingLLM

| Operazione | Tempo | Note |
|------------|-------|------|
| Embed 1 documento (1K words) | 5-10s | Locale embeddings |
| Query RAG (iFlow) | 3-8s | Network + LLM |
| Query RAG (GPT-4) | 5-15s | Più lento ma migliore |
| Workspace switch | < 1s | Cache in memoria |

##### yt-dlp

| Operazione | Tempo | Note |
|------------|-------|------|
| Transcript download | 1-3s | Se disponibile |
| Fallback Whisper | +30-120s | Dipende lunghezza audio |
| Video metadata | < 1s | Solo info, no download |

##### Whisper

| Modello | Audio (10 min) | RAM usata | Qualità (WER) |
|---------|----------------|-----------|---------------|
| tiny | 20s | 1GB | ~16% |
| base | 40s | 1GB | ~11% |
| small | 2 min | 2GB | ~8% |
| medium | 5 min | 5GB | ~6% |
| large | 10 min | 10GB | ~4% |

---

#### 12.6 Scaling Considerations

**Quando Brainery NON scala:**

Se ti trovi in uno di questi scenari, Brainery nella configurazione attuale non è sufficiente:

1. **> 100 utenti concorrenti**
   - Container singoli saturano
   - Serve Kubernetes + replica set

2. **> 100K documenti in RAG**
   - Vector DB locale troppo lento
   - Serve Pinecone, Weaviate, Qdrant cloud

3. **> 1TB di dati**
   - Named volumes non gestibili
   - Serve object storage (S3, MinIO)

4. **Uptime 99.9%+ richiesto**
   - No redundancy, no failover
   - Serve cluster multi-node

5. **Compliance GDPR/HIPAA strict**
   - Security model troppo semplice
   - Serve audit logging, encryption at rest, etc.

**Se hai queste esigenze, Brainery è un ottimo prototipo, ma devi re-architettare per produzione enterprise.**

---

#### 12.7 Confronto Alternative

Perché scegliere Brainery vs. altri tool:

| Tool | Pro | Contro | Quando usarlo |
|------|-----|--------|---------------|
| **Brainery** | Gratuito, locale, customizzabile | Setup complesso, no GUI | Progetti personali, learning |
| **LangChain + UI** | Ecosistema maturo, molti integrazioni | Dipendenze pesanti, lock-in | Prototipazione veloce |
| **Flowise** | No-code, drag-drop | Meno flessibile | Non-technical users |
| **ChatGPT + Plugins** | Zero setup | $20/mese, closed source | Utenti casual |
| **Ollama + Open WebUI** | 100% offline | Richiede GPU potente | Privacy-first projects |
| **Custom Python** | Massimo controllo | Build from scratch | Enterprise specifici |

**Brainery è ottimo per:**
- Imparare come funziona RAG sotto il cofano
- Prototipare sistemi AI personalizzati
- Progetti dove dati devono rimanere locali
- Budget $0 ma con tempo per setup

**Brainery NON è ottimo per:**
- Deployment produzione con utenti paganti
- Progetti con deadline strettissime
- Team senza competenze Docker

---

#### 12.8 Roadmap Limiti Conosciuti

Questi sono limiti noti che potrebbero essere risolti in versioni future:

**P0 (Critical):**
- [ ] Whisper OOM su audio lunghi → implementare chunking automatico
- [ ] Rate limit iFlow non gestito → implementare circuit breaker
- [ ] Nessun healthcheck per dipendenze esterne → aggiungere monitoring

**P1 (High):**
- [ ] Logs non persistenti → volume per log aggregation
- [ ] Backup manuale → script automatici schedulati
- [ ] Nessuna UI unificata → dashboard Streamlit/Gradio

**P2 (Medium):**
- [ ] Multi-language UI → i18n support
- [ ] GPU non utilizzata da Whisper → ottimizzazione CUDA
- [ ] Embeddings locali lenti → cache layer

**P3 (Low):**
- [ ] Documentazione video tutorial
- [ ] Preset configurazioni (researcher, developer, writer)
- [ ] Plugin system per estendere funzionalità

---

#### 12.9 FAQ Costi/Limiti

**Q: Posso usare Brainery per un progetto commerciale?**
A: Sì, tutte le licenze sono permissive (MIT/Apache-2.0). Ma se hai utenti paganti, investi in provider LLM migliori di iFlow.

**Q: Quanto mi costa realmente al mese se uso GPT-4?**
A: Dipende dall'uso. Test interno: ~50 query/giorno = $180/mese. Considera GPT-3.5 ($9/mese) o Ollama (gratis).

**Q: Posso hostare su Raspberry Pi?**
A: Tecnicamente sì (ARM64 supportato), ma troppo lento per Whisper. Considera solo Crawl4AI + AnythingLLM senza Whisper.

**Q: GitHub Actions mi bannerà se buildo troppo?**
A: No, free tier pubblico è 2000 min/mese. Brainery usa ~340. Se superi, paghi $0.008/min extra.

**Q: iFlow può bannare il mio account?**
A: Non documentato. Non abusare (max 50 req/min). Se sei preoccupato, passa a provider a pagamento.

**Q: Posso vendere accesso a Brainery?**
A: Legalmente sì (licenza permette uso commerciale), ma eticamente devi:
1. Usare LLM provider legittimo (non free tier di altri)
2. Rispettare TOS di YouTube se estrai contenuti
3. Dichiarare che non garantisci uptime

---

**Prossima sezione:** Prossimi passi (Sezione 13) guida cosa fare dopo il setup iniziale.

### 13. Prossimi passi

> **Scopo:** Hai completato il setup e i test funzionano. Ora cosa? Questa sezione ti guida nei prossimi passi pratici per rendere Brainery davvero utile.

---

#### 13.1 Quick Wins (primi 30 minuti)

**Cosa fare subito dopo il setup:**

##### 1. Crea il tuo primo workspace personalizzato

```bash
# Via API
curl -X POST http://localhost:3001/api/v1/workspace/new \
  -H "Content-Type: application/json" \
  -d '{
    "name": "research-papers",
    "onboardingComplete": true
  }'

# Oppure via UI
# http://localhost:3001 → New Workspace → "research-papers"
```

##### 2. Importa i tuoi primi documenti

**Opzione A: File locali (PDF, TXT, MD)**
```python
import requests

files = {
    'file': open('paper.pdf', 'rb')
}
response = requests.post(
    'http://localhost:3001/api/v1/workspace/research-papers/upload',
    files=files
)
```

**Opzione B: Articolo web**
```bash
curl -X POST http://localhost:11235/md \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/article"}' \
  > article.md

# Poi upload su AnythingLLM (vedi Sezione 8)
```

**Opzione C: Video YouTube**
```bash
curl -X POST http://localhost:8501/transcript \
  -H "Content-Type: application/json" \
  -d '{"url": "https://youtube.com/watch?v=abc123"}' \
  > transcript.txt

# Poi upload su AnythingLLM
```

##### 3. Fai la tua prima query RAG

```bash
curl -X POST http://localhost:3001/api/v1/workspace/research-papers/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Summarize the key findings about neural networks",
    "mode": "query"
  }'
```

**✅ Se questi 3 step funzionano, sei pronto per usare Brainery davvero.**

---

#### 13.2 Workflow Tipici per Caso d'Uso

##### Ricercatore Accademico

**Obiettivo:** Indicizzare paper scientifici e cercare citazioni/concetti rapidamente.

```python
# workflow_researcher.py
import requests
import glob

ANYTHINGLLM_API = "http://localhost:3001/api/v1"
CRAWL4AI_API = "http://localhost:11235"
WORKSPACE = "research-papers"

# 1. Scrape arXiv papers
arxiv_urls = [
    "https://arxiv.org/abs/2401.00001",
    "https://arxiv.org/abs/2401.00002",
]

for url in arxiv_urls:
    # Download markdown
    response = requests.post(f"{CRAWL4AI_API}/md", json={"url": url})
    md_content = response.json()["markdown"]

    # Upload to AnythingLLM
    requests.post(
        f"{ANYTHINGLLM_API}/workspace/{WORKSPACE}/upload-text",
        json={"text": md_content, "filename": url.split('/')[-1]}
    )

# 2. Upload local PDFs
for pdf_path in glob.glob("papers/*.pdf"):
    with open(pdf_path, 'rb') as f:
        requests.post(
            f"{ANYTHINGLLM_API}/workspace/{WORKSPACE}/upload",
            files={"file": f}
        )

# 3. Query examples
queries = [
    "What are the main techniques for attention mechanisms?",
    "Compare transformer architectures across these papers",
    "List all papers that cite BERT"
]

for query in queries:
    response = requests.post(
        f"{ANYTHINGLLM_API}/workspace/{WORKSPACE}/chat",
        json={"message": query, "mode": "query"}
    )
    print(f"\nQ: {query}")
    print(f"A: {response.json()['textResponse']}")
```

---

##### Content Creator (YouTube)

**Obiettivo:** Trascrivi video, indicizza, trova citazioni per script nuovi.

```python
# workflow_content_creator.py
import requests

YTDLP_API = "http://localhost:8501"
ANYTHINGLLM_API = "http://localhost:3001/api/v1"
WORKSPACE = "video-research"

# 1. Trascrivi playlist
playlist_videos = [
    "https://youtube.com/watch?v=abc123",
    "https://youtube.com/watch?v=def456",
]

for video_url in playlist_videos:
    # Get transcript
    response = requests.post(
        f"{YTDLP_API}/transcript",
        json={"url": video_url}
    )
    transcript = response.json()["transcript"]

    # Get metadata
    metadata = requests.post(
        f"{YTDLP_API}/metadata",
        json={"url": video_url}
    ).json()

    # Combine into document
    doc = f"""# {metadata['title']}
Channel: {metadata['channel']}
Date: {metadata['upload_date']}
URL: {video_url}

## Transcript
{transcript}
"""

    # Upload to AnythingLLM
    requests.post(
        f"{ANYTHINGLLM_API}/workspace/{WORKSPACE}/upload-text",
        json={"text": doc, "filename": f"{metadata['id']}.md"}
    )

# 2. Find quotes/facts for new video script
query = "What did experts say about climate change solutions?"
response = requests.post(
    f"{ANYTHINGLLM_API}/workspace/{WORKSPACE}/chat",
    json={"message": query, "mode": "query"}
)

# Response includes sources with timestamps → easy to verify
print(response.json()["textResponse"])
```

---

##### Developer Documentation

**Obiettivo:** Indicizza documentazione progetti open-source per quick reference.

```python
# workflow_dev_docs.py
import requests

CRAWL4AI_API = "http://localhost:11235"
ANYTHINGLLM_API = "http://localhost:3001/api/v1"
WORKSPACE = "dev-docs"

# 1. Index common docs sites
doc_sites = [
    "https://docs.python.org/3/library/asyncio.html",
    "https://fastapi.tiangolo.com/tutorial/",
    "https://docs.docker.com/compose/",
]

for url in doc_sites:
    # Crawl with filter=fit for relevant content only
    response = requests.post(
        f"{CRAWL4AI_API}/md",
        json={"url": url, "f": "fit"}
    )
    md = response.json()["markdown"]

    requests.post(
        f"{ANYTHINGLLM_API}/workspace/{WORKSPACE}/upload-text",
        json={"text": md, "filename": url.replace('https://', '').replace('/', '_')}
    )

# 2. Query while coding
query = "How do I handle timeouts in asyncio?"
response = requests.post(
    f"{ANYTHINGLLM_API}/workspace/{WORKSPACE}/chat",
    json={"message": query, "mode": "query"}
)
print(response.json()["textResponse"])
```

---

#### 13.3 Integrazioni Avanzate

##### MCP Server Customization

Se usi Claude Code, puoi creare un MCP server custom per Brainery:

```json
// ~/.claude/mcp.json
{
  "mcpServers": {
    "brainery": {
      "command": "python",
      "args": ["-m", "brainery_mcp_server"],
      "env": {
        "ANYTHINGLLM_URL": "http://localhost:3001",
        "CRAWL4AI_URL": "http://localhost:11235",
        "YTDLP_URL": "http://localhost:8501"
      }
    }
  }
}
```

```python
# brainery_mcp_server.py (bozza)
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types

server = Server("brainery")

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="brainery_query",
            description="Query AnythingLLM workspace",
            inputSchema={
                "type": "object",
                "properties": {
                    "workspace": {"type": "string"},
                    "query": {"type": "string"}
                },
                "required": ["workspace", "query"]
            }
        ),
        types.Tool(
            name="brainery_import_url",
            description="Import web page or YouTube video into workspace",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {"type": "string"},
                    "workspace": {"type": "string"}
                },
                "required": ["url", "workspace"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    if name == "brainery_query":
        # Call AnythingLLM API
        # ... implementation ...
        pass
    elif name == "brainery_import_url":
        # Call Crawl4AI or yt-dlp, then upload to AnythingLLM
        # ... implementation ...
        pass

    return [types.TextContent(type="text", text="Result...")]

async def main():
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="brainery",
                server_version="0.1.0"
            )
        )

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

**Vantaggio:** Claude Code può direttamente interrogare Brainery durante le conversazioni.

---

##### Web UI Dashboard

Crea una dashboard Streamlit per usare Brainery senza API:

```python
# dashboard.py
import streamlit as st
import requests

st.title("🧠 Brainery Dashboard")

# Sidebar: Workspace selector
workspaces = requests.get("http://localhost:3001/api/v1/workspaces").json()
workspace = st.sidebar.selectbox("Workspace", [w["name"] for w in workspaces])

# Tab 1: Query
with st.tabs(["Query", "Import", "Settings"])[0]:
    query = st.text_input("Ask a question:")
    if st.button("Search"):
        response = requests.post(
            f"http://localhost:3001/api/v1/workspace/{workspace}/chat",
            json={"message": query, "mode": "query"}
        ).json()
        st.write(response["textResponse"])

        # Show sources
        with st.expander("Sources"):
            for source in response.get("sources", []):
                st.write(f"- {source}")

# Tab 2: Import
with st.tabs(["Query", "Import", "Settings"])[1]:
    url = st.text_input("URL (web page or YouTube):")
    if st.button("Import"):
        # Detect YouTube vs web
        if "youtube.com" in url or "youtu.be" in url:
            transcript = requests.post(
                "http://localhost:8501/transcript",
                json={"url": url}
            ).json()["transcript"]
            content = transcript
        else:
            md = requests.post(
                "http://localhost:11235/md",
                json={"url": url}
            ).json()["markdown"]
            content = md

        # Upload to AnythingLLM
        requests.post(
            f"http://localhost:3001/api/v1/workspace/{workspace}/upload-text",
            json={"text": content, "filename": url}
        )
        st.success("Imported!")

# Run: streamlit run dashboard.py
```

---

#### 13.4 Deployment Pubblico (Avanzato)

**⚠️ IMPORTANTE:** Sezione 12 spiega perché Brainery di default non è secure per internet. Ecco come renderlo sicuro.

##### Opzione A: Reverse Proxy con Auth (Nginx)

```nginx
# /etc/nginx/sites-available/brainery
server {
    listen 443 ssl http2;
    server_name brainery.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/brainery.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/brainery.yourdomain.com/privkey.pem;

    # Basic Auth
    auth_basic "Brainery Access";
    auth_basic_user_file /etc/nginx/.htpasswd;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=brainery:10m rate=10r/m;
    limit_req zone=brainery burst=20 nodelay;

    location /anythingllm/ {
        proxy_pass http://localhost:3001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /crawl4ai/ {
        proxy_pass http://localhost:11235/;
    }

    location /ytdlp/ {
        proxy_pass http://localhost:8501/;
    }

    location /whisper/ {
        proxy_pass http://localhost:8502/;
    }
}
```

```bash
# Setup
sudo apt install nginx apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd admin
sudo certbot --nginx -d brainery.yourdomain.com
sudo systemctl reload nginx
```

**Accesso:** `https://brainery.yourdomain.com/anythingllm/` richiede username/password.

---

##### Opzione B: Cloudflare Tunnel (Zero-Config SSL)

```bash
# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/

# Login e setup tunnel
cloudflared tunnel login
cloudflared tunnel create brainery

# config.yml
tunnel: <TUNNEL_ID>
credentials-file: /home/user/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: brainery.yourdomain.com
    service: http://localhost:3001
  - service: http_status:404

# Run
cloudflared tunnel run brainery
```

**Vantaggio:** Zero configurazione firewall/port forwarding.

**Svantaggio:** Traffico passa per Cloudflare (non 100% self-hosted).

---

##### Opzione C: VPN-only Access (Tailscale)

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Share host
tailscale serve http://localhost:3001
```

**Vantaggio:** Nessuna esposizione pubblica, solo tu (o team) via VPN.

---

#### 13.5 Automazioni

##### Cron Job per Backup Giornaliero

```bash
# backup_brainery.sh
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR="/backups/brainery"

# Backup AnythingLLM volume
docker run --rm \
  -v anythingllm-storage:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/anythingllm-$DATE.tar.gz /data

# Backup Crawl4AI cache
docker run --rm \
  -v crawl4ai-data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/crawl4ai-$DATE.tar.gz /data

# Cleanup old backups (>7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completato: $DATE"
```

```bash
# Add to crontab
crontab -e

# Ogni giorno alle 3 AM
0 3 * * * /path/to/backup_brainery.sh >> /var/log/brainery_backup.log 2>&1
```

---

##### GitHub Actions per Auto-Update

```yaml
# .github/workflows/auto-update.yml
name: Auto-Update Brainery

on:
  schedule:
    - cron: '0 2 * * 1'  # Ogni lunedì alle 2 AM
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - name: SSH to server and update
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd ~/brainery
            docker-compose pull
            docker-compose up -d
            docker system prune -f
```

**Setup:**
```bash
# Su server
ssh-keygen -t ed25519 -C "github-actions"
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

# Su GitHub: Settings → Secrets → New repository secret
# SERVER_HOST: your.server.ip
# SERVER_USER: username
# SSH_PRIVATE_KEY: <contenuto di ~/.ssh/id_ed25519>
```

---

#### 13.6 Metriche e Monitoring

##### Prometheus + Grafana (Opzionale)

```yaml
# docker-compose.monitoring.yml
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['host.docker.internal:9323']  # Docker metrics

  - job_name: 'anythingllm'
    static_configs:
      - targets: ['anythingllm:3001']
    # Se AnythingLLM espone /metrics (da verificare)
```

```bash
# Run
docker-compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# Access Grafana: http://localhost:3000 (admin/admin)
# Add Prometheus datasource: http://prometheus:9090
# Import dashboard ID 1860 (Node Exporter) o custom
```

---

##### Simple Healthcheck Monitor

Se Prometheus è overkill, usa questo script Python:

```python
# healthcheck_monitor.py
import requests
import time
from datetime import datetime

SERVICES = {
    "AnythingLLM": "http://localhost:3001/api/ping",
    "Crawl4AI": "http://localhost:11235/health",
    "yt-dlp": "http://localhost:8501/health",
    "Whisper": "http://localhost:8502/health"
}

def check_health():
    results = {}
    for name, url in SERVICES.items():
        try:
            response = requests.get(url, timeout=5)
            results[name] = "✅ UP" if response.status_code == 200 else f"⚠️ DOWN ({response.status_code})"
        except Exception as e:
            results[name] = f"❌ ERROR: {e}"

    return results

if __name__ == "__main__":
    while True:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        health = check_health()

        print(f"\n[{timestamp}]")
        for service, status in health.items():
            print(f"{service}: {status}")

        # Alert se qualcosa è down (esempio: invia email/Slack)
        if any("❌" in status or "⚠️" in status for status in health.values()):
            print("⚠️ ALERT: Some services are down!")
            # TODO: send_alert_email() o send_slack_message()

        time.sleep(60)  # Check ogni minuto
```

```bash
# Run in background
nohup python healthcheck_monitor.py > healthcheck.log 2>&1 &
```

---

#### 13.7 Contribuire al Progetto

Se vuoi contribuire a Brainery:

##### 1. Setup Sviluppo Locale

```bash
# Fork su GitHub, poi clone
git clone https://github.com/YOUR_USERNAME/brainery.git
cd brainery

# Crea branch per feature
git checkout -b feature/new-endpoint

# Modifica codice (es. server.py)
# Test locale con rebuild
docker-compose build whisper  # rebuild solo container modificato
docker-compose up -d whisper

# Test manuale
curl http://localhost:8502/health

# Commit e push
git add .
git commit -m "feat: add new /health endpoint to whisper"
git push origin feature/new-endpoint

# Open PR su GitHub
```

##### 2. Tipi di Contributi Benvenuti

- **Bug fixes:** Qualsiasi fix a problemi esistenti
- **Documentazione:** Miglioramenti a questo documento o README
- **Nuovi endpoint:** Espandere API yt-dlp/whisper
- **Ottimizzazioni:** Migliorare performance, ridurre RAM
- **Integrazioni:** Nuovi MCP servers, UI dashboard
- **Test:** Unit test, integration test

##### 3. Code Review Checklist

Prima di aprire PR, verifica:
- [ ] Codice segue style esistente (PEP8 per Python)
- [ ] Dockerfile builda senza errori
- [ ] GitHub Actions CI passa
- [ ] README aggiornato se necessario
- [ ] Changelog aggiornato (se versione bump)

---

#### 13.8 Roadmap Ufficiale

**Versione corrente:** v0.1.0 (Gennaio 2026)

**v0.2.0 (Q1 2026):**
- [ ] UI dashboard Streamlit inclusa
- [ ] Healthcheck automatico dipendenze esterne
- [ ] Script backup automatici
- [ ] Supporto OpenAI vision API per multimodal

**v0.3.0 (Q2 2026):**
- [ ] GPU acceleration per Whisper
- [ ] Vector DB alternatives (Qdrant, Weaviate)
- [ ] MCP server ufficiale per Claude Code
- [ ] Docker Swarm support per HA

**v1.0.0 (Q3 2026):**
- [ ] Produzione-ready con security hardening
- [ ] Kubernetes Helm charts
- [ ] Multi-user authentication system
- [ ] Plugin system per estendibilità

---

#### 13.9 Risorse Aggiuntive

**Documentazione Progetti Upstream:**
- Crawl4AI: https://docs.crawl4ai.com
- AnythingLLM: https://docs.anythingllm.com
- yt-dlp: https://github.com/yt-dlp/yt-dlp#readme
- Whisper: https://github.com/openai/whisper#readme

**Community:**
- GitHub Discussions: https://github.com/Tapiocapioca/brainery/discussions
- Discord: [TODO: setup Discord server]
- Twitter: @brainery_ai [TODO: setup Twitter]

**Video Tutorial:**
- Setup completo: [TODO: registrare video]
- Workflow ricercatore: [TODO: registrare video]
- Deployment VPS: [TODO: registrare video]

---

#### 13.10 Conclusione

**Hai completato il setup di Brainery. Ora:**

1. **Sperimenta:** Prova i workflow della sezione 13.2 per il tuo caso d'uso
2. **Personalizza:** Modifica configurazioni per le tue esigenze (Sezione 11)
3. **Contribuisci:** Apri issue/PR su GitHub se trovi bug o vuoi migliorare
4. **Condividi:** Se trovi Brainery utile, star ⭐ il repo e condividi con altri

**Il sistema RAG locale è solo l'inizio.** Le possibilità di estendere Brainery sono infinite:
- Integra con altri tool (Obsidian, Notion, etc.)
- Automatizza flussi di lavoro ripetitivi
- Crea dashboard custom per il tuo team
- Espandi con nuove fonti dati (Podcast, Twitter, Reddit, etc.)

**Domande?** Apri una Discussion su GitHub: https://github.com/Tapiocapioca/brainery/discussions

**Buon hacking! 🧠⚡**

---

*Documento completato - Gennaio 2026*
*Versione: 1.0*
*Contributori: Tapiocapioca + Claude Sonnet 4.5*
