# Esempi d'Uso

Esempi pratici per i workflow comuni di Brainery.

## Prerequisiti

Assicurati che i container siano in esecuzione e AnythingLLM sia configurato:

```bash
docker ps --filter "name=brainery-" --format "table {{.Names}}\t{{.Status}}"
curl http://localhost:9103/api/ping
```

## Esempio 1: Importare un Articolo Web

**Scenario:** Importare un post di un blog tecnico in Brainery per riferimento futuro.

### Passo 1: Importare l'articolo

In Claude Code:

```
Importa questo articolo in Brainery: https://example.com/blog/docker-best-practices
```

Claude utilizzerà:
```
mcp__crawl4ai__md
  url: "https://example.com/blog/docker-best-practices"
  f: "fit"

mcp__anythingllm__embed_webpage
  slug: "brainery"
  url: "https://example.com/blog/docker-best-practices"
```

### Passo 2: Interrogare il contenuto

```
Quali sono le 3 migliori pratiche Docker menzionate nell'articolo che ho appena importato?
```

Claude utilizzerà:
```
mcp__anythingllm__chat_with_workspace
  slug: "brainery"
  message: "Quali sono le 3 migliori pratiche Docker?"
  mode: "query"
```

**Risultato:** Claude recupera le sezioni rilevanti dall'articolo importato e riassume le pratiche chiave.

---

## Esempio 2: Importare Trascrizione Video YouTube

**Scenario:** Estrarre e salvare la trascrizione da un video educativo di YouTube.

### Passo 1: Importare la trascrizione

```
Importa la trascrizione da questo video: https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Claude:
1. Estrae la trascrizione: `mcp__yt-dlp__ytdlp_download_transcript`
2. Incorpora in AnythingLLM: `mcp__anythingllm__embed_text`

### Passo 2: Interrogare il contenuto

```
Riassumi i principali argomenti trattati nella trascrizione del video che ho appena importato.
```

**Risultato:** Claude fornisce un riepilogo strutturato basato sul contenuto della trascrizione.

---

## Esempio 3: Importazione Batch di Più Articoli

**Scenario:** Importare diversi articoli correlati sullo stesso argomento.

```
Importa questi articoli in Brainery:
1. https://example.com/kubernetes-intro
2. https://example.com/kubernetes-networking
3. https://example.com/kubernetes-security

Poi dimmi quali sono i temi comuni tra tutti e tre gli articoli.
```

Claude:
1. Importa ogni articolo in sequenza
2. Interroga tutti i contenuti importati con una singola query RAG
3. Analizza i temi comuni nei documenti

**Vantaggio:** Tutti e tre gli articoli sono ricercabili insieme, consentendo analisi tra documenti.

---

## Esempio 4: Importazione PDF

**Scenario:** Importare un paper di ricerca PDF per l'analisi.

### Se il PDF è accessibile via URL:

```
Importa questo paper di ricerca: https://arxiv.org/pdf/2301.12345.pdf
```

Claude utilizzerà Crawl4AI per estrarre il testo e incorporarlo.

### Se il PDF è locale:

1. **Converti PDF in testo** (configurazione una tantum):
   ```bash
   pdftotext documento.pdf documento.txt
   ```

2. **Carica su URL temporaneo** o usa la funzione di caricamento documenti di AnythingLLM tramite interfaccia web

3. **Interroga il contenuto**:
   ```
   Qual è la conclusione principale del paper di ricerca che ho caricato?
   ```

---

## Esempio 5: Importazione File Audio Locale

**Scenario:** Trascrivere e importare un episodio di podcast o una registrazione di una riunione dalla tua macchina locale.

### Passo 1: Preparare il file audio

Assicurati che il tuo file audio sia in un formato supportato (MP3, WAV, M4A, OGG, FLAC, WEBM).

### Passo 2: Trascrivere con Whisper

```
Trascrivi questo file audio locale: /home/user/podcasts/episodio-123.mp3
```

Claude eseguirà:

1. **Chiamata al server Whisper**:
   ```bash
   curl -X POST http://localhost:9102/transcribe \
     -F "audio=@/home/user/podcasts/episodio-123.mp3" \
     -F "language=auto" \
     -F "model=base"
   ```

2. **Estrazione della trascrizione** dalla risposta JSON

3. **Embed in AnythingLLM**:
   ```
   mcp__anythingllm__embed_text
     slug: "brainery"
     texts: ["<testo trascrizione>"]
   ```

### Passo 3: Interrogare il contenuto

```
Quali sono i temi chiave discussi nell'episodio del podcast che ho appena importato?
```

**Risultato:** Claude recupera la trascrizione e riassume i punti principali della discussione.

### Suggerimenti

- **Per file lunghi (>30 minuti)**: Usa `model=tiny` per un'elaborazione più veloce, poi ri-trascrivi le sezioni importanti con `model=base` o `model=small`
- **Rilevamento lingua**: Usa `language=auto` se non sei sicuro, oppure specifica esplicitamente (`en`, `it`, `zh`)
- **Percorso file**: Usa percorsi assoluti (es. `/home/user/file.mp3`) o relativi alla directory di lavoro di Claude Code

**Casi d'uso comuni:**
- Episodi di podcast per ricerca
- Registrazioni di riunioni per prendere appunti
- Trascrizioni di interviste per analisi
- Memo vocali per knowledge base personale

---

## Esempio 6: Creare Workspace Specifico per Argomento

**Scenario:** Organizzare contenuti per argomento usando workspace separati.

### Passo 1: Creare workspace

```
Crea un nuovo workspace AnythingLLM chiamato "machine-learning"
```

Claude utilizzerà:
```
mcp__anythingllm__create_workspace
  name: "machine-learning"
