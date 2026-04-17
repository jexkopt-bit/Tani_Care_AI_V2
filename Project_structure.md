Tani_Care_ai/                          # Root Project Folder
├── android/                           # Flutter Android folder
├── ios/                               # Flutter iOS folder
├── lib/
│   ├── main.dart                      # Entry point + Bottom Navigation
│   ├── gemini_service.dart            # Gemini AI for crop disease diagnosis
│   ├── earth_engine_service.dart      # Calls backend for NDVI/EVI + weather
│   ├── screens/
│   │   ├── home_screen.dart           # Home with quick alerts
│   │   ├── scan_screen.dart           # Camera scan for disease detection
│   │   ├── result_screen.dart         # Diagnosis result page
│   │   ├── analytics_screen.dart      # ← Advanced Dashboard with charts
│   │   └── alerts_screen.dart         # Dedicated alerts list
│   └── utils/
│       └── constants.dart             # Colors & branding
│
├── backend/
│   └── functions/
│       └── earth-engine-alert/
│           ├── main.py                # Real Earth Engine + Real-time Weather
│           └── requirements.txt
│
├── assets/
│   └── logo.png                       # Optional TaniCare logo
│
├── pubspec.yaml
├── deploy.sh                          # One-click backend deployment
├── README.md
└── .gitignore