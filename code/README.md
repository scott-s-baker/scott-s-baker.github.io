# Prism — PMM Decision Intelligence Agent

Signal intelligence and decision governance system for IBM FlashSystem EMEA PMM.
Ingests market signals, clusters them into patterns, and forces binary positioning
decisions with SLA deadlines and outcome tracking.

**Status: Live · V1.2 · July 2026**

---

## What it does

| Layer | Function |
|-------|----------|
| **Ingest** | RSS feeds (13), PeerSpot field reviews (6 vendors), competitor web scrape (10 sources) |
| **Score** | Independence × recency weighting — field/analyst 1.0×, press 0.5×, competitor 0.25× |
| **Embed** | SBERT `all-MiniLM-L6-v2` → Weaviate (384-dim) |
| **Cluster** | UMAP → HDBSCAN → BERTopic with relevance filter and MIN_CLUSTER_SIZE=5 |
| **Interpret** | 4-prompt LLM pipeline → direction, constraint, decision, impact |
| **Govern** | SLA enforcement, tier upgrades, 30/60/90-day outcome tracking |

---

## Infrastructure

| Component | Host | Details |
|-----------|------|---------|
| Docker LXC | `192.168.1.104` | 4 cores · 8GB RAM · Postgres 16, Weaviate, FastAPI `:8000`, Prefect 3 |
| Ollama LXC | `192.168.1.121` | 4 cores · 8GB RAM · `llama3.1:8b` · Intel Arc GPU · Vulkan · 33/33 layers |
| Proxmox host | `192.168.1.80` | Beelink SEi14 · Intel Core Ultra 5 125H · 32GB RAM |

---

## Stack

- **Postgres 16** — signals, patterns, decisions, outcomes
- **Weaviate** — vector store (SBERT vectors, no vectorizer module)
- **FastAPI** — API spine + all endpoints
- **Prefect 3** — pipeline scheduling
- **LLM** — Ollama (default) · swap to Claude via `LLM_PROVIDER=claude`
- **GUI** — React SPA served by FastAPI at `/` · dark/light mode · 4 design
  versions (`v1`-`v4`, switcher persisted in `localStorage`) — v2 (Stan),
  v3 (IBM Carbon), v4 (Scott — own dashboard charts + Configuration flyout
  asset search, gated to v4 only)

---

## Bring-up

```bash
cp .env.example .env          # set OLLAMA_BASE_URL, PG_PASSWORD
docker compose up -d --build
curl localhost:8000/health    # {"api":"ok","llm_provider":"ollama","postgres":"ok","ollama":"ok","signal_count":0}
```

GUI: `http://<host>:8000` · Prefect UI: `http://<host>:4200` · Weaviate: `http://<host>:8080`

---

## Signal sources

### RSS feeds (13 verified · httpx fetcher)
| Family | Source weight |
|--------|--------------|
| DCIG, Futurum Group | analyst 1.0× |
| Blocks & Files, StorageNewsletter, The Register (storage + all), CIO, Computerworld, ITPro, DatacenterDynamics, ZDNet, TechRepublic, eWeek, Pure Storage Blog | press 0.5× |

### PeerSpot reviews (field · 1.0× · slow decay curve)
IBM FlashSystem, Dell PowerStore, Pure FlashArray, NetApp AFF A-Series, HPE Alletra MP, Huawei OceanStor Dorado

### Competitor web scrape (0.25×)
Dell PowerStore/PowerMax, Pure FlashArray/FlashBlade, NetApp AFF-A/C, HPE Alletra MP, Huawei OceanStor Dorado/hi

---

## Running the pipeline

```bash
# Individual stages
curl -X POST localhost:8000/ingest/rss
curl -X POST localhost:8000/ingest/peerspot
curl -X POST localhost:8000/ingest/competitor
curl -X POST localhost:8000/embed
curl -X POST localhost:8000/cluster
curl -X POST localhost:8000/interpret      # manual trigger — requires pattern review first
curl -X POST localhost:8000/stage5

# Review patterns before interpret
curl localhost:8000/patterns               # list unreviewed
curl -X POST localhost:8000/patterns/{id}/review
```

