#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# TaniCare AI — Deploy Genkit Multi-Agent Backend to Google Cloud Run
# Region: us-central1 (cost-optimized)
# ─────────────────────────────────────────────────────────────────────────────

set -e  # Exit immediately if any command fails

PROJECT_ID="tani-care-ai"
SERVICE_NAME="tanicare-genkit-backend"
REGION="us-central1"
DATA_STORE_ID="tanicare-rag-datastore"

echo "🌾 TaniCare AI — Deploying Multi-Agent Backend..."
echo "   Project : $PROJECT_ID"
echo "   Region  : $REGION"
echo "   Service : $SERVICE_NAME"
echo ""

# Authenticate (if not already done)
# gcloud auth login
# gcloud config set project $PROJECT_ID

gcloud run deploy $SERVICE_NAME \
  --source ./backend_v2 \
  --region $REGION \
  --allow-unauthenticated \
  --memory 1Gi \
  --cpu 1 \
  --timeout 120 \
  --set-env-vars "GOOGLE_CLOUD_PROJECT=${PROJECT_ID},DATA_STORE_ID=${DATA_STORE_ID}" \
  --project $PROJECT_ID

echo ""
echo "✅ Deployment complete!"
echo "📋 Next steps:"
echo "   1. Copy the Service URL above"
echo "   2. Paste it into lib/gemini_service.dart as BACKEND_URL"
echo "   3. Run setup_vertex_search.py to provision the RAG data store"
