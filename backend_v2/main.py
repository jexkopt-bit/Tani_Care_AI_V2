from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import urllib.request
import tempfile
import base64
from genkit.core import genkit
from genkit.plugins.vertex_ai import vertexai
from google.cloud import discoveryengine_v1 as discoveryengine

# --- CONSTANTS FOR VERTEX AI SEARCH ---
# Replace these with your actual IDs once created in the Google Cloud Console
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "YOUR_PROJECT_ID")
DATA_STORE_LOCATION = "global"  # Or "asia-southeast1" depending on your data store
DATA_STORE_ID = os.getenv("DATA_STORE_ID", "tanicare-rag-datastore")

# Initialize FastAPI
app = FastAPI(title="TaniCare AI Genkit Orchestrator")

# Initialize Genkit
ai = genkit(
    plugins=[vertexai(location="asia-southeast1")],
    model="vertexai/gemini-1.5-pro",
)

class AnalysisRequest(BaseModel):
    image_base64: str
    crop_type: str
    state: str = "Johor"

class AnalysisResponse(BaseModel):
    result: str

async def search_rag_documents(query: str) -> str:
    """Retrieves relevant treatment guidelines from Vertex AI Search (Data Store)."""
    try:
        client = discoveryengine.SearchAsyncClient()
        serving_config = client.serving_config_path(
            project=PROJECT_ID,
            location=DATA_STORE_LOCATION,
            data_store=DATA_STORE_ID,
            serving_config="default_config"
        )
        
        request = discoveryengine.SearchRequest(
            serving_config=serving_config,
            query=query,
            page_size=2,
        )
        
        response = await client.search(request)
        
        context = ""
        for result in response.results:
            # Extract text snippets from the RAG document
            if result.document.derived_struct_data:
                snippets = result.document.derived_struct_data.get("snippets", [])
                for snippet in snippets:
                    context += snippet.get("snippet", "") + "\n"
        
        return context if context else "Tiada rujukan RAG spesifik dijumpai."
    except Exception as e:
        print(f"RAG Error: {e}")
        return "Gagal menyambung ke RAG Data Store."

@ai.flow
async def analyze_crop_flow(crop_type: str, state: str, image_bytes: bytes) -> str:
    """
    Genkit Flow to analyze a crop image for diseases using Vertex AI Gemini.
    """
    # Determine dialect based on state
    dialect = "Bahasa Melayu standard yang mesra"
    if state.lower() in ["kedah", "perlis", "pulau pinang"]:
        dialect = "Loghat Utara (Kedah/Perlis)"
    elif state.lower() in ["kelantan", "terengganu"]:
        dialect = "Dialek Pantai Timur (Kelantan/Ganu)"
    elif state.lower() in ["johor", "melaka"]:
        dialect = "Kelek/Loghat Selatan (Johor)"
        
    # Step 1: Retrieve grounded context from Vertex AI Search
    rag_context = await search_rag_documents(f"Penyakit dan rawatan {crop_type}")
    
    prompt = f"""
    Anda adalah pakar agronomi Malaysia yang bertauliah dan mematuhi undang-undang.
    Analisis gambar tanaman {crop_type.lower()} di negeri {state} ini.
    
    BAHAN RUJUKAN RASMI (RAG CONTEXT):
    Berikut adalah garis panduan rasmi yang DITARIK DARI PANGKALAN DATA (Vertex AI Search). 
    Gunakan konteks ini sebagai sumber utama cadangan rawatan anda:
    {rag_context}
    
    AMARAN PEMATUHAN UNDANG-UNDANG MALAYSIA: 
    Semua diagnosis dan cadangan MESTILAH mematuhi secara ketat:
    1. Akta Racun Makhluk Perosak 1974 (Hanya cadangkan bahan kimia berdaftar).
    2. Akta Kuarantin Tumbuhan 1976 (Sebarang penemuan makhluk perosak invasif MESTI dilaporkan kepada Jabatan Pertanian).
    3. Dasar Agromakanan Negara 2.0 (NAP 2.0) & MyGAP.
    4. Tiada pendedahan data peribadi (PDPA 2010).
    
    Jawab dalam **{dialect}** dengan format berikut:
    1. **Diagnosis**: Nama penyakit / pest (dengan keyakinan %)
    2. **Keterukan**: Rendah / Sederhana / Tinggi
    3. **Anggaran Kewangan (ROI)**: Anggaran kerugian jika dibiarkan vs Kos rawatan anggaran per hektar.
    4. **Rawatan Lestari**: Cadangan kimia (Akta Racun 1974) + organik / IPM (Akta Biokeselamatan 2007)
    5. **Pencegahan**: Langkah mematuhi MyGAP
    6. **Nasihat Keselamatan Makanan**: Kesan kepada hasil negara (NAP 2.0)
    
    Jawapan mestilah terperinci, akurat di sisi undang-undang, selamat, dan mudah difahami oleh petani tempatan.
    """
    
    # In a full Genkit setup, you would also call other tools here!
    # For example: 
    # weather_data = await fetch_local_weather_tool(state)
    # rag_documents = await retrieve_treatment_data_tool(disease_name)
    
    # Generate content using Gemini via Vertex AI plugin
    response = await ai.generate(
        prompt=prompt,
        images=[image_bytes],
    )
    
    return response.text

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_endpoint(request: AnalysisRequest):
    try:
        # Decode the base64 image from the request
        image_bytes = base64.b64decode(request.image_base64)
        
        # Execute the Genkit Flow
        result = await analyze_crop_flow(request.crop_type, request.state, image_bytes)
        return AnalysisResponse(result=result)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "Genkit Backend is running."}