### Cron (runs twice daily)
```
0 6,18 * * * curl -s -X POST http://localhost:8000/ingest/rss > /dev/null && \
              curl -s -X POST http://localhost:8000/ingest/peerspot > /dev/null && \
              curl -s -X POST http://localhost:8000/ingest/competitor > /dev/null && \
              curl -s -X POST http://localhost:8000/embed > /dev/null && \
              curl -s -X POST http://localhost:8000/cluster > /dev/null && \
              curl -s -X POST http://localhost:8000/stage5 > /dev/null
```

`/interpret` is a **manual trigger** — run it after reviewing new patterns in the GUI.

---

## Signal quality design

### Independence weights
```
field / analyst / sales   1.0×   (direct market evidence)
press                     0.5×   (corroborating)
competitor                0.25×  (adversarial discount)
```

### Recency decay
| Source | Curve | Archive threshold |
|--------|-------|------------------|
| field / analyst | Slow — valid 6 months | Never archived (0.25× floor) |
| press / competitor | Fast — stale at 60 days | 0.0× after 60 days |

### Tier thresholds
| Tier | Condition |
|------|-----------|
| EMERGING | ≥ 2.0 weighted count, 1+ source categories |
| CONFIRMED | ≥ 3.0 weighted count, 2+ source categories |
| ESTABLISHED | ≥ 5.0 weighted count, 3+ categories, 30+ days sustained |

---

## Decision output model

Every CONFIRMED/ESTABLISHED pattern produces one decision:

```
signal          Market direction (from → to)
constraint_txt  Which positioning assumption is broken and why
decision_type   FULL_REPOSITION | MESSAGING_ACCENT | FRAMING_SHIFT | HOLD_WITH_TRIGGER
option_a        Commit & act
option_b        Hold — active choice with re-evaluation trigger
urgency         CONFIRMED → medium floor · ESTABLISHED → high floor
commit_by       14 days (medium) · 7 days (high)
outcome         30/60/90-day accuracy review
```

---

## Positioning assumptions

`config/positioning_assumptions.yaml` is git-tracked. Assumptions unreviewed
for >90 days are flagged `STALE` and excluded from decision logic.
**Editing this file IS the governance mechanism — always commit with a rationale.**

---

## Tests

```bash
cd app && python -m pytest tests/ -v
# 66/66 passing — covers signal quality, clustering, stage4/5, recency curves
```

---

## LLM swap

One line in `.env`:
```
LLM_PROVIDER=ollama    # default — llama3.1:8b on Ollama LXC
LLM_PROVIDER=claude    # set ANTHROPIC_API_KEY
```

---

## Git workflow

Canonical editing location is the Mac clone (`~/Documents/Prism`), edited
with Claude Code running locally. The LXC (`/opt/prism`) is a **deploy
target only** — never hand-edit files there.

```bash
# 1. Edit + commit + push from the Mac
cd ~/Documents/Prism
git add -A
git commit -m "fix: <what changed>"
git push

# 2. Pull onto the LXC
ssh root@192.168.1.104 'cd /opt/prism && git pull'

# 3. Restart only if app/*.py changed (GUI-only edits need no restart)
ssh root@192.168.1.104 'docker restart prism-api'
```

---

## Build status

- [x] Stage 1 — stack + schema + 8 DB indexes
- [x] Layer 2 — signal quality framework (source-aware recency, tier thresholds)
- [x] Stage 2 — RSS ingest (httpx fetcher, 13 feeds)
- [x] Phase 1 — signal source expansion (verified feed list)
- [x] Phase 2 — PeerSpot field reviews (6 vendors, 1.0× weight)
- [x] Stage 3 — SBERT embedding + UMAP/HDBSCAN/BERTopic clustering
- [x] Stage 4 — 4-prompt LLM interpretation + deterministic decision IDs
- [x] Stage 5 — SLA enforcement + tier upgrades + outcome tracking
- [x] GUI — React SPA, dark/light mode, decisions/patterns/signals/pipeline views
- [ ] Stage 6 — Slack/Craft delivery, weekly digest, DEFERRED alerts
- [ ] V2 — narrative drift model, entry point validity, Salesforce ISC integration
- [ ] Phase 3 — Gartner Peer Insights + G2 (requires residential proxy)

---

## Recovery

If the Docker LXC is unreachable:
```bash
ssh root@192.168.1.80
pct list                          # find the LXC ID
pct start <id>
pct exec <id> -- systemctl restart ssh
```
