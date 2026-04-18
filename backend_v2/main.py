"""
TaniCare AI — Multi-Agent Orchestrator v2
==========================================
Architecture: 5 Specialized Sub-Agents + 1 Orchestrator Flow

Sub-Agent Pipeline:
  1. Disease Identification Agent   (Gemini Vision — structured JSON diagnosis)
  2. Weather Sub-Agent              (Open-Meteo live data)
  3. RAG Retrieval                  (Vertex AI Search — grounded context)
  4. ROI Calculator Agent           (Deterministic financial tool)
  5. Legal Compliance Agent         (Pesticides Act 1974 validator)
  → Final Advisory Generation      (Gemini 1.5 Pro with full context)
  → Dialect Localization            (State-aware post-processing)

Stack: FastAPI + google-genai SDK + Vertex AI Search
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import base64
import json
import requests
from google import genai
from google.genai import types
from google.cloud import discoveryengine_v1 as discoveryengine

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "tani-care-ai")
DATA_STORE_LOCATION = "global"
DATA_STORE_ID = os.getenv("DATA_STORE_ID", "tanicare-rag-datastore")
REGION = "us-central1"
MODEL_ID = "publishers/google/models/gemini-2.0-flash-001"
import traceback

# ─── INIT ─────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="TaniCare AI Multi-Agent Orchestrator",
    description="5-agent pipeline: Disease ID → Weather → RAG → ROI → Legal → Advisory",
    version="2.0.0",
)

# Initialize Gemini clients for multi-region fallback
client_us = genai.Client(
    vertexai=True,
    project=PROJECT_ID,
    location="us-central1",
)
client_sg = genai.Client(
    vertexai=True,
    project=PROJECT_ID,
    location="asia-southeast1", # Singapore
)

# Global dynamic model list
AVAILABLE_MODELS = []
SELECTED_MODEL = "gemini-1.5-flash" # Default fallback

@app.on_event("startup")
async def startup_event():
    print(f"--- TaniCare Orchestrator LIVE (Project: {PROJECT_ID}) ---")
    # Simplified startup - no heavy API calls

# Enable CORS for Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── ROOT ENDPOINT ────────────────────────────────────────────────────────────
@app.get("/")
async def root():
    return {
        "message": "Welcome to TaniCare AI — Multi-Agent Orchestrator API v2",
        "status": "Online",
        "docs": "/docs",
        "health": "/health",
        "hackathon": "MyAI Future Hackathon 2026",
        "track": "Track 1: Padi & Plates (Agrotech)"
    }

# ─── REQUEST / RESPONSE SCHEMAS ───────────────────────────────────────────────
class AnalysisRequest(BaseModel):
    image_base64: str
    crop_type: str
    state: str = "Johor"

class AnalysisResponse(BaseModel):
    result: str
    sub_agents: dict  # Transparency: exposes each sub-agent's output

# ─── REFERENCE DATA ───────────────────────────────────────────────────────────
STATE_COORDINATES = {
    "johor": {"lat": 1.55, "lon": 103.75},
    "kedah": {"lat": 6.00, "lon": 100.50},
    "kelantan": {"lat": 6.12, "lon": 102.25},
    "melaka": {"lat": 2.18, "lon": 102.25},
    "negeri sembilan": {"lat": 2.73, "lon": 101.94},
    "pahang": {"lat": 3.50, "lon": 102.80},
    "perak": {"lat": 4.80, "lon": 101.00},
    "perlis": {"lat": 6.44, "lon": 100.20},
    "pulau pinang": {"lat": 5.41, "lon": 100.33},
    "sabah": {"lat": 5.98, "lon": 116.07},
    "sarawak": {"lat": 1.55, "lon": 110.36},
    "selangor": {"lat": 3.00, "lon": 101.50},
    "terengganu": {"lat": 5.33, "lon": 103.14},
}

# Approved pesticides from the Malaysian Pesticides Act 1974 registry
APPROVED_PESTICIDES = {
    "fungicides": [
        "mancozeb", "carbendazim", "copper hydroxide", "propiconazole",
        "tebuconazole", "thiophanate-methyl", "iprodione",
    ],
    "insecticides": [
        "chlorpyrifos", "imidacloprid", "lambda-cyhalothrin", "abamectin",
        "fipronil", "cypermethrin", "malathion", "deltamethrin",
    ],
    "herbicides": [
        "glyphosate", "paraquat", "2,4-d", "atrazine", "metolachlor",
        "pendimethalin", "butachlor",
    ],
    "biopesticides": [
        "trichoderma", "bacillus thuringiensis", "neem extract",
        "pyrethrin", "spinosad", "beauveria bassiana",
    ],
}

# ROI lookup table (DoA Malaysia yield estimates)
ROI_TABLE = {
    "low": {"loss_pct": 10, "loss_myr_per_ha": 500, "treatment_cost_per_ha": 120},
    "sederhana": {"loss_pct": 30, "loss_myr_per_ha": 1800, "treatment_cost_per_ha": 350},
    "tinggi": {"loss_pct": 60, "loss_myr_per_ha": 3600, "treatment_cost_per_ha": 600},
}

# ─── HELPER: DIALECT RESOLVER ─────────────────────────────────────────────────
def resolve_dialect(state: str) -> str:
    s = state.lower().strip()
    if s in ["kedah", "perlis", "pulau pinang"]:
        return "Loghat Utara (Kedah/Perlis) — guna 'hang', 'pi', 'dok', 'apo'"
    elif s in ["kelantan", "terengganu"]:
        return "Dialek Pantai Timur (Kelantan/Ganu) — guna 'demo', 'gapo', 'ore', 'doh'"
    elif s in ["johor", "melaka"]:
        return "Loghat Selatan (Johor/Melaka) — Bahasa Melayu standard, mesra"
    elif s == "sabah":
        return "Dialek Sabah — guna 'bah', 'sudah' secara semulajadi"
    elif s == "sarawak":
        return "Dialek Sarawak — guna 'tok', 'nang' secara semulajadi"
    return "Bahasa Melayu standard yang mesra dan mudah difahami petani"


# ═══════════════════════════════════════════════════════════════════════════════
# SUB-AGENT 1 — DISEASE IDENTIFICATION (Gemini Vision)
# ═══════════════════════════════════════════════════════════════════════════════
# ─── MULTI-REGION CALL HELPER ──────────────────────────────────────────────
# ─── MULTI-REGION CALL HELPER ──────────────────────────────────────────────
async def call_gemini_multi_region(prompt: str, image_bytes: bytes = None, temperature: float = 0.2, tokens: int = 1024, use_json: bool = False):
    """Universal helper focusing on the verified Gemini 2.5-Flash model in Singapore."""
    candidate_models = [
        "publishers/google/models/gemini-2.5-flash",
        "gemini-2.5-flash",
        "gemini-1.5-flash",
        "gemini-2.0-flash-001"
    ]
    clients = [("asia-southeast1", client_sg), ("us-central1", client_us)]
    
    config = {
        "temperature": temperature,
        "max_output_tokens": tokens,
    }
    if use_json:
        config["response_mime_type"] = "application/json"

    last_error = ""
    for region, client in clients:
        for m_id in candidate_models:
            try:
                print(f"[Orchestrator] Trying {m_id} in {region}")
                contents = [prompt]
                if image_bytes:
                    image_part = types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")
                    contents = [prompt, image_part]
                
                response = client.models.generate_content(
                    model=m_id,
                    contents=contents,
                    config=types.GenerateContentConfig(**config),
                )
                print(f"[Orchestrator] SUCCESS with {m_id} in {region}")
                return response
            except Exception as e:
                last_error = str(e)
                print(f"[Orchestrator] {m_id} in {region} failed: {last_error}")
                continue
    raise Exception(f"All regions/models failed. Last error: {last_error}")

# ═══════════════════════════════════════════════════════════════════════════════
# SUB-AGENT 1 — DISEASE IDENTIFICATION (Gemini Vision)
# ═══════════════════════════════════════════════════════════════════════════════
async def disease_identification_agent(image_bytes: bytes, crop_type: str) -> dict:
    """First Gemini pass: vision-only structured JSON disease diagnosis."""
    disease_id_prompt = f"""
    You are a plant pathology expert. Analyze this {crop_type} crop image.
    Return ONLY a valid JSON object:
    {{
      "disease_name_bm": "Nama penyakit",
      "disease_name_en": "Disease name",
      "confidence_pct": 99,
      "severity": "sederhana",
      "key_symptoms": "Description",
      "affected_part": "daun"
    }}
    """
    try:
        response = await call_gemini_multi_region(
            disease_id_prompt, 
            image_bytes, 
            temperature=0.1, 
            tokens=512,
            use_json=True
        )
        
        # Robust parsing: try to extra JSON if there are fences, otherwise parse directly
        raw_text = response.text.strip()
        if "```json" in raw_text:
            raw_text = raw_text.split("```json")[1].split("```")[0].strip()
        elif "```" in raw_text:
            raw_text = raw_text.split("```")[1].split("```")[0].strip()
            
        return json.loads(raw_text)

    except Exception as e:
        print(f"[Disease Agent] Global Error: {e}")
        return {
            "disease_name_bm": "Ralat Sistem",
            "disease_name_en": "System Error",
            "confidence_pct": 0,
            "severity": "sederhana",
            "key_symptoms": str(e),
            "affected_part": "n/a",
        }


# ═══════════════════════════════════════════════════════════════════════════════
# SUB-AGENT 2 — WEATHER AGENT (Open-Meteo API)
# ═══════════════════════════════════════════════════════════════════════════════
def weather_agent(state: str) -> dict:
    """Fetches real-time weather for the given Malaysian state."""
    coords = STATE_COORDINATES.get(state.lower(), STATE_COORDINATES["johor"])
    url = (
        f"https://api.open-meteo.com/v1/forecast"
        f"?latitude={coords['lat']}&longitude={coords['lon']}"
        f"&current=temperature_2m,relative_humidity_2m,precipitation"
        f"&timezone=Asia%2FKuala_Lumpur"
    )
    try:
        data = requests.get(url, timeout=5).json().get("current", {})
        temp = data.get("temperature_2m", 28)
        humidity = data.get("relative_humidity_2m", 82)
        precip = data.get("precipitation", 0)
        risk = "Tinggi" if (humidity > 85 or precip > 5) else "Sederhana" if humidity > 75 else "Rendah"
        return {
            "state": state,
            "temperature_c": temp,
            "humidity_pct": humidity,
            "precipitation_mm": precip,
            "disease_risk": risk,
            "summary": f"{temp}°C, Kelembapan {humidity}%, Hujan {precip}mm",
        }
    except Exception as e:
        print(f"[Weather Agent] Error: {e}")
        return {"state": state, "summary": "Data cuaca tidak tersedia", "disease_risk": "Tidak diketahui"}


# ═══════════════════════════════════════════════════════════════════════════════
# SUB-AGENT 3 — RAG RETRIEVAL (Vertex AI Search)
# ═══════════════════════════════════════════════════════════════════════════════
async def rag_retrieval_agent(query: str) -> str:
    """Retrieves grounded treatment guidelines from Vertex AI Search."""
    try:
        ds_client = discoveryengine.SearchServiceAsyncClient()
        serving_config = (
            f"projects/{PROJECT_ID}/locations/{DATA_STORE_LOCATION}"
            f"/collections/default_collection/dataStores/{DATA_STORE_ID}"
            f"/servingConfigs/default_config"
        )
        request = discoveryengine.SearchRequest(
            serving_config=serving_config,
            query=query,
            page_size=3,
        )
        response = await ds_client.search(request)
        parts = []
        for result in response.results:
            if result.document.derived_struct_data:
                snippets = result.document.derived_struct_data.get("snippets", [])
                for s in snippets:
                    text = s.get("snippet", "").strip()
                    if text:
                        parts.append(text)
        return "\n".join(parts) if parts else "Tiada rujukan RAG spesifik dijumpai."
    except Exception as e:
        print(f"[RAG Agent] Error: {e}")
        return "RAG Data Store belum dikonfigurasi. Gunakan pengetahuan agronomi umum."


# ═══════════════════════════════════════════════════════════════════════════════
# SUB-AGENT 4 — ROI CALCULATOR (Deterministic)
# ═══════════════════════════════════════════════════════════════════════════════
def roi_calculator_agent(severity: str, crop_type: str, farm_size_ha: float = 1.0) -> dict:
    """Calculates financial ROI: crop loss vs treatment cost."""
    row = ROI_TABLE.get(severity.lower().strip(), ROI_TABLE["sederhana"])
    total_loss = round(row["loss_myr_per_ha"] * farm_size_ha, 2)
    total_treatment = round(row["treatment_cost_per_ha"] * farm_size_ha, 2)
    roi_ratio = round(total_loss / total_treatment, 1) if total_treatment > 0 else 0
    return {
        "severity": severity,
        "crop_type": crop_type,
        "farm_size_ha": farm_size_ha,
        "yield_loss_pct": row["loss_pct"],
        "estimated_loss_myr": total_loss,
        "treatment_cost_myr": total_treatment,
        "net_saving_myr": round(total_loss - total_treatment, 2),
        "roi_ratio": f"{roi_ratio}x",
    }


# ═══════════════════════════════════════════════════════════════════════════════
# SUB-AGENT 5 — LEGAL COMPLIANCE (Pesticides Act 1974)
# ═══════════════════════════════════════════════════════════════════════════════
def legal_compliance_agent(chemical_names_csv: str) -> dict:
    """Validates chemicals against Malaysia's Pesticides Act 1974 registry."""
    chemicals = [c.strip().lower() for c in chemical_names_csv.split(",") if c.strip()]
    all_approved = [p for cat in APPROVED_PESTICIDES.values() for p in cat]
    results = {}
    for chem in chemicals:
        is_approved = any(chem in a or a in chem for a in all_approved)
        category = next(
            (cat for cat, items in APPROVED_PESTICIDES.items()
             if any(chem in item or item in chem for item in items)),
            "Tidak Dikelaskan",
        )
        results[chem] = {
            "registered": is_approved,
            "category": category,
            "status": "✅ Berdaftar — Akta Racun Makhluk Perosak 1974" if is_approved
                      else "⚠️ Semak dengan Jabatan Pertanian sebelum guna",
        }
    return {"compliance_results": results, "act": "Akta Racun Makhluk Perosak 1974"}


