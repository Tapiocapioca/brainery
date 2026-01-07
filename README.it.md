# Brainery

Skill per Claude Code per importare contenuti web, video YouTube e PDF in un sistema RAG locale.

[🇬🇧 English](README.md) | [🇨🇳 中文](README.zh.md)

## Panoramica

Brainery consente a Claude Code di importare e interrogare contenuti web utilizzando AnythingLLM come database RAG (Retrieval-Augmented Generation) locale. Importa articoli, trascrizioni YouTube e PDF, poi interrogali usando il linguaggio naturale.

**Funzionalità Principali:**
- 🌐 **Web scraping** con estrazione markdown pulita (Crawl4AI)
- 📺 **Trascrizioni YouTube** con fallback automatico alla trascrizione audio (yt-dlp + Whisper)
- 📄 **Importazione PDF** con estrazione testo
- 🧠 **Database RAG locale** per interrogazione di contenuti privati offline (AnythingLLM)
- 🐳 **Infrastruttura Docker** con immagini pre-costruite
- 🌍 **Documentazione multilingua** (EN/IT/ZH)

## Avvio Rapido

### 1. Installare Container Docker

```bash
git clone https://github.com/Tapiocapioca/brainery-containers.git
cd brainery-containers
docker-compose up -d
```

**Stack Container:**
- **crawl4ai** (porta 9100) - Web scraping
- **yt-dlp-server** (porta 9101) - Trascrizioni YouTube
- **whisper-server** (porta 9102) - Trascrizione audio
- **anythingllm** (porta 9103) - Database RAG

### 2. Configurare AnythingLLM

Apri http://localhost:9103 e:
1. Crea account admin
2. Configura provider LLM (consigliato: iFlow Platform con modello glm-4.6)
3. Crea workspace (es. "brainery")
4. Genera chiave API in Impostazioni → Chiavi API

### 3. Installare Skill

```bash
cd ~/.claude/skills
git clone https://github.com/Tapiocapioca/brainery.git
```

Riavvia Claude Code per caricare la skill.

### 4. Testare Importazione

In Claude Code:

```
Importa questo articolo in Brainery: https://example.com/article
```

Poi interroga:

```
Quali sono i punti principali nell'articolo che ho appena importato?
```

## Esempi d'Uso

### Importare Pagina Web
```
Importa questa guida tecnica: https://example.com/docker-guide
```

### Importare Video YouTube
```
Importa la trascrizione da: https://www.youtube.com/watch?v=VIDEO_ID
```

### Importazione Batch
```
Importa questi articoli:
1. https://example.com/article1
2. https://example.com/article2
3. https://example.com/article3

Poi dimmi quali sono i temi comuni.
```

### Interrogare Contenuti Importati
```
Quali sono i concetti chiave discussi in tutti gli articoli che ho importato oggi?
```

## Documentazione

- **[Guida Installazione](docs/it/installation.md)** - Istruzioni complete di setup
- **[Esempi d'Uso](docs/it/usage.md)** - Workflow pratici e scenari comuni
- **[BRAINERY_CONTEXT.md](BRAINERY_CONTEXT.md)** - Dettagli tecnici implementazione

### Altre Lingue
- **English**: [Installation](docs/en/installation.md) | [Usage](docs/en/usage.md)
- **中文**: [安装](docs/zh/installation.md) | [使用示例](docs/zh/usage.md)

## Architettura

Brainery usa un'architettura modulare con 4 container Docker:

```
┌─────────────┐
│ Claude Code │
└──────┬──────┘
       │ MCP Tools
       │
       ├──────────────┬──────────────┬──────────────┐
       ▼              ▼              ▼              ▼
  ┌─────────┐   ┌──────────┐   ┌─────────┐   ┌──────────────┐
  │Crawl4AI │   │ yt-dlp   │   │ Whisper │   │ AnythingLLM  │
  │  :9100  │   │  :9101   │   │  :9102  │   │    :9103     │
  └─────────┘   └──────────┘   └─────────┘   └──────────────┘
   Web scraping  Trascrizioni   Trascrizione   Database RAG
                 YouTube        audio
```

## Requisiti di Sistema

- **Docker Desktop** 20.10+
- **Docker Compose** 2.0+
- **8GB RAM minimo** (12GB consigliati)
- **~13GB spazio disco** per container e modelli

## Configurazione Porte

Le porte predefinite (9100-9103) funzionano out-of-box. Per personalizzare, crea file `.env`:

```bash
cd brainery-containers
cp .env.example .env
# Modifica porte in .env
docker-compose up -d
```

## Risoluzione Problemi

### Container Non in Esecuzione
```bash
docker ps --filter "name=brainery-"
docker-compose restart <nome-servizio>
```

### AnythingLLM "Unauthorized"
Verifica la chiave API nel file `.env` e reinizializza il client MCP.

### Importazione Fallisce
1. Controlla salute container: `curl http://localhost:9100/health`
2. Verifica connettività di rete
3. Controlla log: `docker-compose logs <nome-servizio>`

Vedi [Guida Installazione](docs/it/installation.md) per risoluzione problemi dettagliata.

## Struttura Repository

- **brainery** (questo repo) - Skill Claude Code con docs multilingua
- **[brainery-containers](https://github.com/Tapiocapioca/brainery-containers)** - Infrastruttura Docker con immagini pre-costruite su Docker Hub

## Contribuire

Contributi benvenuti! Per favore:
1. Fork del repository
2. Crea feature branch
3. Testa approfonditamente
4. Invia pull request

## Licenza

Licenza MIT - vedi file [LICENSE](LICENSE).

## Supporto

- **Issues**: [GitHub Issues](https://github.com/Tapiocapioca/brainery/issues)
- **Container**: [brainery-containers issues](https://github.com/Tapiocapioca/brainery-containers/issues)
- **Documentazione**: Vedi [docs/](docs/) per guide dettagliate

## Versione

**Versione corrente**: 1.0.0

Vedi [CHANGELOG.md](CHANGELOG.md) per storico versioni.
