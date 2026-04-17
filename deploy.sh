#!/bin/bash
echo "🚀 Deploying TaniCare AI Earth Engine Backend..."

gcloud functions deploy earth-engine-alerts \
  --gen2 \
  --runtime python312 \
  --region asia-southeast1 \
  --memory 1024MB \
  --timeout 180s \
  --trigger-http \
  --allow-unauthenticated \
  --source backend/functions/earth-engine-alert \
  --entry-point get_earth_engine_alerts

echo "✅ Deployment completed!"
echo "Test URL: https://earth-engine-alerts-asia-southeast1-tanicare-ai-2026.cloudfunctions.net/earth-engine-alerts"