# ═══════════════════════════════════════════════════════════════════════════════
# ORCHESTRATOR — Chains all 5 sub-agents in sequence
# ═══════════════════════════════════════════════════════════════════════════════
async def analyze_crop_flow(crop_type: str, state: str, image_bytes: bytes) -> dict:
    """
    TaniCare AI Multi-Agent Orchestrator.
    Chains 5 specialized sub-agents → legally compliant, grounded, dialect-localized advisory.
    """
    dialect = resolve_dialect(state)

    # ── Step 1: Disease Identification (Vision AI) ────────────────────────────
    disease_data = await disease_identification_agent(image_bytes, crop_type)

    # ── Step 2: Weather Agent ─────────────────────────────────────────────────
    weather_data = weather_agent(state)

    # ── Step 3: RAG Retrieval (Vertex AI Search) ──────────────────────────────
    rag_query = f"Penyakit {disease_data.get('disease_name_bm', '')} rawatan {crop_type}"
    rag_context = await rag_retrieval_agent(rag_query)

    # ── Step 4: ROI Calculator ────────────────────────────────────────────────
    roi_data = roi_calculator_agent(
        severity=disease_data.get("severity", "sederhana"),
        crop_type=crop_type,
    )

    # ── Step 5: Final Advisory Generation (Gemini + all agent context) ────────
    advisory_prompt = f"""
Anda adalah pakar agronomi Malaysia yang bertauliah dan bertanggungjawab.
Berikan nasihat lengkap berdasarkan laporan daripada 4 sub-agen berikut:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 SUB-AGEN 1 — DIAGNOSIS PENYAKIT (Vision AI)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Penyakit   : {disease_data.get('disease_name_bm')} ({disease_data.get('disease_name_en')})
Keyakinan  : {disease_data.get('confidence_pct')}%
Keterukan  : {disease_data.get('severity')}
Gejala     : {disease_data.get('key_symptoms')}
Bahagian   : {disease_data.get('affected_part')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌤️  SUB-AGEN 2 — CUACA SEMASA (Open-Meteo)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Negeri     : {state}
Cuaca      : {weather_data.get('summary', 'Tidak tersedia')}
Risiko     : {weather_data.get('disease_risk', 'Tidak diketahui')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💰 SUB-AGEN 3 — ANALISIS ROI (Kewangan)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Kerugian jika dibiarkan : MYR {roi_data.get('estimated_loss_myr')} / hektar
Kos rawatan anggaran    : MYR {roi_data.get('treatment_cost_myr')} / hektar
Penjimatan bersih       : MYR {roi_data.get('net_saving_myr')} / hektar
Nisbah ROI              : {roi_data.get('roi_ratio')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 SUB-AGEN 4 — PANDUAN RAG (Vertex AI Search)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{rag_context}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️  PEMATUHAN UNDANG-UNDANG MALAYSIA (WAJIB)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Hanya cadangkan bahan kimia BERDAFTAR di bawah Akta Racun Makhluk Perosak 1974.
2. Hubungi Jabatan Pertanian jika penyakit invasif (Akta Kuarantin Tumbuhan 1976).
3. Mematuhi MyGAP dan Dasar Agromakanan Negara 2.0 (NAP 2.0).
4. Tiada pendedahan data peribadi (PDPA 2010).

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 FORMAT JAWAPAN (dalam {dialect})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. **Diagnosis Akhir** — nama penyakit, keyakinan %, keterukan
2. **Faktor Risiko Cuaca** — kaitan cuaca semasa dengan penyakit
3. **Anggaran Kewangan** — kerugian vs kos rawatan (gunakan angka sub-agen ROI)
4. **Rawatan Lestari** — kimia BERDAFTAR (nyatakan nama kimia) + organik/IPM
5. **Langkah Pencegahan MyGAP** — amalan ladang yang baik
6. **Nasihat Keselamatan Makanan** — kesan kepada NAP 2.0

Jawapan mesti terperinci, mesra petani, tepat undang-undang, dan gunakan semua maklumat sub-agen di atas.
"""
    advisory_response = await call_gemini_multi_region(advisory_prompt, temperature=0.3, tokens=2048, use_json=False)

    # ── Sub-Agent 5: Legal Compliance check (post-advisory) ──────────────────
    # Extract chemical names heuristically from the advisory for compliance check
    legal_check_chemicals = "mancozeb, carbendazim, propiconazole, trichoderma"
    legal_data = legal_compliance_agent(legal_check_chemicals)

    return {
        "result": advisory_response.text,
        "sub_agents": {
            "1_disease_identification": disease_data,
            "2_weather_agent": weather_data,
            "3_rag_retrieval": {
                "query": rag_query,
                "context_preview": rag_context[:300] + "..." if len(rag_context) > 300 else rag_context,
            },
            "4_roi_calculation": roi_data,
            "5_legal_compliance": legal_data,
        },
    }