```

### Passo 2: Importare contenuto in workspace specifico

```
Importa questo articolo nel workspace "machine-learning": https://example.com/ml-tutorial
```

Claude specificherà lo slug del workspace durante l'incorporamento:
```
mcp__anythingllm__embed_webpage
  slug: "machine-learning"
  url: "https://example.com/ml-tutorial"
```

### Passo 3: Interrogare workspace specifico

```
Interroga il workspace machine-learning: Quali sono i concetti chiave nel ML?
```

**Vantaggio:** Il contenuto è organizzato per argomento, prevenendo contaminazione incrociata tra documenti non correlati.

---

## Esempio 6: Filtraggio Avanzato dei Contenuti

**Scenario:** Estrarre solo sezioni rilevanti da un articolo lungo.

### Opzione A: Filtraggio BM25

```
Importa questo articolo usando filtraggio BM25 con query "Docker security":
https://example.com/docker-complete-guide
```

Claude utilizzerà:
```
mcp__crawl4ai__md
  url: "https://example.com/docker-complete-guide"
  f: "bm25"
  q: "Docker security"
```

### Opzione B: Filtraggio LLM

```
Importa questo articolo, ma solo le sezioni sull'ottimizzazione delle prestazioni:
https://example.com/web-development-guide
```

Claude utilizzerà:
```
mcp__crawl4ai__md
  url: "https://example.com/web-development-guide"
  f: "llm"
  q: "performance optimization"
```

**Vantaggio:** Riduce l'uso di token e si concentra solo sui contenuti rilevanti.

---

## Esempio 8: Verificare Successo Importazione

**Scenario:** Assicurarsi che il contenuto sia stato incorporato correttamente prima di procedere.

```
Importa questo articolo: https://example.com/article

Poi verifica che sia stato importato correttamente chiedendo: "Qual è il titolo dell'ultimo articolo che ho importato?"
```

Claude:
1. Importa l'articolo
2. Interroga AnythingLLM per confermare che il contenuto sia recuperabile
3. Segnala successo o fallimento

**Buona Pratica:** Verifica sempre le importazioni, specialmente per documenti critici.

---

## Esempio 8: Contenuti Multilingua

**Scenario:** Importare contenuti in lingue diverse (inglese, italiano, cinese).

### Articolo inglese:
```
Importa: https://example.com/en/article
```

### Articolo italiano:
```
Importa: https://example.com/it/articolo
```

### Articolo cinese:
```
Importa: https://example.com/zh/文章
```

### Interroga in qualsiasi lingua:
```
Quali sono i temi comuni in tutti e tre gli articoli? (Rispondi in italiano)
```

**Vantaggio:** Brainery supporta contenuti multilingua. Il provider LLM (es. glm-4.6 di iFlow) gestisce la traduzione durante le query.

---

## Esempio 9: Eliminare Contenuti Vecchi

**Scenario:** Rimuovere contenuti obsoleti dal workspace.

### Elencare documenti:
```
Mostrami tutti i documenti nel workspace brainery
```

Claude utilizzerà:
```
mcp__anythingllm__list_documents
  slug: "brainery"
```

### Eliminare documento specifico:
```
Elimina il documento con ID "doc_abc123"
```

Claude utilizzerà:
```
mcp__anythingllm__delete_document
  slug: "brainery"
  documentId: "doc_abc123"
```

---

## Esempio 10: Risolvere Importazione Fallita

**Scenario:** L'importazione fallisce a causa di un problema di connessione.

### Messaggio di errore:
```
Error: Failed to connect to http://localhost:9100
```

### Risoluzione:
1. **Controlla stato container:**
   ```bash
   docker ps --filter "name=brainery-crawl4ai"
   ```

2. **Riavvia container se necessario:**
   ```bash
   docker-compose restart crawl4ai
   ```

3. **Riprova importazione:**
   ```
   Importa: https://example.com/article
   ```

---

## Pattern Comuni

### Pattern 1: Importa → Verifica → Interroga

```
1. Importa contenuto
2. Verifica: "Qual è stato l'ultimo articolo che ho importato?"
3. Interroga: "Quali sono i punti chiave?"
```

### Pattern 2: Importazione Batch → Query Aggregata

```
1. Importa più articoli correlati
2. Interroga: "Quali sono i temi comuni tra tutti gli articoli?"
```

### Pattern 3: Organizzazione Workspace

```
1. Crea workspace specifico per argomento
2. Importa tutti i contenuti correlati in quel workspace
3. Interroga il workspace per risultati focalizzati
```

---

## Consigli e Buone Pratiche

1. **Usa `f: "fit"` per la maggior parte delle pagine web** - Estrae contenuti puliti e rilevanti senza annunci/navigazione

2. **Verifica le importazioni** - Testa sempre con una query semplice dopo aver importato documenti critici

3. **Organizza per workspace** - Separa argomenti non correlati in workspace diversi

4. **Pulisci gli URL** - Rimuovi parametri di tracciamento prima di importare:
   ```
   ❌ https://example.com/article?utm_source=twitter&ref=123
   ✅ https://example.com/article
   ```

5. **Controlla limiti di rate** - Se ricevi errori 429, attendi 60 secondi prima di riprovare

6. **Usa mode: "query"** - Usa sempre `mode: "query"` per query RAG, non `mode: "chat"`

---

## Prossimi Passi

- Rivedi la [Guida all'Installazione](installation.md) per le istruzioni di setup
- Controlla [BRAINERY_CONTEXT.md](../../BRAINERY_CONTEXT.md) per la configurazione avanzata
- Visita [brainery-containers](https://github.com/Tapiocapioca/brainery-containers) per la documentazione dei container
