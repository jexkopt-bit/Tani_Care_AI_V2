#!/bin/bash
echo "🚀 Deploying TaniCare AI Genkit Backend to Google Cloud Run..."

# Replace YOUR_PROJECT_ID with your actual Google Cloud Project ID
# Make sure your Docker daemon is running if required, and you are authenticated via: gcloud auth login

gcloud run deploy tanicare-genkit-backend \
  --source ./backend_v2 \
  --region asia-southeast1 \
  --allow-unauthenticated \
  --memory 1Gi \
  --set-env-vars GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID,DATA_STORE_ID=tanicare-rag-datastore

echo "✅ Deployment completed!"
echo "Make sure to copy the Service URL provided above and paste it into lib/gemini_service.dart as your BACKEND_URL!"
