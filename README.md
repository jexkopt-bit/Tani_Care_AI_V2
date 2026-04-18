# TaniCare AI – Kawan Petani, Penjaga Tanaman

![TaniCare AI Banner](assets/banner.jpeg)

![Fully Assisted by AI](https://img.shields.io/badge/Status-Fully%20Assisted%20by%20AI-blueviolet?style=for-the-badge) ![NotebookLM](https://img.shields.io/badge/Generated%20by-NotebookLM-blue?style=for-the-badge&logo=google)

**Developer:** jexkopt@gmail.com  
**Hackathon:** MyAI Future Hackathon 2026  
**Track:** Track 1 – Padi & Plates (Agrotech & Food Security)

## Project Overview

TaniCare AI is a smart mobile application designed to help Malaysian smallholder farmers detect crop diseases instantly and receive intelligent recommendations using Google AI technologies.

**Live Demo (Official):** [https://tanicare-frontend-672367571031.us-central1.run.app](https://tanicare-frontend-672367571031.us-central1.run.app)

By combining **Gemini 1.5 Flash** for image analysis, **Vertex AI Search (RAG)** for grounded Malaysian agricultural context, and **real-time weather data**, the app provides actionable insights in simple Bahasa Melayu to reduce yield losses and support national food security goals.

## Key Features

- **Instant Disease Diagnosis**: 5-Agent Pipeline (Diagnosis → Weather → RAG → ROI → Legal)
- **Agentic Orchestration**: Autonomous multi-step reasoning using Firebase Genkit.
- **RAG Integration**: Grounded in official Malaysian crop guides via Vertex AI Search.
- **Real-time Weather Integration**: Live Open-Meteo data for precise risk alerts.
- **Beautiful Analytics Dashboard**: Interactive UI for farmer engagement.
- **Multi-State Support**: Customized dialect resolution for 13 Malaysian states.
- **Strict Legal Compliance**: Validation against the Pesticides Act 1974.

## Technology Stack

- **Frontend**: Flutter (Material 3) + Riverpod 2.0 (advanced state management)
- **AI Analysis**: Google Gemini 1.5 Pro (multimodal)
- **Satellite Data**: Google Earth Engine (Sentinel-2)
- **Weather Data**: Open-Meteo Real-time API
- **Database**: Google Cloud Firestore (GCP)
- **Backend**: Google Cloud Run (Python / Firebase Genkit)
- **Charts**: fl_chart
- **Performance**: Optimized with const constructors, caching, and minimal rebuilds

## Project Structure

tani_care_ai/
├── lib/
│   ├── main.dart
│   ├── providers/
│   ├── screens/
│   ├── utils/constants.dart
│   └── gemini_service.dart, earth_engine_service.dart
├── backend_v2/
│   ├── main.py (Genkit Agent)
│   └── Dockerfile
├── pubspec.yaml
├── deploy_v2.sh
└── README.md

## How to Run

### Flutter App
```bash
flutter pub get
flutter run
```

### Backend (Google Cloud Run)
```bash
# 1. Authorize your terminal
gcloud auth login

# 2. Deploy the Genkit Agent
chmod +x deploy_v2.sh
./deploy_v2.sh
```

## Impact

- Helps reduce crop yield losses by 30–50% through early detection
- Directly supports DKMN 2030 and NAP 2.0 (National Food Security Policy)
- Empowers smallholder farmers with accessible AI technology
- Contributes to lowering Malaysia’s food import dependency

---
**Developed by:** jexkopt@gmail.com  
**Submission for:** MyAI Future Hackathon 2026

> ## 🛡️ Section 4: AI Disclosure
> In strict compliance with Section 4 (Code of Conduct & Plagiarism Policy) of the MyAI Future Hackathon Official Handbook, we declare that this project's development was **significantly assisted by Google AI Ecosystem tools**. 
> - **Code Generation**: Google Antigravity & Gemini 1.5 Pro were used for architecting the multi-agent orchestrator and Flutter state management.
> - **Orchestration**: Firebase Genkit was used to design the agentic workflows.
> - **Documentation**: Project summaries and technical documentation were refined using Google AI.