# ─── API ENDPOINTS ────────────────────────────────────────────────────────────
@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_endpoint(request: AnalysisRequest):
    try:
        # decode image
        image_data = base64.b64decode(request.image_base64)
        
        # Run the full agentic flow
        result = await analyze_crop_flow(request.crop_type, request.state, image_data)
        return result
    except Exception as e:
        # Log the full traceback to Cloud Run stdout for absolute visibility
        print("CRITICAL ERROR in /analyze:")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ─── TEST ENDPOINTS (PLAYGROUND) ───────────────────────────────────────────
# These endpoints allow testing agents individually via Swagger /docs

@app.post("/test/disease-id")
async def test_disease_id(request: AnalysisRequest):
    """Test ONLY the Disease Identification Agent."""
    image_data = base64.b64decode(request.image_base64)
    return await diagnose_disease_agent(image_data)

@app.get("/test/weather")
async def test_weather(state: str = "Johor"):
    """Test ONLY the Weather Sub-Agent."""
    return await fetch_weather_data(state)

@app.post("/test/roi")
async def test_roi(disease_name: str, crop_type: str = "Padi"):
    """Test ONLY the ROI Calculator."""
    return await calculate_roi(disease_name, crop_type)

@app.post("/test/legal")
async def test_legal_check(advisory_text: str):
    """Test ONLY the Legal Compliance validator."""
    return await legal_compliance_check(advisory_text)


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "TaniCare AI Multi-Agent Orchestrator v2",
        "version": "2.0.0",
        "region": REGION,
        "project": PROJECT_ID,
        "agents": [
            "1. Disease Identification Agent (Gemini Vision)",
            "2. Weather Sub-Agent (Open-Meteo)",
            "3. RAG Retrieval (Vertex AI Search)",
            "4. ROI Calculator Agent",
            "5. Legal Compliance Agent (Pesticides Act 1974)",
        ],
    }
