## Developer: jexkopt (jexkopt@gmail.com)
**Project Title:** TaniCare AI – Kawan Petani, Penjaga Tanaman
**Hackathon:** MyAI Future Hackathon 2026 – Track 1: Padi & Plates (Agrotech & Food Security)

## Problem
Malaysia’s rice self-sufficiency ratio is only ~52% in 2026, far below the NAP 2.0 target of 80%. Smallholder farmers (padi, sawit, sayur, buah) lose 30–70% of yield each season due to late detection of crop diseases. Limited access to agronomists and lack of real-time tools worsen food import dependency and threaten farmer livelihoods.

## Solution
TaniCare AI is a smart, farmer-friendly mobile application that enables instant crop disease detection and advanced satellite-based monitoring to empower smallholders with data-driven insights.

## Key Features
- **Multi-Agent AI Pipeline**: Orchestrated workflow (Disease ID, Weather, RAG, ROI, Legal Compliance) using Gemini 1.5 Pro.
- **Advanced Satellite Analysis**: NDVI + EVI + anomaly detection via Google Earth Engine (Sentinel-2).
- **Dialect Localization**: Regional advisory in local Malaysian dialects (Kedah, Kelantan, etc.).
- **Professional Analytics**: Interactive NDVI/EVI trend charts and farm health metrics.
- **Legal Compliance**: Cross-checks treatments against the Pesticides Act 1974.
- **Scan History**: Automatic persistence to Google Cloud Firestore.

## Technology Stack
- **Frontend:** Flutter + Riverpod 2.0
- **Orchestrator:** Firebase Genkit + Vertex AI Agent Builder
- **AI Models:** Google Gemini 1.5 Pro (Vision & Text)
- **Engines:** Google Earth Engine, Open-Meteo API
- **Backend:** Google Cloud Run & Cloud Functions (Python)
- **Database:** Google Cloud Firestore

## Impact
- Expected to reduce crop yield losses by 30–50% for smallholders.
- Supports Malaysia's DKMN 2030 and NAP 2.0 (Smart Agriculture & Food Security).
- Lowers national food import bill and improves farmer resilience.

## Slogan
“Satu Gambar, Banyak Harapan untuk Ladang Anda”

**Submitted by:** jexkopt@gmail.com
**Date:** 19 April 2026