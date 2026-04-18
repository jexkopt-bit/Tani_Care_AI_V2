# TaniCare AI — Vertex AI Agent Builder Setup Guide
## MyAI Future Hackathon 2026 Compliance

This guide walks you through creating the **Vertex AI Agent Builder** agent in the GCP Console to satisfy the hackathon's mandatory "Orchestrator" requirement.

---

## Why Do We Need This?

The hackathon mandate explicitly requires:
> *"The Orchestrator: **Vertex AI Agent Builder** and Firebase Genkit for building Agentic AI workflows."*

Our `backend_v2/main.py` uses **Genkit** (✅ done). We need to also provision an **Agent Builder** agent in GCP Console to fully comply.

---

## Step 1 — Enable APIs

Run in Cloud Shell or terminal:
```bash
gcloud services enable \
  dialogflow.googleapis.com \
  discoveryengine.googleapis.com \
  aiplatform.googleapis.com \
  --project=tani-care-ai
```

---

## Step 2 — Open Vertex AI Agent Builder

1. Go to [GCP Console](https://console.cloud.google.com)
2. Search: **"Agent Builder"**
3. Click **"Vertex AI Agent Builder"**
4. Click **"Create App"**

---

## Step 3 — Create the Agent App

| Field | Value |
|---|---|
| App type | **Agent** |
| App name | `TaniCare AI Orchestrator` |
| Company name | `jexkopt@gmail.com` |
| Region | `us-central1` |

Click **"Create"**

---

## Step 4 — Configure the Default Agent

Inside Agent Builder, go to **"Agents" → "Default Generative Agent"**

**Display Name:** `TaniCare Crop Advisory Agent`

**Goal:**
```
Anda adalah pakar agronomi Malaysia yang bertauliah. Tugas anda adalah menganalisis imej tanaman yang diserahkan oleh petani, mengenal pasti penyakit, memeriksa cuaca semasa, mengira ROI rawatan, mengesahkan pematuhan undang-undang di bawah Akta Racun Makhluk Perosak 1974, dan memberikan nasihat rawatan yang lengkap dalam dialek tempatan petani.
```

**Agent Instructions:**
```
1. Terima imej tanaman dan maklumat negeri dari pengguna.
2. Gunakan alat 'identify_disease' untuk mengenal pasti penyakit dari imej.
3. Gunakan alat 'get_weather' untuk mendapatkan cuaca semasa di negeri tersebut.
4. Gunakan Vertex AI Search (RAG) untuk mendapatkan panduan rawatan rasmi.
5. Gunakan alat 'calculate_roi' untuk mengira anggaran kerugian vs kos rawatan.
6. Gunakan alat 'check_legal_compliance' untuk mengesahkan bahan kimia yang dicadangkan.
7. Berikan nasihat lengkap dalam dialek Bahasa Melayu yang sesuai dengan negeri.
8. SENTIASA mematuhi: Akta Racun Makhluk Perosak 1974, Akta Kuarantin Tumbuhan 1976, MyGAP, NAP 2.0, PDPA 2010.
```

---

## Step 5 — Add Data Store (RAG Grounding)

1. In Agent Builder, click **"Data Stores"** in the left panel
2. Click **"Create Data Store"**
3. Choose source: **"Cloud Storage"** or **"Upload files"**
4. Upload the 3 files from `rag_docs/`:
   - `paddy_diseases_guide.txt`
   - `pesticides_act_1974_summary.txt`
   - `mygap_guidelines.txt`
5. Data store ID: `tanicare-rag-datastore`
6. Click **"Create"**

> **OR** run `python setup_vertex_search.py` which does this automatically via the API.

---

## Step 6 — Link Data Store to Agent

1. Go to **Default Agent → Tools**
2. Click **"+ Add Tool"**
3. Select **"Data Store"**
4. Choose `tanicare-rag-datastore`
5. Click **"Save"**

---

## Step 7 — Add OpenAPI Tool (Link to Cloud Run)

1. Go to **Default Agent → Tools → + Add Tool**
2. Select **"OpenAPI"**
3. Tool Name: `tanicare_backend`
4. OpenAPI spec URL: `https://<YOUR_CLOUD_RUN_URL>/openapi.json`
5. Click **"Save"**

---

## Step 8 — Test the Agent

1. Go to **"Test Agent"** in the right panel
2. Type: `"Saya ada padi di Kedah, sila analisis penyakit ini"`
3. Verify the agent responds using RAG context and tools

---

## Step 9 — Get the Agent ID for Documentation

After creation, note your Agent ID from the URL:
```
https://console.cloud.google.com/agent-builder/agents/<AGENT_ID>
```

Add this to your README.md submission.

---

## Architecture Diagram

```
Flutter App
    │
    ├──► Vertex AI Agent Builder (GCP Console)
    │         │
    │         ├── Data Store Tool (RAG — tanicare-rag-datastore)
    │         └── OpenAPI Tool → Cloud Run (Genkit Backend)
    │                                │
    └──► Cloud Run /analyze          ├── Disease ID Sub-Agent (Gemini Vision)
              │                      ├── Weather Sub-Agent (Open-Meteo)
              └── Genkit Flow        ├── ROI Calculator Agent
                                     ├── Legal Compliance Agent
                                     └── Dialect Localization
```
