# Project Improvement & Data Collection Plan

This document outlines potential improvements for the TaniCare AI project and strategies for collecting dummy data for development and testing.

## 1. Project Improvements

### 1.1. Security & Authentication (High Priority)
- **Action:** Secure the backend Cloud Function.
- **Implementation:**
  - The function is currently a public endpoint.
  - **Option A (Recommended):** Integrate Firebase Authentication. The client app (Flutter) would send the user's ID token in the `Authorization` header of the HTTP request.
  - The Python Cloud Function would use the Firebase Admin SDK to verify this token before processing the request.
  - **Option B (Simpler):** Implement API Key authentication. Generate a secret key, store it securely on the client and server (e.g., using Secret Manager on GCP), and require it in a request header.

### 1.2. User Features & Personalization
- **Action:** Implement User Profiles and personalized history.
- **Implementation:**
  - Create a `users` collection in Firestore.
  - When a user first signs up/in, create a document for them.
  - Store user preferences like default `state` and `crop`.
  - Link analytics results to the user's ID. When `analytics_provider` saves data to the `analytics` collection, it should include a `userId` field.
  - Modify the `analytics_provider` to fetch historical data for the currently logged-in user, instead of just making a new call every time.

### 1.3. Performance & Cost Optimization
- **Action:** Implement caching for Earth Engine & Gemini results.
- **Implementation:**
  - **Backend Caching:** For the Earth Engine data, results are unlikely to change more than once a day for a given location. Use a simple cache (like a Firestore document or Cloud Memorystore) to store the results of a request for a specific state/crop for a few hours. Before running the `ee` logic, check if a recent, valid cache entry exists.
  - **Client-Side Caching:** The Gemini analysis for the same image will always yield the same result. If a user scans the same image twice, store the result locally on the device (e.g., using `shared_preferences` or a simple local DB like `sqflite`) keyed by a hash of the image file.

### 1.4. DevOps & Testing
- **Action:** Create a basic CI/CD pipeline and add tests.
- **Implementation:**
  - **CI/CD:** Use GitHub Actions to:
    - Run `flutter analyze` and `flutter test` on every push to `main`.
    - Automatically deploy the Cloud Function when changes are pushed to `backend/functions`.
  - **Testing:**
    - **Flutter:** Write unit tests for the providers and services. Write widget tests for the screens.
    - **Python:** Write unit tests for the Cloud Function, mocking the `ee` and `requests` libraries.

## 2. Dummy Data Collection Strategy

### 2.1. Crop Image Data
- **Objective:** Obtain a dataset of crop images showing various diseases and pest infestations to test the `GeminiService`.
- **Strategy 1: Public Datasets**
  - **Description:** Find and download existing open-source datasets. This is the most reliable and legally sound method.
  - **Execution:**
    1. Use web searches to find relevant datasets on platforms like Kaggle, Mendeley Data, or university archives.
    2. Example search queries:
       - "paddy disease image dataset"
       - "plant disease dataset PlantVillage"
       - "agricultural pest image dataset kaggle"
- **Strategy 2: Web Scraping**
  - **Description:** Scrape images from agricultural websites or image search engines.
  - **Execution:**
    1. Write a simple Python script using libraries like `requests` and `BeautifulSoup`.
    2. **CRITICAL:** Be mindful of `robots.txt` and the terms of service of the websites you scrape. Do not use scraped images for commercial purposes without permission.
- **Strategy 3: Generative AI**
  - **Description:** Use a text-to-image model to generate synthetic images.
  - **Execution:**
    - Use a service (like Midjourney, DALL-E, or Gemini's own image generation) with prompts like:
      - "photorealistic image of a rice paddy leaf with brown spot disease, close-up"
      - "a chili plant leaf infested with aphids, macro photography"

### 2.2. Analytics Time-Series Data
- **Objective:** Generate realistic historical data for NDVI, EVI, and weather to test the analytics screen.
- **Strategy 1: Enhanced Simulation**
  - **Description:** Improve the existing random data generation in `backend/functions/main.py` to be more realistic.
  - **Execution:**
    - Instead of `random.uniform`, model the data with more structure. For example, a yearly seasonal trend (sine wave) with some added random noise.
    - Simulate weather events, e.g., a few days of heavy rain (`precipitation > 0`) could correspond to a slight dip in NDVI/EVI.
- **Strategy 2: Real Historical Data**
  - **Description:** Find a public API that provides historical weather and satellite data.
  - **Execution:**
    1. Search for free weather history APIs.
    2. Search for public APIs that provide historical NDVI/EVI data (this is less common for free).
    3. Write a script to fetch data for a specific location in Malaysia for the past year and store it in a JSON file that your development environment can read.
